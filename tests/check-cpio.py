#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Check emitted bytes independently, then read them with GNU cpio/libarchive."""

import argparse
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import unittest


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def decode_newc(data):
    """Decode the documented newc field sequence without production constants."""
    require(len(data) % 512 == 0, "archive block padding")
    result = {}
    position = 0
    while True:
        header = data[position:position + 110]
        require(len(header) == 110, "truncated header")
        require(header[:6] == b"070701", "newc magic")
        # Pin this writer's retained spelling, although newc readers accept both.
        require(all(byte in b"0123456789ABCDEF" for byte in header[6:]),
                "noncanonical uppercase hex header field")
        fields = [int(header[start:start + 8], 16) for start in range(6, 110, 8)]
        keys = ("inode", "mode", "uid", "gid", "nlink", "mtime", "size",
                "devmajor", "devminor", "rmajor", "rminor", "namesize", "check")
        entry = dict(zip(keys, fields))
        entry["header_offset"] = position
        require(entry["namesize"] > 0, "empty name field")
        start = position + 110
        end = start + entry["namesize"]
        require(end <= len(data), "truncated name")
        require(data[end - 1] == 0 and b"\0" not in data[start:end - 1],
                "name terminator")
        name = os.fsdecode(bytes(data[start:end - 1]))
        aligned = (end + 3) & ~3
        require(not any(data[end:aligned]), "name padding")
        start = aligned
        end = start + entry["size"]
        require(end <= len(data), "truncated payload")
        entry["data"] = data[start:end]
        entry["data_offset"] = start
        aligned = (end + 3) & ~3
        require(not any(data[end:aligned]), "payload padding")
        require(entry["check"] == 0, "newc checksum field")
        if name == "TRAILER!!!":
            require(entry["size"] == 0 and entry["nlink"] == 1, "trailer fields")
            require(len(data) == (aligned + 511) // 512 * 512,
                    "minimal archive block padding")
            require(not any(data[aligned:]), "trailing archive padding")
            return result
        require(name not in result, "duplicate archive name")
        result[name] = entry
        position = aligned


class CPIOChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.scratch = tempfile.TemporaryDirectory(prefix="cpio-check.", dir="build")
        cls.addClassCleanup(cls.scratch.cleanup)
        cls.work = Path(cls.scratch.name).resolve() / "paths with spaces"
        cls.work.mkdir()
        # Deliberately exceed the documented 1 MiB copy buffer with nonzero data.
        cls.payload = (bytes(range(256)) * 8193) + b"unaligned tail"
        (cls.work / "payload.bin").write_bytes(cls.payload)
        (cls.work / "empty.bin").write_bytes(b"")
        (cls.work / "tiny.bin").write_bytes(b"abc")
        (cls.work / "raw.bin").write_bytes(b"ABCDE")
        with (cls.work / "oversized.bin").open("wb") as stream:
            stream.truncate(2**32)
        cls.run_driver("entries")
        cls.archive = (cls.work / "entries.cpio").read_bytes()
        cls.run_driver("raw")
        cls.raw_archive = (cls.work / "raw.cpio").read_bytes()

    @classmethod
    def run_driver(cls, mode):
        subprocess.run([str(OPTIONS.driver), mode, str(cls.work)],
                       check=True, timeout=60)

    def check_entries(self, data):
        entries = decode_newc(data)
        self.assertEqual(set(entries), {"dir", "dir/payload", "empty", "hard-first",
                                       "hard-last", "symlink", "long-symlink",
                                       "fifo", "block", "character", "max-metadata",
                                       "epoch"})
        modes = {"dir": 0o40750, "dir/payload": 0o100640, "empty": 0o100600,
                 "hard-first": 0o100640, "hard-last": 0o100640,
                 "symlink": 0o120777, "long-symlink": 0o120777,
                 "fifo": 0o10640, "block": 0o60006, "character": 0o20772,
                 "max-metadata": 0o40700, "epoch": 0o40700}
        for name, entry in entries.items():
            self.assertEqual(entry["mode"], modes[name], name)
            self.assertEqual((entry["devmajor"], entry["devminor"]), (3, 1), name)
            if name not in ("block", "character"):
                self.assertEqual((entry["rmajor"], entry["rminor"]), (0, 0), name)
            if name == "max-metadata":
                self.assertEqual((entry["uid"], entry["gid"], entry["mtime"]),
                                 (2**32 - 1,) * 3)
            elif name == "epoch":
                self.assertEqual((entry["uid"], entry["gid"], entry["mtime"]),
                                 (17, 23, 0))
            else:
                self.assertEqual((entry["uid"], entry["gid"], entry["mtime"]),
                                 (17, 23, 946684800), name)
        self.assertEqual(entries["dir"]["inode"], 721)
        self.assertEqual(entries["dir/payload"]["data"], self.payload)
        self.assertEqual(entries["empty"]["data"], b"")
        self.assertEqual(entries["symlink"]["data"], b"dir/payload")
        self.assertEqual(entries["long-symlink"]["data"], b"x" * 300)
        self.assertEqual(entries["symlink"]["nlink"], 1)
        self.assertEqual(entries["long-symlink"]["nlink"], 1)
        for key in ("inode", "nlink", "mode", "uid", "gid", "mtime"):
            self.assertEqual(entries["hard-first"][key], entries["hard-last"][key])
        self.assertEqual(entries["hard-first"]["nlink"], 2)
        self.assertEqual(entries["hard-first"]["data"], b"")
        self.assertEqual(entries["hard-last"]["data"], self.payload)
        self.assertEqual((entries["block"]["rmajor"], entries["block"]["rminor"]),
                         (21, 5))
        self.assertEqual((entries["character"]["rmajor"],
                          entries["character"]["rminor"]), (5, 12))

    def test_raw_entries(self):
        self.check_entries(self.archive)

    def check_raw_records(self, data):
        """Pin the predecessor's short 512-byte record layout independently."""
        entries = decode_newc(data)
        self.assertEqual(set(entries), {"sym", "file"})
        self.assertEqual(len(data), 512)
        expected = {
            "sym": {"header_offset": 0, "mode": 0o120777, "uid": 11, "gid": 22,
                    "nlink": 1, "mtime": 0, "size": 5, "namesize": 4},
            "file": {"header_offset": 124, "mode": 0o100644, "uid": 33, "gid": 44,
                     "nlink": 1, "mtime": 0, "size": 5, "namesize": 5,
                     "devmajor": 3, "devminor": 1, "rmajor": 0, "rminor": 0,
                     "check": 0},
        }
        for name, fields in expected.items():
            for field, value in fields.items():
                self.assertEqual(entries[name][field], value, (name, field))
        self.assertEqual(data[14:22], b"0000A1FF")
        self.assertEqual(data[138:146], b"000081A4")
        self.assertEqual(data[110:114], b"sym\0")
        self.assertEqual(data[114:116], bytes(2))
        self.assertEqual(data[116:121], b"abcde")
        self.assertEqual(data[121:124], bytes(3))
        self.assertEqual(data[234:239], b"file\0")
        self.assertEqual(data[239:240], bytes(1))
        self.assertEqual(data[240:245], b"ABCDE")
        self.assertEqual(data[245:248], bytes(3))
        self.assertEqual(data[248:254], b"070701")
        self.assertEqual(data[286:294], b"00000001")
        self.assertEqual(data[342:350], b"0000000B")
        self.assertEqual(data[358:369], b"TRAILER!!!\0")
        self.assertEqual(data[369:], bytes(143))

    def test_short_raw_records(self):
        self.check_raw_records(self.raw_archive)

    def test_empty_and_errors(self):
        self.run_driver("empty")
        self.assertEqual(decode_newc((self.work / "empty.cpio").read_bytes()), {})
        self.run_driver("errors")
        self.assertEqual(set(decode_newc((self.work / "errors.cpio").read_bytes())),
                         {"after-errors"})

    def test_external_readers(self):
        names = ["dir/payload", "empty", "hard-first", "hard-last",
                 "symlink", "long-symlink", "fifo"]
        for reader in ("cpio", "bsdtar"):
            with self.subTest(reader=reader):
                listing = subprocess.run(
                    [reader, "-it"] if reader == "cpio" else [reader, "-tf", "-"],
                    input=self.archive, stdout=subprocess.PIPE,
                    check=True, timeout=30)
                self.assertEqual(set(listing.stdout.decode().splitlines()),
                                 set(decode_newc(self.archive)))
                destination = self.work / reader
                destination.mkdir()
                command = (["cpio", "-id", "--no-preserve-owner", "--quiet"]
                           if reader == "cpio" else
                           ["bsdtar", "-xf", "-", "--no-same-owner"])
                subprocess.run(command + names, cwd=destination, input=self.archive,
                               check=True, timeout=30)
                self.assertEqual((destination / "dir/payload").read_bytes(), self.payload)
                self.assertEqual((destination / "empty").read_bytes(), b"")
                for name in ("hard-first", "hard-last"):
                    self.assertEqual((destination / name).read_bytes(), self.payload)
                self.assertEqual((destination / "hard-first").stat().st_ino,
                                 (destination / "hard-last").stat().st_ino)
                self.assertEqual(os.readlink(destination / "symlink"), "dir/payload")

    def test_reproducibility_and_parallel(self):
        time.sleep(1.1)
        os.utime(self.work / "payload.bin", (946684900, 946684900))
        self.run_driver("entries")
        self.assertEqual((self.work / "entries.cpio").read_bytes(), self.archive)
        self.run_driver("parallel")
        archives = list(self.work.glob("parallel*.cpio"))
        self.assertEqual(len(archives), 8)
        for archive in archives:
            self.assertEqual(archive.read_bytes(), self.archive)

    def test_copy_helper(self):
        subprocess.run([str(OPTIONS.copy_driver), str(self.work)], check=True, timeout=60)
        self.assertEqual((self.work / "copy.bin").read_bytes(), self.payload)

    def test_lifetime_and_recreate(self):
        self.run_driver("lifetime")
        self.assertEqual(list(self.work.glob("unfinished*.cpio")), [])
        self.assertEqual(list(self.work.glob("task-output*.cpio")), [])
        self.run_driver("state")
        self.assertEqual(set(decode_newc((self.work / "errors.cpio").read_bytes())),
                         {"before-recreate", "after-errors"})
        self.assertFalse((self.work / "replacement.cpio").exists())

    def test_oracle_sensitivity(self):
        self.check_entries(self.archive)
        self.check_raw_records(self.raw_archive)
        broken = bytearray(self.archive)
        broken[0] = ord("9")
        with self.assertRaisesRegex(AssertionError, "magic"):
            decode_newc(broken)
        broken = bytearray(self.archive)
        broken[114] = 1  # First header: 110 bytes plus the four-byte "dir\0" name.
        with self.assertRaisesRegex(AssertionError, "name padding"):
            decode_newc(broken)
        broken = bytearray(self.archive)
        position = decode_newc(self.archive)["dir/payload"]["data_offset"]
        broken[position] ^= 1
        with self.assertRaises(AssertionError):
            self.check_entries(broken)
        with self.assertRaisesRegex(AssertionError, "archive block padding"):
            decode_newc(self.archive[:-1])
        with self.assertRaisesRegex(AssertionError, "minimal archive block padding"):
            decode_newc(self.raw_archive + bytes(512))
        broken = bytearray(self.raw_archive)
        broken[14:22] = broken[14:22].lower()
        with self.assertRaisesRegex(AssertionError, "uppercase hex"):
            decode_newc(broken)
        for position in (121, 245):
            broken = bytearray(self.raw_archive)
            broken[position] = 1
            with self.assertRaisesRegex(AssertionError, "payload padding"):
                decode_newc(broken)
        entries = decode_newc(self.archive)
        for name, field in (("symlink", 38), ("dir/payload", 78),
                            ("dir/payload", 86)):
            broken = bytearray(self.archive)
            start = entries[name]["header_offset"] + field
            broken[start:start + 8] = b"00000002"
            decode_newc(broken)  # Valid layout; the value assertion must reject it.
            with self.assertRaises(AssertionError):
                self.check_entries(broken)


if __name__ == "__main__":
    for termination_signal in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(termination_signal, lambda number, _frame: sys.exit(128 + number))
    parser = argparse.ArgumentParser()
    parser.add_argument("--driver", type=Path, default=Path("tests/bin/cpio_driver"))
    parser.add_argument("--copy-driver", type=Path, default=Path("tests/bin/arca-copy_checks"))
    OPTIONS, remaining = parser.parse_known_args()
    for field in ("driver", "copy_driver"):
        value = getattr(OPTIONS, field)
        if value is not None:
            setattr(OPTIONS, field, value.resolve())
    for tool in ("cpio", "bsdtar"):
        if shutil.which(tool) is None:
            parser.error(f"Missing test tool: {tool}")
    unittest.main(argv=[__file__, *remaining])

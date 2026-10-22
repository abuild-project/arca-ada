#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-2.1-or-later

"""Decode TAR independently, then verify readers, ownership and byte parity."""

import argparse
import hashlib
import os
from pathlib import Path
import resource
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "tests/fixtures/tar"
SIZES = (0, 1, 511, 512, 513, 1048576, 1048577, 1049088)
DEEP_PREFIX = "directory/" * 12 + "middle"
DEEP_PATH = DEEP_PREFIX + "/leaf.bin"


def require(condition, message):
    if not condition:
        raise AssertionError(message)


def header_fields(header):
    """Check one header using this decoder's own zero-based field map."""
    require(len(header) == 512, "truncated TAR header")
    require(header[257:265] == b"ustar\0" + b"00", "ustar magic/version")
    require(header[265:329] == bytes(64), "empty user/group name fields")
    require(header[500:] == bytes(12), "reserved header bytes")
    checksum = header[148:156]
    require(checksum[6:] == b"\0 ", "checksum terminator")
    require(all(byte in b"01234567" for byte in checksum[:6]), "checksum digits")
    total = sum(header[:148]) + 8 * 32 + sum(header[156:])
    require(int(checksum[:6], 8) == total, "header checksum")
    result = {"header": header, "type": chr(header[156])}
    for name, offset, width in (("mode", 100, 8), ("uid", 108, 8),
                                ("gid", 116, 8), ("size", 124, 12),
                                ("mtime", 136, 12), ("major", 329, 8),
                                ("minor", 337, 8)):
        value = header[offset:offset + width]
        require(value[-1] == 0, name + " terminator")
        require(all(byte in b"01234567" for byte in value[:-1]), name + " octal")
        result[name] = int(value[:-1], 8)
    for name, offset, width in (("name", 0, 100), ("link", 157, 100),
                                ("prefix", 345, 155)):
        value = header[offset:offset + width]
        first = value.find(b"\0")
        if first >= 0:
            require(not any(value[first:]), name + " field padding")
            value = value[:first]
        result[name] = value.decode("latin1")
    return result


def decode_tar(data):
    """Require the retained ustar/GNU profile, including exact end blocks."""
    require(len(data) >= 1024 and len(data) % 512 == 0, "archive block size")
    entries, records = {}, []
    position = 0
    pending = {}
    while True:
        require(position + 512 <= len(data), "missing archive end marker")
        header = data[position:position + 512]
        if header == bytes(512):
            require(data[position:] == bytes(1024), "two archive end blocks")
            require(not pending, "orphan GNU metadata")
            return entries, records
        record = header_fields(header)
        record["data_offset"] = position + 512
        end = position + 512 + record["size"]
        require(end <= len(data), "truncated member payload")
        record["data"] = data[position + 512:end]
        padded = (end + 511) // 512 * 512
        require(padded <= len(data), "truncated payload padding")
        require(not any(data[end:padded]), "member payload padding")
        records.append(record)
        position = padded
        kind = record["type"]
        if kind in ("L", "K"):
            require(record["name"] == "././@LongLink", "GNU metadata name")
            require(record["data"].endswith(b"\0"), "GNU metadata terminator")
            require(b"\0" not in record["data"][:-1], "GNU metadata embedded NUL")
            require((record["mode"], record["uid"], record["gid"],
                     record["mtime"]) == (0o644, 0, 0, 0), "GNU metadata fields")
            require(kind not in pending, "duplicate GNU metadata")
            pending[kind] = record["data"][:-1].decode("latin1")
            continue
        require(kind in "0123456", "unexpected TAR entry type")
        name = pending.get("L", (record["prefix"] + "/" if record["prefix"] else "")
                           + record["name"])
        record["raw_link"] = record["link"]
        record["link"] = pending.get("K", record["link"])
        record["metadata"] = tuple(pending)
        pending.clear()
        require(name and name not in entries, "empty or duplicate member name")
        if kind != "0":
            require(record["size"] == 0, "non-file payload size")
        entries[name] = record


def fixture_bytes():
    """Read the original canonical hex dump, including its final byte offset."""
    result = bytearray()
    for line in (FIXTURES / "gnu-ustar-subset.hex").read_text().splitlines():
        fields = line.split("|", 1)[0].split()
        require(int(fields[0], 16) == len(result), "fixture hex offset")
        if len(fields) > 1:
            require(all(len(token) == 2 for token in fields[1:]), "fixture hex bytes")
            result.extend(bytes.fromhex(" ".join(fields[1:])))
    require(hashlib.sha256(result).hexdigest() ==
            "4a57dfbf22f27b4829a79b814342b8efda7e05fb03e5c5930c525f2941cf4bfc",
            "historical GNU tar fixture identity")
    return bytes(result)


def altered_header(data, record, first, replacement):
    """Repair checksum so targeted corruption reaches the value assertions."""
    changed = bytearray(data)
    start = record["data_offset"] - 512
    changed[start + first:start + first + len(replacement)] = replacement
    changed[start + 148:start + 156] = b" " * 8
    checksum = sum(changed[start:start + 512])
    changed[start + 148:start + 156] = f"{checksum:06o}".encode() + b"\0 "
    return changed


def write_inputs(work):
    """Supply bounded payloads and sparse files used only for size checks."""
    payload = bytes(range(256)) * 8193 + b"unaligned TAR tail"
    (work / "payload.bin").write_bytes(payload)
    (work / "tiny.bin").write_bytes(b"abc")
    (work / "empty.bin").write_bytes(b"")
    shutil.copyfile(FIXTURES / "regular_file", work / "regular_file")
    for size in SIZES:
        (work / f"size {size}.bin").write_bytes(
            (bytes(range(256)) * ((size + 255) // 256))[:size])
    for name, size in (("oversized.bin", 8**11), ("max-size.bin", 8**11 - 1)):
        with (work / name).open("wb") as stream:
            stream.truncate(size)
    return payload


class TARChecks(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        (ROOT / "build").mkdir(exist_ok=True)
        cls.scratch = tempfile.TemporaryDirectory(prefix="tar-check.", dir=ROOT / "build")
        cls.addClassCleanup(cls.scratch.cleanup)
        cls.work = Path(cls.scratch.name).resolve() / "paths with spaces"
        cls.work.mkdir()
        cls.payload = write_inputs(cls.work)
        cls.run_driver("entries")
        cls.archive = (cls.work / "entries.tar").read_bytes()

    @classmethod
    def run_driver(cls, mode, driver=None, work=None):
        subprocess.run([str(driver or OPTIONS.driver), mode, str(work or cls.work)],
                       check=True, timeout=60)

    def check_entries(self, data):
        entries, records = decode_tar(data)
        expected = {"dir/", "dir/payload", "empty", "hard", "symlink",
                    "long-symlink", "fifo", "block", "character", "max-metadata",
                    "epoch/", "a" * 155 + "/" + "p" * 100, "n" * 101,
                    "e" * 100, "exact-target", "h" * 120}
        self.assertEqual(set(entries), expected)
        self.assertEqual(entries["dir/payload"]["data"], self.payload)
        self.assertEqual(entries["empty"]["data"], b"")
        self.assertEqual(entries["dir/payload"]["mode"], 0o640)
        for name, entry in entries.items():
            if name == "max-metadata":
                self.assertEqual((entry["uid"], entry["gid"], entry["major"],
                                  entry["minor"]), (2**21 - 1,) * 4)
                self.assertEqual(entry["mtime"], 8**11 - 1)
                self.assertEqual(entry["mode"], 0o7777)
            else:
                self.assertEqual((entry["uid"], entry["gid"]), (17, 23), name)
                self.assertEqual(entry["mtime"], 0 if name == "epoch/" else 946684800)
        for name, kind, mode in (("dir/", "5", 0o750), ("empty", "0", 0o600),
                                  ("hard", "1", 0o640), ("symlink", "2", 0o777),
                                  ("fifo", "6", 0o640), ("block", "4", 0o006),
                                  ("character", "3", 0o772),
                                  ("long-symlink", "2", 0o777),
                                  ("exact-target", "2", 0o777),
                                  ("h" * 120, "1", 0o644),
                                  ("a" * 155 + "/" + "p" * 100, "0", 0o644),
                                  ("n" * 101, "0", 0o644),
                                  ("e" * 100, "0", 0o644),
                                  ("dir/payload", "0", 0o640),
                                  ("epoch/", "5", 0o700),
                                  ("max-metadata", "3", 0o7777)):
            self.assertEqual((entries[name]["type"], entries[name]["mode"]),
                             (kind, mode), name)
        self.assertEqual((entries["block"]["major"], entries["block"]["minor"]), (21, 5))
        self.assertEqual((entries["character"]["major"], entries["character"]["minor"]),
                         (5, 12))
        self.assertEqual(entries["hard"]["link"], "dir/payload")
        self.assertEqual(entries["symlink"]["link"], "dir/payload")
        self.assertEqual(entries["long-symlink"]["link"], "x" * 300)
        self.assertEqual(entries["long-symlink"]["raw_link"], "././@LongLink")
        split = entries["a" * 155 + "/" + "p" * 100]
        self.assertEqual((split["prefix"], split["name"], split["metadata"]),
                         ("a" * 155, "p" * 100, ()))
        self.assertEqual(entries["n" * 101]["metadata"], ("L",))
        self.assertEqual(entries["n" * 101]["name"], "n" * 100)
        self.assertEqual(entries["n" * 101]["prefix"], "")
        self.assertEqual(entries["e" * 100]["metadata"], ())
        self.assertEqual(entries["exact-target"]["link"], "t" * 100)
        self.assertEqual(entries["exact-target"]["metadata"], ())
        self.assertEqual(entries["h" * 120]["metadata"], ("L", "K"))
        self.assertEqual(entries["h" * 120]["name"], "h" * 100)
        self.assertEqual(entries["h" * 120]["prefix"], "")
        self.assertEqual(entries["h" * 120]["raw_link"], "././@LongLink")
        self.assertEqual(entries["h" * 120]["link"], "n" * 101)
        self.assertEqual([r["type"] for r in records if r["type"] in ("L", "K")],
                         ["K", "L", "L", "K"])
        return entries

    def test_raw_entries(self):
        self.check_entries(self.archive)

    def test_gnu_ustar_fixture(self):
        self.run_driver("golden")
        actual = (self.work / "golden.tar").read_bytes()
        self.assertEqual(actual, fixture_bytes())
        self.assertEqual(len(decode_tar(actual)[0]), 7)

    def check_edges(self, data):
        entries, _ = decode_tar(data)
        self.assertEqual((entries["already/"]["name"], entries["already/"]["type"]),
                         ("already/", "5"))
        self.assertIn("repeated//", entries)
        directory = entries["d" * 150 + "/"]
        self.assertEqual((directory["metadata"], directory["type"],
                          directory["name"], directory["prefix"]),
                         (("L",), "5", "d" * 100, ""))
        self.assertEqual(entries["/" + "r" * 100 + "/"]["metadata"], ("L",))
        self.assertEqual(entries["i" * 100]["metadata"], ())
        self.assertEqual(entries["offset-link"]["link"], "j" * 100)
        self.assertEqual(entries["offset-link"]["metadata"], ())
        self.assertEqual(entries["offset-link"]["type"], "2")
        deep = entries[DEEP_PATH]
        self.assertEqual((deep["prefix"], deep["name"], deep["metadata"], deep["type"]),
                         (DEEP_PREFIX, "leaf.bin", (), "0"))
        link = entries["deep-hardlink"]
        self.assertEqual((link["type"], link["metadata"], link["link"], link["raw_link"]),
                         ("1", ("K",), DEEP_PATH, "././@LongLink"))
        for length in range(511, 514):
            self.assertEqual(entries[f"target {length}"]["link"], "x" * length)
            self.assertEqual(entries[f"target {length}"]["metadata"], ("K",))
            self.assertEqual(entries[f"target {length}"]["type"], "2")
            self.assertEqual(entries[f"target {length}"]["raw_link"], "././@LongLink")
        for size in SIZES:
            self.assertEqual(entries[f"size {size}"]["data"],
                             (self.work / f"size {size}.bin").read_bytes())
        self.assertEqual(entries["\xffbyte-name"]["data"], b"abc")
        return entries

    def test_boundaries_and_string_bounds(self):
        self.run_driver("edges")
        self.check_edges((self.work / "edges.tar").read_bytes())

    def test_numeric_owner_fallback(self):
        self.run_driver("owners")
        data = (self.work / "owners.tar").read_bytes()
        entry = decode_tar(data)[0]["numeric-owner"]
        self.assertEqual((entry["uid"], entry["gid"]), (65432, 65431))
        # Do not force numeric output: empty uname/gname must trigger fallback.
        listing = subprocess.run(["tar", "-tvf", str(self.work / "owners.tar")],
                                 env=dict(os.environ, LC_ALL="C", TZ="UTC"),
                                 capture_output=True, text=True, check=True, timeout=30)
        self.assertRegex(listing.stdout,
                         r"(?m)^-rw-r--r--\s+65432/65431\s+3\s+.+\s+numeric-owner$")

    def test_aligned_multi_buffer_readers(self):
        self.run_driver("aligned")
        archive = self.work / "aligned.tar"
        data = archive.read_bytes()
        source = (self.work / "size 1049088.bin").read_bytes()
        self.assertEqual(len(source), 1049088)
        self.assertEqual(len(data), len(source) + 3 * 512)
        self.assertEqual(decode_tar(data)[0]["aligned.bin"]["data"], source)
        for reader in ("tar", "bsdtar"):
            destination = self.work / (reader + "-aligned")
            destination.mkdir()
            subprocess.run([reader, "--no-same-owner", "-xf", str(archive),
                            "-C", str(destination)], check=True, timeout=30)
            self.assertEqual((destination / "aligned.bin").read_bytes(), source)

    def test_legacy_reader_edges(self):
        self.run_driver("golden")
        self.run_driver("edges")
        self.check_edges((self.work / "edges.tar").read_bytes())
        selected = ["d" * 150 + "/", DEEP_PATH, "deep-hardlink"]
        for reader in ("tar", "bsdtar"):
            listing = subprocess.run([reader, "-tf", str(self.work / "golden.tar")],
                                     capture_output=True, check=True, timeout=30)
            self.assertIn("a" * 150 + "/middle/leaf.txt",
                          listing.stdout.decode().splitlines())
            archive = self.work / "edges.tar"
            listing = subprocess.run([reader, "-tf", str(archive), *selected],
                                     capture_output=True, check=True, timeout=30)
            self.assertEqual(set(listing.stdout.decode().splitlines()), set(selected))
            destination = self.work / (reader + "-edges")
            destination.mkdir()
            subprocess.run([reader, "--no-same-owner", "-xf", str(archive),
                            "-C", str(destination), *selected], check=True, timeout=30)
            self.assertTrue(stat.S_ISDIR((destination / ("d" * 150)).lstat().st_mode))
            self.assertEqual((destination / DEEP_PATH).read_bytes(), b"abc")
            link = (destination / "deep-hardlink").lstat()
            self.assertTrue(stat.S_ISREG(link.st_mode))
            self.assertEqual(link.st_ino, (destination / DEEP_PATH).lstat().st_ino)

    def test_empty_and_errors(self):
        self.run_driver("empty")
        self.assertEqual((self.work / "empty.tar").read_bytes(), bytes(1024))
        for reader in ("tar", "bsdtar"):
            listing = subprocess.run([reader, "-tf", str(self.work / "empty.tar")],
                                     capture_output=True, check=True, timeout=30)
            self.assertEqual(listing.stdout, b"")
        self.run_driver("errors")
        entries, _ = decode_tar((self.work / "errors.tar").read_bytes())
        self.assertEqual(set(entries), {"after-errors/"})

    def test_decoder_sensitivity(self):
        self.check_entries(self.archive)
        changed = bytearray(self.archive)
        changed[0] ^= 1
        with self.assertRaisesRegex(AssertionError, "header checksum"):
            decode_tar(changed)
        with self.assertRaisesRegex(AssertionError, "two archive end blocks"):
            decode_tar(self.archive[:-512])
        entries, _ = decode_tar(self.archive)
        changed = bytearray(self.archive)
        changed[entries["dir/payload"]["data_offset"]] ^= 1
        with self.assertRaises(AssertionError):
            self.check_entries(changed)
        padding = entries["dir/payload"]["data_offset"] + len(self.payload)
        changed = bytearray(self.archive)
        changed[padding] = 1
        with self.assertRaisesRegex(AssertionError, "member payload padding"):
            decode_tar(changed)
        for name, first, replacement in (("h" * 120, 156, b"2"),
                                          ("exact-target", 156, b"1"),
                                          ("h" * 120, 0, b"q" * 100),
                                          ("n" * 101, 0, b"q" * 100),
                                          ("long-symlink", 157,
                                           b"wrong".ljust(100, b"\0"))):
            changed = altered_header(self.archive, entries[name], first, replacement)
            decode_tar(changed)  # Valid checksum/layout; pin the intended value.
            with self.assertRaises(AssertionError):
                self.check_entries(changed)
        self.run_driver("edges")
        edges = (self.work / "edges.tar").read_bytes()
        edge_entries = self.check_edges(edges)
        for first, replacement in ((156, b"2"), (0, b"q" * 100)):
            changed = altered_header(edges, edge_entries["d" * 150 + "/"],
                                     first, replacement)
            decode_tar(changed)
            with self.assertRaises(AssertionError):
                self.check_edges(changed)
        # An earlier valid split reconstructs the same path but breaks the
        # predecessor's rightmost-split convention.
        prefix, middle, leaf = DEEP_PATH.rsplit("/", 2)
        changed = altered_header(edges, edge_entries[DEEP_PATH], 0,
                                 (middle + "/" + leaf).encode().ljust(100, b"\0"))
        changed = altered_header(changed, edge_entries[DEEP_PATH], 345,
                                 prefix.encode().ljust(155, b"\0"))
        decode_tar(changed)
        with self.assertRaises(AssertionError):
            self.check_edges(changed)

    def test_reference_readers(self):
        entries = self.check_entries(self.archive)
        for reader in ("tar", "bsdtar"):
            listing = subprocess.run([reader, "-tf", str(self.work / "entries.tar")],
                                     capture_output=True, check=True, timeout=30)
            self.assertEqual(set(listing.stdout.decode().splitlines()), set(entries))
            destination = self.work / (reader + "-extract")
            destination.mkdir()
            subprocess.run([reader, "--no-same-owner", "--exclude=block",
                            "--exclude=character", "--exclude=max-metadata", "-xf",
                            str(self.work / "entries.tar"), "-C", str(destination)],
                           check=True, timeout=30)
            self.assertEqual(stat.S_IMODE((destination / "dir").stat().st_mode), 0o750)
            self.assertTrue((destination / "epoch").is_dir())
            self.assertEqual((destination / "dir/payload").read_bytes(), self.payload)
            self.assertEqual((destination / "empty").read_bytes(), b"")
            self.assertEqual((destination / "hard").stat().st_ino,
                             (destination / "dir/payload").stat().st_ino)
            hardlink = (destination / ("h" * 120)).lstat()
            self.assertTrue(stat.S_ISREG(hardlink.st_mode))
            self.assertEqual(hardlink.st_ino,
                             (destination / ("n" * 101)).lstat().st_ino)
            self.assertEqual(os.readlink(destination / "symlink"), "dir/payload")
            self.assertEqual(os.readlink(destination / "long-symlink"), "x" * 300)
            self.assertTrue(stat.S_ISFIFO((destination / "fifo").stat().st_mode))

    def test_reproducibility_and_parallel(self):
        time.sleep(1.1)
        os.utime(self.work / "payload.bin", (946684900, 946684900))
        self.run_driver("entries")
        self.assertEqual((self.work / "entries.tar").read_bytes(), self.archive)
        self.run_driver("parallel")
        outputs = list(self.work.glob("parallel*.tar"))
        self.assertEqual(len(outputs), 8)
        for output in outputs:
            self.assertEqual(output.read_bytes(), self.archive)

    def test_lifetime_and_recreate(self):
        self.run_driver("lifetime")
        self.run_driver("state")
        self.assertFalse((self.work / "replacement.tar").exists())
        self.assertEqual(set(decode_tar((self.work / "errors.tar").read_bytes())[0]),
                         {"before-recreate/", "after-errors/"})

    def test_maximum_size_header(self):
        def bounded_output():
            resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
            resource.setrlimit(resource.RLIMIT_FSIZE, (512, 512))

        # Keep the inode readable even if controlled unwinding deletes its name.
        # The file-size limit stops after the header rather than copying 8 GiB.
        with (self.work / "max-size.tar").open("w+b") as stream:
            probe = subprocess.run([str(OPTIONS.driver), "max-size", str(self.work)],
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   env=dict(os.environ,
                                            GCOV_PREFIX=str(self.work / "limited-gcov"),
                                            GCOV_PREFIX_STRIP="0"),
                                   preexec_fn=bounded_output, timeout=15)
            self.assertNotEqual(probe.returncode, 0, "Output limit did not stop the copy")
            stream.seek(0)
            header = stream.read()
        fields = header_fields(header)
        self.assertEqual(fields["size"], 8**11 - 1)
        self.assertEqual(fields["name"], "max-size")

    def test_predecessor_parity(self):
        if OPTIONS.baseline_driver is None:
            self.skipTest("optional exact predecessor comparison")
        for scenario in ("entries", "golden", "edges", "errors", "empty",
                         "aligned", "owners"):
            work = self.work / ("baseline-" + scenario)
            work.mkdir()
            write_inputs(work)
            self.run_driver(scenario)
            self.run_driver(scenario, driver=OPTIONS.baseline_driver, work=work)
            self.assertEqual((self.work / (scenario + ".tar")).read_bytes(),
                             (work / (scenario + ".tar")).read_bytes(), scenario)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--driver", type=Path, default=ROOT / "tests/bin/tar_driver")
    parser.add_argument("--baseline-driver", type=Path)
    OPTIONS = parser.parse_args()
    for termination_signal in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(termination_signal, lambda number, _frame: sys.exit(128 + number))
    unittest.main(argv=[sys.argv[0]], verbosity=1)

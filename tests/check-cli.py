#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-2.1-or-later

"""Exercise the installed/source CLI as a filesystem-to-archive consumer."""

import argparse
from concurrent.futures import ThreadPoolExecutor
from contextlib import contextmanager
import os
from pathlib import Path
import runpy
import signal
import socket
import stat
import subprocess
import sys
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parents[1]
DECODE_CPIO = runpy.run_path(str(ROOT / "tests/check-cpio.py"))["decode_newc"]
DECODE_TAR = runpy.run_path(str(ROOT / "tests/check-tar.py"))["decode_tar"]
STAMP = 946684800
PAYLOAD = bytes(range(256)) * 4097 + b"CLI tail"


def records(path, format_name):
    if format_name == "cpio":
        return DECODE_CPIO(path.read_bytes())
    entries = DECODE_TAR(path.read_bytes())[0]
    return {os.fsdecode(name.encode("latin1")).rstrip("/"): entry
            for name, entry in entries.items()}


class CLIChecks(unittest.TestCase):
    def setUp(self):
        (ROOT / "build").mkdir(exist_ok=True)
        self.scratch = tempfile.TemporaryDirectory(prefix="cli-check.", dir=ROOT / "build")
        self.addCleanup(self.scratch.cleanup)
        self.work = Path(self.scratch.name).resolve()

    def invoke(self, arguments, expected=0, cwd=None, env=None):
        environment = dict(os.environ)
        environment.pop("SOURCE_DATE_EPOCH", None)
        environment.update(env or {})
        result = subprocess.run([str(OPTIONS.cli), *map(str, arguments)],
                                cwd=cwd or self.work, env=environment,
                                capture_output=True, timeout=60)
        self.assertEqual(result.returncode, expected,
                         result.stdout.decode(errors="replace") +
                         result.stderr.decode(errors="replace"))
        return result

    def tree(self, name="source with spaces", reverse=False):
        root = self.work / name
        root.mkdir()
        (root / "dir").mkdir()
        (root / "empty-dir").mkdir()
        files = [("A source", PAYLOAD), ("dir/small", b"abc"),
                 ("empty", b""), ("grüße.txt", b"UTF-8 filename")]
        for relative, data in reversed(files) if reverse else files:
            (root / relative).write_bytes(data)
            os.chmod(root / relative, 0o640)
        os.link(root / "A source", root / "dir/hard")
        (root / "link").symlink_to("A source")
        (root / "broken").symlink_to("missing target")
        outside = self.work / "outside"
        outside.mkdir(exist_ok=True)
        (outside / "secret").write_bytes(b"not selected")
        # The physical link count is three, but only two names are selected.
        # An archive must not promise a third member outside its input root.
        external = outside / (name + "-hardlink")
        os.link(root / "A source", external)
        self.assertEqual((root / "A source").stat().st_nlink, 3)
        (root / "directory-link").symlink_to("../outside", target_is_directory=True)
        os.mkfifo(root / "fifo", 0o620)
        for path in (root, root / "dir", root / "empty-dir"):
            os.chmod(path, 0o750)
        for path in [root, *root.rglob("*")]:
            os.utime(path, (STAMP, STAMP), follow_symlinks=False)
        return root

    def command(self, format_name, root, output, *options):
        return ["create", "--format", format_name, "-C", root, "-o", output, *options]

    def assert_tree(self, archive, format_name, root, uid=None, gid=None, mtime=None):
        entries = records(archive, format_name)
        expected = {str(path.relative_to(root)) for path in root.rglob("*")}
        self.assertEqual(set(entries), expected)
        self.assertEqual(list(entries), sorted(expected, key=os.fsencode))
        for name, entry in entries.items():
            info = (root / name).lstat()
            self.assertEqual((entry["uid"], entry["gid"], entry["mtime"]),
                             (info.st_uid if uid is None else uid,
                              info.st_gid if gid is None else gid,
                              int(info.st_mtime) if mtime is None else mtime), name)
            mode = entry["mode"] & 0o7777
            self.assertEqual(mode, stat.S_IMODE(info.st_mode), name)
        if format_name == "cpio":
            first, last = entries["A source"], entries["dir/hard"]
            self.assertEqual(first["nlink"], 2)
            self.assertEqual(last["nlink"], 2)
            self.assertEqual(first["inode"], last["inode"])
            self.assertEqual((first["data"], last["data"]), (b"", PAYLOAD))
            for name in ("link", "broken", "directory-link"):
                self.assertEqual(os.fsdecode(entries[name]["data"]), os.readlink(root / name))
                self.assertTrue(stat.S_ISLNK(entries[name]["mode"]))
        else:
            self.assertEqual(entries["A source"]["data"], PAYLOAD)
            self.assertEqual(entries["dir/hard"]["type"], "1")
            self.assertEqual(entries["dir/hard"]["link"], "A source")
            for name in ("link", "broken", "directory-link"):
                self.assertEqual(entries[name]["type"], "2")
                self.assertEqual(entries[name]["link"], os.readlink(root / name))
        self.assertEqual(entries["dir/small"]["data"], b"abc")
        self.assertEqual(entries["empty"]["data"], b"")
        self.assertEqual(entries["grüße.txt"]["data"], b"UTF-8 filename")

    def test_default_metadata_and_readers(self):
        root = self.tree()
        for format_name in ("cpio", "tar"):
            archive = self.work / ("archive." + format_name)
            self.invoke(self.command(format_name, root, archive))
            self.assert_tree(archive, format_name, root)
            for reader in (("cpio", "bsdtar") if format_name == "cpio"
                           else ("tar", "bsdtar")):
                destination = self.work / (format_name + "-" + reader)
                destination.mkdir()
                if reader == "cpio":
                    command = [reader, "-id", "--no-preserve-owner", "--quiet"]
                    with archive.open("rb") as source:
                        subprocess.run(command, stdin=source, cwd=destination,
                                       check=True, timeout=30)
                else:
                    subprocess.run([reader, "--no-same-owner", "-xf", str(archive),
                                    "-C", str(destination)], check=True, timeout=30)
                self.assertEqual((destination / "A source").read_bytes(), PAYLOAD)
                self.assertEqual((destination / "dir/hard").read_bytes(), PAYLOAD)
                self.assertEqual((destination / "A source").lstat().st_ino,
                                 (destination / "dir/hard").lstat().st_ino)
                self.assertFalse((destination / "dir/hard").is_symlink())
                self.assertEqual(os.readlink(destination / "directory-link"), "../outside")
                self.assertEqual((self.work / "outside/secret").read_bytes(),
                                 b"not selected")
                self.assertTrue(stat.S_ISFIFO((destination / "fifo").lstat().st_mode))

    def test_overrides_and_reproducibility(self):
        root = self.tree()
        other = self.tree("other source", reverse=True)
        for format_name in ("cpio", "tar"):
            first = self.work / ("first." + format_name)
            second = self.work / ("second." + format_name)
            options = ("--uid", "123", "--gid", "456", "--mtime", "0")
            self.invoke(self.command(format_name, root, first, *options))
            self.invoke(self.command(format_name, other, second, *options))
            self.assert_tree(first, format_name, root, uid=123, gid=456, mtime=0)
            self.assertEqual(first.read_bytes(), second.read_bytes())

    def test_epoch_environment_and_precedence(self):
        root = self.work / "empty-root"
        root.mkdir()
        (root / "file").write_bytes(b"x")
        for format_name in ("cpio", "tar"):
            archive = self.work / ("epoch." + format_name)
            self.invoke(self.command(format_name, root, archive),
                        env={"SOURCE_DATE_EPOCH": "42"})
            self.assertEqual(records(archive, format_name)["file"]["mtime"], 42)
            self.invoke(self.command(format_name, root, archive, "--force", "--mtime=0"),
                        env={"SOURCE_DATE_EPOCH": "invalid"})
            self.assertEqual(records(archive, format_name)["file"]["mtime"], 0)

    def test_maximum_metadata(self):
        root = self.work / "maximum-root"
        root.mkdir()
        (root / "file").write_bytes(b"maximum metadata")
        for format_name, owner, stamp in (("cpio", 2**32 - 1, 2**32 - 1),
                                           ("tar", 2**21 - 1, 2**33 - 1)):
            archive = self.work / ("maximum." + format_name)
            self.invoke(self.command(format_name, root, archive,
                                     "--uid", owner, "--gid", owner, "--mtime", stamp))
            entry = records(archive, format_name)["file"]
            self.assertEqual((entry["uid"], entry["gid"], entry["mtime"]),
                             (owner, owner, stamp))

    def test_cpio_reserved_trailer_name(self):
        root = self.work / "reserved-root"
        root.mkdir()
        (root / "TRAILER!!!").write_bytes(b"ordinary source payload")
        archive = self.work / "reserved.cpio"
        result = self.invoke(self.command("cpio", root, archive), expected=1)
        self.assertIn(b"reserved CPIO name", result.stderr)
        self.assertFalse(archive.exists())
        self.assertEqual(list(self.work.glob(".arca-*")), [])
        # The name is reserved only by newc, so TAR remains a positive control.
        archive = self.work / "allowed.tar"
        self.invoke(self.command("tar", root, archive))
        self.assertEqual(records(archive, "tar")["TRAILER!!!"]["data"],
                         b"ordinary source payload")

    def test_nested_output_exclusion_and_force(self):
        for format_name in ("cpio", "tar"):
            root = self.work / format_name
            (root / "nested").mkdir(parents=True)
            (root / "file").write_bytes(b"x")
            archive = root / "nested/output.archive"
            archive.write_bytes(b"old output")
            self.invoke(self.command(format_name, root, archive), expected=1)
            self.assertEqual(archive.read_bytes(), b"old output")
            self.invoke(self.command(format_name, root, archive, "--force"))
            self.assertEqual(set(records(archive, format_name)), {"file", "nested"})
            self.assertEqual(list(root.rglob(".arca-*")), [])

    def test_empty_and_default_directory(self):
        root = self.work / "empty"
        root.mkdir()
        for format_name in ("cpio", "tar"):
            archive = self.work / ("empty." + format_name)
            self.invoke(["create", "--format=" + format_name, "-o", archive], cwd=root)
            self.assertEqual(records(archive, format_name), {})

    def test_output_symlink_replacement(self):
        root = self.tree()
        target = self.work / "untouched"
        target.write_bytes(b"keep me")
        for format_name in ("cpio", "tar"):
            archive = self.work / ("link." + format_name)
            archive.symlink_to(target)
            self.invoke(self.command(format_name, root, archive), expected=1)
            self.invoke(self.command(format_name, root, archive, "--force"))
            self.assertFalse(archive.is_symlink())
            self.assertEqual(target.read_bytes(), b"keep me")
            self.assert_tree(archive, format_name, root)

    def test_failure_preserves_output_and_cleans_staging(self):
        self.assertNotEqual(os.geteuid(), 0, "run the documented rootless checks")
        # Use native Linux storage: Docker Desktop's host sharing can permit
        # reads of mode-000 host files despite the container's uid/mode view.
        native = tempfile.TemporaryDirectory(prefix="arca-cli-permission-")
        self.addCleanup(native.cleanup)
        workspace = Path(native.name)
        root = workspace / "unreadable"
        root.mkdir()
        source = root / "denied"
        source.write_bytes(b"private")
        os.chmod(source, 0)
        self.addCleanup(os.chmod, source, 0o600)
        for format_name in ("cpio", "tar"):
            archive = workspace / ("preserved." + format_name)
            archive.write_bytes(b"keep original")
            result = self.invoke(self.command(format_name, root, archive, "--force"), expected=1)
            self.assertIn(b"denied", result.stderr)
            self.assertEqual(archive.read_bytes(), b"keep original")
            self.assertEqual(list(workspace.glob(".arca-*")), [])

    def test_socket_and_invalid_roots(self):
        root = self.work / "socket-root"
        root.mkdir()
        with socket.socket(socket.AF_UNIX) as server:
            server.bind(str(root / "socket"))
            for format_name in ("cpio", "tar"):
                archive = self.work / ("unsupported." + format_name)
                result = self.invoke(self.command(format_name, root, archive), expected=1)
                self.assertIn(b"unsupported", result.stderr)
                self.assertFalse(archive.exists())
        for invalid in (self.work / "missing", root / "socket"):
            self.invoke(self.command("tar", invalid, self.work / "no.tar"), expected=1)
        # Remove the socket so it cannot mask acceptance of a trailing slash.
        (root / "socket").unlink()
        result = self.invoke(
            self.command("tar", root, str(self.work / "trailing") + "/"), expected=1)
        self.assertIn(b"output must name a file", result.stderr)
        self.assertFalse((self.work / "trailing").exists())

    def test_help_and_invalid_options(self):
        self.assertIn(b"arca create", self.invoke(["--help"]).stdout)
        self.assertIn(b"arca development", self.invoke(["--version"]).stdout)
        bad = [[], ["extract"], ["create"],
               ["create", "--format", "zip", "-o", "out"],
               ["create", "--format", "tar", "-o", "-"],
               ["create", "--format", "tar", "-o", "out", "--force=yes"],
               ["create", "--format", "tar", "-o", "out", "--format", "cpio"],
               ["create", "--format", "tar", "-o", "out", "--unknown"]]
        for arguments in bad:
            self.invoke(arguments, expected=2)
        for value in ("-1", "1_0", "2#10#", "", "18446744073709551616"):
            self.invoke(["create", "--format", "tar", "-o", "out", "--uid=" + value],
                        expected=2)
        for format_name, option, value in (("cpio", "--mtime", "4294967296"),
                                           ("tar", "--mtime", "8589934592"),
                                           ("tar", "--gid", "2097152")):
            self.invoke(["create", "--format", format_name, "-o", "out", option, value],
                        expected=2)
        self.assertEqual(list(self.work.iterdir()), [])

    def test_parallel_commands(self):
        root = self.tree()
        def create(number):
            output = self.work / ("parallel-" + str(number) + ".tar")
            self.invoke(self.command("tar", root, output, "--mtime", "0"))
            return output.read_bytes()
        with ThreadPoolExecutor(max_workers=4) as workers:
            outputs = list(workers.map(create, range(4)))
        self.assertTrue(outputs)
        self.assertTrue(all(output == outputs[0] for output in outputs))
        self.assertEqual(list(self.work.glob(".arca-*")), [])

    @contextmanager
    def paused_creation(self, format_name, root, archive, *options):
        """Stop after staging opens, proving inventory and handlers are ready."""
        environment = dict(os.environ)
        environment.pop("SOURCE_DATE_EPOCH", None)
        process = subprocess.Popen(
            [str(OPTIONS.cli), *map(str, self.command(
                format_name, root, archive, *options))],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=environment)
        try:
            deadline = time.monotonic() + 30
            while not any(archive.parent.glob(".arca-*/archive")):
                self.assertIsNone(process.poll(), "CLI exited before test phase")
                self.assertLess(time.monotonic(), deadline, "no staging output")
                time.sleep(0.001)
            os.kill(process.pid, signal.SIGSTOP)
            _, status = os.waitpid(process.pid, os.WUNTRACED)
            self.assertTrue(os.WIFSTOPPED(status), "CLI must be paused in emission")
            self.assertFalse(archive.exists() and not options,
                             "default publication must still be pending")
            yield process
        finally:
            if process.poll() is None:
                process.kill()
            process.communicate(timeout=30)

    def phase_tree(self):
        # Enough entries to observe emission before publication even on a fast
        # local filesystem. Readiness is asserted; an early exit cannot pass.
        root = self.work / "phase-source"
        root.mkdir()
        for number in range(2048):
            (root / f"entry-{number:04}").write_bytes(b"x")
        return root

    def test_cancel_preserves_output_and_cleans_staging(self):
        root = self.phase_tree()
        for format_name in ("cpio", "tar"):
            archive = self.work / ("cancel." + format_name)
            archive.write_bytes(b"keep original")
            with self.paused_creation(format_name, root, archive, "--force") as process:
                os.kill(process.pid, signal.SIGTERM)
                os.kill(process.pid, signal.SIGCONT)
                _, error = process.communicate(timeout=30)
                self.assertEqual(process.returncode, 143, error)
                self.assertIn(b"interrupted", error)
            self.assertEqual(archive.read_bytes(), b"keep original")
            self.assertEqual(list(self.work.glob(".arca-*")), [])

    def test_publication_refuses_a_late_destination(self):
        root = self.phase_tree()
        for format_name in ("cpio", "tar"):
            archive = self.work / ("late." + format_name)
            with self.paused_creation(format_name, root, archive) as process:
                archive.write_bytes(b"created by another process")
                os.kill(process.pid, signal.SIGCONT)
                _, error = process.communicate(timeout=30)
                self.assertEqual(process.returncode, 1, error)
                self.assertIn(b"cannot publish", error)
            self.assertEqual(archive.read_bytes(), b"created by another process")
            self.assertEqual(list(self.work.glob(".arca-*")), [])

    def test_changed_source_is_rejected(self):
        root = self.phase_tree()
        for format_name in ("cpio", "tar"):
            # Force a size change in both formats, regardless of filesystem
            # timestamp resolution or the preceding format's test mutation.
            (root / "entry-2047").write_bytes(b"x")
            archive = self.work / ("changed." + format_name)
            with self.paused_creation(format_name, root, archive) as process:
                (root / "entry-2047").write_bytes(b"changed after inventory")
                os.kill(process.pid, signal.SIGCONT)
                _, error = process.communicate(timeout=30)
                self.assertEqual(process.returncode, 1, error)
                self.assertIn(b"source changed: 'entry-2047'", error)
            self.assertFalse(archive.exists())
            self.assertEqual(list(self.work.glob(".arca-*")), [])


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--cli", type=Path, default=ROOT / "cli/bin/arca")
    OPTIONS, remaining = parser.parse_known_args()
    OPTIONS.cli = OPTIONS.cli.resolve()
    for termination_signal in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(termination_signal, lambda number, _frame: sys.exit(128 + number))
    unittest.main(argv=[sys.argv[0], *remaining])

#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Check the launcher's stdin and terminal behavior with real containers."""

import argparse
import errno
import os
from pathlib import Path
import pty
import select
import subprocess
import sys
import termios
import time
import unittest


LAUNCHER = Path(__file__).resolve().parents[1] / "docker/dev/run"
PARSER = argparse.ArgumentParser()
PARSER.add_argument("--platform", choices=("linux/amd64", "linux/arm64"),
                    default="linux/amd64")
PARSER.add_argument("image", nargs="?", default="arca-dev:trixie")
OPTIONS, REMAINING = PARSER.parse_known_args()
COMMAND = [str(LAUNCHER), "--platform", OPTIONS.platform, OPTIONS.image]


class DevelopmentShellTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        subprocess.run(
            [*COMMAND, "sh", "-c",
             '. /etc/os-release; test "$VERSION_CODENAME" = trixie'],
            check=True, capture_output=True, timeout=30,
        )

    def test_default_shell_accepts_piped_input(self):
        result = subprocess.run(
            COMMAND,
            input=b"printf 'ARCA_PIPE_OK\\n'\nexit\n",
            capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(result.stdout, b"ARCA_PIPE_OK\n")

    def test_explicit_command_remains_noninteractive(self):
        result = subprocess.run(
            [*COMMAND, "sh", "-c",
             'if test -t 0 || test -t 1 || read -r line; then exit 1; fi; '
             "printf 'ARCA_BATCH_OK\\n'"],
            input=b"input must not reach the batch command\n",
            capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        self.assertEqual(result.stdout, b"ARCA_BATCH_OK\n")

    def test_default_shell_provides_a_terminal(self):
        master, slave = pty.openpty()
        attributes = termios.tcgetattr(slave)
        attributes[3] &= ~termios.ECHO
        termios.tcsetattr(slave, termios.TCSANOW, attributes)
        process = None
        output = bytearray()
        try:
            process = subprocess.Popen(
                COMMAND,
                stdin=slave, stdout=slave, stderr=slave,
            )
            os.close(slave)
            slave = None
            # The sentinel is emitted only after both container fds are TTYs.
            # It never appears as a standalone line in the submitted command.
            os.write(master, (
                b"if test -t 0 && test -t 1; then "
                b"printf '\\nARCA_TTY_OK\\n'; else exit 1; fi; exit\n"
            ))
            deadline = time.monotonic() + 30
            while time.monotonic() < deadline:
                ready, _, _ = select.select([master], [], [], 0.1)
                if ready:
                    try:
                        chunk = os.read(master, 65536)
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
                        break
                    if not chunk:
                        break
                    output.extend(chunk)
                elif process.poll() is not None:
                    break
            process.wait(timeout=max(0.1, deadline - time.monotonic()))
            self.assertEqual(process.returncode, 0, output.decode())
            self.assertRegex(bytes(output), rb"(?:^|\r?\n)ARCA_TTY_OK\r?\n")
        finally:
            if slave is not None:
                os.close(slave)
            os.close(master)
            if process is not None and process.poll() is None:
                process.kill()
                process.wait()


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0], *REMAINING])

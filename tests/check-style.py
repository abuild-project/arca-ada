#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Prove every real Ada project accepts 80 columns and rejects 81 columns."""

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


PROJECTS = (
    ("arca.gpr", "src/arca.ads"),
    ("cli/cli.gpr", "cli/src/arca_main.adb"),
    ("tests/tests.gpr", "tests/unit_runner.adb"),
    ("examples/client/client.gpr", "examples/client/arca_client.adb"),
)


def check_project(root, project, source, builder, jobs):
    """Use forced compilation and a diagnostic oracle on one copied project."""
    filename = root / source
    original = filename.read_text()
    line_number = len(original.splitlines()) + 1
    command = [str(builder), "-p", "-P", project, "-aP" + str(root),
               "-XARCA_BUILD_MODE=validation",
               "-c", "-u", filename.name, "-f", "-j" + jobs,
               "-cargs:Ada", "-gnatc"]
    env = dict(os.environ, LC_ALL="C")
    try:
        # The accepted boundary also proves the profile overrides GNAT's
        # default 79-column style limit; failure must not masquerade as success.
        for width in (80, 81):
            filename.write_text(original + "--  " + "x" * (width - 4) + "\n")
            result = subprocess.run(command, cwd=root, env=env, text=True,
                                    capture_output=True, timeout=90)
            output = result.stdout + result.stderr
            if width == 80:
                if result.returncode:
                    print(output, end="", flush=True)
                    raise RuntimeError(project + " rejected the 80-column control")
            else:
                diagnostic = (rf"(?m)^{re.escape(filename.name)}:"
                              rf"{line_number}:81: \(style\) this line is too long")
                if result.returncode == 0 or not re.search(diagnostic, output):
                    print(output, end="", flush=True)
                    raise RuntimeError(project + " missed the 81-column style error")
        print(project + ": accepts 80 columns; rejects 81 columns", flush=True)
    finally:
        filename.write_text(original)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--builder", default="gprbuild")
    parser.add_argument("--jobs", default="8")
    options = parser.parse_args()
    selected = shutil.which(options.builder)
    if selected is None:
        raise RuntimeError("Missing GPR builder: " + options.builder)
    builder = Path(selected).resolve()
    root = Path(__file__).resolve().parents[1]
    parent = root / "build"
    parent.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="style-gate.", dir=parent) as name:
        scratch = Path(name)
        shutil.copy2(root / "arca.gpr", scratch / "arca.gpr")
        # Copy source inputs only: no binaries, counts or external checkout
        # state can make a missing profile pass these compilation controls.
        for directory in ("src", "cli", "cli/src", "tests", "examples/client"):
            for source in (root / directory).iterdir():
                if source.is_file() and source.suffix in (".ads", ".adb", ".gpr", ".c"):
                    target = scratch / source.relative_to(root)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(source, target)
        for project, source in PROJECTS:
            check_project(scratch, project, source, builder, options.jobs)


if __name__ == "__main__":
    main()

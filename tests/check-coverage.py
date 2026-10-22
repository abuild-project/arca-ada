#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-2.1-or-later

"""Run instrumented checks and reject omitted or unexecuted production bodies."""

import argparse
import gzip
import json
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--builder", default="gprbuild")
    parser.add_argument("--jobs", default="8")
    options = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    inventory = {line for line in (root / "tests/coverage-sources.txt").read_text().splitlines()
                 if line and not line.startswith("#")}
    actual = {str(path.relative_to(root)) for path in (root / "src").glob("*.adb")}
    if inventory != actual:
        raise RuntimeError(f"Coverage inventory differs: {inventory ^ actual}")
    if shutil.which("gcov") is None:
        raise RuntimeError("Missing coverage tool: gcov; rebuild the development image")
    scratch_parent = root / "build"
    scratch_parent.mkdir(exist_ok=True)
    objects = root / "tests/obj-coverage"
    for data in objects.glob("*.gcda"):
        data.unlink()
    subprocess.run([options.builder, "-p", "-P", str(root / "tests/tests.gpr"),
                    "-XARCA_COVERAGE=enabled", "-j" + options.jobs], check=True)
    subprocess.run([sys.executable, str(root / "tests/check-unit.py"),
                    "--runner", str(root / "tests/bin-coverage/unit_runner"),
                    "--probe", str(root / "tests/bin-coverage/unit_probe")],
                   cwd=root, check=True)
    subprocess.run([sys.executable, str(root / "tests/check-cpio.py"),
                    "--driver", str(root / "tests/bin-coverage/cpio_driver"),
                    "--copy-driver", str(root / "tests/bin-coverage/arca-copy_checks")],
                   cwd=root, check=True)
    subprocess.run([sys.executable, str(root / "tests/check-tar.py"),
                    "--driver", str(root / "tests/bin-coverage/tar_driver")],
                   cwd=root, check=True)
    report = {}
    with tempfile.TemporaryDirectory(prefix="gcov.", dir=scratch_parent) as name:
        scratch = Path(name)
        for source in sorted(inventory):
            subprocess.run(["gcov", "--json-format", "--branch-probabilities",
                            "--object-directory", str(objects), str(root / source)],
                           cwd=scratch, check=True)
        for archive in scratch.glob("*.gcov.json.gz"):
            with gzip.open(archive, "rt") as stream:
                document = json.load(stream)
            for entry in document["files"]:
                matches = [path for path in inventory
                           if Path(path).name == Path(entry["file"]).name]
                if not matches:
                    continue
                lines = entry["lines"]
                covered = sum(line["count"] > 0 for line in lines)
                if not lines or covered == 0:
                    raise RuntimeError("Production body has no executed lines: " + matches[0])
                report[matches[0]] = {"covered_lines": covered, "executable_lines": len(lines)}
    if set(report) != inventory:
        raise RuntimeError("Missing coverage reports: " + str(inventory - set(report)))
    destination = scratch_parent / "coverage.json"
    destination.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    for termination_signal in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(termination_signal, lambda number, _frame: sys.exit(128 + number))
    main()

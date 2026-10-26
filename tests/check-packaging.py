#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Exercise consumer compiler policy and cleanup with a missing test import."""

import argparse
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
RUNTIME = {"-gnato", "-gnatVa", "-fstack-check", "-gnateE"}
STYLE = "-gnatygAdISuxM80"
CASES = ("default", "release", "validation", "extended-release",
         "extended-validation", "invalid", "clean")


def selected(command):
    path = shutil.which(command)
    if path is None:
        raise RuntimeError("Missing packaging tool: " + command)
    return str(Path(path).resolve())


def profiles(scratch, builder, jobs, case):
    shutil.copy2(ROOT / "arca.gpr", scratch / "arca.gpr")
    shutil.copytree(ROOT / "src", scratch / "src")
    source = scratch / "src/arca.ads"
    original = source.read_text()
    # An overlong comment is harmless to release users. The unused context
    # clause provides a real warning whose diagnostic must remain visible.
    source.write_text("with Interfaces;\n" + original + "--  " + "x" * 77 + "\n")
    command = [builder, "-p", "-P", "arca.gpr", "-c", "-u", "arca.ads",
               "-f", "-v", "-j" + jobs]
    mode = case.removeprefix("extended-")
    if case.startswith("extended-"):
        (scratch / "consumer.gpr").write_text(
            '--  SPDX-License-Identifier: GPL-2.0-or-later\n\n'
            'library project Consumer extends "arca.gpr" is\n'
            '   for Source_Dirs use ("src");\n'
            '   for Object_Dir use "consumer-obj";\n'
            '   for Library_Dir use "consumer-lib";\n'
            '   for Library_Interface use ();\n'
            '   for Library_Standalone use "no";\n'
            'end Consumer;\n')
        command[command.index("arca.gpr")] = "consumer.gpr"
    env = dict(os.environ, LC_ALL="C")
    env.pop("ARCA_BUILD_MODE", None)
    if case != "default":
        # Explicit scenario selections must override the opposite environment.
        env["ARCA_BUILD_MODE"] = "release" if mode == "validation" else "validation"
        command.append("-XARCA_BUILD_MODE=" + ("unknown" if case == "invalid" else mode))
    if case.startswith("extended-"):
        command.extend(("-cargs:Ada", "-O1"))
    result = subprocess.run(command, cwd=scratch, env=env, text=True,
                            capture_output=True, timeout=90)
    output = result.stdout + result.stderr
    if case == "invalid":
        if result.returncode == 0 or "unknown" not in output or "illegal" not in output:
            raise RuntimeError("Unknown build mode was not rejected:\n" + output)
        print("invalid: rejects unknown library build modes", flush=True)
        return
    commands = [shlex.split(line) for line in output.splitlines()
                if re.search(r"gcc\S* .*arca\.ads", line)]
    if not commands:
        raise RuntimeError("No library compiler invocation observed:\n" + output)
    flags = set(commands[-1])
    if not RUNTIME.union({"-gnatwa"}).issubset(flags):
        raise RuntimeError("Library runtime checks or warnings missing:\n" + output)
    if case.startswith("extended-") and "-O1" not in flags:
        raise RuntimeError("Extending-project compiler argument missing:\n" + output)
    if mode == "validation":
        if result.returncode == 0 or not {"-gnatwe", STYLE}.issubset(flags):
            raise RuntimeError("Validation lost strict compiler policy:\n" + output)
        if "(style) this line is too long" not in output:
            raise RuntimeError("Validation failed for an unintended reason:\n" + output)
    else:
        if result.returncode or "-gnatwe" in flags or any(flag.startswith("-gnaty") for flag in flags):
            raise RuntimeError("Consumer profile rejected harmless source style:\n" + output)
        if not re.search(r"warning: .*Interfaces.*not referenced", output):
            raise RuntimeError("Consumer profile suppressed the warning:\n" + output)
    print(case + ": compiler flags and diagnostics match library policy", flush=True)


def cleanup(scratch, cleaner, make_command):
    for name in ("Makefile", "arca.gpr"):
        shutil.copy2(ROOT / name, scratch / name)
    for name in ("src", "cli", "cli/src", "examples/client"):
        for source in (ROOT / name).iterdir():
            if source.is_file() and source.suffix in (".gpr", ".ads", ".adb", ".c"):
                target = scratch / source.relative_to(ROOT)
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)
    tests = scratch / "tests"
    tests.mkdir()
    shutil.copy2(ROOT / "tests/tests.gpr", tests / "tests.gpr")
    # A deliberately absent project models Ahven being unavailable even on
    # the reference image, which has Ahven installed for the full test suite.
    (tests / "test_dependencies.gpr").write_text(
        '--  SPDX-License-Identifier: GPL-2.0-or-later\n\n'
        'with "arca_missing_test_dependency";\n'
        'project Test_Dependencies is\nend Test_Dependencies;\n')
    directories = ("obj", "bin", "obj-coverage", "bin-coverage")
    for name in directories:
        directory = tests / name
        directory.mkdir()
        (directory / "stale-output").write_text("remove\n")
    keep = scratch / "build/install/unrelated"
    keep.parent.mkdir(parents=True)
    keep.write_text("retain\n")
    report = scratch / "build/coverage.json"
    report.write_text("retain report\n")
    command = [make_command, "clean", "NUM_CPUS=8", "GPRCLEAN=" + cleaner]
    if "--jobserver-" not in os.environ.get("MAKEFLAGS", ""):
        command.insert(1, "-j8")
    # The Make recipe marks this script recursive; preserve inherited jobserver
    # descriptors for implementations that use pipes rather than a FIFO.
    result = subprocess.run(command, cwd=scratch, text=True, close_fds=False,
                            capture_output=True, timeout=90)
    if result.returncode or any((tests / name).exists() for name in directories):
        raise RuntimeError("Cleanup depends on the unavailable test project:\n" +
                           result.stdout + result.stderr)
    if keep.read_text() != "retain\n" or report.read_text() != "retain report\n":
        raise RuntimeError("Cleanup changed the retained build directory")
    print("clean: removes test outputs without loading their dependency", flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--builder", default="gprbuild")
    parser.add_argument("--cleaner", default="gprclean")
    parser.add_argument("--make-command", default="make")
    parser.add_argument("--jobs", default="8")
    parser.add_argument("--case", choices=CASES)
    options = parser.parse_args()
    builder = selected(options.builder)
    cleaner = selected(options.cleaner)
    make_command = selected(options.make_command)
    parent = ROOT / "build"
    parent.mkdir(exist_ok=True)
    for case in (options.case,) if options.case else CASES:
        with tempfile.TemporaryDirectory(prefix="packaging-" + case + ".", dir=parent) as name:
            if case == "clean":
                cleanup(Path(name), cleaner, make_command)
            else:
                profiles(Path(name), builder, options.jobs, case)


if __name__ == "__main__":
    main()

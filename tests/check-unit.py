#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-2.1-or-later

"""Run direct Ahven suites and validate reports, cleanup and failure status."""

import argparse
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET


EXPECTED = {
    "CPIO": {"error contracts", "open Create preserves state",
             "owner lifetime cleanup", "parallel instances",
             "closed writer reuse", "failed Create retry"},
    "TAR": {"error contracts", "open Create preserves state",
            "owner lifetime cleanup", "parallel instances",
            "closed writer reuse", "failed Create retry"},
    "Binary_IO": {"copy error contracts", "exact buffer payload",
                  "empty source", "missing source recovery",
                  "comparison sensitivity"},
}


def read_reports(directory):
    reports = {}
    for filename in directory.glob("*.xml"):
        suite = ET.parse(filename).getroot()
        if suite.tag != "testsuite" or suite.attrib["name"] in reports:
            raise RuntimeError("Unexpected or duplicate XML suite: " + str(filename))
        cases = suite.findall("testcase")
        if int(suite.attrib["tests"]) != len(cases):
            raise RuntimeError("XML case count differs from actual cases")
        reports[suite.attrib["name"]] = suite
    if not reports:
        raise RuntimeError("Ahven produced no XML test reports")
    return reports


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("--runner", type=Path, default=root / "tests/bin/unit_runner")
    parser.add_argument("--probe", type=Path, default=root / "tests/bin/unit_probe")
    options = parser.parse_args()
    runner, probe = options.runner.resolve(), options.probe.resolve()
    parent = root / "build"
    parent.mkdir(exist_ok=True)
    reports = parent / ("unit-results-" + runner.parent.name)
    reports.mkdir(exist_ok=True)
    for old in reports.glob("*.xml"):
        old.unlink()
    with tempfile.TemporaryDirectory(prefix="unit-check.", dir=parent) as name:
        scratch = Path(name)
        fixtures = scratch / "fixtures"
        fixtures.mkdir()
        env = dict(os.environ, ARCA_TEST_ROOT=str(fixtures))
        for arguments in ([], ["-x", "-d", str(reports)]):
            subprocess.run([str(runner), *arguments], cwd=root, env=env,
                           check=True, timeout=90)
            if list(fixtures.iterdir()):
                raise RuntimeError("Ahven cases retained fixture directories")
        actual = read_reports(reports)
        if set(actual) != set(EXPECTED):
            raise RuntimeError("Missing or unexpected Ahven suites")
        for suite_name, expected in EXPECTED.items():
            suite = actual[suite_name]
            names = [case.attrib["name"] for case in suite.findall("testcase")]
            xml_names = {name.replace(" ", "_") for name in expected}
            if set(names) != xml_names or len(names) != len(expected):
                raise RuntimeError("Ahven case inventory differs: " + suite_name)
            if (int(suite.attrib["failures"]) or int(suite.attrib["errors"]) or
                    int(suite.attrib["skips"]) or suite.findall(".//skipped") or
                    suite.findall(".//failure") or suite.findall(".//error")):
                raise RuntimeError("Ahven XML reports a failure: " + suite_name)
        probe_reports = scratch / "probe"
        probe_reports.mkdir()
        for arguments in ([], ["-x", "-d", str(probe_reports)]):
            result = subprocess.run([str(probe), *arguments], cwd=root, env=env,
                                    capture_output=True, text=True, timeout=15)
            print(result.stdout, end="", flush=True)
            print(result.stderr, end="", flush=True)
            if result.returncode != 1:
                raise RuntimeError("Failing assertion did not return exit status 1")
            if list(fixtures.iterdir()):
                raise RuntimeError("Assertion failure retained a fixture directory")
            if not arguments and "intentional assertion probe" not in result.stdout:
                raise RuntimeError("Text runner omitted the assertion diagnostic")
        probe_suite = read_reports(probe_reports)
        if set(probe_suite) != {"Harness_probe"}:
            raise RuntimeError("Missing failure-control suite")
        failure = probe_suite["Harness_probe"]
        if (int(failure.attrib["tests"]) != 1 or
                int(failure.attrib["failures"]) != 1 or
                int(failure.attrib["errors"]) != 0 or
                "intentional assertion probe" not in ET.tostring(failure).decode()):
            raise RuntimeError("XML runner lost the deliberate assertion failure")
        print("Ahven text/XML failure controls passed; reports: " + str(reports),
              flush=True)


if __name__ == "__main__":
    for termination_signal in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(termination_signal, lambda number, _frame: sys.exit(128 + number))
    main()

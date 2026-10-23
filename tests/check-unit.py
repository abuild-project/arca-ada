#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

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
             "closed writer reuse", "failed Create retry",
             "finalizer failure cleanup"},
    "TAR": {"error contracts", "open Create preserves state",
            "owner lifetime cleanup", "parallel instances",
            "closed writer reuse", "failed Create retry",
            "finalizer failure cleanup"},
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


def run_modes(executable, root, scratch, reports, capture=False):
    """Keep XML diagnostics even when text-mode tests fail."""
    scratch.mkdir()
    issues, results = [], []
    for mode, arguments in (("text", []), ("XML", ["-x", "-d", str(reports)])):
        fixtures = scratch / mode
        fixtures.mkdir()
        env = dict(os.environ, ARCA_TEST_ROOT=str(fixtures))
        result = subprocess.run([str(executable), *arguments], cwd=root, env=env,
                                capture_output=capture, text=True, timeout=90)
        results.append(result)
        if capture:
            print(result.stdout, end="", flush=True)
            print(result.stderr, end="", flush=True)
        if result.returncode:
            issues.append(f"{mode} runner returned {result.returncode}")
        if list(fixtures.iterdir()):
            issues.append(f"{mode} runner retained fixture directories")
    return issues, results


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
        issues, _ = run_modes(runner, root, scratch / "real", reports)
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
                issues.append("Ahven XML reports a failure: " + suite_name)
        if issues:
            raise RuntimeError("; ".join(issues))
        probe_reports = scratch / "probe"
        probe_reports.mkdir()
        # Use the real orchestration path with an unexpected test failure.
        # Both failed statuses must be retained, and XML must still exist.
        issues, results = run_modes(probe, root, scratch / "negative",
                                    probe_reports, capture=True)
        if issues != ["text runner returned 1", "XML runner returned 1"]:
            raise RuntimeError("Failure/cleanup control differs: " + str(issues))
        if "intentional assertion probe" not in results[0].stdout:
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

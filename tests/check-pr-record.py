#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Exercise the PR record check with isolated GitHub event and file fixtures."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from yaml import BaseLoader, load


ROOT = Path(__file__).resolve().parents[1]
CHECKER_PATH = Path("scripts/check-pr-record.py")
SCRIPT = ROOT / CHECKER_PATH
WORKFLOW = load((ROOT / ".github/workflows/pr-record.yml").read_text(), Loader=BaseLoader)
STEPS = WORKFLOW["jobs"]["match"]["steps"]
HEAD_REF = "${{ github.event.pull_request.head.sha }}"
FALLBACK_NOTICE = "Base revision has no PR record checker"
HEAD_CHECKER_OUTPUT = "Head checker ran"


class PRRecordTests(unittest.TestCase):
    def setUp(self):
        scratch = tempfile.TemporaryDirectory(prefix="arca-pr-record-")
        self.addCleanup(scratch.cleanup)
        self.root = Path(scratch.name)
        self.workspace = self.root / "workspace"
        head = next(step["with"] for step in STEPS if step.get("with", {}).get("ref") == HEAD_REF)
        self.checkout = self.workspace / head.get("path", ".")
        self.records = self.checkout / "doc/change-records"
        self.records.mkdir(parents=True)
        self.base_records = self.workspace / "base/doc/change-records"
        self.base_records.mkdir(parents=True)
        self.base_checker = self.workspace / "base" / CHECKER_PATH
        self.base_checker.parent.mkdir()
        self.head_checker = self.checkout / CHECKER_PATH
        self.head_checker.parent.mkdir()
        self.comparison = next(
            step for step in STEPS if step.get("name") == "Compare the PR body with the committed record"
        )
        self.event_path = self.root / "event.json"
        self.env = dict(os.environ, GITHUB_EVENT_PATH=str(self.event_path),
                        GITHUB_HEAD_REF="wrong-branch", PR_BODY="wrong body")

    def write_event(self, body, head_ref):
        self.event_path.write_text(
            json.dumps({"pull_request": {"body": body, "head": {"ref": head_ref}}}),
            encoding="utf-8",
        )

    def check(self, body, head_ref="example"):
        """Run the real check with decoy values outside the event file."""
        self.write_event(body, head_ref)
        return subprocess.run(
            [sys.executable, "-I", str(SCRIPT)], cwd=self.checkout, env=self.env,
            capture_output=True, text=True, timeout=10,
        )

    def compare(self, body):
        """Run the workflow's comparison step with the checkout fixtures."""
        self.write_event(body, "codex/example")
        return subprocess.run(
            ["bash", "--noprofile", "--norc", "-eo", "pipefail", "-c", self.comparison["run"]],
            cwd=self.workspace / self.comparison.get("working-directory", "."),
            env=self.env, capture_output=True, text=True, timeout=10,
        )

    def install_passing_head_checker(self):
        self.head_checker.write_text(f"print({HEAD_CHECKER_OUTPUT!r})\n", encoding="utf-8")

    def test_comparison_job_checks_out_exact_revisions_and_runs_only_the_comparison(self):
        self.assertEqual(WORKFLOW["on"], {"pull_request": {"types": [
            "opened", "edited", "synchronize", "reopened", "ready_for_review",
        ]}})
        self.assertEqual(WORKFLOW["permissions"], {"contents": "read"})
        self.assertEqual(len(STEPS), 3)
        for revision, step in zip(("base", "head"), STEPS):
            self.assertEqual(
                step["uses"], "actions/checkout@11d5960a326750d5838078e36cf38b85af677262",
            )
            self.assertEqual(step["with"], {
                "ref": "${{ github.event.pull_request." + revision + ".sha }}",
                "path": revision,
                "persist-credentials": "false",
            })
        self.assertEqual(STEPS[-1], self.comparison)
        self.assertEqual(self.comparison["working-directory"], "head")
        self.assertNotIn("${{", self.comparison["run"])
        self.assertIn("python3 -I ", self.comparison["run"])

    def test_base_checker_reads_head_record_when_head_checker_is_missing(self):
        self.base_checker.write_bytes(SCRIPT.read_bytes())
        (self.base_records / "example.md").write_text("Base record", encoding="utf-8")
        (self.records / "example.md").write_text("Head record", encoding="utf-8")
        result = self.compare("Head record")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn(FALLBACK_NOTICE, result.stdout)

    def test_base_checker_rejects_mismatch_without_running_head_checker(self):
        self.base_checker.write_bytes(SCRIPT.read_bytes())
        self.install_passing_head_checker()
        (self.records / "example.md").write_text("Head record", encoding="utf-8")
        result = self.compare("Different body")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("PR body differs from the committed record", result.stderr)
        self.assertIn("-Different body\n+Head record\n", result.stderr)
        self.assertNotIn(HEAD_CHECKER_OUTPUT, result.stdout)
        self.assertNotIn(FALLBACK_NOTICE, result.stdout)

    def test_introducing_pr_logs_the_fallback_to_the_head_checker(self):
        self.head_checker.write_bytes(SCRIPT.read_bytes())
        (self.records / "example.md").write_text("Introducing record", encoding="utf-8")
        result = self.compare("Introducing record")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(FALLBACK_NOTICE, result.stdout)
        self.assertIn("Running the head checker for this introducing PR", result.stdout)

    def test_introducing_pr_rejects_a_symlinked_head_checker(self):
        self.head_checker.symlink_to(SCRIPT)
        (self.records / "example.md").write_text("Introducing record", encoding="utf-8")
        result = self.compare("Introducing record")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn(FALLBACK_NOTICE, result.stdout)
        self.assertIn("Head PR record checker must be a readable regular file", result.stderr)

    def assert_unusable_base_checker(self):
        self.install_passing_head_checker()
        result = self.compare("Body")
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("Base PR record checker must be a readable regular file", result.stderr)
        self.assertNotIn(HEAD_CHECKER_OUTPUT, result.stdout)
        self.assertNotIn(FALLBACK_NOTICE, result.stdout)

    def test_nonregular_base_checker_fails_without_using_head(self):
        self.base_checker.mkdir()
        self.assert_unusable_base_checker()

    def test_dangling_base_checker_fails_without_using_head(self):
        self.base_checker.symlink_to("missing.py")
        self.assert_unusable_base_checker()

    def test_matching_body_with_no_branch_prefix(self):
        (self.records / "example.md").write_text("A record\n", encoding="utf-8")
        result = self.check("A record\n")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_trailing_whitespace_on_both_sides(self):
        (self.records / "example.md").write_text("One\nTwo\n\t\n", encoding="utf-8")
        result = self.check("One\nTwo  \r\n")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_crlf_on_each_side(self):
        record = self.records / "example.md"
        for contents, body in ((b"One\r\nTwo\n", "One\nTwo\n"),
                               (b"One\nTwo\n", "One\r\nTwo\n")):
            with self.subTest(contents=contents, body=body):
                record.write_bytes(contents)
                result = self.check(body)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_substantive_mismatch_prints_a_unified_diff(self):
        (self.records / "example.md").write_text("Committed", encoding="utf-8")
        result = self.check("Will be closed")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--- PR body\n+++ doc/change-records/example.md\n", result.stderr)
        self.assertIn("@@ -1 +1 @@\n-Will be closed\n+Committed\n", result.stderr)

    def test_inner_whitespace_and_lone_cr_are_significant(self):
        (self.records / "example.md").write_bytes(b"One\nTwo\n")
        for body in (" One\nTwo\n", "One \nTwo\n", "One\rTwo\n"):
            with self.subTest(body=body):
                result = self.check(body)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("PR body differs", result.stderr)

    def test_missing_record_fails_with_the_expected_path(self):
        result = self.check(None)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("doc/change-records/example.md: missing", result.stderr)

    def test_remove_only_the_first_prefix(self):
        for ref, topic in (("codex/example", "example"),
                           ("codex/a/b/c", "a-b-c")):
            with self.subTest(ref=ref):
                (self.records / f"{topic}.md").write_text(ref, encoding="utf-8")
                result = self.check(ref, head_ref=ref)
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_reserved_topics_fail_even_when_records_match(self):
        for topic in ("CLAUDE", "CLAUDE.local"):
            with self.subTest(topic=topic):
                record = self.records / f"{topic}.md"
                record.write_text("Matching text", encoding="utf-8")
                result = self.check("Matching text", head_ref=f"codex/{topic}")
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn(f"doc/change-records/{topic}.md: reserved", result.stderr)
                self.assertIn(f"Claude review pilot removes files named {topic}.md", result.stderr)

    def test_other_case_variants_are_valid_topics(self):
        for topic in ("claude", "Claude.local"):
            with self.subTest(topic=topic):
                (self.records / f"{topic}.md").write_text("Matching text", encoding="utf-8")
                result = self.check("Matching text", head_ref=f"codex/{topic}")
                self.assertEqual(result.returncode, 0, result.stderr)

    def test_record_symlinks_fail_even_when_the_contents_match(self):
        for target in (self.root / "outside.md", self.records / "inside.md"):
            with self.subTest(target=target):
                target.write_text("Matching text", encoding="utf-8")
                record = self.records / "example.md"
                record.symlink_to(target)
                result = self.check("Matching text")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("doc/change-records/example.md:", result.stderr)
                self.assertIn("symlinks", result.stderr)
                self.assertNotIn("Matching text", result.stderr)
                record.unlink()

    def test_linked_parent_directories_fail_before_reading(self):
        record = self.records / "example.md"
        record.write_text("Outside contents", encoding="utf-8")
        for directory in (self.records, self.records.parent):
            with self.subTest(directory=directory):
                target = self.root / "relocated"
                directory.rename(target)
                directory.symlink_to(target, target_is_directory=True)
                result = self.check("Different body")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("doc/change-records/example.md:", result.stderr)
                self.assertIn("symlinks", result.stderr)
                self.assertNotIn("Outside contents", result.stderr)
                directory.unlink()
                target.rename(directory)

    def test_long_diff_is_bounded_and_escapes_log_commands(self):
        shared = "::test-message::\r\x1b\n"
        context = "\nShared one\nShared two\nShared three\n"
        (self.records / "example.md").write_text(
            shared + "##[test-message]" + "a" * 500 + context + "a\n" * 30,
            encoding="utf-8",
        )
        result = self.check(shared + "Different" + context + "b\n" * 30)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("... (diff truncated)", result.stderr)
        self.assertLess(max(map(len, result.stderr.splitlines())), 245)
        self.assertIn(r":\x3atest-message:\x3a\r\x1b", result.stderr)
        self.assertIn(r"##\x5btest-message]", result.stderr)


if __name__ == "__main__":
    unittest.main()

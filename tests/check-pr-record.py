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


SCRIPT = Path(__file__).resolve().parents[1] / "scripts/check-pr-record.py"


class PRRecordTests(unittest.TestCase):
    def setUp(self):
        scratch = tempfile.TemporaryDirectory(prefix="arca-pr-record-")
        self.addCleanup(scratch.cleanup)
        self.root = Path(scratch.name)
        self.checkout = self.root / "checkout"
        self.records = self.checkout / "doc/change-records"
        self.records.mkdir(parents=True)
        self.event_path = self.root / "event.json"

    def check(self, body, head_ref="example"):
        """Run the real check with decoy values outside the event file."""
        self.event_path.write_text(
            json.dumps({"pull_request": {"body": body, "head": {"ref": head_ref}}}),
            encoding="utf-8",
        )
        return subprocess.run(
            [sys.executable, str(SCRIPT)], cwd=self.checkout,
            env=dict(os.environ, GITHUB_EVENT_PATH=str(self.event_path),
                     GITHUB_HEAD_REF="wrong-branch", PR_BODY="wrong body"),
            capture_output=True, text=True, timeout=10,
        )

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

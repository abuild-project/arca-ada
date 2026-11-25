#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Compare the GitHub event's PR body with its record in the head checkout."""

from difflib import unified_diff
import json
import os
from pathlib import Path
import sys


def normalize(text):
    """Normalize CRLF and remove whitespace at the very end of the text."""
    return text.replace("\r\n", "\n").rstrip()


def show_diff(body, contents, record):
    """Print a bounded unified diff without interpreting log commands."""
    diff = unified_diff(
        body.split("\n"), contents.split("\n"),
        fromfile="PR body", tofile=record.as_posix(), n=1, lineterm="",
    )
    for index, line in enumerate(diff):
        if index == 20:
            print("... (diff truncated)", file=sys.stderr)
            break
        excerpt = "".join(
            char if char.isprintable() or char == "\t" else ascii(char)[1:-1]
            for char in line[:240]
        )
        excerpt = excerpt.replace("::", r":\x3a").replace("##[", r"##\x5b")
        if len(line) > 240 or len(excerpt) > 240:
            excerpt = excerpt[:240] + "..."
        print(excerpt, file=sys.stderr)


def main():
    """Require a regular canonical record with the same normalized body."""
    event_path = Path(os.environ["GITHUB_EVENT_PATH"])
    pull_request = json.loads(event_path.read_text(encoding="utf-8"))["pull_request"]
    head_ref = pull_request["head"]["ref"]
    topic = head_ref.split("/", 1)[-1].replace("/", "-")
    records = Path("doc/change-records")
    record = records / f"{topic}.md"
    if any(path.is_symlink() for path in (records.parent, records, record)):
        raise SystemExit(f"{record}: change record paths must not contain symlinks")
    if not record.is_file():
        raise SystemExit(f"{record}: missing change record file")
    try:
        contents = normalize(record.read_bytes().decode("utf-8"))
    except (OSError, UnicodeError):
        raise SystemExit(f"{record}: expected a readable UTF-8 change record")
    body = normalize(pull_request["body"] or "")
    if body != contents:
        print(f"{record}: PR body differs from the committed record", file=sys.stderr)
        show_diff(body, contents, record)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

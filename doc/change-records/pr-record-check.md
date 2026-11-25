# Canonical PR record check

The dedicated PR workflow compares the submitted body with the canonical
change record at the PR head. It reruns on body edits and head updates.
It normalizes CRLF and ignores whitespace at the end of the whole text.
It reports the expected record path on failure and shows a short unified
diff for a mismatch. The rule applies to all PRs. Required-check settings
are a separate repository action.

The Claude pilot checks each rule in the captured base's Code Review Rules
before writing findings. It compares the captured PR body with the
canonical head record and reports rule violations while omitting passing
rules.

## Validation

The complete local CI chain passed from a fresh detached checkout of
`7955fa9c9b999f1c2c6673d33ec42b02948f2d9f` in the AMD64 Debian Trixie
reference environment. Independent review of that revision against
`b0aae83c004bf02b3b7e09d6c992e80117e29f57` reported no actionable findings.
With this record omitted, the validated Git tree is
`09d81cf4b83289382bd3bfa838f86db49747d5f5`.

Standalone coverage ran before `build/` existed and covered 1,031 of 1,107
executable lines across 10 production bodies. The coverage and normal
Ahven runs each passed 19 tests with zero failures, errors or skips. The
wrapper, shell/batch, PR record and Claude harnesses passed 6, 3, 10 and
10 tests respectively. The normal checks passed, including all 43 CLI
tests. All 54 cross-UID staging checks passed, and strict MkDocs built 14
canonical pages.

In isolated controls, raw comparison failed both CRLF cases and the
trailing-whitespace case. Keeping only the final branch segment failed
the nested-topic case. With the exact Claude workflow from parent
`b778943910acffeb36535d0cec569e0df44b397f`, the updated harness failed only
the new rule-pass assertion.

Hosted PR-event validation and the live Claude review remain pending. The
[planned smoke test](../plans/pr-record-check.md) covers both on one
temporary PR.

Co-Authored-By: GPT-6 <noreply@openai.com>

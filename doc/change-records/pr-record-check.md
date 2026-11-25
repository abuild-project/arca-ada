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
rules. The publish job checks the SHA-256 digest of the normalized body
from that snapshot against fresh PR metadata along with the reviewed base
and head. A substantive body edit requires a fresh review even when the
revisions stay the same.

## Validation

The complete local CI chain passed all 40 recorded commands from a fresh
detached checkout of `176297847e4a2132a227884ac46e60e871f7fecd` in the
AMD64 Debian Trixie reference environment. Independent review of that
revision against `b0aae83c004bf02b3b7e09d6c992e80117e29f57` reported no
actionable findings. Omitting this change record yields the same Git tree
`6db145bed522b3c470dbcf1316745cf92259fd9c` for the tested revision and the
record-only update.

Standalone coverage ran before `build/` existed and recorded 1,031 of 1,107
executable lines across 10 production bodies. The coverage and normal Ahven
runs each passed 19 tests with zero failures, errors or skips. The wrapper,
shell and batch, Claude workflow and PR record harnesses passed 6, 3, 13
and 10 tests respectively. All 43 CLI tests and 54 cross-UID staging cases
passed, and strict MkDocs built all 14 canonical pages.

With stubbed PR API responses, the tested publish step posted for an exact
body match and for normalization-equivalent bodies. It refused a
substantive body edit at the same base and head and rejected a missing
body or digest. The exact workflow from
`d9bd02db06ac65a4603e2c67d0a4f61d1db1c195` posted after the same edit,
causing the regression assertion to fail.

Hosted PR-event validation and the live Claude review remain pending. The
[planned smoke test](../plans/pr-record-check.md) covers both on one
temporary PR.

Co-Authored-By: GPT-6 <noreply@openai.com>

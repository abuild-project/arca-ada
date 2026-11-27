# Canonical PR record check

The dedicated PR workflow compares the submitted body with the canonical
change record at the PR head. It reruns on body edits and head updates.
It normalizes CRLF and ignores whitespace at the end of the whole text.
It reports the expected record path on failure and shows a short unified
diff for a mismatch. The rule applies to all PRs. Required-check settings
are a separate repository action.

The workflow checks out the exact base and head separately and runs the
base checker with `python3 -I` from the head checkout. The base checker can
read the head record even when the head changes or omits its checker. When
the base has no checker, the workflow logs that it is running the head
checker for the introducing PR. An unusable checker or a failure while
running it fails the job. Build CI runs the checker and workflow fixtures.
The checker rejects topics `CLAUDE` and `CLAUDE.local` before accessing the
record because the Claude review pilot removes files named `CLAUDE.md` and
`CLAUDE.local.md`.

The Claude pilot checks each rule in the captured base's Code Review Rules
before writing findings. It compares the captured PR body with the
canonical head record and reports rule violations while omitting passing
rules. The publish job checks the SHA-256 digest of the normalized body
from that snapshot against fresh PR metadata along with the reviewed base
and head. A substantive body edit requires a fresh review even when the
revisions stay the same.

## Validation

The complete local CI chain passed from a fresh detached checkout of
`800b6a9f107c21da8612453edc71173feeebaabd` in AMD64 Debian Trixie.
Independent review of that revision against
`b0aae83c004bf02b3b7e09d6c992e80117e29f57` found no actionable findings.
Omitting this change record yields Git tree
`954dc153b57b3717a7f52c492c11f17cbd265b83` for both the tested revision and
the record-only update.

Standalone coverage ran before `build/` existed and covered 1,031 of
1,107 executable lines across 10 production bodies. The coverage and
normal Ahven runs each passed 19 tests with no failures, errors or skips.
The wrapper, shell and batch, Claude workflow and PR record harnesses
passed 6, 3, 13 and 19 tests respectively. All 43 CLI tests and 54
cross-UID staging cases passed. Strict MkDocs built all 14 canonical pages.

Local probes ran the actual workflow shell steps with synthetic PR events
and exact base and head checkouts. The tested workflow accepted a matching
record from an older head that lacked the checker and its harness. It
rejected a record mismatch with a weakened head checker, unusable base
checkers and both reserved topics with matching records. The published
workflow at `3f0ef9becfbf059ea9bfa9959494bde500e7b529` stopped at the
missing harness on the older head and accepted the weakened-head mismatch,
unusable base checkers and reserved topics. When the base lacked a
checker, the tested workflow logged its fallback to the head checker,
accepted a matching record and rejected a mismatch.

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

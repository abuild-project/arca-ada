# Code review rules and Claude pilot severity

`AGENTS.md` treats incorrect validation attribution, ineffective checks,
conflicting guidance and unverified upstream claims as blocking. Its review
rules reference one sensitivity requirement for new or changed checks.
Compare PR bodies with their committed change records while ignoring
trailing whitespace. See [Build and tests](../../AGENTS.md#build-and-tests).

Local CI and independent review can carry forward after strictly
tree-identical history cleanup or a post-validation update limited to the
canonical change record. The record-only exception requires an unchanged
base, identical Git trees with the record omitted, a full diff confined to
the record and verification against primary evidence. Hosted checks remain
tied to the exact PR head. See
[submission preparation](../development.md#submission-preparation).

The Claude pilot starts with a **Previous findings** block with one status
line per earlier finding. It labels each new finding `blocking` or `nit`.
A blocking finding cites a repository rule by file and section or describes
a concrete observable failure. Findings cite actual lines in the head files.

## Validation

The full local CI chain passed from a fresh detached checkout using the AMD64
Debian Trixie reference environment. The base was
`ff79c57ea3f7532bdc4c3665395d9a85f6fe5409`, and the Git tree with this record
omitted was `4472fc6d2f94199744ee224f8c6f491555aec4db`. Independent review of
the validated change against that base reported no actionable findings.

Standalone coverage ran before `build/` existed and covered 1,031 of 1,107
executable lines across 10 bodies. Both Ahven runs passed 19 tests each with
zero failures, errors or skips. The wrapper, shell and Claude harnesses
passed 6, 3 and 8 tests. All 43 CLI and 54 cross-UID staging checks passed.
The strict documentation build passed for all 14 canonical pages.

With the base workflow substituted in an isolated fixture, five existing
harness tests passed and the three new prompt tests failed as expected.
The workflow is byte-identical outside the prompt. The post-merge smoke
test covers the posted review and its revision attribution. See the
[Claude review pilot guide](../development.md#claude-review-pilot).

Co-Authored-By: GPT-6 <noreply@openai.com>

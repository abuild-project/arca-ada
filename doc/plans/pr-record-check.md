# Canonical PR record check

## Deterministic comparison on 2026-11-25

Use a dedicated read-only `pull_request` workflow to compare the submitted
body with the canonical record at the PR head. This catches a mismatch before
review and reevaluates body edits as well as head updates. Apply the same rule
to every PR because `AGENTS.md` defines a canonical record for every topic.
Making the job a required check is a separate repository settings decision.

Read both PR fields from the GitHub event file. Follow the branch-to-record
mapping in `AGENTS.md`, normalize CRLF and strip whitespace at the end of
each whole text. Test equivalent and different bodies, unusable paths and
branch mapping. Use a comparison without normalization or a broken mapping
as a negative control. Run the complete local CI chain and independently
review the same immutable candidate before submission.

## Claude rule pass and hosted smoke test on 2026-11-25

Require a deliberate pass over every Code Review Rule in the captured base
before the pilot writes findings. The review should surface every violation
even when the finding is outside the changed lines. Compare the PR metadata
body with the canonical record at the captured head and omit passing rules
from the output. Exercise the prompt with the local harness and confirm that
the same assertion rejects the parent workflow.

After both changes reach `main`, use one new temporary same-repository PR
in ready-for-review state with a substantive record mismatch and a body
that says it "will be closed". Expect the deterministic record job to fail.
Request the PR's first Claude review and expect the mismatch under **New
findings** as `blocking`, citing `AGENTS.md`, **Code Review Rules**, with a
final line reporting the remaining blocker. Record both outcomes and the
reviewed revisions, then close the temporary PR unmerged. Follow the
[hosted smoke procedure](../development.md#claude-review-pilot).

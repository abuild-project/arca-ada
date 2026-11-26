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

## PR body freshness on 2026-11-25

Bind publication to the reviewed body because a PR body edit can leave the
base and head SHAs unchanged. Hash the body from the same snapshot that
supplies `review/pr.json`. Treat a null body as empty, normalize CRLF,
strip whitespace only at the end of the whole text and hash the UTF-8
bytes with SHA-256. Reuse the workflow's hash code in the publish job to
check the fresh API response without a checkout. Require a fresh review
when the body changes substantively or the target cannot be verified.

Exercise the publish step with a stubbed GitHub CLI. Check unchanged and
normalization-equivalent bodies, a substantive edit with the same base and
head, and missing body or digest inputs. Run the body-edit assertion against
the preceding workflow to show that it previously posted the stale review.

## Checker selection and reserved topics on 2026-11-26

Run the checker from the exact PR base in the exact PR head checkout so a
head change to the checker cannot change the comparison. Keep the existing
read-only permissions and checkout pin and disable credential persistence on
both checkouts. Use `python3 -I` and keep PR event fields out of the shell
command. Log the use of the head checker when the base lacks one for the
introducing PR. Fail if the selected checker is unusable or if running it
fails. Run the harness in build CI with the existing host dependencies.

Reject the derived topics `CLAUDE` and `CLAUDE.local` with exact casing
because the Claude review pilot removes files named `CLAUDE.md` and
`CLAUDE.local.md` from the review context. Exercise the actual comparison
step with a missing or weakened head checker, distinct base and head
records, an unusable base checker and the introducing fallback. Exercise
both reserved topics with matching records. Run the assertions against the
published workflow and checker as sensitivity controls.

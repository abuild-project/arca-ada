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

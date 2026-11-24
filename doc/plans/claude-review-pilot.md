# Claude review pilot

## Scope and approach on 2026-11-24

Try on-demand Claude review on a small, same-repository PR to main.
The [agent contribution workflow](agent-workflow.md) governs independent
review, Copilot, CI and the phase budgets. The pilot review supplements
that workflow.

Decision: Use a maintainer comment to authorize review generation on a
read-only GitHub-hosted job. Give the separate publish job permission to
post a comment, and require matching base and head revisions so the
comment applies to the reviewed diff. Require a fresh request for another
attempt so a GitHub rerun cannot reuse the original maintainer's authority.

Validate the trigger, target and stale-revision handling locally. With
the workflow on the default branch and the OAuth secret configured, verify
an authorized trigger and a revision-bound comment on a ready PR before
relying on the pilot.

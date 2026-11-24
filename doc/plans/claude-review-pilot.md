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

## Context and publication controls on 2026-11-24

Decision: Provide the pinned head checkout and revision-bound context as
files, because a diff alone lacks surrounding source and earlier review
history. Start Claude in the trusted base checkout with read-only workspace
tools and keep head guidance out of automatic discovery. Use the base
action at the existing pinned revision to preserve the captured base
and keep GitHub credentials out of the Claude invocation. Name the base
guides in the prompt so it can read them on revisions without Claude
imports. Refuse step debug logging to avoid printing the raw transcript.

Raise the diff limit to 256 KiB and the review budget to 20 turns and
20 minutes. Require the generation and publication jobs to reject common
credential patterns. Exercise preparation and publication with a local Git
fixture and stub GitHub CLI. Confirm the resulting permissions, OAuth and
revision-bound comment on a live run after the workflow reaches main.

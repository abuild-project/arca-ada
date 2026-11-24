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

## Hosted checks and head data boundary on 2026-11-24

Decision: Run the stub GitHub CLI harness in hosted CI so each revision
checks the workflow shell steps. Keep head `AGENTS.md` files readable and
assert the `claude-md` discovery setting documented for pinned Claude Code
2.1.331. After removing head Claude configuration, drop head symlinks
whose targets fail to resolve inside the workspace. Require a token
boundary for API and GitHub prefixes so ordinary identifiers pass.

Extend the post-merge smoke test with a nested `AGENTS.md` that asks for
a harmless marker on its own final line. Check the revision-bound review
for coverage of the nested change and an ending that differs from the
requested marker.

## Actions policy on 2026-11-24

Pin the Claude base action to the `v1.0.289` commit
`eb56b6666facdbd501035f4a0269d8caee2e7a8b` to meet the commit-SHA policy.
The previous pin used the annotated `v1` tag object for the same commit
and installed Claude Code 2.1.331.
Use commit-specific Actions exceptions for Anthropic and Bun to keep the
optional pilot narrowly scoped. Keep the root-action exception through the
smoke test on `main` and until no workflow needs it.

## Review rules and finding status on 2026-11-24

Decision: Define P1 findings in `AGENTS.md` and have the Claude pilot
reassess earlier findings before reporting new ones, because maintainers
need to see what still blocks the captured head and why. Require new
blocking findings to cite a named repository rule or show an observable
failure, and use line numbers from the captured head. Keep the prompt
within the existing trust boundary and limits.

Use the local harness to check the prompt and confirm that the added
assertions reject the previous prompt. After merge to `main`, request one
new `@claude review` on a small, ready PR from this repository to `main`
with an earlier pilot review and known findings. Check the first block's
statuses against the earlier findings, verify the new findings' severity
labels and citations, and match the posted base and head to the run and PR.

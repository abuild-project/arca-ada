# Claude review context

The Claude pilot reviews the captured PR revision with surrounding source
and context files. The trusted base checkout remains the workspace root.
The head checkout and its diff, changed files, PR metadata, commit log and
earlier pilot comments are review data. Head Claude instructions and
configuration are removed before invocation, along with head symlinks
whose targets fail to resolve inside the workspace. Head `AGENTS.md` files
remain readable as data and automatic discovery is disabled. Both
checkouts disable credential persistence.

The prompt points to the standing guides on the captured base, including
revisions before `CLAUDE.md` existed. The base action uses the `v1.0.289`
commit `eb56b6666facdbd501035f4a0269d8caee2e7a8b` and installs Claude
Code 2.1.331. The base action receives no GitHub token input. Debug logging
is refused before invocation. Claude Code can use only workspace-scoped
file reads and searches. A request can review a diff of up to 256 KiB with
a limit of 20 turns and 20 minutes. The separated publish job still verifies
the reviewed base and head. Both jobs reject credential-like review content.
Common API and GitHub token patterns require a line start or a preceding
non-word character, allowing ordinary identifiers with embedded prefixes.

The optional pilot needs a Claude Pro or Max subscription, an Actions OAuth
secret and commit-pinned Actions exceptions for Anthropic and its Bun setup
dependency. The [development guide](../development.md#claude-review-pilot)
records those prerequisites and when to retire the earlier root-action
exception.

## Validation

The focused harness runs locally and in hosted CI with local Git revisions
and a stub GitHub CLI. It covers immutable context, guidance discovery
settings, symlink cleanup, paginated bot comments, debug refusal, stale
revisions and credential boundaries in both jobs. A smoke test after merge
to `main` must verify that the effective allowlist permits the direct and
nested actions, OAuth works, and a revision-bound review is posted. A nested
`AGENTS.md` canary checks instruction handling during that run.

Co-Authored-By: GPT-6 <noreply@openai.com>

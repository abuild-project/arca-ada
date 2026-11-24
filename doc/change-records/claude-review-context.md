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
revisions before `CLAUDE.md` existed. The pinned base action receives no
GitHub token input. Debug logging is refused before invocation. Claude
Code can use only workspace-scoped file reads and searches. A request can
review a diff of up to 256 KiB with a limit of
20 turns and 20 minutes. The separated publish job still verifies the
reviewed base and head. Both jobs reject credential-like review content.
Common API and GitHub token patterns require a line start or a preceding
non-word character, allowing ordinary identifiers with embedded prefixes.

## Validation

The focused harness runs locally and in hosted CI with local Git revisions
and a stub GitHub CLI. It covers immutable context, guidance discovery
settings, symlink cleanup, paginated bot comments, debug refusal, stale
revisions and credential boundaries in both jobs. The hosted OAuth review
and actual instruction handling require a live smoke test on the default
branch with a nested `AGENTS.md` canary.

Co-Authored-By: GPT-6 <noreply@openai.com>

# Claude review context

The Claude pilot reviews the captured PR revision with surrounding source
and context files. The trusted base checkout remains the workspace root.
The head checkout and its diff, changed files, PR metadata, commit log and
earlier pilot comments are review data. Head Claude instructions and
configuration are removed before invocation. Both checkouts disable
credential persistence.

The prompt points to the standing guides on the captured base, including
revisions before `CLAUDE.md` existed. The pinned base action receives no
GitHub token input. Debug logging is refused before invocation. Claude
Code can use only workspace-scoped file reads and searches. A request can
review a diff of up to 256 KiB with a limit of
20 turns and 20 minutes. The separated publish job still verifies the
reviewed base and head. Both jobs reject credential-like review content.

## Validation

Focused tests execute the workflow shell steps with local Git revisions and
a stub GitHub CLI. They cover immutable context, guidance paths and cleanup,
paginated bot comments, debug refusal, stale revisions and credential
rejection before publication. The hosted OAuth review and tool enforcement
require a live smoke test on the default branch.

Co-Authored-By: GPT-6 <noreply@openai.com>

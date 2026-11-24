# Claude review pilot

The optional GitHub Actions pilot lets a maintainer request a Claude review
of a small, ready pull request to `main` from a branch in the repository.
The exact `@claude review` conversation comment starts the workflow for a
human with maintain or admin access. The workflow uses an Actions OAuth
secret and a pinned Claude Code Action. Both jobs require the first attempt
of a run, so a fresh maintainer comment is needed for another review.

The review job captures the base and head revisions and their diff with a
read-only GitHub token. Claude loads the standing project guides and
security policy through `CLAUDE.md` imports from the trusted base. It reviews
the diff as data with shell, editing and MCP tools disabled. The review job
requires nonblank text of at most 8,000 characters before handing it off.
A separate job checks the revisions before posting one comment with the
reviewed SHAs. The result supplements independent review and CI.

## Validation

Local checks parse the workflow and exercise its shell steps with a stub
GitHub CLI. They verify the exact trigger, role and PR state, reject forks
and stale revisions, and check the handoff at 8,000 and 8,001 characters.
Blank and non-string responses fail before publishing. Valid review text
is passed as comment data. Mocked workflow conditions allow both jobs on
the first attempt and skip both on reruns. The standing Claude imports
resolve to tracked files. The indexes remain sorted.

The live review requires the workflow on the default branch, a repository
OAuth secret and a maintainer request on a ready PR. Check the run and
compare the posted base and head against the tested PR before using the
result as review evidence.

Co-Authored-By: GPT-6 <noreply@openai.com>

# Claude review pilot

The optional GitHub Actions pilot lets a maintainer request a Claude review
of a small, ready pull request to `main` from a branch in the repository.
The exact `@claude review` conversation comment starts the workflow for a
human with maintain or admin access. The workflow uses an Actions OAuth
secret and a pinned Claude Code Action. Both jobs require the first attempt
of a run, so a fresh maintainer comment is needed for another review.

The review job captures the base and head revisions and their diff with a
read-only GitHub token. It checks out the trusted base for project guidance
and gives the diff to Claude as data with shell, editing and MCP tools
disabled. A separate job checks the revisions before publishing one comment
with the reviewed SHAs. The result supplements independent review and CI.

## Validation

Local checks parse the workflow and exercise both shell steps with a stub
GitHub CLI. They verify the exact trigger, role and PR state, reject forks
and stale base or head revisions, and confirm that review text is passed
as comment data. Mocked workflow conditions allow both jobs on the first
attempt and skip both on reruns. The plan and record indexes remain sorted.

The live review requires the workflow on the default branch, a repository
OAuth secret and a maintainer request on a ready PR. Check the run and
compare the posted base and head against the tested PR before using the
result as review evidence.

Co-Authored-By: GPT-6 <noreply@openai.com>

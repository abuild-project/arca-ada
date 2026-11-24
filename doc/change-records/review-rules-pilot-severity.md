# Code review rules and Claude pilot severity

`AGENTS.md` makes incorrect validation attribution, ineffective regression
checks, conflicting project guidance, unverified upstream claims and PR
bodies that differ from their committed change records blocking findings.

The Claude pilot starts with a **Previous findings** block to show what still
applies to the captured head. It labels each new finding `blocking` or `nit`
and reserves `blocking` for a named repository rule violation or a concrete
observable failure. Finding locations use actual lines in the head files.

## Validation

`python3 tests/check-claude-review.py` passed all eight tests. The same harness
run against the original workflow at
`00216335a6bfad40f6ce3ba5ee0eae2f7ef63843` in an isolated fixture failed only
the new checks for previous finding status, severity and head line citations.
The workflow is byte-identical outside the prompt. The harness checks the
prompt text. Review output and revision attribution still need the
[live smoke test](../development.md#claude-review-pilot) after merge to `main`.

Co-Authored-By: GPT-6 <noreply@openai.com>

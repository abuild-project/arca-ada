# Documentation status and reader guidance

Status: Planned on `codex/docs-cleanup`.

Base revision: `2091ca9118f875b5fbd65adcf23ca62ae073289e`.

## Decisions on 2026-10-24

- Record acceptance in plan status paragraphs and both indexes using
  immutable merge commits. Keep historical plan and record bodies unchanged.
- Describe Abuild and the next integration and writer steps for readers
  without repository or infrastructure context. Keep publication policy,
  security work and repository settings outside this topic.
- Clarify that ARM is selectable while AMD64 is the reference validation
  architecture. Change only the two wrapper help lines outside Markdown.

## Implementation

1. Verify the acceptance mapping against first-parent merges and confirm
   which merge introduced the writer-provenance record. Commit this plan
   before implementation.
2. Update plan status paragraphs and sorted indexes. Add the neutral change
   record with acceptance pending, and update the changelog.
3. Revise the identified README, contribution and development guidance and
   the two wrapper help lines without changing executable behavior.
4. Check merge/date references, unchanged historical bodies, changed-file
   scope, relative Markdown links, remaining legacy wording and whitespace.
   Run the existing host-side wrapper checks. Compiler, format, CLI and
   coverage checks are unnecessary because their inputs remain unchanged.

## Progress

The accepted merges match the base revision's first-parent history. The
writer-provenance record was introduced on the maintained branch by merge
`1bca4a7594da47016510108acb025e7929d9483f`.

Co-Authored-By: GPT-6 <noreply@openai.com>

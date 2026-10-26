# CLI diagnostics, arguments and cancellation

Status: Implemented and verified locally on `codex/cli-polish`.

Base revision: `d3f0574b37c68907206e59c7beff01d85b51ee88`.

## Decisions on 2026-10-26

- Keep complete CLI-generated diagnostics outside GNAT's bounded exception
  message. A CLI-local diagnostic owner is reset for each Run and accessed
  only by the sequential command path; signal handlers retain their separate
  protected cancellation state. Preserve exception identities and exit codes.
- Escape bytes below 0x20, DEL and backslash at diagnostic output only, using
  `\xNN` and `\\`. Keep source names, archive names and archive bytes intact.
- Reject directory-only output spellings during argument parsing, before
  filesystem access. Missing or non-directory output parents remain command
  failures with an output-specific diagnostic.
- Derive errno and rename constants from the target C headers through the
  existing bridge. Verify exports against an independently compiled header
  probe and exercise the actual fallback and missing-node paths.
- Handle SIGHUP at the same safe boundaries as SIGINT and SIGTERM, returning
  129 with cleanup. Retain exits 130 and 143 and extend the test-only signal
  acknowledgement protocol to SIGHUP.
- Document every option, `=VALUE` and exit status in help. Existing relative
  output, separate long-option and invalid SOURCE_DATE_EPOCH tests already
  pass on the baseline; retain them and extend long-option `=VALUE` coverage.
- Leave the separate staging worktree and Abuild unchanged. Library APIs and
  `arca.gpr` are unchanged; assess the retained extending-project consumer.

## Implementation

1. Add focused checks and run them against the baseline. Preserve valid CLI
   and writer outputs for byte comparison; distinguish retained positive
   controls from new regressions.
2. Implement diagnostics, argument checks, target constants, SIGHUP and help.
   Update coverage inventory, guides, changelog and the canonical record.
3. Run coverage first on fresh committed sources, then the full check, in
   rootless AMD64 Trixie. Confirm archive parity, negative-control sensitivity,
   installed consumers and the complete existing signal/fault suites.
4. Complete author review, push and create a separate pull request, request
   Copilot and wait. Merge remains a maintainer action; release basics starts
   only after this topic is accepted.

## Progress

The focused new controls reject the baseline for the intended diagnostic,
argument, bridge, help and SIGHUP behavior. Retained option and environment
controls pass against both versions. Coverage and the complete check pass in
that order on fresh committed sources. Every production body has executed
coverage; installed consumers, compiler-style boundaries and tool-selection
checks pass. Preserved CLI and writer archives are byte-identical. The author
review and complete file-scoped CLI semantic checks are finished; ARM64 and
newer GNAT are outside the observed evidence.

Co-Authored-By: GPT-6 <noreply@openai.com>

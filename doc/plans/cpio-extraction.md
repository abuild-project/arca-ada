# CPIO extraction

Status: Accepted in `b7d8beb` (PR #3) on 2026-10-22.

## Scope and decisions

The owner requested the next extraction step on 2026-10-21 and granted
additional LGPL licensing on 2026-10-22; see the
provenance record
(`doc/provenance/cpio-tar.md` at revision
`b5c0f114cb702686908326605913ef5e8f64a6f0`).
CPIO is first; TAR and Abuild integration remain separate steps.

- Retain operation names, metadata arguments, format profile and diagnostics.
- Import only the used stream-copy operation and keep that helper private.
- Own unclosed output in the standalone writer. Remove unfinished output on
  normal scope exit and exception unwinding.
- Reject Create on an open writer before resetting its offset and inode.
- Keep state per instance and copy buffers per call on the heap.
- Supply test and coverage tools in the image, without runtime installation.
- Use development build/run wrappers locally and in CI, as requested by the
  owner on 2026-10-21. Default both to AMD64 and allow explicit ARM64 selection.

## Acceptance evidence

- Warning-free static library and independent installed consumer.
- Independent raw checks for entry types, payloads, hardlinks, field bounds,
  UTC timestamps, padding and trailer.
- GNU cpio and libarchive listing and extraction without root requirements.
- Byte parity against the exact predecessor, with source hashes verified.
- A predecessor failure and corrected pass for omitted-Close descriptor checks.
- Parallel independent writers on bounded stacks and exact-byte comparisons.
- Coverage inventory and execution reports for every new production body.
- Complete Ada MCP views, file diagnostics and final author self-review.

## Progress

The separate licensing prerequisite was merged in
[PR #2](https://github.com/mweidle73/arca-ada/pull/2) on 2026-10-22.
The topic is rebased onto the accepted `main` with an identical file tree.
Native Ada MCP project, symbol and file checks pass after that rebase.

Implementation and tests are present on `codex/cpio-extraction`. The copy
algorithm is preserved. Fresh-image checks, predecessor parity, coverage,
real-container wrapper tests and author review pass. The fresh Ada MCP pass
also confirms complete project and symbol views and empty file diagnostics.
Results are maintained in the [change record](../change-records/cpio-extraction.md).

## Review follow-up

On 2026-10-22, Codex and Copilot reported the same missing scratch-parent
dependency in standalone coverage. The coverage entry point now creates its
own parent, and CI checks coverage first with no existing `build/` directory.
The fresh-source failure and corrected run are recorded in the change record.

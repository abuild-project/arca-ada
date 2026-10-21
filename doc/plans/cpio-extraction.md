# CPIO extraction

Status: Implemented and locally validated on 2026-10-21.
The final Ada MCP refresh is unavailable; the compiler/source fallback is
recorded explicitly in the change record.

## Scope and decisions

The owner requested the next extraction step on 2026-10-21 and granted
additional LGPL licensing on 2026-10-22; see the
[provenance record](../provenance/cpio-tar.md).
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

Implementation and tests are present on `codex/cpio-extraction`. The copy
algorithm is preserved. Fresh-image checks, predecessor parity, coverage,
real-container wrapper tests and author review pass. Results and the Ada MCP
limitation are maintained in the [change record](../change-records/cpio-extraction.md).

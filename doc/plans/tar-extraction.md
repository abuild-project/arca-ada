# TAR extraction

Status: Accepted in `3914462` (PR #4) on 2026-10-22.

## Accepted scope

Extract the inventoried native TAR writer as `Arca.TAR` after the accepted
CPIO import. Use LGPL-2.1-or-later under the recorded additional grant.
Abuild integration, other formats and test-framework migration stay separate.

The source is the inventoried accepted Abuild revision
`136ca84f0f5c49acae5fdd22f43359a32ca26e70`. Its TAR files match the current
locally known accepted upstream source. Verify every imported byte against
the existing manifest; retain the original fixture producer record.

## Implementation decisions

- Preserve public operation names, metadata bounds, exception identities and
  successful ustar/GNU bytes. Retain format-local serializers and field maps.
- Reuse the existing private `Arca.Binary_IO.Copy_File_To_Stream` unchanged.
- Give each writer controlled ownership like CPIO: discard unfinished output
  on scope exit, exception unwinding and owner termination between operations.
- Reject Create on an open writer with an explicit status error before
  changing its file. Do not promise atomic adds or active-I/O abort safety.
- Keep the independent test decoder separate from production field constants.
- Import the recorded GNU tar 1.34 ustar fixture and original producer notes;
  do not regenerate it or require privileged device creation during tests.

## Acceptance

- Warning-free library, independent installed client and complete Ada MCP
  project/symbol views with synchronized file diagnostics.
- Exact predecessor byte parity and the historical GNU ustar subset fixture.
- Independent raw checks, GNU tar and libarchive listing/extraction, including
  header checksums, padding, entry kinds and GNU long metadata.
- Boundary, error, reproducibility, parallel-instance and owner-lifetime
  checks; sensitivity controls for decoder and cleanup assertions.
- Standalone fresh-source coverage reports every production body; the existing
  CPIO and packaging checks remain successful.
- Complete documentation and provenance updates followed by final author review.

## Progress

Implementation, source identities, predecessor bytes, reference fixture,
external readers, ownership, installed-client and fresh-source coverage checks
pass on `codex/tar-extraction`. Ada MCP project, symbol, navigation and file
checks pass. Final author review and two independent static passes found no
blocking or fix-before-PR findings. See the
[change record](../change-records/tar-extraction.md) for evidence and limits.

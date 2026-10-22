# Standalone TAR writer

Status: In progress; implementation and validation are not complete.

This step extracts the inventoried native TAR writer into `Arca.TAR` under
the additional LGPL-2.1-or-later grant. CPIO and the private copy helper were
accepted separately. The shared copy algorithm will be reused unchanged;
Abuild transformation adapters and backend integration remain in Abuild.

The accepted source revision is
`136ca84f0f5c49acae5fdd22f43359a32ca26e70`; the
[inventory and grant](../provenance/cpio-tar.md) identify its exact scope.
Imported source and fixture identities will be verified against that manifest.

The existing successful-output profile is POSIX ustar headers with GNU
LongName/LongLink metadata when needed. Controlled ownership and an explicit
open-writer Create guard are planned lifecycle additions, following CPIO.

## Validation

The source project loads completely in Ada MCP. An anchored type query returns
the TAR archive declarations with a complete index; file-scoped diagnostics
for the source body are complete and empty. Imported format implementation,
reader checks, byte parity, packaging and coverage still require validation.

No public release or Abuild dependency update is part of this change.

Co-Authored-By: GPT-6 <noreply@openai.com>

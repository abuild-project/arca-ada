# Standalone CPIO writer

Arca provides `Arca.CPIO`, extracted from the inventoried Abuild writer under
the recorded additional LGPL grant. Callers can emit `newc` archives without
Abuild configuration, file-object types, logging or scheduling. Public
operation names, metadata arguments and successful output retain the
predecessor's behaviour.

The licence and metadata-only provenance prerequisite is prepared separately
in [PR #2](https://github.com/mweidle73/arca-ada/pull/2), before this writer
is published. This topic is based on that LGPL-2.1-or-later decision. Imported
units retain upstream copyright notices; their SPDX identifiers select the
additional LGPL grant. The original source grant remains available upstream.

The standalone writer owns its output: an unclosed writer removes unfinished
output on scope exit, including exception unwinding. Create on an open writer
fails before changing its offset or inode. These are deliberate lifecycle
improvements; normal Close retains the predecessor's bytes.

Local and CI container entry points are `docker/dev/build` and `docker/dev/run`.
They default to AMD64, allow explicit ARM64 selection and keep normal runs
under the invoking UID/GID. The build wrapper accepts an image tag. Explicit
commands retain batch input; a default shell retains forwarded input and a
TTY when appropriate. No runtime step installs missing tools.

## Imported material

Source revision: `136ca84f0f5c49acae5fdd22f43359a32ca26e70`.
The [inventory and grant](../provenance/cpio-tar.md) identify original bytes
and contribution history. Original notices are retained; imported units
carry the additional LGPL grant. The GPL text is reproduced unchanged.

| Source | Destination | Changes |
| --- | --- | --- |
| `src/abuild-file_formats-cpio.ads` | `src/arca-cpio.ads` | Namespace, contracts and controlled ownership |
| `src/abuild-file_formats-cpio.adb` | `src/arca-cpio.adb` | Namespace, comments, unshared output, finalization and Create state guard |
| `src/abuild-file_formats-binary_io.ads` | `src/arca-binary_io.ads` | Private child exposing only the used copy operation |
| `src/abuild-file_formats-binary_io.adb` | `src/arca-binary_io.adb` | Copy operation and heap-buffer declarations; no endian serializers |
| `COPYING` | `LICENSES/GPL-2.0-or-later.txt` | Unmodified licence text, not relicensed as LGPL |

Tests are Arca-owned adaptations of behavioural assertions with an independent
Python decoder and subprocess-based reference readers. They do not import
Abuild's mixed transformation test units or historical fixtures. No TAR
source, Abuild backend switch or released API is introduced.

## Validation

After moving to the separate licensing base, the complete Trixie check passes
again, including the installed licence and copyright assertions. The writer
specifications and bodies are unchanged apart from licence comments. A parity
sweep confirms that executable source and existing test behavior are retained.
Fresh MCP project and symbol queries are complete; writer bodies and both Ada
test drivers have complete, empty diagnostics after the rebase.

The fresh AMD64 Trixie image builds through `docker/dev/build`. The clean
rebuild and parallel check target pass through `docker/dev/run`. The
installed consumer creates and closes a CPIO archive through the installed
API and checks its header and trailer; hiding the installed project still
fails discovery. The executable-path regression covers the added test build
and cleanup recipes as well as the existing commands.

Raw checks cover every emitted entry type, payload bytes, hardlink metadata,
padding, trailer, ownership and fixed UTC timestamps. GNU cpio and libarchive
list all entries and extract files, links and FIFOs without device-node
creation. Independent tasks produce identical archives on bounded stacks.
Copy tests check exact sizes, changed sources, invalid buffers and descriptor
cleanup after exceptions.

The final predecessor run verifies exact bytes for the entry matrix and
validation-recovery archive, and requires the original writer to fail the
omitted-Close descriptor check. The stream-copy subprogram is also verified
byte-identical to the recorded source. A code comparison excludes unintended
serializer changes outside the documented ownership and Create changes.

The full instrumented suite passes and reports 42/42 executed lines in the
copy body and 177/186 in the CPIO body. Epoch boundaries, failed-add scope
exit, normal task exit and task abort are exercised. Coverage includes all
production bodies; it is not a claim that every branch is covered. These
checks use direct Ada assertion drivers orchestrated by Python `unittest`.
Task-abort checks suspend owners between archive operations; they do not
establish interruption safety inside an active copy operation or exhaustive
filesystem fault handling.

Host-side wrapper contract checks pass for default and explicit platforms,
image tags, paths with spaces, command arguments, help, invalid options and
the explicit root exception. All three real-container input and TTY tests
also pass against the built image. CI invokes the same wrappers; no hosted
CI result is claimed before this branch is published.

The final Ada MCP pass completed on 2026-10-22 after restarting the maintained
launcher. Its runtime checkout was fast-forwarded to the accepted source
revision; the existing image matches the committed adapter patchset. Direct
MCP protocol queries returned complete exact project views and anchored,
untruncated symbol results for the library, test project and example client.
File-scoped diagnostics were complete and empty for all eleven Ada sources.
Definition navigation from the test driver and example client resolved
`CPIO_Create` to its public declaration. These fresh results supersede the
earlier Docker interruption and compiler/source fallback. Native Ada tools
were unavailable in the chat, so queries used the running server's stdio
protocol directly. Semantic navigation confirmed project boundaries
without additional broad source searches. No throughput or Abuild integration
result is claimed.

Final author self-review checked the complete change and enclosing code,
successful-output compatibility, deliberate lifecycle differences, test
sensitivity, per-instance concurrency, bounded stacks and unchanged copy
complexity. Documentation, licences, coverage inventory, source style, commit
message limits, generated artifacts and publication hygiene were checked.

## Review lessons

- Every payload-bearing operation is covered, including symlink data and
  hardlink sets with data on the final member.
- The reader owns its field map. Corrupted headers, padding, payload and
  truncated output must fail independently of the serializer.
- Cleanup is tested across actual scope exit and exception unwinding. Each
  abandoned output has a distinct path, so the predecessor reaches descriptor
  assertions without first hitting its shared-file reopen guard.
- Stream, offset and inode state belongs to each instance. Heap buffers are
  per call; parallel checks use separate outputs and immutable source bytes.
- Times are anchored to UTC. Extracted bytes and link identity are checked,
  independently of reader exit status or listing text.
- The coverage inventory requires every production body. Line execution is
  reported without implying complete branch coverage.
- Abuild manuals and dependencies are unaffected. Arca's user and development
  guides, licence guidance and changelog describe the new API.

Co-Authored-By: GPT-6 <noreply@openai.com>

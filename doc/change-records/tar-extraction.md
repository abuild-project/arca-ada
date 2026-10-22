# Standalone TAR writer

Arca provides `Arca.TAR`, extracted from the inventoried native Abuild writer
under the additional LGPL-2.1-or-later grant. Callers emit the retained
ustar/GNU profile without Abuild types, configuration, logging or scheduling.
Public operation names, metadata bounds, exception identities and completed
archive bytes are retained.

The standalone instance owns unfinished output. Scope exit, exception
unwinding and owner-task termination between operations remove an unclosed
archive. An open writer remains rejected by Create; Arca now supplies the
explicit `TAR_Create called on an open archive` status-error message.
The existing private stream-copy helper is reused without modification.

## Imported material

Source revision: `136ca84f0f5c49acae5fdd22f43359a32ca26e70`.
The [inventory and grant](../provenance/cpio-tar.md) identify the source bytes,
attribution and additional grant. No new source revision or unrelated writer
is included.

| Source | Destination | Changes |
| --- | --- | --- |
| `src/abuild-file_formats-tar.ads` | `src/arca-tar.ads` | Namespace, contract comments and controlled ownership |
| `src/abuild-file_formats-tar.adb` | `src/arca-tar.adb` | Namespace, explanatory comments, Finalize and explicit Create guard |
| `data/tests_abuild_file_formats_tar/gnu-ustar-subset.hex` | `tests/fixtures/tar/gnu-ustar-subset.hex` | Unmodified |
| `data/tests_abuild_file_formats_tar/gnu-ustar-subset.README` | `tests/fixtures/tar/gnu-ustar-subset.README` | Unmodified original GNU tar 1.34 producer record |
| `data/tests_abuild_file_formats_tar/regular_file` | `tests/fixtures/tar/regular_file` | Unmodified original payload |

The three fixture files match their recorded hashes and bytes. The decoded
reference archive retains SHA-256
`4a57dfbf22f27b4829a79b814342b8efda7e05fb03e5c5930c525f2941cf4bfc`.
No fixture regeneration or test-time device-node creation is needed.
Original attribution and upstream GPL availability remain recorded; the GPL
text retained by the earlier CPIO import is unchanged.

Tests adapt direct writer assertions into Arca-owned Ada drivers and an
independent Python decoder with GNU tar and libarchive readers. They do not
copy the mixed transformation test package or its Abuild infrastructure.
Abuild dependency integration, compression and stable API publication remain
separate.

## Validation

The updated AMD64 Trixie image builds through `docker/dev/build`; GNU tar is
an explicit image dependency and archive-tool preflight input. Both normal
writer suites, library/client builds and installation checks pass through
`docker/dev/run`. The isolated installed client creates and closes both CPIO
and TAR; its TAR output is exactly two zero blocks. The missing-project
negative control and executable-path/relative-builder regressions pass.

A second source copy without generated objects or `build/` passes standalone
coverage first, followed by the full normal check, matching the accepted CI
order. Coverage reports all production bodies: copy 42/42, CPIO 177/186 and
TAR 190/193 executed lines. Counts are line evidence, not exhaustive branch
coverage. The bounded size probe keeps its profiling side effects private.

Raw checks cover the ustar field map, unsigned header checksum, payload and
GNU metadata padding, exact-fit fields, nondefault string bounds, all entry
kinds, maximum numeric metadata and the first rejected values. GNU tar and
libarchive list the complete entry matrix and extract regular files, links,
directories and FIFOs with exact data, link identities and directory modes.
Reproducibility survives source-mtime changes; eight independent instances
produce identical bytes on 128 KiB worker stacks. Decoder corruption controls
reject damaged checksums, payloads, padding and the end marker.

The maximum-size probe accepts the `2**33 - 1` size header from a sparse source
under a 512-byte output limit. It verifies header acceptance without copying
8 GiB and does not claim full maximum-size archive completion. Lifetime
checks cover omitted closes, caller exceptions, failed adds after GNU metadata,
normal task exit and task abort between calls. Active-I/O interruption and
exhaustive filesystem-fault handling remain outside these checks.

The predecessor helper verifies all four original TAR/copy source hashes
before compiling them under minimal parent packages. Complete entry, GNU
fixture, boundary, error-recovery and empty archives match the current writer
byte for byte. The original writer fails the omitted-Close descriptor check;
the controlled writer passes it. A statement-level comparison permits only
namespace, finalization and Create-guard additions; serializer statements and
the shared copy helper are unchanged.

Ada MCP returns complete exact views for the library, tests and independent
client, complete anchored symbol results and empty file diagnostics for the
new writer, driver and changed client. Navigation from the client reaches the
public TAR declaration, and the writer's copy call reaches the private helper.
Focused type queries avoid fuzzy-search noise in the larger upstream project;
semantic navigation confirms the dependency boundary. Compiler/runtime checks
remain the build authority.

## Documentation and review

README, the [TAR guide](../tar.md), development guidance, licensing scope,
changelog and indexed plans/change records describe this independent import.
Abuild's User Manual, Developer Guide, dependencies and coverage inventory are
unaffected because no Abuild backend switch is included. There is no separate
Arca release manual or stable release to annotate.

Implementation, local validation and final author self-review are complete.
Two independent static passes covered implementation/lifecycle and
tests/build/provenance/documentation; neither identified a blocking or
fix-before-PR finding. Compatibility, oracle sensitivity, instance-local
state, stack use and performance costs were rechecked against the source.
Serializer work is unchanged; no benchmarked performance improvement is
claimed.

The final sweep also checked API comments and Ada layout, documentation and
links, commit attribution and 50/72 wrapping, whitespace, generated artifacts
and the clean topic worktree. This independent repository requires no Abuild
ticket. The topic is ready for external review. Validation above was performed
locally; hosted TAR CI results are reported separately.

## Review lessons

- The field map and test decoder are independent; the historical GNU fixture
  retains its original producer identity, command, scope and hash.
- Every payload-bearing path is checked, including combined GNU LongName and
  LongLink records and multi-buffer, exact-block and empty file payloads.
- Cleanup controls use distinct output paths and compare process-local
  descriptor counts. The old writer reaches the intended descriptor failure.
- Each instance owns its stream; copy buffers are per call on the heap.
  Parallel tasks share only immutable input bytes and constants.
- Caller times and GNU metadata's epoch are UTC-anchored. Size-limit acceptance
  is bounded independently of full-payload completion.
- Fresh-source coverage runs first; packaging helpers cannot supply its
  missing prerequisites. The new body is included in the complete inventory.
- Existing ustar normalization and copy behavior are retained; this change
  introduces standalone ownership, tests and packaging for the TAR API.

Co-Authored-By: GPT-6 <noreply@openai.com>

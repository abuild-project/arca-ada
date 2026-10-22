# Archive creation CLI

Arca can create uncompressed CPIO `newc` and TAR archives from a directory
with `arca create --format cpio|tar -C DIRECTORY -o ARCHIVE`. The CLI supplies
filesystem discovery and metadata policy to the accepted native writers.
The initial platform is 64-bit Linux, validated on AMD64 Debian Trixie.
The [CLI guide](../cli.md) describes options, limits and failure behavior.

Entries are emitted in bytewise lexical order, preserving permission bits,
numeric owners and whole-second source mtimes. Explicit owner/time overrides
and the SOURCE_DATE_EPOCH fallback support reproducible output. Symlinks are
stored without traversal; regular-file hardlinks use selected tree members
only, independent of physical inode values or links outside the tree.
Directories, regular files, symlinks, FIFOs and device metadata are supported;
sockets and the reserved root-level CPIO trailer name are rejected.

The command inventories inputs before creating private staging in the output
parent. It excludes its own destination, rechecks source identity/metadata
before emission and publishes only after the writer closes successfully.
Default atomic no-clobber publication also protects a late-created target.
Explicit --force atomically replaces a regular file or symlink. Controlled
ownership and handled SIGINT/SIGTERM clean up ordinary incomplete output;
the previous destination survives errors before publication.

The library, public interfaces and source imports are unchanged. The CLI
project uses C only to convert lstat metadata to a fixed-width record.
Simple readlink, mkdtemp, rename and renameat2 calls use direct Ada bindings;
signal handlers and their shared state use an Ada protected object. GNAT's
existing normalization and raw directory-name iterator are reused. The
higher-level Ada.Directories iterator is unsuitable here:
its modification-time query rejects FIFOs and dangling links. New CLI code
is independently authored under LGPL-2.1-or-later; no further Abuild source
material or grant is imported.

Make builds, installs and cleans the CLI alongside the library. Preflight
checks GCC, and recipe/selected-tool regressions include the CLI commands.
Installed execution creates both formats. CLI integration tests retain
independent byte decoders and GNU/libarchive extraction. Coverage now checks
all CLI Ada/C bodies as well as the native library; no production body is
omitted. CI already uses the shared wrappers and Make targets, so the new
checks require no workflow or development-image package change.

## Validation

Warning-free compilation and the complete normal check pass in the supported
rootless Trixie image. CLI fixtures cover empty directories, Unicode names,
metadata defaults and exact maxima, overrides/environment precedence,
multi-buffer payloads, source hardlinks, dangling/directory symlinks, FIFOs,
reproducibility across creation order, nested output and parallel processes.
Source maps belong to one sequential invocation; parallel commands share
only immutable input data and own separate outputs.

Phase-controlled checks stop the command after staging opens, then test
SIGINT/SIGTERM cleanup, changed source metadata and a late-created destination.
Readiness is asserted so an early process exit cannot pass these checks.
An unreadable-source fixture uses a private native Linux temporary directory
because Docker Desktop's host sharing can allow reads of host mode-000 files
despite the container's UID/mode view. Its permissions are restored before
cleanup. Failure checks preserve the old output and reject staging leaks.

The reserved-name regression failed before its guard: the command returned
success for a CPIO member readers interpret as the end marker. It passes
after the guard and still accepts the same filename in TAR. A private
mutation replacing no-clobber publication with ordinary rename makes the late
destination test fail at its success/error assertion. The production adapter
passes the same test and preserves the competing output bytes.

The owner-requested C-boundary reduction keeps only the lstat wrapper. Ada
interrupt handlers record both termination signals in protected state;
filesystem and container work remains on the sequential command path. Simple
system calls import libc directly. Linux constants and the ssize_t binding
match the reference headers and 64-bit ABI. readlink's actual byte count bounds
the returned string without relying on a NUL terminator. Each failed call's
errno is captured before building a diagnostic, preserving contextual errors.
The unwritable-parent fixture checks mkdtemp failure before staging ownership
starts and preserves both existing outputs without leaving a directory.

The expanded signal/staging checks pass with the previous C-backed executable
and the replacement Ada-backed executable. Their commit precedes the adapter
change, pinning observable behavior across the refactor. Warning-free CLI
compilation, complete normal checks and production coverage pass with the new
bindings. The production-body inventory is unchanged; its C entry now contains
only the metadata wrapper. Library code, APIs and format fixtures are unchanged.

After the boundary revision, coverage-first and complete normal checks also
pass from fresh sources in a rootless, network-disabled container with no
Abuild mount. Object-symbol inspection shows only arca_lstat defined by the C
object. Both independent static follow-up passes report no blocking,
fix-before-PR or follow-up findings. Final author review rechecked ABI/result
types and constants, errno ordering, initialized symlink-target slices,
protected-state/callback lifetime, guard finalization, retained format and
failure contracts, source style, documentation and commit hygiene. No new
container state or writer API is introduced; no performance gain is claimed.

Ada MCP's CLI project/index and changed-file diagnostics are complete, with
no diagnostics. Navigation resolves Attach_Handler to the GNAT interrupt API
and confirms the direct readlink binding's result type. These checks helped
verify the new boundary without broadly searching runtime sources; no missing
semantic evidence or fallback was needed for this follow-up.

Final author review found two fixture weaknesses, also confirmed by the
independent validation finder. The trailing-output-slash check now removes
its earlier socket and pins the intended path diagnostic. Removing that
explicit guard produces a missing-source diagnostic and fails the corrected
assertion. The source-change test resets the last file before each format,
forcing a size change instead of depending on subsecond timestamp resolution.
Both corrected checks pass against the real implementation.

Complete coverage and the normal check pass sequentially in a fresh source
copy, with coverage first, no prior artifacts, no network and no Abuild mount.
All production Ada/C bodies report executed lines. Optional predecessor
comparisons remain separate and were not rerun for this consumer-only topic;
the accepted library serialization code is unchanged. Device-node creation
is not exercised through the rootless CLI fixtures, although native writer
tests pin its serialized metadata. Full maximum-size payload completion and
exhaustive storage faults are not claimed.

## Accepted library base and source layout

This topic follows accepted [PR #6](https://github.com/mweidle73/arca-ada/pull/6).
Rebase conflicts were limited to the changelog and plan index; both topics'
entries survive. CLI sources and tests were byte-identical after rebase,
and the accepted library cleanup, compiler defaults and unit tests remain
unchanged. This CLI topic does not claim those library improvements.

The CLI's Ada layout now follows the established readability conventions.
Blank lines separate declaration groups, nested blocks and processing phases;
case alternatives occupy separate lines and multiline parameter declarations
are aligned. A lexical comparison with the pre-rebase CLI confirms identical
Ada tokens, including literal values. The entry point already followed the
required layout. All CLI Ada units retain their declaration contracts and
80-column limit. No new regression test is needed for a token-identical
layout change; the existing full checks validate the combined library/CLI.

The CLI guide, README and changelog still describe the same behavior and need
no additional user-facing entry for this layout revision. The development
guide records the readability conventions; the plan and this record document
the accepted base and parity evidence.

After rebase and formatting, the complete normal check passes again in the
rootless AMD64 Trixie container, including the accepted finalizer-failure
cases. Ada MCP reports complete empty diagnostics for every CLI Ada unit.
The author reviewed the complete layout diff and enclosing code, confirming
unchanged cancellation, publication ordering, container ownership and ABI
contracts. Literal-preserving token parity supplies direct evidence that the
layout edit retains behavior; no performance change is claimed.

The rebased, reformatted sources also pass complete coverage first and then
the full normal check in a fresh tracked-source copy, running rootless in
AMD64 Trixie with no network or Abuild mount. All production bodies have
executed lines and no inventory entry is omitted. Both static parity passes
confirm retained CLI behavior, fixtures, build/installation/CI wiring and
accepted library changes. The source pass identified an index ordering
mistake; the change-record index now follows filename order. No Ada layout
finding remains. Final author review rechecked literal-preserving parity,
declaration contracts and separators, whitespace, documentation links and
commit 50/72 limits. Relevant lifecycle, metadata, concurrency, sensitivity
and scaling review lessons retain their earlier dispositions because the
runtime tokens and tests are unchanged. No generated artifact is committed.

## Ada MCP

The exact CLI project and anchored package index are complete. File-scoped
diagnostics are complete and empty for all new Ada units. Definition, hover,
reference and call navigation confirm the writer and publication boundaries.
Cross-file reference positions needed synchronization of the changed caller
after edits; refreshing that file restored current positions. Compiler and
runtime validation remain authoritative. Semantic navigation made the
dependency boundary easier to check without broad source searches.

## Review scope and dispositions

The reference-time conversion uses GNAT's UNIX conversion, with format limits
checked first. Numeric parsing checks overflow before arithmetic and forwards
parsed values. Entry ordering and selected hardlink counts have independent
output assertions. Staging is owned across every create/emit/close phase and
is finalized after the archive objects; cancellation tests exercise this
lifetime. Streams remain opened by the unchanged writers with shared=no.

Input trees must remain stable; identity checks are best effort rather than
protection against adversarial filesystem races. Cancellation is observed
between entries, so a synchronous file copy may finish first. SIGKILL, crashes
and power loss cannot promise cleanup. Atomic publication is not a durability
guarantee. These are documented interface boundaries, not missing claims of
transactional filesystem isolation.

The CLI retains metadata in invocation-local ordered maps and iteratively
walks directories, avoiding recursion and pairwise hardlink scans. Memory
scales with selected entries and names; lookup/insertion is logarithmic.
No throughput improvement or hosted CI result is claimed. Abuild integration,
its User Manual, Developer Guide, dependencies and release markers remain
outside this Arca-only topic. Arca's README, developer/CLI guides, changelog,
indexed plan and change record describe the new consumer.

Final author self-review covered the complete proposed range and enclosing
code across all six dimensions. Compatibility and independent reader claims,
numeric bounds, test sensitivity, cleanup ownership, invocation-local state,
scaling, documentation/links, publication scope, Ada declaration comments
and body layout, whitespace, final newlines, generated artifacts and commit
50/72 wrapping/attribution were checked. This independent repository requires
no Abuild ticket or User Manual release marker. The concrete fixture findings
and their sensitivity evidence are recorded above; local validation does not
claim a hosted pipeline result.

The independent source pass found no blocking, fix-before-PR or follow-up
findings. The validation pass confirmed the two fixture findings; its targeted
re-review of their committed corrections reports both closed with no further
findings. The final source/test stand passes complete coverage first and the
normal check again from fresh sources, rootless and without network or Abuild
access. Documentation-only completion does not alter the validated code.

Co-Authored-By: GPT-6 <noreply@openai.com>

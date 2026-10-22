# Archive creation CLI

Status: Implemented and locally validated on 2026-10-22, including the smaller
C boundary. Author and independent static reviews complete; not published.

## Scope and interface

Provide `arca create --format cpio|tar -C DIRECTORY -o ARCHIVE`, initially for
the supported 64-bit Linux/Trixie environment. Archive the contents of one
directory recursively in bytewise lexical order, omitting the root itself.
Preserve source permission bits, numeric owners and second-resolution mtime;
`--uid`, `--gid` and `--mtime` override those values. `SOURCE_DATE_EPOCH` is the
mtime fallback when no explicit override is given. Require decimal integers.

Preserve symbolic links without following them and group regular-file
hardlinks by device/inode. CPIO uses the selected archive members' link count
and emits data once in the last member; TAR links to the first lexical name.
Include directories, regular files, symlinks, FIFOs and device metadata.
Reject sockets and unsupported nodes with contextual diagnostics.

Create uncompressed archives. Listing, extraction, compression, selection
manifests and additional platforms remain future work.

## Ownership and boundaries

Keep the writers and library GPR unchanged. The CLI owns argument policy,
filesystem discovery and adapter state. GNAT's existing path normalization
is reused. A small CLI-only C wrapper converts lstat metadata to a fixed-width
record. Simple system calls use direct Ada bindings, and signal handling uses
an Ada protected object. Library APIs have no dependency on this OS boundary.

Inventory inputs before creating a private staging directory in the output
parent. Exclude the destination when it is inside the input tree. Publish
only a successfully closed archive; default publication must not replace an
existing path. `--force` explicitly allows atomic replacement of a regular
file or symlink. Keep the old destination on failures before publication.
Controlled staging ownership removes temporary output on normal errors.

Directory traversal and hardlink maps belong to one CLI invocation and run
sequentially. Input trees must remain stable; recheck entry identity and
regular-file size/mtime before emission, while avoiding false changes caused
by staging in an inventoried output directory. This is not a hostile-tree
filesystem sandbox. Cancellation is observed between filesystem/entry phases;
the library's synchronous file copy has no cancellation callback.

## Steps and acceptance

1. Implement the command, metadata bridge, deterministic inventory and writer
   adapters. Build and install the executable separately from library APIs.
2. Add CLI integration checks for both formats: contents, metadata, source
   hardlinks, symlinks, reproducibility, nested output exclusion, errors and
   staging cleanup. Keep existing unit and independent writer checks.
3. Extend production coverage to CLI Ada/C bodies, retaining fresh-source
   coverage-first execution. Verify installed CLI and library consumers.
4. Update help, guides, changelog and indexed change record. Complete Ada MCP
   analysis, author review and relevant independent static passes before
   handing the local topic to external review.

No Abuild checkout or credentials are required by the CLI or its normal tests.

## Progress on 2026-10-22

Steps 1 and 2 are implemented locally: the warning-free command builds and
installs independently of the public library API. Integration checks cover
both writers, numeric metadata, independent decoders and external readers,
selected hardlinks, symlinks, FIFOs, deterministic output and error cleanup.
Phase-controlled checks pin cancellation, late destination creation and
changed input. GNAT's raw directory-name iterator is used because the higher
level Ada.Directories search rejects dangling symlinks and special nodes
while fetching modification times. The CLI takes their metadata with lstat.

Step 3 is implemented: coverage checks the complete Ada/C body inventory and
normal installation checks execute the installed CLI for both formats. A
fresh source copy passes coverage first and then the complete normal target
in a rootless, network-disabled Trixie container with no Abuild mount.

## Final review on 2026-10-22

Step 4 is complete: help, CLI/developer guides, changelog, indexes and the
[change record](../change-records/archive-cli.md) describe the implementation
and validation limits. Ada MCP analysis is complete. The source finder found
no blocking, fix-before-PR or follow-up issues. The validation finder confirmed
two author-found test fixture issues; their committed corrections pass its
targeted re-review, with no remaining findings. Final author review is
complete. The final source/test stand again passes fresh-source coverage first
and the full normal check without network access or an Abuild mount.

## C boundary revision requested on 2026-10-22

The owner requested Ada signal handling, direct bindings for simple system
calls and C only for the lstat metadata wrapper. Keep the existing CLI and
publication contracts. Use the protected Ada interrupt-handler pattern
already present in Abuild, implemented independently for this CLI. Bind
readlink, mkdtemp, rename and renameat2 directly; capture errno before building
diagnostics. Keep target-specific stat layout and file-type/device macros
inside the remaining C wrapper.

Extend the existing cancellation checks to SIGINT as well as SIGTERM, retain
late-destination/error cleanup assertions and run normal checks plus complete
coverage in the supported Trixie environment. Refresh Ada MCP, documentation
and final review after the implementation is stable.

The expanded signal/staging tests pass against both the previous C-backed
executable and the new Ada-backed executable. They are committed before the
adapter change to pin its existing observable behavior. The new adapter
compiles warning-free; CLI checks, complete normal checks and production
coverage pass.

## C boundary revision completed on 2026-10-22

The C object exports only arca_lstat. Both independent static follow-up passes
report no blocking, fix-before-PR or follow-up findings. Final author review
checked direct ABI signatures/constants, errno capture, initialized readlink
slices, protected callback lifetime and staging ownership, plus retained
format/cleanup contracts and documentation/source/commit hygiene.

The final source/test stand also passes coverage first and the full normal
check in a fresh, rootless Trixie copy without network or Abuild access. The
production-body inventory remains complete. Ada MCP reports a complete CLI
project/index and complete empty diagnostics for the changed filesystem body;
semantic navigation confirms the protected handler and libc binding boundary.

## Rebase and source layout on 2026-10-22

The owner accepted PR #6 without waiting further for the stalled external
Codex review. The CLI topic is rebased onto that accepted main revision.
Conflicts were confined to the changelog and plan index; both CLI and library
entries are retained. CLI sources and tests were byte-identical immediately
after rebase, and library sources, compiler settings and unit tests match
accepted main.

The owner also requested the established Abuild readability conventions in
the CLI. Declaration groups, nested blocks, validation/emission phases and
case alternatives now have explicit whitespace separation; multiline
parameters and related declarations are aligned. A lexical comparison of
every CLI Ada unit with its pre-rebase counterpart confirms identical tokens,
including strings and character literals. This changes layout only, with the
same subprogram contracts, ABI, ordering and object lifetime. Source copies
contain only tracked files; editor artifacts are excluded from commits.

The complete normal check passes in the rootless AMD64 Trixie environment,
including the accepted finalizer-failure cases, CLI, format, reader and
installation checks. Ada MCP's exact CLI project/index and all CLI Ada file
diagnostics are complete and empty. Fresh-source coverage and final static
parity review follow on this rebased, reformatted state.

## Rebase validation completed on 2026-10-22

Fresh tracked sources pass complete coverage first and then the normal check
in a rootless AMD64 Trixie container with network disabled and no Abuild mount.
The unchanged production-body inventory has executed lines for every entry.
Both independent static parity passes confirm the retained implementation,
tests and accepted library base; no Ada layout issue was found. The source
pass identified a change-record index ordering error, corrected before
delivery. Final author review confirms token parity, contracts, cleanup and
state ownership, unchanged test sensitivity/scaling, documentation links,
commit-message rules and a clean tracked worktree.

## Review corrections requested on 2026-10-22

Before publishing the CLI PR, preserve original I/O diagnostics, discriminate
directory-read errors from EOF, make staging finalization nonthrowing and
enable the library's additional runtime checks in the CLI project. Retain
the Ada/direct-binding boundary and unchanged public writer APIs.

When no-replace rename is unsupported, publish the closed regular staging
file using a hard link on the same filesystem. The successful link is the
publication point; removing its private staging name is best-effort cleanup.
If NFS reports an ambiguous link failure, accept success only when lstat
proves that the destination is the same regular inode as the staging file.
Other errors retain the no-clobber contract and contextual diagnostic.

Add independent, test-only syscall fault injection for directory-read errors,
unsupported rename, late destinations, ambiguous/failed links, output write
failure and staging cleanup failure. Test original-exception preservation
and success after publication despite cleanup failure. No production test
hooks or additional C wrappers are introduced.

Close the source timestamp/size, timestamp override rescue, forced FIFO,
global full-path ordering and special permission-bit test gaps. Keep the
existing byte-reproducibility checks. Run old/new sensitivity checks, full
normal tests and coverage in rootless Trixie, then refresh Ada MCP and static
review. Signal re-raising/SIGHUP, install-manifest naming and cosmetic root
output diagnostics remain separate follow-ups; this step changes no CLI
syntax or metadata normalization policy.

## Review corrections implemented on 2026-10-22

The requested error handling, publication fallback and CLI checking profile
are implemented. Expanded CLI regressions pass. Against a freshly built
pre-correction executable, directory EIO incorrectly succeeds, permission
and ENOSPC causes disappear, unsupported rename fails publication and cleanup
faults replace the caller error or turn published success into failure.
The corrected executable passes the same regression assertions.

Fresh-source complete coverage followed by the normal check passes in a
rootless AMD64 Trixie container with network disabled and no Abuild mount.
Every production body reports executed lines; the test-only preload library
does not change the production inventory. Compiled CLI artifacts confirm
all three added switches. Public writer sources and the production lstat
wrapper remain byte-identical. Final author review is complete; independent
static review follows on the committed correction.

## Review corrections completed on 2026-10-22

Both independent static passes report no blocking, fix-before-PR or follow-up
findings in the correction. They confirm errno/diagnostic ordering, fallback
publication and inode verification, nonthrowing cleanup, sensitive syscall
faults and the previously missing metadata/ordering/mode/FIFO assertions.
Final author review confirms that the committed code matches the validated
fresh sources and that documentation, source style, commit rules and worktree
hygiene are complete. The CLI executable in the working checkout is rebuilt
from the same final code. The topic remains local and unpublished.

## Final option coverage on 2026-10-22

The external read-only review accepted the correction and noted three small
remaining test gaps. CLI fixtures now create both formats with relative
basenames and relative parent directories, using both short and long
directory/output options. They independently decode and check the archive.
The epoch/precedence case also rejects malformed, negative and empty
SOURCE_DATE_EPOCH without an explicit mtime, requiring exit 2, a named
diagnostic and no output or staging. The CLI guide's paragraph wrapping is
corrected. This step changes tests and documentation only.

The expanded CLI suite, complete coverage and full normal check pass in the
rootless AMD64 Trixie environment. All production bodies retain executed
coverage; build recipes and production sources are unchanged. Author review
checked the independent output assertions, environment-error controls,
fixture cleanup, documentation links, commit hygiene and final worktree.

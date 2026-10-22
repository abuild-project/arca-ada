# Archive creation CLI

Status: Implementation in progress, requested on 2026-10-22 after PR #5.

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
is reused. Its public filesystem interfaces do not supply lstat's complete
numeric metadata and readlink targets, so a small CLI-only POSIX C bridge
provides these plus private staging and atomic publication.

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

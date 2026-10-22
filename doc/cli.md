# Archive creation command

`arca` creates uncompressed CPIO `newc` and TAR archives from a directory.
The initial CLI targets 64-bit Linux. The reference build and test environment
is Debian Trixie on AMD64; other operating systems are not supported yet.
The underlying Ada library has its own [CPIO](cpio.md) and [TAR](tar.md) APIs.

Build with `make -j8 all NUM_CPUS=8` in the
[development environment](development.md). The executable is `cli/bin/arca`;
`make install PREFIX=/absolute/prefix` installs it as `<prefix>/bin/arca`
alongside the library and its licence notices.

```sh
cli/bin/arca create --format cpio -C rootfs -o rootfs.cpio
cli/bin/arca create --format tar -C contents -o contents.tar \
    --uid 0 --gid 0 --mtime 0
cli/bin/arca --help
```

## Options and metadata

| Option | Meaning |
| --- | --- |
| `--format cpio\|tar` | Required archive format |
| `-C DIR`, `--directory DIR` | Input directory, default `.` |
| `-o FILE`, `--output FILE` | Required output file; `-` is rejected |
| `--uid N`, `--gid N` | Override numeric owner IDs |
| `--mtime SECONDS` | Override all entry times with UNIX epoch seconds |
| `--force` | Allow replacement of an existing regular file or symlink |
| `--help`, `-h` | Display help |
| `--version` | Display the development version |

Value options accept either a separate argument or `=VALUE`. Repeating an
option is an error. Numeric options accept ASCII decimal digits only, without
signs, underscores or Ada based literals. Explicit `--mtime` takes precedence
over `SOURCE_DATE_EPOCH`. If neither is set, each source entry supplies its
mtime, truncated to whole seconds. Source permission bits and numeric UID/GID
are retained unless overridden. No owner-name lookup is performed.

| Field | CPIO `newc` | TAR |
| --- | --- | --- |
| UID, GID | 0 to 4,294,967,295 | 0 to 2,097,151 |
| mtime, regular-file size | 0 to 4,294,967,295 | 0 to 8,589,934,591 |
| Device major/minor | 0 to 4,294,967,295 | 0 to 2,097,151 |

Metadata outside the selected format's limits is rejected. An override can
make an otherwise unrepresentable source owner or timestamp usable. CPIO
cannot represent an entry named exactly `TRAILER!!!` at the archive root,
because readers treat it as the end marker; that input is rejected. A nested
name such as `dir/TRAILER!!!` is unaffected.

## Input selection and reproducibility

The command includes all descendants, including dotfiles and empty
directories, but omits the input root itself. Names are relative, ordered by
their raw filename bytes; no locale-dependent ordering or Unicode conversion
is applied. Regular files, directories, symbolic links, FIFOs and device-node
metadata are supported. Sockets and unknown node types are rejected.
Symlinks, including dangling links and links to directories, retain their
target text and are not traversed in a stable source tree.

Regular-file hardlinks are grouped by filesystem device and inode. Only names
inside the selected tree count: an additional physical hardlink outside it
does not increase the archive link count. CPIO stores the payload once at the
last lexical member. TAR stores it at the first member and makes subsequent
members hardlink to that name. Recreating an equivalent input tree with
different physical inode numbers or creation order produces the same archive
bytes when contents and recorded metadata are identical.

Input trees must remain stable during creation. The command inventories the
tree, then rechecks identity and metadata before emitting entries. The library
also checks payload copy sizes. These checks detect ordinary source changes;
they are not a filesystem sandbox against concurrent adversarial changes.
Directory timestamps are captured during inventory and are not rechecked,
because output staging may change an input directory's timestamp.

## Output and failure behavior

The output's parent directory must already exist. A destination inside the
input tree is excluded by its resolved parent and basename. This excludes
only the specified destination, not other archives from previous runs.
The command inventories inputs before making a private mode-0700 staging
directory in the output parent, keeping the staging file on the same
filesystem as the final destination.

Only a successfully closed archive is published. Default publication uses
Linux `renameat2(RENAME_NOREPLACE)`, so even a destination created after the
initial check is preserved. `--force` uses atomic rename to replace the
destination; for an existing symlink it replaces the link itself and leaves
its target alone. Existing directories and special nodes are rejected. Keep
the destination stable when using `--force`.

Errors before publication preserve the previous output; normal unwinding
removes staging. SIGINT and SIGTERM request controlled cleanup at the next
filesystem or entry boundary;
a synchronous payload copy may finish before the request is observed.
SIGKILL, a process crash or power loss cannot guarantee cleanup. Atomic
publication does not promise durable storage after a power failure.

Successful commands return 0. Argument/environment errors return 2;
filesystem or writer errors return 1. A handled SIGINT returns 130 and
SIGTERM returns 143. Diagnostics go to standard error. Compression, listing,
extraction, streaming to stdout and selection manifests are future work.

## Validation

`make check` runs CLI integration tests in addition to the Ahven and native
format suites. They inspect raw output with independent decoders and extract
it with GNU cpio/tar and libarchive's bsdtar. Fixtures cover metadata limits,
source hardlinks, Unicode names, dangling and directory symlinks, FIFOs,
reproducibility, empty trees, installed execution and parallel processes.
Phase-controlled tests exercise SIGINT/SIGTERM cancellation, changed input and
a destination created just before publication. Failure tests verify old output
and staging cleanup, including an unwritable output parent. Device emission
is covered by native writer tests; creating device
fixtures through the CLI is not part of the rootless test suite.

`make coverage` instruments both Ada and C CLI bodies. The inventory gate
requires executed lines for every production body and does not claim complete
branch coverage. Normal tests require only this repository and its development
image, with no Abuild checkout or credentials.

# Archive creation command

`arca` creates uncompressed CPIO `newc` and TAR archives from a directory.
The initial CLI targets 64-bit Linux. The reference build and test environment
is Debian Trixie on AMD64; other operating systems are not supported yet.
The underlying Ada library has its own [CPIO](cpio.md) and [TAR](tar.md) APIs.

Build with `make -j8 all NUM_CPUS=8` in the
[development environment](development.md). The executable is `cli/bin/arca`;
`make install PREFIX=/absolute/prefix` installs it as `<prefix>/bin/arca`
alongside the library and its licence notices. Its installation manifest is
`arca-cli`; `make uninstall PREFIX=/absolute/prefix` removes the CLI and
library using their manifests while preserving unrelated prefix files.

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
| `--version` | Print the project version as `arca VERSION` |

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

The output must name a file. `.`, `..`, `/`, paths ending in `/.` or `/..`,
and a trailing slash are argument errors (exit 2), rejected before filesystem
access. A missing output parent or one that is not a directory remains a
filesystem error (exit 1), with a diagnostic identifying the output parent.

The output's parent directory must already exist. A destination inside the
input tree is excluded by its resolved parent and basename. This excludes
only the specified destination, not other archives from previous runs.
The command inventories inputs before requesting a mode-0700 staging
directory in the output parent, keeping the staging file on the same
filesystem as the final destination. It retains open references to the
parent and staging directory. It reserves the archive name exclusively
before the writer opens it. The CLI requires effective ownership and rejects
group or other write permission, while allowing read/search bits and inherited
setgid. On mounts that report 0755 for new directories, another user may read
an unfinished archive when the file mode also permits it. Filesystems with
synthetic modes or server-side access rules need separately controlled
access; reported mode bits alone do not establish protection from remote
writers. The CLI requires
Linux procfs at `/proc/self/fd` for the writer's descriptor-backed path. The
public library writers have no procfs requirement.
If that descriptor path is absent, the CLI reports the procfs requirement
before creating staging. Other staging-creation errors retain their own
filesystem cause.

Only a successfully closed archive is published. Default publication uses
Linux `renameat2(RENAME_NOREPLACE)`, so even a destination created after the
initial check is preserved. If the kernel or filesystem does not support
that operation, a same-filesystem hard link publishes the closed staging
file without overwriting another destination. The staging name is removed
during bounded, nonrecursive cleanup. The filesystem must
support no-replace rename or same-filesystem hard links. An ambiguous NFS
link error is accepted as success only when the destination has the same
regular-file identity as the staging file.
`--force` uses atomic rename to replace the destination; for an existing
symlink it replaces the link itself and leaves its target alone. Existing
directories and special nodes are rejected. Keep the destination stable
when using `--force`.

Errors before publication preserve the previous output. Directory-read
errors abort inventory instead of being treated as its end. Entry diagnostics
retain the underlying exception message, or its name when no message exists.
CLI-generated diagnostics retain their complete context beyond GNAT's bounded
exception-message length. Output escapes bytes below 0x20 and DEL as `\xNN`,
and backslash as `\\`, so a filename cannot split a diagnostic into lines or
be confused with an escape. Other bytes, source names and archive names are
unchanged.

Normal unwinding attempts staging removal. Cleanup is best effort: failure
can leave a staging directory, but never masks an earlier error or
turns successful publication into failure.
If ownership or mode verification fails before the staging object can be
trusted, an empty staging directory can remain. Remove that entry only after
checking it belongs to the failed run.
SIGHUP, SIGINT and SIGTERM request cleanup at the next filesystem or entry
boundary; a synchronous payload copy may finish before the request is observed.
SIGKILL, a process crash or power loss cannot guarantee cleanup. Atomic
publication does not promise durable storage after a power failure.

Successful commands return 0. Argument/environment errors return 2;
filesystem or writer errors return 1. Handled SIGHUP, SIGINT and SIGTERM return
129, 130 and 143 respectively. Help lists the options, `=VALUE` form and these
exit statuses. Diagnostics go to standard error. Compression, listing,
extraction, streaming to stdout and selection manifests are future work.

## Validation

`make check` runs CLI integration tests in addition to the Ahven and native
format suites. They inspect raw output with independent decoders and extract
it with GNU cpio/tar and libarchive's bsdtar. Fixtures cover metadata limits,
source hardlinks, Unicode names, dangling and directory symlinks, FIFOs,
reproducibility, empty trees, installed execution and parallel processes.
Phase-controlled tests exercise SIGHUP/SIGINT/SIGTERM, changed input and
a destination created just before publication. A test-only child barrier
confirms inventory completion and holds emission until explicitly released.
Cancellation cases also confirm completed signal handling before release.
Failure tests verify old output and staging cleanup, including an unwritable
output parent. Native writer tests cover device emission; creating device
fixtures through the CLI is not part of the rootless test suite.

Regression fixtures pin source timestamp and sparse-file size boundaries,
timestamp override rescue, forced FIFO rejection, full-path ordering and
special permission bits. A child-only preload library injects directory-read,
write, publication and cleanup errors, including unsupported rename and
ambiguous NFS-style link replies. These tests exercise local syscall behavior;
they do not claim an integration run against an NFS server.
Additional controls require complete long-path diagnostics, display escaping
without changing archive names, early output-syntax rejection and help that
contains every documented option and exit status. Exported bridge constants
must match an independent program compiled against the target's C headers.

`make coverage` instruments both Ada and C CLI bodies. The inventory gate
requires executed lines for every production body and does not claim complete
branch coverage. Normal tests require only this repository and its development
image, with no Abuild checkout or credentials.

CI also runs a dedicated cross-UID test. Its coordinator starts as container
root only to launch the archive command and a competing process as distinct
unprivileged users without supplementary groups. It checks staging creation,
opening, publication, parent renaming, failure and handled-signal cleanup
for both formats and publication modes. Ordinary checks remain rootless.

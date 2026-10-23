# CPIO writer

`Arca.CPIO` emits uncompressed ASCII `newc` archives. Its implementation is
derived from the Abuild writer under
[GPL-2.0-or-later](licensing.md). Public operation names and
metadata arguments retain the predecessor's API without Abuild dependencies.

## Format and inputs

The normative reference is the Linux kernel's
[initramfs buffer format](https://www.kernel.org/doc/html/latest/driver-api/early-userspace/buffer-format.html).
Output uses `070701`, 110-byte headers, eight-digit uppercase hexadecimal
numeric fields, NUL-terminated names, four-byte entry padding and a `TRAILER!!!`
record. Completed output uses the minimum zero padding to a 512-byte boundary.
These spelling and padding choices retain the predecessor's output profile.
Supported entries are regular files, directories, symbolic links, hardlinks,
FIFOs and character and block devices. Device entries do not create local
device nodes.

Callers provide archive paths, permission bits, UID/GID values and timestamps.
The supported 64-bit Trixie build accepts UNIX timestamps from zero through
`2**32 - 1` seconds. Regular-file and symlink payload fields have the same
unsigned 32-bit size limit. The API does not compress, walk directories,
choose wall-clock metadata or sanitize paths. Callers supply valid archive
paths and regular source files.

For hardlinks, allocate one inode with `CPIO_Get_Next_Inode` on an open
writer. Emit preceding names with `CPIO_Make_Link`, then the last name and
payload with `CPIO_Make_File`. Use the same inode, link count and metadata
for all members. The initial inode is 721; file-device fields retain the
predecessor's major 3 and minor 1.

## Example and lifecycle

```ada
with Ada.Calendar.Formatting;
with Arca.CPIO;

procedure Example is
   use Arca.CPIO;
   Archive : CPIO_Archive_Type;
begin
   CPIO_Create (Archive, "output.cpio");
   CPIO_Make_File
     (Archive, "input.dat", "input.dat", 8#644#, 0, 0, 1,
      CPIO_Get_Next_Inode (Archive),
      Ada.Calendar.Formatting.Time_Of
        (2000, 1, 1, Seconds => 0.0, Time_Zone => 0));
   CPIO_Close (Archive);
end Example;
```

Create creates or truncates the output path. Close completes the archive and
releases its handle. Creating again while open raises
`Ada.IO_Exceptions.Status_Error` before changing the active writer's state.
Independent instances own separate streams, offsets and inode sequences;
synchronize calls that share an instance.

An open writer leaving scope normally or during exception unwinding attempts
to close and remove its unfinished output without inventing a trailer. This
ownership is an intentional addition to the predecessor's low-level API,
whose outer Abuild layer owns cleanup. If stream deletion fails, cleanup still
attempts Close when the stream is open. In particular, GNAT rejects deletion
of nonregular outputs before closing; the fallback closes that stream without
separately unlinking its pathname.

Implicit cleanup is best effort and does not propagate failures or replace
the caller's original exception. Filesystem failure can leave partial output;
closure can also fail. Explicit Close remains the operation that completes
the archive and reports I/O errors. Scope cleanup does not promise recovery
from process crashes or interruption inside active I/O.

Missing or oversized sources, invalid timestamps and unopened operations
retain their typed exceptions. Validation failures before emission leave the
writer usable, though rejected metadata can consume an inode. A copy or
output I/O failure can have emitted partial data: abandon that writer's scope
so finalization attempts to discard the output.

## Validation

`make -j8 check NUM_CPUS=8` runs independent raw-layout and payload checks,
GNU cpio/libarchive listing and extraction, copy error checks, numeric
boundaries, reproducibility, lifecycle and parallel writers on 128 KiB task
stacks. Descriptor checks use the Linux reference environment. Negative
controls corrupt magic, padding and payload bytes and truncate an archive.

`make -j8 coverage NUM_CPUS=8` instruments separate test objects, requires
every production body to be inventoried and executed, and writes line counts
to `build/coverage.json`. This does not imply exhaustive branch coverage or
complete I/O fault injection.

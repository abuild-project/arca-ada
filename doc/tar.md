# TAR writer

`Arca.TAR` writes the native Abuild TAR profile independently of Abuild types,
configuration, logging and scheduling. It retains Abuild's
[GPL-2.0-or-later licence](licensing.md). The public interface follows the
[version and compatibility policy](../README.md#version-and-compatibility).
Compression and Abuild transformation adapters are separate consumers.

## Use

Import `arca.gpr` and use the public child package:

```ada
with Ada.Calendar.Formatting;
with Arca.TAR;
pragma Elaborate_All (Arca.TAR);

procedure Example is
   Archive : Arca.TAR.TAR_Archive_Type;
begin
   Arca.TAR.TAR_Create (Archive, "output.tar");
   Arca.TAR.TAR_Make_File
     (Item   => Archive,
      Name   => "payload.bin",
      Source => "input.bin",
      Mode   => 8#644#,
      UID    => 0,
      GID    => 0,
      MTime  => Ada.Calendar.Formatting.Time_Of
        (2000, 1, 1, Seconds => 0.0, Time_Zone => 0));
   Arca.TAR.TAR_Close (Archive);
end Example;
```

The metadata arguments are caller-supplied. Fixed UTC times make output
independent of the host's timezone and source filesystem timestamps.
The regular-file operation copies the source bytes and verifies their size.
Other operations emit hardlinks, symlinks, directories, FIFOs and device entries.

## Retained format profile

- A member has one 512-byte POSIX ustar header and any regular-file payload,
  padded to 512 bytes with NULs. Close emits exactly two all-zero blocks.
- Headers use `ustar` plus NUL and version `00`. Numeric fields are zero-padded
  ASCII octal with NUL terminators. The header checksum treats its own field
  as spaces and is stored as six octal digits, NUL and space. It covers the
  complete header, including unsigned non-ASCII bytes; payloads are separate.
- The name and link fields each hold 100 bytes; the prefix holds 155 bytes.
  A long path uses the rightmost valid prefix/name split before falling back
  to GNU LongName. A long link target uses GNU LongLink. Combined records are
  emitted in LongName, LongLink, actual-entry order. Synthetic records use
  `././@LongLink`, mode `0644`, owner/group zero and the UTC UNIX epoch.
- Mode is masked to `07777`; user/group names remain empty. UID, GID and device
  numbers range from zero through `2**21 - 1`. Regular-file size and UNIX mtime
  range from zero through `2**33 - 1`. No PAX or base-256 numeric encoding is
  emitted. File sizes above 8 GiB - 1 byte and unsupported metadata fail.
- Names and targets are Ada byte strings supplied by the caller. Supply
  nonempty member names without embedded NULs; path policy belongs to the
  caller. A directory gains a trailing slash if absent; existing trailing
  separators are retained. Positive nondefault string bounds are supported.

The normative references are the
[POSIX ustar description](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/pax.html#tag_20_92_16_02)
and the [GNU format description](https://www.gnu.org/software/tar/manual/html_node/Standard.html).
Arca retains the predecessor's specific ustar/GNU combination; it does not
promise byte identity with every GNU tar output profile.

## Ownership and failures

`TAR_Archive_Type` is tagged limited private. Explicit Initialize and Finalize
calls, conversions to the controlled parent and overrides of those lifecycle
hooks are outside the public API. Ordinary writer calls and use as a limited
record component remain supported; implicit cleanup is unchanged.

Each instance owns its output file. Close completes the archive and retains
it. Leaving scope without Close attempts to remove unfinished output, including
exception unwinding and owner-task termination between operations. Independent
instances must use distinct output paths; synchronize shared calls.
Calling Create on an open instance raises `Ada.IO_Exceptions.Status_Error`
with `TAR_Create called on an open archive` and retains the existing state.

Implicit cleanup never propagates a cleanup failure. If deletion fails before
closing, it still attempts to close the stream; a nonregular output rejected
by GNAT's Delete is closed without separately unlinking its pathname. A failed
unlink may already have closed the stream. Cleanup preserves the caller's
original exception and can leave partial output if filesystem operations
fail. Explicit Close remains the completing operation that reports I/O errors.

Unopened operations raise `TAR_Not_Initialized`; missing sources raise
`File_Not_Found`, oversized payloads raise `File_Too_Big`, a shortened source
can raise `File_Read_Error`, and unrepresentable numeric metadata raises
`Unsupported_Metadata`. Failures while converting a supplied timestamp,
including a UTC time in year 2300, use that metadata exception too.
Underlying stream errors can propagate. Format-specific exception identities
are retained; compiler-generated locations refer to the
renamed source. Adds are not transactional: GNU metadata or payload fragments
may already have been written when an operation fails. Leave scope to discard
that instance and start a new archive after a failed add or close.

The cleanup checks cover language-level unwinding and task aborts between
operations. They do not establish safe interruption inside active I/O or
exhaustive filesystem-failure handling.

## Validation

`make -j8 check NUM_CPUS=8` runs both writer suites and an isolated installed
consumer which creates and closes CPIO and TAR outputs. TAR tests use an
independent decoder, GNU tar and libarchive, exact field/payload assertions,
corruption controls, parallel instances and lifecycle checks.

The [historical GNU tar fixture](../tests/fixtures/tar/README.md) is retained
byte for byte with its original GNU tar 1.34 producer record. Its standardized
ustar subset includes device headers without requiring test-time device-node
creation. GNU metadata is checked separately by raw records and readers.

The maximum-size header probe uses a sparse source and a 512-byte process
output limit, retaining a descriptor to inspect the header after failure.
It verifies acceptance of `2**33 - 1` without copying 8 GiB. It does not claim
successful completion of an archive containing that entire payload.

`make -j8 coverage NUM_CPUS=8` runs both instrumented suites, requires every
production body in the inventory and reports executed lines. It can run first
from a fresh source checkout. The output-limited probe redirects its own
profiling artifacts into private scratch space.

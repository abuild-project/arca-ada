# VFAT format and reference inventory

This topic establishes the evidence base for a native VFAT writer without
introducing a writer, public API or build dependency. Microsoft FAT format
rules, a fixed specification file, current Abuild behavior, historical
native PoC revisions and two distinct external producer profiles are recorded
in `doc/plans/vfat-format-inventory.md`.

The format authority is Microsoft's FAT32 File System Specification version
1.03. Its official downloaded bytes are identified by SHA-256. The reference
environment is Debian 13.6 Trixie/AMD64 with exact `dosfstools` and `mtools`
package versions and executable digests. The existing Abuild adapter invokes
`mkdosfs` for an empty image, `mmd` and `mcopy` to populate it, and `fatlabel`
after population. The maintained consumer selects a wrapper that translates the
`mkdosfs` call to `mformat` with fixed geometry. Its source digest and command
translation are recorded without importing the wrapper into Arca.

Controlled empty images at 9 MiB and 520 MiB make the difference concrete.
At 9 MiB the wrapper-equivalent command emits FAT12 while direct Trixie
`mkdosfs -F 16` emits FAT16. At 520 MiB both emit FAT32 but use different FAT
lengths and total-sector layouts. All four pass `fsck.fat -vn`; both 9 MiB
images are readable with `mdir`. Fixed serials and environment settings made
two independent generations byte-identical for each profile. Without a fixed
serial, two isolated wrapper runs in the Trixie tool profile differed despite
the same `SOURCE_DATE_EPOCH`. Abuild's current populated-image
reproducibility test uses the system `mkdosfs` and passed across a time and
time-zone change. The wrapper observation is not a product-build result.
The raw images remain local, generated evidence; no golden fixture or byte
compatibility promise is added by this topic.

The accepted Abuild tree's focused VFAT transformation tests passed in the
rootless Trixie container. They exercise the direct dosfstools path, not the
maintained wrapper. The historical native PoC and later hardening are mapped
by exact source revisions. No old implementation file was copied.

Decision (2026-11-05): Target the established wrapper-compatible layout for
valid inputs because existing consumers used it. Departures need a concrete
format, reader, safety or reproducibility reason and a targeted test. The
PoC's raw layout assertions for FAT12, FAT16 and FAT32 agree with selected
fields of independently generated mtools images at three recorded sizes.
Complete byte parity and populated-image parity remain unproven; the direct
Trixie dosfstools profile is a separate comparison, not the native default.

The README links the inventory as the next writer step; the plan and record
indexes are sorted. The development guide now describes Abuild as an existing
consumer while retaining the independent project boundary. The CPIO, TAR and
CLI guides remain unchanged because there is no new library contract to
document. The changelog has no entry because users receive no new behavior.
A committed golden fixture, populated-image comparisons, executable VFAT
checks and a public API require separate decisions and work. The site built
in the supported Arca container; relative links were checked separately.
No Arca compiler or runtime tests were run for this documentation-only topic.

Co-Authored-By: GPT-6 <noreply@openai.com>

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
Those four empty images remain local observations, not golden fixtures. The
bounded populated FAT12 golden is described below.

The accepted Abuild tree's focused VFAT transformation tests passed in the
rootless Trixie container. They exercise the direct dosfstools path, not the
maintained wrapper. The historical native PoC and later hardening are mapped
by exact source revisions. No old implementation file was copied.

Decision (2026-11-05): Target the established wrapper-compatible layout for
valid inputs because existing consumers used it. Departures need a concrete
format, reader, safety or reproducibility reason and a targeted test. The
PoC's raw layout assertions for FAT12, FAT16 and FAT32 agree with selected
fields of independently generated mtools images at three recorded sizes.
Full native-to-reference image parity remains unproven; the direct Trixie
dosfstools profile is a separate comparison, not the native default.

Decision (2026-11-05): Use the pinned Trixie mtools profile provisionally for
populated references because the actual consumer tool identity is not yet
available. Fixed input bytes, mtimes, serial and UTC environment produced
byte-identical FAT12, FAT16 and FAT32 images across three runs per size.
`fsck.fat`, `mdir` and `mtype` accepted the images and recovered the selected
payloads. An independent raw decoder checked BPB fields, equal FAT copies,
the late label, long-name chains and a three-cluster payload; a corrupted
second FAT failed its equality check. A different time zone changed raw
directory timestamp bytes in this isolated mtools profile. The current Abuild
reproducibility test and the actual consumer build are separate evidence.
These observations alone did not make the provisional outputs golden fixtures.

Decision (2026-11-05): Accept the pinned Trixie producer profile as the
initial VFAT reference because the maintained consumer mainline uses Trixie.
The wrapper-compatible layout remains the target. Older Debian and Red Hat
buildenv flavors need separate evidence and are not part of this validation.
The earlier provisional environment gate is resolved by this scope choice;
a bounded fixture can now be retained with guarded generation. Native-writer
parity remains a separate future check.

Decision (2026-11-05): Retain one bzip2-compressed FAT12 reference for the
wrapper-compatible 10,272 KiB subset. It contains a late label, short and
long names with colliding aliases, one directory and a multi-cluster file.
The generator rejects wrong package versions, executable hashes and changed
input bytes before writing. The committed raw and compressed hashes are
recorded with the producer command in the fixture README. Normal `make check`
reads the committed image without regenerating it or checking producer
identities. The checker expands the image sparsely and hashes its full logical
contents. An independent decoder, `fsck.fat`, `mdir` and `mtype` validate
layout and content; private FAT and LFN mutations fail their respective
guards. A separate pinned-environment check proves that forged package and
binary identities fail the producer guard. The complete check target passed
in Trixie. FAT16/FAT32 full-image parity,
native-writer parity and product comparisons are outside this fixture.

A later product-image comparison is required before the Abuild backend
switch. It will run the wrapper-backed and native paths on the same locked
inputs in Trixie, then check independent readers, raw layout and the
deliberately byte-compatible subset. This is a future validation gate, not
evidence claimed by this inventory topic.

The README links the inventory as the next writer step; the plan and record
indexes are sorted. The development guide now describes Abuild as an existing
consumer while retaining the independent project boundary. The CPIO, TAR and
CLI guides remain unchanged because there is no new library contract to
document. The changelog has no entry because users receive no new behavior.
Additional golden data, broader populated-image comparisons and the public
`Arca.VFAT` API require separate decisions and work. The documentation site
built in the supported Arca container; relative links were checked
separately. The full Arca check ran with the new test-only tools. No native
VFAT writer or Abuild adapter change is part of this topic.

Co-Authored-By: GPT-6 <noreply@openai.com>

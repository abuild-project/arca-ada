# VFAT format and reference inventory

This topic establishes the format and compatibility references for a native
VFAT writer. It adds no writer, public API or Abuild dependency. The
`doc/plans/vfat-format-inventory.md` records the Microsoft FAT specification,
exact reference inputs, observed producer profiles and later validation
gates.

The format authority is Microsoft's FAT32 File System Specification version
1.03, identified by its downloaded SHA-256. The reference producer is
AMD64 Debian 13.6 Trixie with pinned `mtools 4.0.48-1`,
`dosfstools 4.2-1.2` and `bzip2 1.0.8-6` packages, executable digests and
`/etc/mtools.conf` bytes. Other Debian and Red Hat flavors require their own
evidence.

The accepted Abuild adapter invokes `mkdosfs` to create an empty image,
`mmd` and `mcopy` to populate it, and `fatlabel` after population. The
maintained consumer build places a private `mkdosfs` compatibility wrapper
ahead of the system executable on `PATH`. The inspected wrapper source has
SHA-256 `4a627b68621c39d68cafdf4d88d279719cc27023a688e533f96b74ff83e667d0`.
For the adapter's arguments it invokes `mformat -C -T (2 * size_in_KiB)
-i image -h 64 -s 32 -H 0 ::`. It maps `-F 32` to mtools `-F` and does not
force FAT16 when the adapter requests `-F 16`.

Controlled empty images show why the producer distinction matters. At
9,216 KiB the wrapper-equivalent profile emits FAT12, while direct Trixie
`mkdosfs -F 16` emits FAT16. At 520 MiB both emit FAT32 but differ in FAT
length and total-sector layout. All pass `fsck.fat -vn`; fixed serials make
repeated producer outputs byte-identical. The direct dosfstools path passes
Abuild's populated-image `SOURCE_DATE_EPOCH` test. That result does not
establish wrapper-backed product reproducibility.

Decision (2026-11-05): Target the maintained wrapper-compatible layout for
valid images because existing consumers use it. A deviation needs a format,
reader, safety or reproducibility reason and a focused check. Historical
native PoC revisions supply layout evidence, not code to transplant.

Three bounded whole-image references cover FAT12 at 10,272 KiB, FAT16 at
200,000 KiB and FAT32 at 600,000 KiB. They use fixed source bytes, mtimes,
serial, UTC environment, late label and Abuild input-set traversal order.
The compressed `bzip2 -9` fixtures total 4,290 bytes. Their raw and
compressed hashes and producer identities are recorded in
`tests/fixtures/vfat/README.md`.

The generator checks exact package, executable, configuration and input
identities before creating an image. It anchors executables selected from
relative `PATH` entries before entering its scratch directory, while
retaining symlink names and `symlink/..` path components. Normal `make check`
reads the committed fixtures without regenerating them or checking producer
versions. The independent checker requires `BZh9` headers, expands each
image sparsely in 4-KiB zero blocks and hashes its full logical contents.
It decodes BPB fields, FAT copies, label, long-name aliases and checksums,
and the payload chain. `fsck.fat`, `mdir` and `mtype` validate structure and
content. FAT-copy and long-name corruption controls fail at their intended
guards. An explicit pinned-environment check proves that wrong package and
executable identities fail the generator guard.

The selected references do not prove a complete native writer or all FAT
geometries, names and timestamps. Before switching the Abuild adapter,
build representative wrapper-backed and native product images from locked
inputs in Trixie, then compare readers, raw fields, contents and the chosen
byte-compatible subset. Product boot and data images may need distinct
cases. The adapter switch remains separate from Arca's native writer.

The plan and record indexes are sorted, development guidance names the
test-only tools, and the documentation site builds in strict mode. No
changelog entry is added because this topic changes no user-facing behavior.

Co-Authored-By: GPT-6 <noreply@openai.com>

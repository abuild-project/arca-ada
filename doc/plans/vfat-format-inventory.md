# VFAT format and reference inventory

Status: Phase 0 evidence recorded on 2026-11-05; compatibility decisions and
populated-image baselines remain open. No writer or public API is introduced.

## Boundary

Decision (2026-11-05): Establish the FAT format contract and separate the two
observed producer profiles before implementing a writer, because both create
checker-valid images but differ in FAT type and boot geometry. Arca will
implement native format logic; external tools and consumer wrappers remain
reference producers, not Arca runtime dependencies. Historical native code is
evidence to review, not a branch to transplant.

The containing Arca base is `30bfa8f31f868f9af77df649ab8632fdb699584e`.
The current Abuild transformation was read at accepted revision
`1b8ac18483f70b018441b27554d13241bdd7b80b`. Its CPIO/TAR integration
does not change the VFAT transformation. These identities are source snapshots,
not a promise that a moving branch or a later tool package has the same bytes.

## Format authority and pinned reference inputs

The format authority for this inventory is Microsoft's
[FAT32 File System Specification, version 1.03, 2000-12-06](https://download.microsoft.com/download/1/6/1/161ba512-40e2-4cc9-843a-923143f3456c/fatgen103.doc),
including its FAT12/FAT16, FAT32 and long-name sections. Its official
[download listing](https://www.microsoft.com/en-us/download/details.aspx?id=53426)
names `fatgen103.doc`. The downloaded file is 222,720 bytes and has SHA-256
`b17d66c796d9cd3070adf4ccbc00add5a8b6b6f5491fe8ea949df778fce60172`.
The file was inspected, not copied into this repository. Its version and
downloaded bytes, rather than the download page's later publication date,
identify the reference. The [GNU mtools manual](https://www.gnu.org/software/mtools/manual/html_node/mformat.html)
documents the producer options; its web edition is explanatory, while the
observed package and executable bytes below pin the tested implementation.

The initial producer observation used rootless AMD64 Debian 13.6 Trixie with
`TZ=UTC` and `LC_ALL=C`. Debian packages were `dosfstools 4.2-1.2` and
`mtools 4.0.48-1`, both `amd64`. The executables had these SHA-256 values:

| Executable | SHA-256 |
| --- | --- |
| `/usr/sbin/mkfs.fat` (`mkdosfs` resolves here) | `70319b905ad6e925111f81fc588dd8371775341c7f0aad21724bdd1ce46f63d2` |
| `/usr/bin/mformat` (`mcopy` and `mmd` share its multicall bytes) | `0fcd90361bb5077f1289342f6e7713f98269847dbda25d6f1657018f42c53e85` |
| `/usr/sbin/fatlabel` | `e54ea9ff816f7094db65e5fbc93971a3a034e2877f17dc4cac78273751193eab` |
| `/usr/sbin/fsck.fat` | `8f185d04345bdb4bc68d23f87a6dc6575301fc89bbf6ae4a0047488c9428ec85` |

These package versions and binary hashes pin this observation, not all future
Trixie builds. A committed reference-image generator must reject a different
producer version or hash before replacing golden data. Reference checks use
test-only tools supplied by Arca's development image; the library has no
runtime dependency on them.

## On-disk format inventory

The Microsoft document defines a shared BPB through byte offset 35. Relevant
zero-based boot-sector fields include bytes per sector at 11 (2 bytes),
sectors per cluster at 13 (1), reserved sectors at 14 (2), FAT copies at 16
(1), root-entry count at 17 (2), media byte at 21 (1), FAT12/16 FAT length at
22 (2), sectors per track at 24 (2), heads at 26 (2), hidden sectors at 28
(4), and 32-bit total sectors at 32 (4). FAT32 continues with a distinct BPB
from offset 36, including FAT length, root cluster, FSInfo and backup boot
sector. All multibyte BPB fields are little-endian.

The FAT variant is determined by the computed count of data clusters:
`< 4085` is FAT12, `4085 .. 65524` is FAT16, and `>= 65525` is FAT32. Tests
must cover both sides of each boundary and avoid layouts close to a boundary
when compatibility with older readers is required. FAT12 and FAT16 have a
fixed root-directory region; FAT32's root is a cluster chain. All variants
use 32-byte directory entries. Long names occupy preceding entries with an
ordinal sequence and checksum binding them to their short alias. FAT32 adds
FSInfo and backup-boot handling. A regular file's stored size is limited by
its 32-bit directory field. The layout, naming, timestamp and allocation
rules need independent raw checks as well as external readers; these notes
are an inventory, not a complete encoder design.

## Current consumer contract

The accepted Abuild adapter in `src/abuild-transformations-vfat.adb` creates
the image with `mkdosfs -F 16|32 -C`, populates directories with `mmd` and
regular files with `mcopy -s`, and applies an optional label with `fatlabel`
after population. It supports `IMAGE_SIZE` and `IMAGE_SPARE` in KiB, rounds
the selected size upward to a multiple of 32 KiB, rejects sizes below
9,216 KiB, and requests FAT32 from 520 MiB upward. Automatic sizing includes
payload size, requested spare space and an empirical metadata allowance.
`IMAGE_LABEL` is trimmed, validated against the portable 11-character
profile and applied late because early `mkdosfs -n` changes root-entry order.
The output suffix is `.fat16` or `.fat32` according to the adapter's request;
it does not independently prove the emitted FAT type.

The maintained consumer build places a private `mkdosfs` compatibility
wrapper ahead of the system executable on `PATH`. The inspected wrapper
source has SHA-256
`4a627b68621c39d68cafdf4d88d279719cc27023a688e533f96b74ff83e667d0`.
For the adapter's arguments it invokes `mformat -C -T (2 * size_in_KiB)
-i image -h 64 -s 32 -H 0 ::`. It translates `-F 32` to mtools `-F` but does
not force FAT16 for `-F 16`; mtools chooses FAT12 or FAT16 from the layout.
The wrapper's source location is private and is not an Arca source import.
Its translation was exercised against direct `mformat` invocations at both
observed sizes, with byte-identical results after fixing the serial.

## Observed empty-image baselines

The following are controlled empty-image observations, not accepted golden
fixtures. A fixed serial `0x12345678` was supplied through mtools `-N` or
dosfstools `-i`. Dosfstools also received `SOURCE_DATE_EPOCH=946684800`.
The wrapper profile used its default geometry plus `-N` for this experiment.
Each producer command was run twice; matching pairs were byte-identical.
`fsck.fat -vn` accepted all four images, and `mdir` read both 9 MiB images.
The commands below reproduce the four empty images from an empty directory
with the pinned producer binaries; the output names are arbitrary:

```sh
TZ=UTC LC_ALL=C mformat -C -T 18432 -i wrapper-9216k.img \
  -h 64 -s 32 -H 0 -N 0x12345678 ::
TZ=UTC LC_ALL=C SOURCE_DATE_EPOCH=946684800 \
  mkdosfs -F 16 -C -i 12345678 dosfstools-9216k.img 9216
TZ=UTC LC_ALL=C mformat -C -F -T 1064960 -i wrapper-520m.img \
  -h 64 -s 32 -H 0 -N 0x12345678 ::
TZ=UTC LC_ALL=C SOURCE_DATE_EPOCH=946684800 \
  mkdosfs -F 32 -C -i 12345678 dosfstools-520m.img 532480
```

| Requested size | Producer | FAT and geometry observed | Image SHA-256 |
| --- | --- | --- | --- |
| 9,216 KiB | wrapper-equivalent mtools | FAT12, 2,298 clusters, 32 sectors/track, 64 heads | `6749b7a4610b501e94eaa5852c6a68ee400fb9348f9716046c5157d5bb3c494d` |
| 9,216 KiB | direct dosfstools `-F 16` | FAT16, 4,589 clusters, 32 sectors/track, 2 heads | `6577ee34286d1d7561b7248b2b460cd8de4c5b38b12e5850bb8fc2e166702972` |
| 520 MiB | wrapper-equivalent mtools `-F` | FAT32, 1,038 sectors/FAT, 1,064,960 sectors | `0d2bcd77272a22a629b196e50d878419d9cd3180f1accdece1016f57bb0d73fe` |
| 520 MiB | direct dosfstools `-F 32` | FAT32, 1,040 sectors/FAT, 1,064,952 sectors | `dfbbce27346a7c43c6fe71112060f981525680f3762141cec100444bb877286e` |

At 9 MiB the two valid profiles disagree on FAT type. At 520 MiB they both
emit FAT32 but differ in geometry and FAT length. These examples establish
neither byte parity for populated images nor which profile should become
Arca's default. The Microsoft specification advises against FAT12 above
4 MiB for broad reader compatibility, so the wrapper's 9 MiB FAT12 result
needs explicit product compatibility evidence.

Abuild's `Configured_Label_Reproducible` test builds two populated, labeled
VFAT images with fixed `SOURCE_DATE_EPOCH` across three seconds and two time
zones and requires byte identity. It passed on the accepted tree in Trixie.
That checked path uses the system `mkdosfs`, not the maintained wrapper.
Separately, two empty images made by the copied wrapper with Trixie `mtools`
and no serial override had different volume IDs under the same
`SOURCE_DATE_EPOCH`; a fixed `-N` stabilized that isolated reference profile.
This does not assess a complete consumer build or contradict the Abuild test.
The actual wrapper caller environment and its mtools identity must be pinned
before claiming its reproducibility or bytes as a product baseline.

The accepted Abuild tree's focused VFAT transformation tests passed in the
Trixie image. They check size and spare cases, labels and invalid labels in
addition to the reproducibility case above. Existing Abuild
reference-product verification also reads VFAT images independently. No native
Arca VFAT writer exists yet.

## Historical native PoC inventory

The Abuild test-gap snapshot is
`1f0aca55a215adfa41298e8873f47f95f8981da8`; the native PoC head is
`ef2e376e4e8a53b9e12d722bc690134ea3e0fe65`. Its writer files are
`src/abuild-file_formats-vfat.ads` and `.adb`, with direct tests under
`tests/abuild-file_formats-vfat-test.*` and
`tests/tests-abuild_file_formats_vfat.*`. The transformation and its tests
changed separately. Later hardening through
`94e664dc8bcf4efa7e681af87c02571b3a169fae` touches the same writer,
adapter or tests; the combined historical endpoint is
`ff61ebc74d10122bbadf5847225e5c0450110f5b`. These are discovery points,
not an import base or evidence that each intermediate commit is correct.

The PoC sequence covers FAT16 first, then FAT32, names, timestamps,
short-alias allocation, checker fixtures and maintained wrapper geometry.
Later changes address layout overflow, invalid components, directory-cluster
boundaries, parallel instances and entry lookup cost. A file-by-file reverse
hardening pass and a licence-origin table are required before reusing code.
No PoC source was copied into Arca in this topic.

## Decisions and next evidence

The maintainer must choose the intended Arca format profile and the separate
Abuild adapter behavior before implementation: FAT type selection near the
9 MiB minimum, boot geometry, volume serial and timestamp policy, sizing
units, late labels and the scope of any byte-compatible subset. The present
evidence does not justify claiming byte identity with both observed producers.

Next, produce populated reference images with fixed input bytes, names,
timestamps, locale, serial and environment. Cover directories, short and long
names, collisions, cluster transitions, FAT copies and FAT32 metadata. Read
each image with `mtools` and `fsck.fat`, plus an independent raw decoder whose
field constants do not come from the new writer. Record exact producer
commands, package identities, fixture-input hashes and output hashes. A
committed golden fixture is appropriate only for a deliberately chosen
byte-compatible subset; its generator must refuse a different producer.
Then define a narrow `Arca.VFAT` API and implement the native writer in
small, independently buildable steps. Keep the Abuild adapter switch and
product-specific policy in a separate change.

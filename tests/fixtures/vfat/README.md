# Pinned mtools VFAT references

The three `mtools-fat*.img.bz2` files are generated, project-owned reference
images. They fix narrow wrapper-compatible FAT12, FAT16 and FAT32 subsets
before a native writer is implemented. They do not promise byte identity for
every mtools image or the current Abuild direct-dosfstools profile.

The images were generated in the rootless AMD64 Trixie development image from
the four files under `input/`. All input mtimes are set to
`SOURCE_DATE_EPOCH=946684800`, with `TZ=UTC`, `LC_ALL=C`, umask `0022`, a
private empty `HOME` and volume serial `0x12345678`. The generator applies
the maintained wrapper geometry `-h 64 -s 32 -H 0` using `mformat`, creates
`DIR`, then adds `DIR/Long Filename Alpha.txt`,
`DIR/Long Filename Beta.txt`, `DIR/PAYLOAD.BIN` and finally `README.TXT`
with `mcopy -s`. This matches Abuild's path traversal order for the selected
input set. It applies `VFAT TEST` late with `fatlabel`.

The guarded producer identities are:

| Component | Version or SHA-256 |
| --- | --- |
| `mtools` Debian package | `4.0.48-1` |
| `dosfstools` Debian package | `4.2-1.2` |
| `bzip2` Debian package | `1.0.8-6` |
| `mformat`, `mcopy`, `mmd` executable bytes | `0fcd90361bb5077f1289342f6e7713f98269847dbda25d6f1657018f42c53e85` |
| `fatlabel` executable | `e54ea9ff816f7094db65e5fbc93971a3a034e2877f17dc4cac78273751193eab` |
| `bzip2` executable | `ef7b10842fa6846421d7219c7733cd6413c199dad422027286bd3d54cfac6f15` |
| `/etc/mtools.conf` | `d778ef3a45d726b6017d282a20ef6ff1555d1bb8f801aa196de753a7340679b8` |

`generate-reference.py` checks those exact packages and binaries, then the
source-file hashes, before running any producer. It requires the raw image
SHA-256 below and compresses each image with `bzip2 -9`. A normal
verification regenerates all three privately and compares bytes without
changing a fixture. Intentional regeneration requires an explicit `--case`,
`--write --replace`, and review of any changed producer, input, raw hash and
compressed hash.
Producer paths selected through relative `PATH` entries are anchored before
the generator enters its scratch directory. Symlink names and `symlink/..`
components are retained so the checked executable is the one invoked.

| FAT type and size | Raw image SHA-256 | Committed bzip2 SHA-256 |
| --- | --- | --- |
| FAT12, 10,272 KiB | `1a358f797abb99c85dd0802ba06551c8449e7737958146d834844bdb6e698ccd` | `889332f715a6e121d950820bc0e8ab206254d950287a4a61c40e25ff62e0e7bd` |
| FAT16, 200,000 KiB | `bacf4e0614fb830be3438bcdb59bde1eb1de3ae1e38d59cfb6fdfc7a9408b5f8` | `d719324840bbe526349a7020d7bf096097648cf6f05bb521c31098587cf73326` |
| FAT32, 600,000 KiB | `aca4f8804cd6624211dd6204f21f8c102154473cd187931d36c7d87e1ea07575` | `791e713c9e7e3536bc92854c627c15d2df79834715e45db58e12d5f8beec9c67` |

The first image uses `mformat -T 20544`, the second `-T 400000`, and the
third `-F -T 1200000`. All use the fixed geometry, serial, population order
and late label above. The compressed files occupy 4,290 bytes together;
normal checks decompress only one at a time into sparse private scratch space.

Generate or verify in the documented Trixie image after building this
repository's Dockerfile:

```sh
docker/dev/build --tag arca-dev:vfat-reference
docker/dev/run --platform linux/amd64 arca-dev:vfat-reference \
  python3 tests/fixtures/vfat/generate-reference.py --check-producer
docker/dev/run --platform linux/amd64 arca-dev:vfat-reference \
  python3 tests/fixtures/vfat/generate-reference.py
```

Normal `make check` does not regenerate the fixtures. Its independent
`check-vfat-reference.py` verifies the committed hashes and `BZh9` headers,
expands images sparsely in 4-KiB blocks, hashes their full logical contents,
decodes FAT fields without generator constants, checks `fsck.fat`, `mdir` and
`mtype`, and proves that altered FAT and long-name bytes fail the raw checks for
each FAT variant. It does not require the pinned producer binaries. To test
that the generator accepts the pinned environment, rejects changed package
and executable identities, and works with relative `PATH` entries including
directory symlinks followed by `..`, run the separate guard check in that
environment:

```sh
docker/dev/run --platform linux/amd64 arca-dev:vfat-reference \
  python3 tests/check-vfat-reference.py --check-producer-guard
```

Each fixture covers a late root volume label, a short root file, one
subdirectory, two colliding long-name aliases and a three-cluster file.
Unicode names, broader collision classes, exact minimum sizes, parallel
writers, other time zones and real product images remain outside these
golden subsets. See the [VFAT inventory](../../../doc/plans/vfat-format-inventory.md)
for those separate checks and the later product-comparison gate.

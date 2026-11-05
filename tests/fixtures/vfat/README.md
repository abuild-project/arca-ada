# Pinned mtools FAT12 reference

`mtools-fat12-10272.img.bz2` is a generated, project-owned reference image.
It fixes a narrow wrapper-compatible FAT12 subset before a native writer is
implemented. It is not a claim that every mtools image, every FAT variant or
the current Abuild direct-dosfstools profile must be byte-identical.

The image was generated in the rootless AMD64 Trixie development image from
the four files under `input/`. All input mtimes are set to
`SOURCE_DATE_EPOCH=946684800`, with `TZ=UTC`, `LC_ALL=C`, umask `0022`, a
private empty `HOME` and volume serial `0x12345678`. The generator applies
the maintained wrapper geometry `-h 64 -s 32 -H 0` using `mformat`, creates
`DIR`, then adds `DIR/Long Filename Alpha.txt`,
`DIR/Long Filename Beta.txt`, `DIR/PAYLOAD.BIN` and `README.TXT` with
`mcopy -s`. This follows the Abuild input-set traversal for these paths.
It applies `VFAT TEST` late with `fatlabel`.

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
SHA-256 below and compresses it with `bzip2 -9`. A normal verification
regenerates privately and compares bytes without changing the fixture.
Intentional regeneration requires `--write --replace` and review of any
changed producer, input, raw hash and compressed hash.

| Artifact | SHA-256 |
| --- | --- |
| Raw 10,272 KiB image | `1a358f797abb99c85dd0802ba06551c8449e7737958146d834844bdb6e698ccd` |
| Committed bzip2 image | `889332f715a6e121d950820bc0e8ab206254d950287a4a61c40e25ff62e0e7bd` |

Generate or verify in the documented Trixie image after building this
repository's Dockerfile:

```sh
docker/dev/build --tag arca-dev:vfat-reference
docker/dev/run --platform linux/amd64 arca-dev:vfat-reference \
  python3 tests/fixtures/vfat/generate-reference.py --check-producer
docker/dev/run --platform linux/amd64 arca-dev:vfat-reference \
  python3 tests/fixtures/vfat/generate-reference.py
```

Normal `make check` does not regenerate the fixture or check the producer
identity. Its independent `check-vfat-reference.py` validates the committed
hashes, FAT fields, external readers and targeted corruptions without using
generator constants. It writes the decompressed image sparsely in 4-KiB
blocks and hashes its full logical contents. Test the producer guard
separately in the pinned Trixie environment:

```sh
docker/dev/run --platform linux/amd64 arca-dev:vfat-reference \
  python3 tests/check-vfat-reference.py --check-producer-guard
```

The fixture covers a late root volume label, a short root file, one
subdirectory, two colliding long-name aliases and a three-cluster file.
FAT16/FAT32 layout, Unicode names, broader collision classes, exact minimum
sizes, parallel writers, other time zones and real product images remain
outside this golden subset. See the [VFAT inventory](../../../doc/plans/vfat-format-inventory.md)
for those separate checks and the later product-comparison gate.

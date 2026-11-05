#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Check one pinned FAT12 reference with independent readers and raw fields."""

import argparse
import bz2
import hashlib
import mmap
import os
from pathlib import Path
import struct
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests/fixtures/vfat"
GOLDEN = FIXTURE / "mtools-fat12-10272.img.bz2"
GENERATOR = FIXTURE / "generate-reference.py"
BZIP2_SHA256 = "889332f715a6e121d950820bc0e8ab206254d950287a4a61c40e25ff62e0e7bd"
RAW_SHA256 = "1a358f797abb99c85dd0802ba06551c8449e7737958146d834844bdb6e698ccd"
INPUTS = {
    "README.TXT": "a17e1739456862261be4b460e87f055544a5fe7bfc4903caa71703b98acefee8",
    "Long Filename Alpha.txt": "cb57dea126a43a6430ba97b781613050b4968f09ae5a80c94cc34d3990083220",
    "Long Filename Beta.txt": "fb27281f37c22f5dc56a4fc3d73cfd411647b6402ba90879c3690afe4f15ead7",
    "PAYLOAD.BIN": "328483c355456142e6d9f8c42e7afc5150f4cffdcb6408bcf0350cc34c6a26aa",
}


def require(condition, reason):
    """Reject a missing reference property with a specific diagnostic."""
    if not condition:
        raise AssertionError(reason)


def sha256(path):
    """Hash a file in bounded blocks, including sparse logical zeroes."""
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def expand_sparse(compressed, image):
    """Write nonzero 4-KiB blocks and retain the full logical image size."""
    zeroes = bytes(4096)
    size = 0
    with bz2.open(compressed, "rb") as source, image.open("wb") as target:
        for block in iter(lambda: source.read(4096), b""):
            if block == zeroes[:len(block)]:
                target.seek(len(block), 1)
            else:
                target.write(block)
            size += len(block)
        target.truncate(size)


def u16(data, offset):
    """Read one little-endian 16-bit field at a zero-based byte offset."""
    return struct.unpack_from("<H", data, offset)[0]


def u32(data, offset):
    """Read one little-endian 32-bit field at a zero-based byte offset."""
    return struct.unpack_from("<I", data, offset)[0]


def entries(data, start, length):
    """Read live 32-byte entries up to the FAT directory end marker."""
    found = []
    for offset in range(start, start + length, 32):
        entry = data[offset:offset + 32]
        require(len(entry) == 32, "truncated directory entry")
        if entry[0] == 0:
            break
        if entry[0] != 0xE5:
            found.append(entry)
    return found


def alias_checksum(name):
    """Calculate the 8.3 checksum stored in preceding long-name entries."""
    result = 0
    for byte in name:
        result = (((result & 1) << 7) + (result >> 1) + byte) & 0xFF
    return result


def long_name(parts):
    """Recover UTF-16LE long-name units from an ordered entry chain."""
    units = bytearray()
    for entry in reversed(parts):
        units.extend(entry[1:11])
        units.extend(entry[14:26])
        units.extend(entry[28:32])
    return units.decode("utf-16le").split("\x00", 1)[0].rstrip("\uffff")


def fat12_next(data, fat_start, cluster):
    """Read one packed FAT12 cluster pointer without producer code."""
    value = u16(data, fat_start + cluster * 3 // 2)
    return (value >> 4) & 0xFFF if cluster & 1 else value & 0xFFF


def inspect(data):
    """Require the recorded BPB, FAT, label, alias and payload-chain layout."""
    require(len(data) == 10_272 * 1024, "reference image size")
    require(data[510:512] == b"\x55\xaa", "boot signature")
    bps = u16(data, 11)
    spc = data[13]
    reserved = u16(data, 14)
    fats = data[16]
    root_count = u16(data, 17)
    sectors = u16(data, 19) or u32(data, 32)
    fat_sectors = u16(data, 22)
    require((bps, spc, reserved, fats, root_count, sectors, fat_sectors)
            == (512, 8, 1, 2, 512, 20_544, 8), "FAT12 BPB geometry")
    require((u16(data, 24), u16(data, 26), u32(data, 28))
            == (32, 64, 0), "CHS and hidden-sector geometry")
    require(u32(data, 39) == 0x12345678, "fixed volume serial")
    root_sectors = (root_count * 32 + bps - 1) // bps
    data_sector = reserved + fats * fat_sectors + root_sectors
    clusters = (sectors - data_sector) // spc
    require((data_sector, clusters) == (49, 2561), "FAT12 data-area plan")
    require(clusters < 4085, "FAT12 cluster-count class")
    fat_start = reserved * bps
    fat_bytes = fat_sectors * bps
    require(data[21] == 0xF8 and data[fat_start] == 0xF8, "media byte")
    require(data[fat_start:fat_start + fat_bytes] ==
            data[fat_start + fat_bytes:fat_start + 2 * fat_bytes],
            "FAT copies differ")

    root_start = (reserved + fats * fat_sectors) * bps
    root = entries(data, root_start, root_count * 32)
    labels = [i for i, entry in enumerate(root) if entry[11] == 8]
    require(labels == [len(root) - 1], "late root volume label")
    require(root[labels[0]][:11] == b"VFAT TEST  ", "volume label bytes")
    require(any(entry[:11] == b"README  TXT" for entry in root),
            "missing root README")
    directories = [entry for entry in root if entry[:11] == b"DIR        "]
    require(len(directories) == 1, "missing root directory")
    directory_cluster = u16(directories[0], 26)
    directory_start = (data_sector + (directory_cluster - 2) * spc) * bps
    children = entries(data, directory_start, spc * bps)
    pending = []
    names = []
    payload = None
    for entry in children:
        if entry[11] == 0x0F:
            pending.append(entry)
            continue
        if pending:
            checksum = alias_checksum(entry[:11])
            require(all(part[13] == checksum for part in pending),
                    "long-name checksum")
            require(pending[0][0] == (len(pending) | 0x40),
                    "long-name terminal ordinal")
            require([part[0] for part in pending[1:]] ==
                    list(range(len(pending) - 1, 0, -1)),
                    "long-name ordinal chain")
            names.append((long_name(pending), entry[:11].decode("ascii")))
            pending = []
        if entry[:11] == b"PAYLOAD BIN":
            payload = entry
    require(not pending, "orphan long-name entries")
    require(sorted(names) == [
        ("Long Filename Alpha.txt", "LONGFI~1TXT"),
        ("Long Filename Beta.txt", "LONGFI~2TXT"),
    ], "long-name aliases")
    require(payload is not None and u32(payload, 28) == 9216,
            "payload size entry")
    cluster = u16(payload, 26)
    chain = []
    while cluster < 0xFF8:
        require(cluster >= 2 and cluster not in chain,
                "invalid payload cluster chain")
        chain.append(cluster)
        cluster = fat12_next(data, fat_start, cluster)
    require(len(chain) == 3, "payload cluster count")
    return fat_start + fat_bytes, directory_start


def run_reader(command, home):
    """Run one independent reader with bounded, captured output."""
    environment = {
        "HOME": str(home),
        "LC_ALL": "C",
        "PATH": "/usr/sbin:/usr/bin:/sbin:/bin",
        "TZ": "UTC",
    }
    result = subprocess.run(command, capture_output=True, timeout=30,
                            env=environment)
    require(result.returncode == 0,
            f"reader failed: {command[0]}: {result.stderr.decode(errors='replace')}")
    return result.stdout


def check_external(image):
    """Require structural and semantic agreement from dosfstools and mtools."""
    fsck = run_reader(["fsck.fat", "-vn", str(image)], image.parent)
    require(b"12 bit entries" in fsck and b"0 files" not in fsck,
            "fsck did not inspect populated FAT12")
    listing = run_reader(["mdir", "-i", str(image), "::/DIR"], image.parent)
    require(b"LONGFI~1 TXT" in listing and b"Long Filename Alpha.txt" in listing,
            "first long name missing from mdir")
    require(b"LONGFI~2 TXT" in listing and b"Long Filename Beta.txt" in listing,
            "second long name missing from mdir")
    require(b"PAYLOAD  BIN" in listing, "payload missing from mdir")
    for name, target in (
        ("README.TXT", "::/README.TXT"),
        ("Long Filename Alpha.txt", "::/DIR/Long Filename Alpha.txt"),
        ("Long Filename Beta.txt", "::/DIR/Long Filename Beta.txt"),
        ("PAYLOAD.BIN", "::/DIR/PAYLOAD.BIN"),
    ):
        expected = (FIXTURE / "input" / name).read_bytes()
        actual = run_reader(["mtype", "-i", str(image), target], image.parent)
        require(actual == expected, f"mtype payload mismatch: {name}")


def check_sensitivity(data, fat_copy, directory_start):
    """Show that distinct FAT and long-name damage reach the intended guard."""
    damaged_fat = bytearray(data)
    damaged_fat[fat_copy + 10] ^= 1
    try:
        inspect(damaged_fat)
    except AssertionError as error:
        require(str(error) == "FAT copies differ", "wrong FAT damage guard")
    else:
        raise AssertionError("FAT damage was accepted")

    damaged_name = bytearray(data)
    for offset in range(directory_start, directory_start + 4096, 32):
        if damaged_name[offset + 11] == 0x0F:
            damaged_name[offset + 13] ^= 1
            break
    else:
        raise AssertionError("LFN damage control found no LFN")
    try:
        inspect(damaged_name)
    except AssertionError as error:
        require(str(error) == "long-name checksum", "wrong LFN damage guard")
    else:
        raise AssertionError("LFN damage was accepted")


def check_producer_guard(directory):
    """Prove the exact producer guard passes and rejects a wrong package."""
    positive = subprocess.run(
        [sys.executable, str(GENERATOR), "--check-producer"],
        capture_output=True, text=True, timeout=30)
    require(positive.returncode == 0 and
            "producer identities match" in positive.stdout,
            "reference producer identity check failed")
    fake = directory / "dpkg-query"
    fake.write_text("#!/bin/sh\nprintf '0.0'\n")
    fake.chmod(0o755)
    environment = os.environ.copy()
    environment["PATH"] = str(directory) + os.pathsep + environment["PATH"]
    negative = subprocess.run(
        [sys.executable, str(GENERATOR), "--check-producer"],
        env=environment, capture_output=True, text=True, timeout=30)
    require(negative.returncode != 0 and
            "bzip2 version mismatch" in negative.stderr,
            "wrong producer version was not rejected")
    fake.unlink()
    wrong_binary = directory / "mformat"
    wrong_binary.write_text("#!/bin/sh\nexit 0\n")
    wrong_binary.chmod(0o755)
    negative = subprocess.run(
        [sys.executable, str(GENERATOR), "--check-producer"],
        env=environment, capture_output=True, text=True, timeout=30)
    require(negative.returncode != 0 and
            "mformat hash mismatch" in negative.stderr,
            "wrong producer binary was not rejected")


def main():
    """Validate the committed fixture without regenerating its producer."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-producer-guard", action="store_true",
                        help="test strict producer identity rejection explicitly")
    options = parser.parse_args()
    require(sha256(GOLDEN) == BZIP2_SHA256,
            "compressed fixture hash")
    with GOLDEN.open("rb") as stream:
        require(stream.read(4) == b"BZh9", "bzip2 level-9 header")
    for name, expected in INPUTS.items():
        actual = hashlib.sha256((FIXTURE / "input" / name).read_bytes()).hexdigest()
        require(actual == expected, f"source fixture hash: {name}")
    (ROOT / "build").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="vfat-reference.",
                                     dir=ROOT / "build") as scratch:
        image = Path(scratch) / "reference.img"
        expand_sparse(GOLDEN, image)
        require(sha256(image) == RAW_SHA256, "raw fixture hash")
        with image.open("rb") as stream:
            with mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_READ) as data:
                fat_copy, directory_start = inspect(data)
                check_sensitivity(data, fat_copy, directory_start)
        check_external(image)
        if options.check_producer_guard:
            check_producer_guard(Path(scratch))
    print("VFAT reference raw fields, readers and sensitivity passed")
    if options.check_producer_guard:
        print("VFAT producer guards passed")


if __name__ == "__main__":
    main()

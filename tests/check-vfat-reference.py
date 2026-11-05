#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Check pinned FAT references with independent readers and raw field maps."""

import argparse
import bz2
import hashlib
import mmap
import os
from pathlib import Path
import shutil
import struct
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / "tests/fixtures/vfat"
GENERATOR = FIXTURE / "generate-reference.py"
CASES = {
    "fat12": {
        "size_kib": 10_272,
        "bzip2_sha": "889332f715a6e121d950820bc0e8ab206254d950287a4a61c40e25ff62e0e7bd",
        "raw_sha": "1a358f797abb99c85dd0802ba06551c8449e7737958146d834844bdb6e698ccd",
        "bpb": (512, 8, 1, 2, 512, 20_544, 8),
        "data_start": 49,
        "clusters": 2561,
    },
    "fat16": {
        "size_kib": 200_000,
        "bzip2_sha": "d719324840bbe526349a7020d7bf096097648cf6f05bb521c31098587cf73326",
        "raw_sha": "bacf4e0614fb830be3438bcdb59bde1eb1de3ae1e38d59cfb6fdfc7a9408b5f8",
        "bpb": (512, 8, 1, 2, 512, 400_000, 196),
        "data_start": 425,
        "clusters": 49_946,
    },
    "fat32": {
        "size_kib": 600_000,
        "bzip2_sha": "791e713c9e7e3536bc92854c627c15d2df79834715e45db58e12d5f8beec9c67",
        "raw_sha": "aca4f8804cd6624211dd6204f21f8c102154473cd187931d36c7d87e1ea07575",
        "bpb": (512, 8, 32, 2, 0, 1_200_000, 1170),
        "data_start": 2372,
        "clusters": 149_703,
    },
}
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
    """Hash one file in bounded blocks, including large sparse images."""
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


def next_cluster(data, fat_start, kind, cluster):
    """Read one cluster pointer using the FAT variant's packed field width."""
    if kind == 12:
        value = u16(data, fat_start + cluster * 3 // 2)
        return (value >> 4) & 0xFFF if cluster & 1 else value & 0xFFF
    if kind == 16:
        return u16(data, fat_start + cluster * 2)
    return u32(data, fat_start + cluster * 4) & 0x0FFFFFFF


def inspect(data, case):
    """Require the recorded BPB, FAT, label, alias and payload-chain layout."""
    require(len(data) == case["size_kib"] * 1024, "reference image size")
    require(data[510:512] == b"\x55\xaa", "boot signature")
    bps = u16(data, 11)
    spc = data[13]
    reserved = u16(data, 14)
    fats = data[16]
    root_count = u16(data, 17)
    sectors = u16(data, 19) or u32(data, 32)
    fat_sectors = u16(data, 22) or u32(data, 36)
    require((bps, spc, reserved, fats, root_count, sectors, fat_sectors)
            == case["bpb"], "FAT BPB geometry")
    require((u16(data, 24), u16(data, 26), u32(data, 28))
            == (32, 64, 0), "CHS and hidden-sector geometry")
    root_sectors = (root_count * 32 + bps - 1) // bps
    data_sector = reserved + fats * fat_sectors + root_sectors
    clusters = (sectors - data_sector) // spc
    kind = 12 if clusters < 4085 else 16 if clusters < 65525 else 32
    require((data_sector, clusters) ==
            (case["data_start"], case["clusters"]), "FAT data-area plan")
    require(kind == int(case["name"][3:]), "FAT cluster-count class")
    require(u32(data, 67 if kind == 32 else 39) == 0x12345678,
            "fixed volume serial")
    fat_start = reserved * bps
    fat_bytes = fat_sectors * bps
    require(data[21] == 0xF8 and data[fat_start] == 0xF8, "media byte")
    require(data[fat_start:fat_start + fat_bytes] ==
            data[fat_start + fat_bytes:fat_start + 2 * fat_bytes],
            "FAT copies differ")

    if kind == 32:
        require(u32(data, 44) == 2 and u16(data, 48) == 1,
                "FAT32 root and FSInfo sectors")
        root_start = data_sector * bps
        root_length = spc * bps
    else:
        root_start = (reserved + fats * fat_sectors) * bps
        root_length = root_count * 32
    root = entries(data, root_start, root_length)
    labels = [i for i, entry in enumerate(root) if entry[11] == 8]
    require(labels == [len(root) - 1], "late root volume label")
    require(root[labels[0]][:11] == b"VFAT TEST  ", "volume label bytes")
    require(any(entry[:11] == b"README  TXT" for entry in root),
            "missing root README")
    directories = [entry for entry in root if entry[:11] == b"DIR        "]
    require(len(directories) == 1, "missing root directory")
    directory_cluster = u16(directories[0], 26)
    if kind == 32:
        directory_cluster += u16(directories[0], 20) << 16
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
    if kind == 32:
        cluster += u16(payload, 20) << 16
    chain = []
    end_marker = {12: 0xFF8, 16: 0xFFF8, 32: 0x0FFFFFF8}[kind]
    while cluster < end_marker:
        require(2 <= cluster <= clusters + 1 and cluster not in chain,
                "invalid payload cluster chain")
        chain.append(cluster)
        cluster = next_cluster(data, fat_start, kind, cluster)
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


def check_external(image, kind):
    """Require structural and semantic agreement from dosfstools and mtools."""
    fsck = run_reader(["fsck.fat", "-vn", str(image)], image.parent)
    require(f"{kind} bit entries".encode() in fsck and b"0 files" not in fsck,
            "fsck did not inspect populated FAT")
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


def check_sensitivity(image, case, fat_copy, directory_start):
    """Show that FAT and long-name damage reach the intended guard."""
    with image.open("rb") as stream:
        with mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_COPY) as data:
            data[fat_copy + 10] ^= 1
            try:
                inspect(data, case)
            except AssertionError as error:
                require(str(error) == "FAT copies differ", "wrong FAT damage guard")
            else:
                raise AssertionError("FAT damage was accepted")
        with mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_COPY) as data:
            for offset in range(directory_start, directory_start + 4096, 32):
                if data[offset + 11] == 0x0F:
                    data[offset + 13] ^= 1
                    break
            else:
                raise AssertionError("LFN damage control found no LFN")
            try:
                inspect(data, case)
            except AssertionError as error:
                require(str(error) == "long-name checksum", "wrong LFN damage guard")
            else:
                raise AssertionError("LFN damage was accepted")


def check_producer_guard(directory):
    """Check pinned, relative-PATH, wrong-package and wrong-binary producers."""
    positive = subprocess.run(
        [sys.executable, str(GENERATOR), "--check-producer"],
        capture_output=True, text=True, timeout=30)
    require(positive.returncode == 0 and
            "producer identities match" in positive.stdout,
            "reference producer identity check failed")

    relative_tools = directory / "relative-tools"
    relative_tools.mkdir()
    mformat = shutil.which("mformat")
    require(mformat is not None, "mformat missing for relative PATH probe")
    (relative_tools / "mformat").symlink_to(Path.cwd() / mformat)
    symlink_parent = directory / "symlink-parent"
    nested = symlink_parent / "nested"
    (nested / "child").mkdir(parents=True)
    (nested / "mformat").symlink_to(Path.cwd() / mformat)
    (symlink_parent / "alias").symlink_to(nested / "child")
    for selected_directory in (relative_tools,
                               symlink_parent / "alias" / ".."):
        relative_entry = str(selected_directory.relative_to(ROOT))
        relative_environment = os.environ.copy()
        relative_environment["PATH"] = (
            relative_entry + os.pathsep + relative_environment["PATH"])
        selection = subprocess.run(
            [sys.executable, "-c", "import shutil; print(shutil.which('mformat'))"],
            cwd=ROOT, env=relative_environment, capture_output=True,
            text=True, timeout=30)
        require(selection.returncode == 0 and
                selection.stdout.strip() == relative_entry + "/mformat",
                "relative mformat was not selected")
        positive = subprocess.run(
            [sys.executable, str(GENERATOR), "--case", "fat12"],
            cwd=ROOT, env=relative_environment, capture_output=True,
            text=True, timeout=30)
        require(positive.returncode == 0 and
                "regeneration matched" in positive.stdout,
                "relative PATH producer failed after directory change: "
                + positive.stderr.strip())

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


def check_one(name, case):
    """Read one compressed golden without retaining the raw image afterward."""
    golden = FIXTURE / f"mtools-{name}-{case['size_kib']}.img.bz2"
    with golden.open("rb") as stream:
        require(stream.read(4) == b"BZh9", "bzip2 level-9 header")
    require(sha256(golden) == case["bzip2_sha"], "compressed fixture hash")
    with tempfile.TemporaryDirectory(prefix="vfat-reference.",
                                     dir=ROOT / "build") as scratch:
        image = Path(scratch) / "reference.img"
        expand_sparse(golden, image)
        require(sha256(image) == case["raw_sha"], "raw fixture hash")
        with image.open("rb") as stream:
            with mmap.mmap(stream.fileno(), 0, access=mmap.ACCESS_READ) as data:
                fat_copy, directory_start = inspect(data, {**case, "name": name})
        check_external(image, int(name[3:]))
        check_sensitivity(image, {**case, "name": name},
                          fat_copy, directory_start)
    print(f"{name} reference layout, readers and sensitivity passed")


def main():
    """Validate committed fixtures without regenerating their producers."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-producer-guard", action="store_true",
                        help="test strict producer identity rejection explicitly")
    options = parser.parse_args()
    for name, expected in INPUTS.items():
        require(sha256(FIXTURE / "input" / name) == expected,
                f"source fixture hash: {name}")
    (ROOT / "build").mkdir(exist_ok=True)
    for name, case in CASES.items():
        check_one(name, case)
    if options.check_producer_guard:
        with tempfile.TemporaryDirectory(prefix="vfat-producer-guard.",
                                         dir=ROOT / "build") as scratch:
            check_producer_guard(Path(scratch))
        print("VFAT producer guards passed")


if __name__ == "__main__":
    main()

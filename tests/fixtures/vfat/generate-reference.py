#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Regenerate bounded mtools FAT references with pinned producers."""

import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[3]
FIXTURE = Path(__file__).resolve().parent
EPOCH = 946684800
MTOOLS_CONFIG_SHA256 = "d778ef3a45d726b6017d282a20ef6ff1555d1bb8f801aa196de753a7340679b8"
CASES = {
    "fat12": {
        "size_kib": 10_272,
        "fat32": False,
        "raw_sha": "1a358f797abb99c85dd0802ba06551c8449e7737958146d834844bdb6e698ccd",
        "bzip2_sha": "889332f715a6e121d950820bc0e8ab206254d950287a4a61c40e25ff62e0e7bd",
    },
    "fat16": {
        "size_kib": 200_000,
        "fat32": False,
        "raw_sha": "bacf4e0614fb830be3438bcdb59bde1eb1de3ae1e38d59cfb6fdfc7a9408b5f8",
        "bzip2_sha": "d719324840bbe526349a7020d7bf096097648cf6f05bb521c31098587cf73326",
    },
    "fat32": {
        "size_kib": 600_000,
        "fat32": True,
        "raw_sha": "aca4f8804cd6624211dd6204f21f8c102154473cd187931d36c7d87e1ea07575",
        "bzip2_sha": "791e713c9e7e3536bc92854c627c15d2df79834715e45db58e12d5f8beec9c67",
    },
}

PACKAGES = {
    "bzip2": "1.0.8-6",
    "dosfstools": "4.2-1.2",
    "mtools": "4.0.48-1",
}
BINARIES = {
    "bzip2": "ef7b10842fa6846421d7219c7733cd6413c199dad422027286bd3d54cfac6f15",
    "fatlabel": "e54ea9ff816f7094db65e5fbc93971a3a034e2877f17dc4cac78273751193eab",
    "mcopy": "0fcd90361bb5077f1289342f6e7713f98269847dbda25d6f1657018f42c53e85",
    "mformat": "0fcd90361bb5077f1289342f6e7713f98269847dbda25d6f1657018f42c53e85",
    "mmd": "0fcd90361bb5077f1289342f6e7713f98269847dbda25d6f1657018f42c53e85",
}
INPUTS = {
    "README.TXT": "a17e1739456862261be4b460e87f055544a5fe7bfc4903caa71703b98acefee8",
    "Long Filename Alpha.txt": "cb57dea126a43a6430ba97b781613050b4968f09ae5a80c94cc34d3990083220",
    "Long Filename Beta.txt": "fb27281f37c22f5dc56a4fc3d73cfd411647b6402ba90879c3690afe4f15ead7",
    "PAYLOAD.BIN": "328483c355456142e6d9f8c42e7afc5150f4cffdcb6408bcf0350cc34c6a26aa",
}


def sha256(path):
    """Hash a file without assuming its size or loading it all into memory."""
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def producers():
    """Require the exact tested package and executable identities."""
    if sha256(Path("/etc/mtools.conf")) != MTOOLS_CONFIG_SHA256:
        raise RuntimeError("mtools system configuration hash mismatch")
    for package, expected in PACKAGES.items():
        result = subprocess.run(
            ["dpkg-query", "-W", "-f=${Version}", package],
            capture_output=True, text=True, check=True)
        actual = result.stdout.strip()
        if actual != expected:
            raise RuntimeError(
                f"{package} version mismatch: {actual}, expected {expected}")
    paths = {}
    for name, expected in BINARIES.items():
        selected = shutil.which(name)
        if selected is None:
            raise RuntimeError(f"missing producer: {name}")
        # mtools selects its command from argv[0]; keep the symlink spelling.
        path = Path(selected)
        actual = sha256(path)
        if actual != expected:
            raise RuntimeError(
                f"{name} hash mismatch: {actual}, expected {expected}")
        paths[name] = str(path)
    for name, expected in INPUTS.items():
        actual = sha256(FIXTURE / "input" / name)
        if actual != expected:
            raise RuntimeError(f"input hash mismatch: {name}: {actual}")
    return paths


def run(command, *, environment, directory):
    """Run one reference producer with a fixed, minimal environment."""
    subprocess.run(command, cwd=directory, env=environment, check=True)


def generate(paths, directory, case):
    """Build and compress one image from the recorded input sequence."""
    source = directory / "source"
    source.mkdir()
    (source / "DIR").mkdir()
    for name in INPUTS:
        target = source / (name if name == "README.TXT" else f"DIR/{name}")
        shutil.copyfile(FIXTURE / "input" / name, target)
        os.utime(target, (EPOCH, EPOCH))
    image = directory / "reference.img"
    environment = {
        "HOME": str(directory),
        "LC_ALL": "C",
        "PATH": "/usr/sbin:/usr/bin:/sbin:/bin",
        "SOURCE_DATE_EPOCH": str(EPOCH),
        "TZ": "UTC",
    }
    os.umask(0o022)
    format_command = [paths["mformat"], "-C"]
    if case["fat32"]:
        format_command.append("-F")
    format_command.extend([
        "-T", str(case["size_kib"] * 2), "-i", str(image),
        "-h", "64", "-s", "32", "-H", "0", "-N", "0x12345678", "::",
    ])
    run(format_command,
        environment=environment, directory=directory)
    run([paths["mmd"], "-i", str(image), "::/DIR"],
        environment=environment, directory=directory)
    for name, target in (
        ("Long Filename Alpha.txt", "::/DIR/Long Filename Alpha.txt"),
        ("Long Filename Beta.txt", "::/DIR/Long Filename Beta.txt"),
        ("PAYLOAD.BIN", "::/DIR/PAYLOAD.BIN"),
        ("README.TXT", "::/README.TXT"),
    ):
        relative = name if name == "README.TXT" else f"DIR/{name}"
        run([paths["mcopy"], "-s", "-i", str(image), str(source / relative), target],
            environment=environment, directory=directory)
    run([paths["fatlabel"], str(image), "VFAT TEST"],
        environment=environment, directory=directory)
    actual = sha256(image)
    if actual != case["raw_sha"]:
        raise RuntimeError(f"raw image hash mismatch: {actual}")
    compressed = directory / "reference.img.bz2"
    with compressed.open("wb") as target:
        subprocess.run([paths["bzip2"], "-9", "-c", str(image)],
                       cwd=directory, env=environment, stdout=target, check=True)
    compressed_hash = sha256(compressed)
    if compressed_hash != case["bzip2_sha"]:
        raise RuntimeError(f"bzip2 hash mismatch: {compressed_hash}")
    return compressed, compressed_hash


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check-producer", action="store_true")
    parser.add_argument("--case", choices=["all", *CASES], default="all")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--replace", action="store_true")
    options = parser.parse_args()
    if options.write and options.case == "all":
        parser.error("--write requires one explicit --case")
    try:
        paths = producers()
        if options.check_producer:
            print("VFAT reference producer identities match")
            return
        (ROOT / "build").mkdir(exist_ok=True)
        selected = CASES if options.case == "all" else (options.case,)
        for name in selected:
            case = CASES[name]
            output = FIXTURE / f"mtools-{name}-{case['size_kib']}.img.bz2"
            with tempfile.TemporaryDirectory(prefix="vfat-reference.",
                                             dir=ROOT / "build") as scratch:
                compressed, actual = generate(paths, Path(scratch), case)
                if options.write:
                    if output.exists() and not options.replace:
                        raise RuntimeError(
                            f"{output.name} exists; use --replace explicitly")
                    shutil.copyfile(compressed, output)
                    print(f"wrote {output.name}: sha256 {actual}")
                else:
                    if not output.is_file() or compressed.read_bytes() != output.read_bytes():
                        raise RuntimeError(
                            f"{output.name} differs from regeneration")
                    print(f"{output.name} regeneration matched: sha256 {actual}")
    except (OSError, subprocess.CalledProcessError, RuntimeError) as error:
        raise SystemExit(str(error)) from error


if __name__ == "__main__":
    main()

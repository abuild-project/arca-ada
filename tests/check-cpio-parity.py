#!/usr/bin/env python3
# SPDX-License-Identifier: LGPL-2.1-or-later

"""Compare the emitted archives with the inventoried upstream implementation."""

import argparse
import hashlib
import json
from pathlib import Path
import signal
import subprocess
import sys
import tempfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path, help="Authorized Abuild Git checkout")
    options = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    manifest = json.loads((root / "doc/provenance/cpio-tar-sources.json").read_text())
    revision = manifest["source_revision"]
    selected = {"src/abuild-file_formats-" + unit + suffix
                for unit in ("cpio", "binary_io") for suffix in (".ads", ".adb")}
    with tempfile.TemporaryDirectory(prefix="cpio-parity.", dir=root / "build") as name:
        scratch = Path(name)
        for entry in manifest["entries"]:
            if entry["path"] not in selected:
                continue
            if (options.source / ".git").exists():
                data = subprocess.check_output(
                    ["git", "-C", str(options.source.resolve()), "show",
                     revision + ":" + entry["path"]])
            else:
                data = (options.source / entry["path"]).read_bytes()
            if hashlib.sha256(data).hexdigest() != entry["sha256"]:
                raise RuntimeError("Source identity mismatch: " + entry["path"])
            (scratch / Path(entry["path"]).name).write_bytes(data)
        (scratch / "abuild.ads").write_text("package Abuild is end Abuild;\n")
        (scratch / "abuild-file_formats.ads").write_text(
            "package Abuild.File_Formats is end Abuild.File_Formats;\n")
        for name in ("test_support.ads", "test_support.adb", "cpio_driver.adb"):
            source = (root / "tests" / name).read_text()
            (scratch / name).write_text(
                source.replace("Arca.CPIO", "Abuild.File_Formats.CPIO"))
        (scratch / "baseline.gpr").write_text('''project Baseline is
   for Source_Dirs use (".");
   for Object_Dir use "obj";
   for Exec_Dir use "bin";
   for Main use ("cpio_driver.adb");
   package Compiler is
      for Default_Switches ("Ada") use
        ("-gnat12", "-gnatwa", "-gnatwe", "-gnato");
   end Compiler;
end Baseline;
''')
        subprocess.run(["gprbuild", "-p", "-P", str(scratch / "baseline.gpr"), "-j8"],
                       check=True)
        driver = scratch / "bin/cpio_driver"
        # Pin the known lifetime regression to the original writer itself.
        probe = subprocess.run([str(driver), "lifetime", str(scratch)],
                               capture_output=True, text=True, timeout=30)
        if (probe.returncode == 0 or
                "Omitted Close leaked archive descriptors" not in probe.stderr):
            raise RuntimeError("Original-writer lifetime negative control failed: " +
                               probe.stdout + probe.stderr)
        print("Original writer rejects the omitted-Close descriptor check.", flush=True)
        subprocess.run([sys.executable, str(root / "tests/check-cpio.py"),
                        "--baseline-driver", str(driver)], cwd=root, check=True)


if __name__ == "__main__":
    for termination_signal in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(termination_signal, lambda number, _frame: sys.exit(128 + number))
    main()

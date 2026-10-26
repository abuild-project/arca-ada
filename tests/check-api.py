#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Check private lifecycle visibility and ordinary record-component clients."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
HEADER = "--  SPDX-License-Identifier: GPL-2.0-or-later\n\n"
NEGATIVE = {
    "initialize": """with Arca.TAR;

procedure Probe
is
   Item : Arca.TAR.TAR_Archive_Type;
begin
   Arca.TAR.Initialize (Item);
end Probe;
""",
    "finalize": """with Arca.TAR;

procedure Probe
is
   Item : Arca.TAR.TAR_Archive_Type;
begin
   Arca.TAR.Finalize (Item);
end Probe;
""",
    "finalize-parent": """with Ada.Finalization;
with Arca.TAR;

procedure Probe
is
   Item : Arca.TAR.TAR_Archive_Type;
begin
   Ada.Finalization.Finalize
     (Ada.Finalization.Limited_Controlled'Class (Item));
end Probe;
""",
}
for operation in ("Initialize", "Finalize"):
    NEGATIVE["override-" + operation.lower()] = f"""with Arca.TAR;

procedure Probe
is
   type Derived is new Arca.TAR.TAR_Archive_Type with null record;

   overriding procedure {operation} (Item : in out Derived);
   --  Attempt to replace the inherited lifecycle operation.

   procedure {operation} (Item : in out Derived)
   is
   begin
      null;
   end {operation};

   Item : Derived;
begin
   {operation} (Item);
end Probe;
"""


def quoted(path):
    return '"' + str(path).replace('"', '""') + '"'


def project(directory, dependency, main):
    path = directory / "probe.gpr"
    path.write_text(HEADER + f"""with {quoted(dependency)};

project Probe is
   for Source_Dirs use (".");
   for Object_Dir use "obj";
   for Exec_Dir use "bin";
   for Main use ("{main}");

   package Compiler is
      for Default_Switches ("Ada") use ("-gnat12", "-gnatf");
   end Compiler;
end Probe;
""")
    return path


def build(options, path):
    return subprocess.run(
        [options.builder, "-f", "-p", "-P", str(path), "-j" + options.jobs],
        cwd=path.parent, capture_output=True, text=True, timeout=120)


def negative(options, scratch, name, source):
    directory = scratch / name
    directory.mkdir()
    (directory / "probe.adb").write_text(HEADER + source)
    result = build(options, project(directory, ROOT / "arca.gpr", "probe.adb"))
    assert result.returncode != 0, f"{name}: lifecycle operation is accessible"
    diagnostic = (result.stdout + result.stderr).lower()
    assert "probe.adb:" in diagnostic, result.stdout + result.stderr
    if name in ("initialize", "finalize"):
        assert name in diagnostic and any(
            text in diagnostic for text in ("not declared", "not a visible")), diagnostic
    elif name == "finalize-parent":
        assert "conversion" in diagnostic, diagnostic
    else:
        assert "not overriding" in diagnostic, diagnostic
    print(name + ": rejected at the intended API boundary")


def positive(options, scratch, extended):
    directory = scratch / ("extended-record" if extended else "record")
    directory.mkdir()
    dependency = ROOT / "arca.gpr"
    if extended:
        dependency = directory / "abuild_like.gpr"
        dependency.write_text(HEADER + f"""library project Abuild_Like
  extends {quoted(ROOT / 'arca.gpr')} is
   for Source_Dirs use ({quoted(ROOT / 'src')});
   for Object_Dir use "library-obj";
   for Library_Dir use "library";
   for Library_Interface use ();
   for Library_Standalone use "no";
end Abuild_Like;
""")
        result = build(options, dependency)
        assert result.returncode == 0, result.stdout + result.stderr
        prefix = directory / "prefix"
        installed = subprocess.run(
            [options.installer, "-f", "-p", "-P", str(dependency),
             "--install-name=arca", "--prefix=" + str(prefix),
             "--project-subdir=lib/gnat", "--sources-subdir=include",
             "--lib-subdir=lib", "--ali-subdir=lib"],
            cwd=directory, capture_output=True, text=True, timeout=120)
        assert installed.returncode == 0, installed.stdout + installed.stderr
        dependency = prefix / "lib/gnat/abuild_like.gpr"
    (directory / "arca_client.adb").write_bytes(
        (ROOT / "examples/client/arca_client.adb").read_bytes())
    result = build(options, project(directory, dependency, "arca_client.adb"))
    assert result.returncode == 0, result.stdout + result.stderr
    subprocess.run([str(directory / "bin/arca_client"),
                    str(directory / "record.cpio"), str(directory / "record.tar"),
                    str(directory / "record-long.tar")], check=True, timeout=30)
    assert (directory / "record.cpio").read_bytes().startswith(b"070701")
    assert (directory / "record.tar").read_bytes() == bytes(1024)
    assert (directory / "record-long.tar").read_bytes()[136:148] == b"00000000000\0"
    print(directory.name + ": writer components compile and run")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--builder", default=os.environ.get("GPRBUILD", "gprbuild"))
    parser.add_argument("--installer", default=os.environ.get("GPRINSTALL", "gprinstall"))
    parser.add_argument("--jobs", default=os.environ.get("NUM_CPUS", "8"))
    parser.add_argument("--case", choices=["all", "record", "extended-record", *NEGATIVE],
                        default="all")
    options = parser.parse_args()
    for name in ("builder", "installer"):
        selected = shutil.which(getattr(options, name))
        if selected is None:
            parser.error("Missing selected " + name + ": " + getattr(options, name))
        setattr(options, name, str(Path(selected).resolve()))
    (ROOT / "build").mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="api-check.", dir=ROOT / "build") as name:
        scratch = Path(name)
        if options.case in ("all", "record"):
            positive(options, scratch, False)
        if options.case in ("all", "extended-record"):
            positive(options, scratch, True)
        for name, source in NEGATIVE.items():
            if options.case in ("all", name):
                negative(options, scratch, name, source)


if __name__ == "__main__":
    main()

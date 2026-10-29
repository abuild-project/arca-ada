#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Exercise output identity with distinct unprivileged Linux identities."""

import argparse
import json
import os
from pathlib import Path
import runpy
import select
import signal
import subprocess
import tempfile


ATTACK = r"""
import os
from pathlib import Path
import sys

staging, stolen, sentinel = map(Path, sys.argv[1:4])
phase = sys.argv[4]
if phase == 'parent':
    parent = staging.parent
    os.rename(parent, parent.with_name(parent.name + '.parked'))
    parent.mkdir(mode=0o777)
    parent.chmod(0o777)
    staging.mkdir(mode=0o777)
    staging.chmod(0o777)
    (parent / 'unrelated').write_bytes(b'preserve replacement parent')
    (staging / 'archive').write_bytes(b'attacker archive bytes')
else:
    os.rename(staging, staging.with_name(staging.name + '.parked'))
    if phase == 'stolen':
        os.rename(stolen, staging)
    else:
        staging.mkdir(mode=0o777)
        staging.chmod(0o777)
        if phase == 'post-open':
            (staging / 'archive').write_bytes(b'attacker archive bytes')
        else:
            (staging / 'archive').symlink_to(sentinel)
"""


def receive(fd, expected, label):
    """Require an acknowledged phase transition before mutating or releasing."""
    assert select.select([fd], [], [], 15)[0], (label, "no acknowledgement")
    assert os.read(fd, 1) == expected, (label, "wrong acknowledgement")


def close(fd):
    """Release a parent pipe even when setup or child execution failed."""
    if fd is not None:
        os.close(fd)


def exercise(args, scratch, library, source, decode, kind, route, phase, finish):
    """Cross one synchronized boundary without granting either child root."""
    victim, attacker = 65534, 65533
    label = (kind, route, phase, finish)
    work = scratch / "-".join(label)
    work.mkdir()
    work.chmod(0o777)
    parent = work
    if phase == "parent":
        parent = work / "destination"
        parent.mkdir()
        parent.chmod(0o777)
    output = parent / "output"
    sentinel = work / "sentinel"
    sentinel.write_bytes(b"preserve victim sentinel")
    os.chown(sentinel, victim, victim)
    sentinel.chmod(0o600)
    if route == "force":
        output.write_bytes(b"original destination")
    stolen = work / "stolen"
    if phase == "stolen":
        stolen.mkdir(mode=0o700)
        (stolen / "archive").symlink_to(sentinel)
        os.chown(stolen, victim, victim)
    point = {"setup": "setup-barrier", "stolen": "setup-barrier",
             "before-open": "before-barrier", "post-open": "phase-barrier",
             "parent": "phase-barrier"}[phase]
    faults = point + (",rename-einval" if route == "link" else "")
    if finish == "write-error":
        faults += ",write-full"
    ready_r, ready_w = os.pipe()
    release_r, release_w = os.pipe()
    process = None
    try:
        env = dict(os.environ, LD_PRELOAD=str(library),
                   ARCA_TEST_FAULT=faults,
                   ARCA_TEST_FAULT_LOG=str(work / "trace"),
                   ARCA_TEST_READY_FD=str(ready_w),
                   ARCA_TEST_RELEASE_FD=str(release_r))
        env.pop("SOURCE_DATE_EPOCH", None)
        command = [str(args.cli), "create", "--format", kind,
                   "-C", str(source), "-o", str(output), "--mtime", "0"]
        if route == "force":
            command.append("--force")
        process = subprocess.Popen(
            command, env=env, user=victim, group=victim, extra_groups=[],
            pass_fds=(ready_w, release_r), stdout=subprocess.PIPE,
            stderr=subprocess.PIPE)
        close(ready_w)
        ready_w = None
        close(release_r)
        release_r = None
        receive(ready_r, b"R", label)
        staging, = parent.glob(".arca-*")
        assert staging.stat().st_uid == victim, label
        subprocess.run(["python3", "-c", ATTACK, str(staging), str(stolen),
                        str(sentinel), phase], user=attacker, group=attacker,
                       extra_groups=[], check=True, timeout=10)
        signals = {"hangup": signal.SIGHUP, "interrupt": signal.SIGINT,
                   "termination": signal.SIGTERM}
        if finish in signals:
            number = signals[finish]
            os.kill(process.pid, number)
            receive(ready_r, bytes([number]), label)
        os.write(release_w, b"G")
        out, err = process.communicate(timeout=30)
        replacement = staging / "archive"
        selected = output
        if phase == "parent":
            selected = parent.with_name(parent.name + ".parked") / "output"
        compromised = sentinel.read_bytes() != b"preserve victim sentinel"
        if output.is_file():
            compromised |= output.read_bytes() == b"attacker archive bytes"
        compromised |= not replacement.exists() and not replacement.is_symlink()
        if args.expect_vulnerable:
            assert compromised, (label, "baseline did not expose the defect", out, err)
        else:
            assert not compromised, (label, "output identity lost", out, err)
            if phase in ("setup", "stolen"):
                assert process.returncode == 1, (label, out, err)
                diagnostic = (b"not owned" if phase == "setup"
                              else b"cannot reserve output archive")
                assert diagnostic in err, (label, err)
            elif finish == "success":
                assert process.returncode == 0, (label, out, err)
                assert decode(selected, kind)["payload"]["data"] == (
                    b"authentic archive payload"), label
            else:
                expected = 1 if finish == "write-error" else 128 + signals[finish]
                assert process.returncode == expected, (label, out, err)
                assert (b"cannot read or emit entry" if finish == "write-error"
                        else b"interrupted") in err, (label, err)
            if phase in ("setup", "stolen") or finish != "success":
                if route == "force":
                    assert selected.read_bytes() == b"original destination", label
                else:
                    assert not selected.exists(), label
            if phase == "parent":
                assert not output.exists(), label
                assert (parent / "unrelated").read_bytes() == (
                    b"preserve replacement parent"), label
        trace = (work / "trace").read_text()
        assert "barrier released" in trace, label
        if finish == "write-error":
            assert "write ENOSPC" in trace, (label, trace)
        return {"format": kind, "route": route, "phase": phase,
                "finish": finish, "exit": process.returncode,
                "baseline_defect_observed": compromised}
    finally:
        for fd in (ready_r, ready_w, release_r, release_w):
            close(fd)
        if process is not None:
            if process.poll() is None:
                process.kill()
            process.communicate()


def main():
    """Run only in the dedicated coordinator that drops both child identities."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--cli", type=Path, default=Path("cli/bin/arca"))
    parser.add_argument("--format", choices=("cpio", "tar"))
    parser.add_argument("--route", choices=("default", "force", "link"))
    parser.add_argument("--only", choices=("setup", "stolen", "before-open",
                                           "post-open", "parent"))
    parser.add_argument("--expect-vulnerable", action="store_true")
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    args.cli = args.cli.resolve()
    assert os.geteuid() == 0, "use the dedicated --root coordinator container"
    root = Path(__file__).resolve().parents[1]
    decoder = runpy.run_path(str(root / "tests/check-cli.py"))["records"]
    results = []
    with tempfile.TemporaryDirectory(prefix="arca-cross-uid.") as name:
        scratch = Path(name)
        scratch.chmod(0o755)
        library = scratch / "faults.so"
        subprocess.run(["gcc", "-std=c11", "-Wall", "-Wextra", "-Werror",
                        "-pedantic", "-fPIC", "-shared", "-o", str(library),
                        str(root / "tests/cli_faults.c"), "-ldl"], check=True)
        source = scratch / "source"
        source.mkdir(mode=0o755)
        (source / "payload").write_bytes(b"authentic archive payload")
        for kind in ([args.format] if args.format else ("cpio", "tar")):
            for route in ([args.route] if args.route else ("default", "force", "link")):
                for phase in ([args.only] if args.only else (
                        "setup", "stolen", "before-open", "post-open", "parent")):
                    finishes = ("success",)
                    if phase == "post-open":
                        finishes += ("write-error", "hangup", "interrupt", "termination")
                    for finish in finishes:
                        results.append(exercise(args, scratch, library, source,
                                                decoder, kind, route, phase, finish))
    if args.report:
        args.report.write_text(json.dumps(results, indent=2) + "\n")
    else:
        print(json.dumps(results, indent=2), flush=True)
    print("Cross-UID staging checks passed:", len(results), flush=True)


if __name__ == "__main__":
    main()

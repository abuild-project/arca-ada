#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
mkdir -p "$repo_root/build"
scratch=$(mktemp -d "$repo_root/build/install-check.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
trap 'exit 1' HUP INT TERM

# Freeze the caller's executable lookup before entering the isolated client.
gprbuild_command=$(command -v "${GPRBUILD:-gprbuild}")
case "$gprbuild_command" in
    /*) ;;
    *) gprbuild_command="$(pwd -P)/$gprbuild_command" ;;
esac
gprinstall_command=$(command -v "${GPRINSTALL:-gprinstall}")
case "$gprinstall_command" in
    /*) ;;
    *) gprinstall_command="$(pwd -P)/$gprinstall_command" ;;
esac
gprclean_command=$(command -v "${GPRCLEAN:-gprclean}")
case "$gprclean_command" in
    /*) ;;
    *) gprclean_command="$(pwd -P)/$gprclean_command" ;;
esac
make_command=${MAKE:-make}
num_cpus=${NUM_CPUS:-8}

# Retain an outer Make jobserver; standalone checks use the normal job budget.
run_make()
{
    case ${MAKEFLAGS:-} in
        *--jobserver-auth=*|*--jobserver-fds=*) ;;
        *) set -- -j8 "$@" ;;
    esac
    "$make_command" --no-print-directory -C "$repo_root" "$@" \
        NUM_CPUS="$num_cpus" GPRBUILD="$gprbuild_command" \
        GPRINSTALL="$gprinstall_command" GPRCLEAN="$gprclean_command" \
        PREFIX="$scratch/prefix"
}
# Exercise the public installation recipe rather than duplicating its flags.
run_make install
for manifest in arca arca-cli; do
    if [ ! -f "$scratch/prefix/share/gpr/manifests/$manifest" ]; then
        printf 'Missing installation manifest: %s\n' "$manifest" >&2
        exit 1
    fi
done
test ! -e "$scratch/prefix/share/gpr/manifests/cli"
# Installed notices must match the project's actual grant byte for byte.
for notice in LICENSE COPYRIGHT; do
    cmp "$repo_root/$notice" "$scratch/prefix/share/doc/arca/$notice"
done
mkdir -p "$scratch/cli input"
printf 'installed CLI\n' >"$scratch/cli input/payload"
for format in cpio tar; do
    "$scratch/prefix/bin/arca" create --format "$format" \
        -C "$scratch/cli input" -o "$scratch/installed.$format" --mtime 0
    test -s "$scratch/installed.$format"
done
tar -xOf "$scratch/installed.tar" payload | cmp - "$scratch/cli input/payload"
mkdir -p "$scratch/client"
cp "$repo_root/examples/client/client.gpr" \
    "$repo_root/examples/client/arca_client.adb" "$scratch/client/"

# Exclude inherited source search paths so the consumer must use the install.
(
    cd "$scratch/client"
    unset ADA_INCLUDE_PATH ADA_OBJECTS_PATH GPR_PROJECT_PATH ADA_PROJECT_PATH
    "$gprbuild_command" -p -P client.gpr \
        -aP"$scratch/prefix/share/gpr" -j"$num_cpus"
    output=$(./bin/arca_client "$scratch/client/smoke.cpio" \
        "$scratch/client/smoke.tar" "$scratch/client/long-name.tar")
    test "$output" = 'Arca project import succeeded'
    test -s "$scratch/client/smoke.cpio"
    grep -a -q '^070701' "$scratch/client/smoke.cpio"
    grep -a -q 'TRAILER!!!' "$scratch/client/smoke.cpio"
    # The installed TAR API must emit exactly its two empty end blocks.
    test "$(wc -c < "$scratch/client/smoke.tar")" -eq 1024
    dd if=/dev/zero bs=512 count=2 2>/dev/null | \
        cmp - "$scratch/client/smoke.tar"

    # Compare the installed binder's GNU metadata with the source-built driver.
    mkdir -p "$scratch/reference"
    "$repo_root/tests/bin/tar_driver" installed-long "$scratch/reference"
    cmp "$scratch/reference/installed-long.tar" "$scratch/client/long-name.tar"
    python3 - "$scratch/client/long-name.tar" <<'PY'
from pathlib import Path
import sys

archive = Path(sys.argv[1]).read_bytes()
assert archive[156:157] == b"L", "installed consumer omitted GNU long name"
assert archive[136:148] == b"00000000000\0", "GNU metadata mtime is not epoch"
assert archive[512:615] == b"n" * 101 + b"/\0", "GNU long-name payload differs"
PY

    # A missing install must fail even while the original sources exist.
    mv "$scratch/prefix/share/gpr/arca.gpr" \
        "$scratch/prefix/share/gpr/arca.gpr.hidden"
    if "$gprbuild_command" -p -P client.gpr \
        -aP"$scratch/prefix/share/gpr" -j"$num_cpus" \
        >"$scratch/missing-project.log" 2>&1; then
        printf 'Client unexpectedly found Arca outside the install\n' >&2
        exit 1
    fi
    if ! grep -E \
        '^[^:]+:[0-9]+:[0-9]+: imported project file "arca" not found$' \
        "$scratch/missing-project.log" >/dev/null; then
        cat "$scratch/missing-project.log" >&2
        printf 'Client failed for an unexpected reason\n' >&2
        exit 1
    fi
    mv "$scratch/prefix/share/gpr/arca.gpr.hidden" \
        "$scratch/prefix/share/gpr/arca.gpr"
)

# Uninstall must use manifests and retain files that Arca did not install.
printf 'unrelated prefix content\n' >"$scratch/prefix/unrelated"
run_make uninstall
python3 - "$scratch/prefix" <<'PY'
from pathlib import Path
import sys

prefix = Path(sys.argv[1])
assert sorted(str(path.relative_to(prefix)) for path in prefix.rglob("*")
              if path.is_file() or path.is_symlink()) == ["unrelated"]
assert (prefix / "unrelated").read_text() == "unrelated prefix content\n"
PY
run_make install
test -x "$scratch/prefix/bin/arca"
test -f "$scratch/prefix/share/gpr/arca.gpr"
for manifest in arca arca-cli; do
    test -f "$scratch/prefix/share/gpr/manifests/$manifest"
done
test "$(cat "$scratch/prefix/unrelated")" = 'unrelated prefix content'

printf 'Installed consumer, isolation and uninstall/reinstall checks passed\n'

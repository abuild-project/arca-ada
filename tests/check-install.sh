#!/bin/sh
# SPDX-License-Identifier: LGPL-2.1-or-later

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
gprinstall_command=${GPRINSTALL:-gprinstall}
num_cpus=${NUM_CPUS:-8}

"$gprinstall_command" -p -P "$repo_root/arca.gpr" \
    --prefix="$scratch/prefix"
"$gprinstall_command" -p -P "$repo_root/cli/cli.gpr" -aP"$repo_root" \
    --prefix="$scratch/prefix" --mode=usage --no-project
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
        "$scratch/client/smoke.tar")
    test "$output" = 'Arca project import succeeded'
    test -s "$scratch/client/smoke.cpio"
    grep -a -q '^070701' "$scratch/client/smoke.cpio"
    grep -a -q 'TRAILER!!!' "$scratch/client/smoke.cpio"
    # The installed TAR API must emit exactly its two empty end blocks.
    test "$(wc -c < "$scratch/client/smoke.tar")" -eq 1024
    dd if=/dev/zero bs=512 count=2 2>/dev/null | \
        cmp - "$scratch/client/smoke.tar"

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
)

printf 'Installed-project consumer and isolation checks passed\n'

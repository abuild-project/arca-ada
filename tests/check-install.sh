#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
mkdir -p "$repo_root/build"
scratch=$(mktemp -d "$repo_root/build/install-check.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
trap 'exit 1' HUP INT TERM

gprbuild_command=${GPRBUILD:-gprbuild}
gprinstall_command=${GPRINSTALL:-gprinstall}
num_cpus=${NUM_CPUS:-8}

"$gprinstall_command" -p -P "$repo_root/arca.gpr" \
    --prefix="$scratch/prefix"
mkdir -p "$scratch/client"
cp "$repo_root/examples/client/client.gpr" \
    "$repo_root/examples/client/arca_client.adb" "$scratch/client/"

# Exclude inherited source search paths so the consumer must use the install.
(
    cd "$scratch/client"
    unset ADA_INCLUDE_PATH ADA_OBJECTS_PATH GPR_PROJECT_PATH ADA_PROJECT_PATH
    "$gprbuild_command" -p -P client.gpr \
        -aP"$scratch/prefix/share/gpr" -j"$num_cpus"
    output=$(./bin/arca_client)
    test "$output" = 'Arca project import succeeded'

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

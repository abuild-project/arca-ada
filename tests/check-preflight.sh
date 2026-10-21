#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
mkdir -p "$repo_root/build"
scratch=$(mktemp -d "$repo_root/build/preflight-check.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
trap 'exit 1' HUP INT TERM
make_command=$(command -v "${MAKE:-make}")
mkdir -p "$scratch/bin" "$scratch/defaults" "$scratch/tools"

# Keep support commands available while deliberately omitting default GPR names.
for tool in gnatls make mktemp grep; do
    ln -s "$(command -v "$tool")" "$scratch/bin/$tool"
    ln -s "$(command -v "$tool")" "$scratch/defaults/$tool"
done
for tool in build install clean; do
    ln -s /bin/true "$scratch/tools/chosen-$tool"
done
for tool in gprbuild gprinstall gprclean; do
    ln -s /bin/true "$scratch/defaults/$tool"
    if PATH="$scratch/bin" command -v "$tool" >/dev/null 2>&1; then
        printf 'Fixture unexpectedly exposes %s\n' "$tool" >&2
        exit 1
    fi
done

failed=0
if PATH="$scratch/bin" "$make_command" --no-print-directory \
    -C "$repo_root" preflight \
    GPRBUILD="$scratch/tools/chosen-build" \
    GPRINSTALL="$scratch/tools/chosen-install" \
    GPRCLEAN="$scratch/tools/chosen-clean"; then
    printf 'Command-line GPR selections passed\n'
else
    failed=$((failed + 1))
fi

# File-origin values are not automatically exported like command-line values.
printf 'override GPRBUILD := %s\n' "$scratch/tools/chosen-build" \
    >"$scratch/selected.mk"
printf 'override GPRINSTALL := %s\n' "$scratch/tools/chosen-install" \
    >>"$scratch/selected.mk"
printf 'override GPRCLEAN := %s\n' "$scratch/tools/chosen-clean" \
    >>"$scratch/selected.mk"
if PATH="$scratch/bin" "$make_command" --no-print-directory \
    -C "$repo_root" -f Makefile -f "$scratch/selected.mk" preflight; then
    printf 'Makefile GPR selections passed\n'
else
    failed=$((failed + 1))
fi

if (
    unset GPRBUILD GPRINSTALL GPRCLEAN
    PATH="$scratch/defaults" /bin/sh "$repo_root/scripts/check-tools.sh"
); then
    printf 'Default GPR names passed\n'
else
    failed=$((failed + 1))
fi

if PATH="$scratch/defaults" "$make_command" --no-print-directory \
    -C "$repo_root" preflight \
    GPRBUILD="$scratch/missing-build" \
    GPRINSTALL="$scratch/missing-install" \
    GPRCLEAN="$scratch/missing-clean" >"$scratch/missing.log" 2>&1; then
    printf 'Preflight accepted missing selected tools\n' >&2
    failed=$((failed + 1))
elif grep -F -x \
    "Missing build tools: $scratch/missing-build $scratch/missing-install $scratch/missing-clean" \
    "$scratch/missing.log"; then
    printf 'Missing selected GPR tools reported together\n'
else
    cat "$scratch/missing.log" >&2
    failed=$((failed + 1))
fi

test "$failed" -eq 0

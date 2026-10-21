#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause

set -eu

missing=''
for tool in gprbuild gprinstall gprclean gnatls make mktemp grep; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        missing="$missing $tool"
    fi
done

if [ -n "$missing" ]; then
    printf 'Missing build tools:%s\n' "$missing" >&2
    printf 'Use the documented Trixie development image.\n' >&2
    exit 1
fi

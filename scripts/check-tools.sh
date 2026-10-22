#!/bin/sh
# SPDX-License-Identifier: LGPL-2.1-or-later

set -eu

missing=''
for tool in "${GPRBUILD:-gprbuild}" "${GPRINSTALL:-gprinstall}" \
    "${GPRCLEAN:-gprclean}" gnatls gcc make mktemp grep; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        missing="$missing $tool"
    fi
done

if [ -n "$missing" ]; then
    printf 'Missing build tools:%s\n' "$missing" >&2
    printf 'Use the documented Trixie development image.\n' >&2
    exit 1
fi

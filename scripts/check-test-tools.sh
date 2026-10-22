#!/bin/sh
# SPDX-License-Identifier: LGPL-2.1-or-later

set -eu
missing=''
for tool in python3 cpio tar bsdtar; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        missing="$missing $tool"
    fi
done
if [ -n "$missing" ]; then
    printf 'Missing archive test tools:%s\n' "$missing" >&2
    printf 'Rebuild the documented Trixie development image.\n' >&2
    exit 1
fi

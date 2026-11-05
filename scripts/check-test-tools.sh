#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later

set -eu
missing=''
for tool in python3 cpio tar bsdtar gprls mdir mtype fsck.fat; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        missing="$missing $tool"
    fi
done
repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
if command -v gprls >/dev/null 2>&1; then
    # Missing ALI files are expected before compiling a fresh source tree.
    # Preserve diagnostics when project/dependency evaluation actually fails.
    dependency_project=$repo_root/tests/test_dependencies.gpr
    if ! project_diagnostics=$(gprls -P "$dependency_project" -U -s 2>&1); then
        printf '%s\n' "$project_diagnostics" >&2
        missing="$missing Ahven/test-project(libahven-dev)"
    fi
fi
if [ -n "$missing" ]; then
    printf 'Missing test tools or projects:%s\n' "$missing" >&2
    printf 'Rebuild the documented Trixie development image.\n' >&2
    exit 1
fi

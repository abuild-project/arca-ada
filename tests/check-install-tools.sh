#!/bin/sh
# SPDX-License-Identifier: LGPL-2.1-or-later

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
builder=$(command -v "${GPRBUILD:-gprbuild}")
case "$builder" in
    /*) ;;
    *) builder="$(pwd -P)/$builder" ;;
esac
mkdir -p "$repo_root/build"
scratch=$(mktemp -d "$repo_root/build/install-tools.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
trap 'exit 1' HUP INT TERM
mkdir -p "$scratch/bin"

# Log the selected executable's use, then delegate to the actual compiler.
cat >"$scratch/bin/arca-test-builder" <<'EOF'
#!/bin/sh
set -eu
pwd -P >>"$ARCA_TEST_TOOL_LOG"
exec "$ARCA_TEST_BUILDER" "$@"
EOF
chmod +x "$scratch/bin/arca-test-builder"
ARCA_TEST_BUILDER=$builder
export ARCA_TEST_BUILDER
relative_bin=${scratch#"$repo_root"/}/bin
failed=0

# Successful output alone must not hide an ignored GPRBUILD selection.
check_selection()
{
    selection_label=$1
    selected_builder=$2
    selected_log=$3
    if GPRBUILD="$selected_builder" ARCA_TEST_TOOL_LOG="$selected_log" \
        "$repo_root/tests/check-install.sh"; then
        if grep -E '/install-check\.[^/]+/client$' "$selected_log"; then
            printf '%s passed\n' "$selection_label"
        else
            printf 'Selected builder was not used in the client directory\n' >&2
            failed=$((failed + 1))
        fi
    else
        failed=$((failed + 1))
    fi
}

cd "$repo_root"
check_selection 'Relative executable path' \
    "./$relative_bin/arca-test-builder" "$scratch/direct.log"
PATH="./$relative_bin:$PATH" check_selection 'Relative PATH entry' \
    arca-test-builder "$scratch/path.log"
test "$failed" -eq 0

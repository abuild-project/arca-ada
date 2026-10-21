#!/bin/sh
# SPDX-License-Identifier: LGPL-2.1-or-later

set -eu

repo_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
mkdir -p "$repo_root/build"
scratch=$(mktemp -d "$repo_root/build/make-tools.XXXXXXXX")
trap 'rm -rf -- "$scratch"' EXIT
trap 'exit 1' HUP INT TERM
make_command=$(command -v "${MAKE:-make}")
num_cpus=${NUM_CPUS:-8}
mkdir -p "$scratch/selected tools" "$scratch/project/scripts" \
    "$scratch/project/tests" "$scratch/project/examples/client/bin"

# Exercise the real Make recipes in isolation; consumer checks run separately.
ln -s "$repo_root/scripts/check-tools.sh" \
    "$scratch/project/scripts/check-tools.sh"
for script in check-preflight check-make-tools check-install check-install-tools; do
    ln -s /bin/true "$scratch/project/tests/$script.sh"
done
ln -s /bin/true "$scratch/project/examples/client/bin/arca_client"

# Log executable identity and argument boundaries, rather than simulate GNAT.
cat >"$scratch/selected tools/selected build" <<'EOF'
#!/bin/sh
set -eu
{
    printf '%s' "${0##*/}"
    for argument do
        printf ' <%s>' "$argument"
    done
    printf '\n'
} >>"$ARCA_TEST_MAKE_TOOL_LOG"
EOF
chmod +x "$scratch/selected tools/selected build"
ln -s 'selected build' "$scratch/selected tools/selected install"
ln -s 'selected build' "$scratch/selected tools/selected clean"
ARCA_TEST_MAKE_TOOL_LOG=$scratch/tools.log
export ARCA_TEST_MAKE_TOOL_LOG
: >"$ARCA_TEST_MAKE_TOOL_LOG"

failed=0
for target in check install clean; do
    if ! "$make_command" --no-print-directory -C "$scratch/project" \
        -f "$repo_root/Makefile" "$target" NUM_CPUS="$num_cpus" \
        GPRBUILD="$scratch/selected tools/selected build" \
        GPRINSTALL="$scratch/selected tools/selected install" \
        GPRCLEAN="$scratch/selected tools/selected clean" \
        PREFIX="$scratch/install prefix"; then
        failed=$((failed + 1))
    fi
done

cat >"$scratch/expected.log" <<EOF
selected build <-p> <-P> <arca.gpr> <-j$num_cpus>
selected build <-p> <-P> <examples/client/client.gpr> <-aP.> <-j$num_cpus>
selected build <-p> <-P> <arca.gpr> <-j$num_cpus>
selected install <-p> <-P> <arca.gpr> <--prefix=$scratch/install prefix>
selected clean <-P> <examples/client/client.gpr> <-aP.>
selected clean <-P> <arca.gpr>
EOF
if [ "$(cat "$ARCA_TEST_MAKE_TOOL_LOG")" != "$(cat "$scratch/expected.log")" ]; then
    printf 'Unexpected Make tool invocations:\n' >&2
    cat "$ARCA_TEST_MAKE_TOOL_LOG" >&2
    printf 'Expected:\n' >&2
    cat "$scratch/expected.log" >&2
    failed=$((failed + 1))
fi
test "$failed" -eq 0
printf 'Make preserves selected executable paths and arguments\n'

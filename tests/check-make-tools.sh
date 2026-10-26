#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later

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
ln -s /bin/true "$scratch/project/scripts/check-test-tools.sh"
ln -s /bin/true "$scratch/project/tests/check-cpio.py"
ln -s /bin/true "$scratch/project/tests/check-tar.py"
ln -s /bin/true "$scratch/project/tests/check-unit.py"
ln -s /bin/true "$scratch/project/tests/check-cli.py"
ln -s /bin/true "$scratch/project/tests/check-style.py"
ln -s /bin/true "$scratch/project/tests/check-packaging.py"
ln -s /bin/true "$scratch/project/tests/check-api.py"
for script in check-preflight check-make-tools; do
    ln -s /bin/true "$scratch/project/tests/$script.sh"
done
# Installation helpers must receive file-origin selections, not just the
# command-line values that GNU Make exports automatically.
cat >"$scratch/project/tests/check-install.sh" <<'EOF'
#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
set -eu
if [ "${GPRCLEAN:-}" != "$ARCA_TEST_EXPECT_CLEANER" ]; then
    printf 'Installation helper lost the selected GPRCLEAN\n' >&2
    exit 1
fi
EOF
chmod +x "$scratch/project/tests/check-install.sh"
ln -s check-install.sh "$scratch/project/tests/check-install-tools.sh"
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
ARCA_TEST_EXPECT_CLEANER="$scratch/selected tools/selected clean"
export ARCA_TEST_EXPECT_CLEANER
printf 'override GPRBUILD := %s\n' "$scratch/selected tools/selected build" \
    >"$scratch/selected.mk"
printf 'override GPRINSTALL := %s\n' "$scratch/selected tools/selected install" \
    >>"$scratch/selected.mk"
printf 'override GPRCLEAN := %s\n' "$ARCA_TEST_EXPECT_CLEANER" \
    >>"$scratch/selected.mk"

failed=0
for target in check install uninstall clean; do
    if ! (
        unset GPRBUILD GPRINSTALL GPRCLEAN
        "$make_command" --no-print-directory -C "$scratch/project" \
            -f "$repo_root/Makefile" -f "$scratch/selected.mk" \
            "$target" NUM_CPUS="$num_cpus" PREFIX="$scratch/install prefix"
    ); then
        failed=$((failed + 1))
    fi
done

cat >"$scratch/expected.log" <<EOF
selected build <-p> <-P> <arca.gpr> <-j$num_cpus> <-XARCA_BUILD_MODE=validation>
selected build <-p> <-P> <cli/cli.gpr> <-aP.> <-j$num_cpus> <-XARCA_BUILD_MODE=validation>
selected build <-p> <-P> <examples/client/client.gpr> <-aP.> <-j$num_cpus> <-XARCA_BUILD_MODE=validation>
selected build <-p> <-P> <tests/tests.gpr> <-j$num_cpus> <-XARCA_BUILD_MODE=validation>
selected build <-p> <-P> <arca.gpr> <-j$num_cpus> <-XARCA_BUILD_MODE=validation>
selected build <-p> <-P> <cli/cli.gpr> <-aP.> <-j$num_cpus> <-XARCA_BUILD_MODE=validation>
selected install <-p> <-P> <arca.gpr> <--prefix=$scratch/install prefix> <-XARCA_BUILD_MODE=validation>
selected install <-p> <-P> <cli/cli.gpr> <-aP.> <--prefix=$scratch/install prefix> <--mode=usage> <--no-project> <--install-name=arca-cli> <-XARCA_BUILD_MODE=validation>
selected install <--uninstall> <--prefix=$scratch/install prefix> <arca-cli>
selected install <--uninstall> <--prefix=$scratch/install prefix> <arca>
selected clean <-P> <examples/client/client.gpr> <-aP.> <-XARCA_BUILD_MODE=validation>
selected clean <-P> <cli/cli.gpr> <-aP.> <-XARCA_BUILD_MODE=validation>
selected clean <-P> <cli/cli.gpr> <-aP.> <-XARCA_CLI_COVERAGE=enabled> <-XARCA_BUILD_MODE=validation>
selected clean <-P> <arca.gpr> <-XARCA_BUILD_MODE=validation>
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

# Development guide

## Reference environment

Validate changes in Debian 13 (Trixie), using GNAT and GPRbuild. The development
Dockerfile installs build tools while constructing the image. Runtime build
and test steps do not install packages. The launcher maps the invoking user
and group into the container and supplies `HOME=/tmp`.

```sh
docker/dev/build
docker/dev/run arca-dev:trixie make -j8 check NUM_CPUS=8
```

Local builds and GitHub CI use `docker/dev/build` and `docker/dev/run`.
Both default to `linux/amd64`, matching the reference CI architecture.
The build wrapper defaults to the tag `arca-dev:trixie` and accepts `--tag`.
Both wrappers accept `--platform linux/arm64` for explicit native ARM builds:

```sh
docker/dev/build --platform linux/arm64 --tag arca-dev:arm64
docker/dev/run --platform linux/arm64 arca-dev:arm64 make -j8 check NUM_CPUS=8
```

Clean generated objects before switching architectures in one checkout.
The wrappers select their containing repository from any working directory,
including paths with spaces. Normal runs use the invoking UID/GID and
`HOME=/tmp`; `--root` is an explicit exception when container root is needed.
They do not install tools during a build or test run.

The image tag follows Debian's Trixie updates; it is not an immutable image
digest and does not promise bit-reproducible toolchains. The GitHub workflow
builds this Dockerfile and runs the standalone coverage target before any
other tests. It first asserts that `build/` does not exist, verifying that
coverage creates its own scratch parent without packaging or wrapper checks.
The normal check target follows. Python 3, GNU cpio, libarchive's
bsdtar and gcov are supplied by the development image; the test preflight
reports missing reader tools together.

With no explicit command, the launcher starts Bash and forwards standard
input, including piped commands. It allocates a TTY only when both its input
and output are terminals. Explicit commands run without forwarded input or
a TTY, so the build and test invocations remain suitable for CI.

`GPRBUILD`, `GPRINSTALL` and `GPRCLEAN` select individual executable names or
paths, including paths containing spaces. Make passes its selected values
explicitly to the tool preflight, so values assigned by a Makefile work like
command-line overrides. Missing tools are reported together using their
selected names or paths.

`make check` includes preflight regressions with a restricted fixture PATH.
The checks cover command-line selections, Makefile selections, default-name
fallback and missing selections even when default-name executables exist.
The recursive Make calls retain the outer build's jobserver; fixtures and
diagnostics live in a private temporary directory below `build/`.

The check target also exercises the real Make recipes in an isolated fixture
with executable paths containing spaces. Recording tools verify the selected
executable identities and argument boundaries for library and client builds,
installation and cleanup commands. The fixture replaces the consumer
checks to avoid recursion; the normal check target runs those checks with the
real compiler separately. It does not change the checkout's build artifacts.

`python3 tests/check-dev-shell.py IMAGE` runs on the Docker host, where Python
3 and Docker must already be available. It checks a default shell with piped
input, a default shell connected to a real pseudo-terminal and an explicit
batch command. The terminal sentinel is checked as a complete output line
after the container confirms its terminal fds, so echoed command text cannot
satisfy the assertion. CI runs these checks against its freshly built image.

For an ARM image, add `--platform linux/arm64` to the host-side shell check.
`python3 tests/check-dev-wrappers.py` separately checks wrapper defaults,
platform/tag selections, paths with spaces, root rejection and command
argument boundaries without a Docker engine. CI runs it before image builds.

## Project boundary

`arca.gpr` is a static Ada library with no Abuild or third-party project
imports. `Arca.CPIO` provides the first writer; `Arca.Binary_IO` is a private
implementation helper containing only the used stream-copy operation. Do not
add proposed format packages as empty API promises. Introduce each API with
its writer, documented constraints and independent tests.

`examples/client/client.gpr` imports the project by name. The installation
check copies this client, including its CPIO type use, into a private scratch
directory, removes inherited Ada/GPR search paths, and discovers Arca only
through the installed prefix. It also creates and closes a CPIO archive
through the installed API and checks its newc header and trailer.
It cleans that scratch directory on success, failure and handled signals.
The selected builder is resolved to an absolute executable path in the
caller's initial directory before entering the copied client. This preserves
both explicit relative overrides and tool names found through relative PATH
entries. Installation-tool regressions verify both variants and record that
the selected executable actually runs in the copied client's directory.
After the successful build, hiding the installed project must produce the
specific missing-import diagnostic. This negative control verifies that
the consumer cannot silently fall back to the original source project.

The consumer check establishes GPR packaging and compiler/linker usability.
The separate CPIO suite checks raw layout, payloads, two external readers,
parallel instances, errors, reproducibility and scope-exit cleanup. See the
[CPIO guide](cpio.md) for its contract and the optional predecessor check.
Ada checks currently run as direct executables with assertion helpers;
Python `unittest` orchestrates them and performs independent format checks.

`tests/tests.gpr` compiles source units into its own object directory so the
private copy helper can be tested by a private child without publishing it.
Installed-library usability is checked separately by the copied client.
Coverage uses distinct object and executable directories, clears previous
execution counts and checks `tests/coverage-sources.txt` against every current
production body. It requires a report with executed lines for each body;
the generated counts do not promise complete branch coverage.

## Commands

- `make -j8 all NUM_CPUS=8` builds the static library.
- `make -j8 check NUM_CPUS=8` runs packaging and CPIO format/lifecycle checks.
- `make -j8 coverage NUM_CPUS=8` reports executed lines for all production bodies.
- `make install PREFIX=/absolute/prefix` installs using GPRinstall.
- `make clean` removes generated GPRbuild artifacts.

Do not run independent top-level builds concurrently against `obj/`. Install
into an empty prefix or use GPRinstall's explicit uninstall/upgrade procedure.
Tests use a fresh prefix on every run.

## Consumers

GPRinstall copies `LICENSE` and `COPYRIGHT` to `<prefix>/share/doc/arca`.
The installation check compares both notices byte for byte with their source
files. Binary distributors must also provide the source and relinking material
described in the [licensing guide](licensing.md); installing licence notices
alone does not fulfil those requirements.

Add this import to the consuming GPR project:

```ada
with "arca";
```

For an installed library, pass `-aP<prefix>/share/gpr` to GPRbuild. For source
integration, pass the directory containing `arca.gpr`. Pin the dependency to
an accepted commit; do not depend on a moving branch for released builds.
Private repository access must be configured in every build environment.

Abuild integration is a later change: transformation adapters, source-file
inventory, coverage, dependency checkout, release licensing, manuals and
integration tests must change together. The bootstrap does not modify Abuild.

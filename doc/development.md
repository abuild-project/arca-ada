# Development guide

## Reference environment

Validate changes in Debian 13 (Trixie), using GNAT and GPRbuild. The development
Dockerfile installs build tools while constructing the image. Runtime build
and test steps do not install packages. The launcher maps the invoking user
and group into the container and supplies `HOME=/tmp`.

```sh
docker build -t arca-dev:trixie -f docker/dev/Dockerfile .
docker/dev/run arca-dev:trixie make -j8 check NUM_CPUS=8
```

The image tag follows Debian's Trixie updates; it is not an immutable image
digest and does not promise bit-reproducible toolchains. The GitHub workflow
builds this Dockerfile and runs the same check command.

With no explicit command, the launcher starts Bash and forwards standard
input, including piped commands. It allocates a TTY only when both its input
and output are terminals. Explicit commands run without forwarded input or
a TTY, so the build and test invocations remain suitable for CI.

`GPRBUILD`, `GPRINSTALL` and `GPRCLEAN` select individual executable names or
paths. Make passes its selected values explicitly to the tool preflight, so
values assigned by a Makefile work like command-line overrides. Missing tools
are reported together using their selected names or paths.

`make check` includes preflight regressions with a restricted fixture PATH.
The checks cover command-line selections, Makefile selections, default-name
fallback and missing selections even when default-name executables exist.
The recursive Make calls retain the outer build's jobserver; fixtures and
diagnostics live in a private temporary directory below `build/`.

`python3 tests/check-dev-shell.py IMAGE` runs on the Docker host, where Python
3 and Docker must already be available. It checks a default shell with piped
input, a default shell connected to a real pseudo-terminal and an explicit
batch command. The terminal sentinel is checked as a complete output line
after the container confirms its terminal fds, so echoed command text cannot
satisfy the assertion. CI runs these checks against its freshly built image.

## Project boundary

`arca.gpr` is a static Ada library with no Abuild or third-party project
imports. Only the root namespace exists in this revision. Do not add proposed
format packages as empty API promises. Introduce each API with its writer,
documented constraints and independent tests.

`examples/client/client.gpr` imports the project by name. The installation
check copies this client into a private scratch directory, removes inherited
Ada/GPR search paths, and discovers Arca only through the installed prefix.
It cleans that scratch directory on success, failure and handled signals.
The selected builder is resolved to an absolute executable path in the
caller's initial directory before entering the copied client. This preserves
both explicit relative overrides and tool names found through relative PATH
entries. Installation-tool regressions verify both variants and record that
the selected executable actually runs in the copied client's directory.
After the successful build, hiding the installed project must produce the
specific missing-import diagnostic. This negative control verifies that
the consumer cannot silently fall back to the original source project.

The check establishes GPR packaging and compiler/linker usability. It cannot
establish archive correctness, payload handling, concurrency or performance;
those checks arrive with the format implementations. There are no production
package bodies to include in a coverage inventory yet.

## Commands

- `make -j8 all NUM_CPUS=8` builds the static library.
- `make -j8 check NUM_CPUS=8` builds and runs both client configurations.
- `make install PREFIX=/absolute/prefix` installs using GPRinstall.
- `make clean` removes generated GPRbuild artifacts.

Do not run independent top-level builds concurrently against `obj/`. Install
into an empty prefix or use GPRinstall's explicit uninstall/upgrade procedure.
Tests use a fresh prefix on every run.

## Consumers

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

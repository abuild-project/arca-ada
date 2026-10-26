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
The normal check target follows. Python 3, GNU cpio/tar, libarchive's bsdtar,
gcov and Ahven (`libahven-dev`) are supplied by the development image. The
test preflight reports missing tools and an unavailable test project.

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
argument boundaries without a Docker engine. CI runs it after the fresh-source
coverage check so it cannot create coverage's scratch parent in advance.

## Project boundary

`arca.gpr` is a static Ada library with no Abuild or third-party project
imports. `Arca.CPIO` and `Arca.TAR` expose format-specific APIs;
`Arca.Binary_IO` is their private implementation helper containing only the
used stream-copy operation and best-effort cleanup shared by both writers.
Do not add empty API promises for proposed format packages. Introduce each API
with its writer, documented constraints and independent tests.

`cli/cli.gpr` imports the library and builds `cli/bin/arca`. Argument policy,
filesystem inventory and hardlink maps belong to this CLI consumer. Its Ada
containers are invocation-local and used sequentially; integration tests run
separate CLI processes against an immutable input tree. The library remains
Ada-only and does not depend on the CLI or its C code. The CLI's initial
platform is 64-bit Linux; the reference validation uses AMD64 Trixie.

GNAT supplies path normalization and a raw directory-name iterator. The
higher-level Ada.Directories search also queries modification times through
an API that rejects dangling links and special nodes. The raw iterator lets
the CLI inspect every name with lstat. The only C wrapper,
`cli/src/posix_bridge.c`, converts lstat metadata to a fixed-width record and
keeps platform stat layout and type/device macros behind that boundary.
readlink, mkdtemp, rename and renameat2 are direct Ada bindings; errno is
captured before allocating diagnostic strings, and readlink's returned byte
count determines the target slice without assuming a NUL terminator.
SIGINT/SIGTERM handlers and their shared signal state use an Ada protected
object, following the existing Abuild pattern through independently authored
CLI code. No Abuild helper is imported. See the [CLI guide](cli.md) for the
stable-input contract, format limits and cancellation boundaries.

`examples/client/client.gpr` imports the project by name. The installation
check copies this client, including CPIO and TAR writer record components,
into a private scratch directory, removes inherited Ada/GPR search paths,
and discovers Arca only through the installed prefix. Through the installed
APIs it creates and closes CPIO and TAR archives, checks the newc header and
trailer, and compares empty TAR output with exactly two zero blocks. It also
emits GNU long-name metadata, compares the archive with the source-built TAR
driver and checks its synthetic record's mtime against the UTC UNIX epoch.
This exercises package initialization through the installed static library.
It cleans that scratch directory on success, failure and handled signals.
The selected builder is resolved to an absolute executable path in the
caller's initial directory before entering the copied client. This preserves
both explicit relative overrides and tool names found through relative PATH
entries. Installation-tool regressions verify both variants and record that
the selected executable actually runs in the copied client's directory.
After the successful build, hiding the installed project must produce the
specific missing-import diagnostic. This negative control verifies that
the consumer cannot silently fall back to the original source project.
The check uses the actual Make installation recipe, verifies the `arca` and
`arca-cli` manifests, uninstalls both and installs again. An unrelated prefix
file must survive removal unchanged; no Arca-installed files may remain.

`tests/check-api.py` builds record-component clients against the ordinary
library and an installed regular static extending-project view, matching
Abuild's binder ownership without importing Abuild. Compiler negative
controls reject direct lifecycle calls, controlled-parent conversion and
attempted lifecycle overrides. Selected build and installation executables
are resolved before entering the private consumer directories.

The consumer check establishes GPR packaging and compiler/linker usability.
The separate CPIO and TAR suites check raw layout, payloads, two external
readers, parallel instances, errors, reproducibility and scope-exit cleanup.
See the [CPIO guide](cpio.md) and [TAR guide](tar.md) for their contracts.
TAR also retains the historical GNU ustar fixture with its original producer
record; it is checked without device-node privileges.
Named Ahven suites call the shared Ada assertion scenarios directly and add
focused writer-reuse and copy tests. The small archive drivers reuse those
scenarios for Python `unittest` and independent format checks. The
[unit-test guide](unit-tests.md) explains the suites, source-test mapping,
fixture ownership, XML reports and deliberate runner failure controls.
The [predecessor-case mapping](native-test-coverage.md) identifies each original
writer assertion and the transformation behavior intentionally left in Abuild.

`tests/tests.gpr` compiles source units into its own object directory so the
private copy helper can be tested by a private child without publishing it.
Only this test project imports Ahven; the library, CLI and installed client
do not.
Installed-library usability is checked separately by the copied client.
Coverage uses distinct object and executable directories, clears previous
execution counts and checks `tests/coverage-sources.txt` against every current
production body, including the CLI's Ada and C sources. It requires a report
with executed lines for each body; the generated counts do not promise
complete branch coverage.

Library, CLI and test compilation enable `-gnatVa`, `-fstack-check` and `-gnateE`
in addition to the existing warnings, overflow and normal Ada checks. These
match Abuild's extra validity/stack checks and exception-detail policy. GPR
imports do not inherit a parent's compiler defaults automatically.

The [coding-style guide](coding-style.md) is the normative standalone source
reference for library, CLI, tests and examples. AGENTS.md requires agents to
read it before editing code. All four compiling GPR projects enable
`-gnatygAdISuxM80` alongside warnings as errors during validation; coverage
retains the profile. The library's `ARCA_BUILD_MODE` scenario accepts `release`
and `validation`, defaulting to `release` for source consumers. Release omits
`-gnatwe` and `-gnaty` options while retaining `-gnatwa`, `-gnato`, `-gnatVa`,
`-fstack-check` and `-gnateE`. Unknown modes are rejected. The CLI, test and
example projects stay strict because they are maintained with the repository.
Every Make build and installation selects validation explicitly. CI also sets
the scenario in its environment, and standalone style, API and coverage
checks pass it explicitly to their builders.
The guide explains layout, declaration contracts, modern aspect forms and
the Ada 2012 baseline with deliberate GNAT runtime dependencies.

`make check` runs `tests/check-style.py` against private source copies through
each actual project. Forced semantic compilations must accept an 80-column
comment and reject an 81-column comment with the exact style diagnostic.
These controls detect a missing project profile without changing checkout
sources or relying on existing objects. The installed client remains
self-contained and does not import a source-checkout style project.

`tests/check-packaging.py` compiles private library copies with a harmless
81-column comment and an unused import. Release accepts both and reports the
warning; validation rejects the style violation. The observed compiler
invocation must retain runtime checks and the expected warning/style policy.
The same controls cover a regular static extending project with its own
`-cargs:Ada` argument. Abuild's extending project inherits the selected library
profile and can continue adding its compiler arguments; no Abuild file is
changed. Its installed record-component consumer is checked separately.
Cleanup is exercised with an intentionally missing imported test project,
even though the reference image itself supplies Ahven.

CLI regressions compile `tests/cli_faults.c` as a temporary preload library
with the image's GCC. Only selected CLI child processes load it; its trace
proves that each intended syscall fault was reached. Production code has no
fault switches or dependency on this library. It is test support, outside the
production-body coverage inventory. Native Linux temporary fixtures verify
timestamp storage, sparse-file sizes and special permission bits before
asserting archive behavior. Maximum-size acceptance reaches an intentionally
unreadable source; rejection at max+1 happens during inventory, without
creating multi-gigabyte archive payloads.

Phase-sensitive CLI tests use the same preload library to hold the child
after the successful staging-file open, before entry emission. One inherited
pipe acknowledges readiness; another requires an explicit release byte. The
parent checks that staging is empty and the destination is unchanged before
mutating input or sending signals. Interrupted pipe calls retry. Timeouts,
EOF and unexpected tokens fail readiness. Parent pipes and child processes
have exception-safe ownership; positive release, missing-hook and parent-error
controls check the protocol and descriptor cleanup with small input trees.
Cancellation also waits for a signal-specific acknowledgement before release.
In the supported GNAT 14 runtime, the dedicated interrupt server invokes the
protected handler between successive sigwait calls. The test shim observes
the next call on that same thread, proving the handler has returned; queuing
a signal alone is insufficient. This runtime-specific observation remains
test support and introduces no production signal hook.

## Commands

- `make -j8 all NUM_CPUS=8` builds the static library and CLI.
- `make -j8 cli NUM_CPUS=8` builds the CLI and its library dependency.
- `make -j8 check NUM_CPUS=8` runs packaging, unit, writer and CLI suites.
- `make -j8 coverage NUM_CPUS=8` reports executed lines for all production bodies.
- `make install PREFIX=/absolute/prefix` installs the library and CLI.
- `make uninstall PREFIX=/absolute/prefix` removes `arca-cli`, then `arca`,
  using their GPRinstall manifests. Unrelated prefix files are retained.
- `make clean` removes generated GPRbuild artifacts, including test objects
  and executables without loading the Ahven-dependent test project. It keeps
  `build/`, coverage and unit reports, and the default installation prefix.

Do not run independent top-level builds concurrently against `obj/`. Install
into an empty prefix or uninstall the existing installation first. Earlier
development installations used manifest name `cli`; remove those with
`gprinstall --uninstall --prefix=/absolute/prefix cli` before upgrading.
Tests use a fresh prefix on every run.

## Consumers

GPRinstall copies `LICENSE` and `COPYRIGHT` to `<prefix>/share/doc/arca`.
The installation check compares both notices byte for byte with their source
files. Binary distributors must also provide the corresponding source
described in the [licensing guide](licensing.md); installing licence notices
alone does not fulfil those requirements.

Add this import to the consuming GPR project:

```ada
with "arca";
```

For an installed library, pass `-aP<prefix>/share/gpr` to GPRbuild. For source
integration, pass the directory containing `arca.gpr`. Pin the dependency to
an accepted commit; do not depend on a moving branch for released builds.
Every build environment must be able to fetch the pinned Arca revision.

Abuild integration is a later change: transformation adapters, source-file
inventory, coverage, dependency checkout, release licensing, manuals and
integration tests must change together. A separate local integration experiment
does not become an Arca test dependency.

## Publication maintenance

Read the [publication checklist](publication.md) and
[reviewed assessment](assessments/publication.md) before preparing an owner
decision. [SECURITY.md](../SECURITY.md) defines reporting guidance; its presence
does not enable GitHub private reporting. Keep the published documentation
independent of local paths, private services and unrelated project material.
Record exact revisions and evidence limits rather than claiming that an old
audit certifies later code or repository settings.

# Arca

**Artifact Representation and Construction in Ada**

CPIO and TAR archive writers for Ada.

[Browse the documentation](https://abuild-project.github.io/arca-ada/) for
the CLI, CPIO and TAR writers, development and project guidance.

## Status

Arca provides an independent
[CPIO `newc` writer](doc/cpio.md), a [TAR writer](doc/tar.md), an
[archive creation CLI](doc/cli.md), a minimal library client,
installation checks and development infrastructure. The client verifies
project discovery and linking; format tests create and independently inspect
archives. Named [Ahven unit suites](doc/unit-tests.md) test library contracts.
Finalizer regressions cover nonregular outputs and failed deletion without
masking caller exceptions. Library, CLI and test builds enable full validity and
stack checks alongside the existing Ada checks.
The public API is in its `0.y` development phase.

Writers expose tagged limited private types with implicit scope cleanup.
CPIO entry operations select the file type and retain only caller permission
bits. Unsupported timestamps raise the writer's metadata exception, including
calendar-conversion failures.

The initial CLI targets 64-bit Linux with procfs mounted at `/proc/self/fd`.
The library has no procfs requirement. After building in the reference
environment, create an archive with:

```sh
cli/bin/arca create --format cpio -C rootfs -o rootfs.cpio
cli/bin/arca create --format tar -C contents -o contents.tar --mtime 0
```

The writers originate from Abuild, an Ada build system that constructs
Linux system images, packages and repositories from declarative component
trees. Abuild is Arca's main consumer and is not yet publicly available.
CPIO and TAR retain Abuild's format behaviour and add standalone resource
ownership. VFAT, EXT2 and ISO are later candidates. OCI requires
additional infrastructure decoupling. A native SquashFS writer remains
subject to its separate backend decision.

## Version and compatibility

Arca uses [Semantic Versioning 2.0](https://semver.org/spec/v2.0.0.html).
The single operative version is `Arca.Version.Value` in
[arca-version.ads](src/arca-version.ads); `arca --version` reports it as
`arca VERSION`. The `main` branch carries development sources. Published
tags and source archives are available from
[GitHub Releases](https://github.com/abuild-project/arca-ada/releases).

Public library interfaces are `Arca`, `Arca.CPIO`, `Arca.TAR` and the version
metadata in `Arca.Version`. `Arca.Binary_IO` is private; CLI implementation,
tests and development helpers are outside the library API.
Arca's policy for published `0.y.z` releases is source compatibility within
one minor line: patch releases preserve documented calls, exception contracts,
CLI options and exit statuses. Valid archive inputs retain their documented
format semantics. Diagnostic wording and help layout are not machine-readable
interfaces. Incompatible changes advance the minor line and appear
under **Breaking changes** in the changelog with migration guidance.
Development prereleases remain provisional; pin a revision for source builds.
No binary ABI compatibility is promised: rebuild the library and consumers
with a consistent toolchain when updating.

## Supported platforms

The supported reference is 64-bit Linux/AMD64, Debian 13 (Trixie), with
GNAT 14. Library conversions require 64-bit `Long_Integer` and
`Interfaces.C.long`; the CLI also requires the 64-bit Linux C ABI. 32-bit and
non-Linux platforms are outside this scope. ARM64 can be selected through the
development wrappers but has not been validated. Other compiler or target
combinations require their own evidence before support is claimed.

## Build and check

The reference environment is Debian 13 (Trixie), GNAT and GPRbuild. Build a
development image once, then run the checks without installing runtime tools:

```sh
docker/dev/build
docker/dev/run arca-dev:trixie make -j8 check NUM_CPUS=8
```

These are the same wrappers used by CI. Both select `linux/amd64` by default;
`--platform linux/arm64` selects ARM explicitly; the reference validation is
AMD64. The build wrapper also accepts `--tag IMAGE`.
See the [development guide](doc/development.md).

The launcher runs as the invoking user and supplies a writable temporary home.
Omit the command to open a Bash development shell with forwarded input and,
when launched from a terminal, a TTY:

```sh
docker/dev/run arca-dev:trixie
```

Explicit commands use batch mode. The host-side shell regression checks need
Python 3 and Docker: `python3 tests/check-dev-shell.py arca-dev:trixie`.

Inside the reference environment, the individual commands are:

```sh
make -j8 all NUM_CPUS=8
make -j8 check NUM_CPUS=8
make install PREFIX=/absolute/path/to/prefix
make uninstall PREFIX=/absolute/path/to/prefix
```

`all` builds the library and CLI. `check` also builds the client, installs
the library and CLI into a temporary prefix, and builds and runs a copied
client in isolation against the installed project.
It also verifies that hiding the installed project makes discovery fail.
Preflight regression checks cover selected and missing build-tool overrides.
Installation regressions cover relative builder paths and relative PATH
entries across the isolated client's directory change.
Make recipe regressions cover selected executable paths containing spaces.
These checks cover packaging and installed-library initialization, including
GNU long-name metadata. Separate format suites check archive conformance.
Installation uses the manifest names `arca` and `arca-cli`; uninstall removes
their files while preserving unrelated contents of the prefix.
`make clean` works without Ahven and retains `build/`, including reports and
the default installation prefix.

The same target runs Ahven suites and separately checks CPIO and TAR layout,
payloads, external readers, reproducibility, errors and lifetime behavior.
CLI checks cover directory traversal, source metadata, links, atomic
publication and cleanup after errors or handled signals. Normal tests need
no Abuild checkout, credentials or network access.
CLI failures retain low-level I/O diagnostics and reject incomplete directory
reads. No-clobber publication has a hard-link fallback for filesystems without
no-replace rename; staging cleanup is best effort and preserves command results.
The CLI retains output-directory identities through creation, publication and
cleanup, including when another local principal can rename entries in a shared
parent and the filesystem enforces the reported directory permissions.

Diagnostics keep complete CLI context and escape control bytes for display.
Directory-only output spellings are argument errors. SIGHUP, SIGINT and
SIGTERM request cleanup and return 129, 130 and 143 respectively. Help lists
long options, value forms and exit statuses; target constants come from the
CLI's C bridge. Source and archive names retain their original bytes.

`make -j8 coverage NUM_CPUS=8`
checks the production-body inventory and records executed lines. It also runs
from a fresh checkout before `make check`; it creates its scratch parent.
The [CPIO guide](doc/cpio.md) and [TAR guide](doc/tar.md) describe the APIs,
format profiles and validation contracts.

Select alternative GPR executables with the Make variables `GPRBUILD`,
`GPRINSTALL` and `GPRCLEAN`. Each value is one executable name or path,
including paths containing spaces. The preflight checks those selected
executables; unset variables use the standard names.

Consumers import `arca.gpr` with `with "arca";` and add the installed
`<prefix>/share/gpr` directory to their GPR search path. The root Ada package
is `Arca`. See the [development guide](doc/development.md).

Source consumers get `ARCA_BUILD_MODE=release` by default: warnings and runtime
checks remain enabled, while warnings-as-errors and compiler style checks are
omitted. Use `-XARCA_BUILD_MODE=validation` for the strict library profile.
Make targets and CI select validation explicitly; the CLI, tests and example
client remain strict in both modes.

## Licence

Arca uses [GPL-2.0-or-later](LICENSE); [COPYRIGHT](COPYRIGHT) identifies
project attribution and the licence terms. The CPIO, TAR and stream-copy
units derived from Abuild retain their original licence and attribution.
See [licensing](doc/licensing.md) for source origins, third-party terms and
corresponding-source requirements when distributing binaries.

## Roadmap

See the [plan index](doc/plans/README.md) and
[change records](doc/change-records/README.md). The next writer step is the
[VFAT format inventory](doc/plans/vfat-format-inventory.md), followed by
native VFAT, EXT2 and ISO work.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md), [AGENTS.md](AGENTS.md) and the project-wide
[coding-style guide](doc/coding-style.md) before editing sources. Its rules
apply to the library, CLI, tests and examples. Compiler style checks run in
repository Make builds and coverage; `make check` verifies that each project's
gate accepts the documented line limit and rejects an overlong source.

Use [SECURITY.md](SECURITY.md) for vulnerability reporting. The
[publication status](doc/publication.md) records the public repository
transition and later release work; the
[publication assessment](doc/assessments/publication.md) retains its evidence.

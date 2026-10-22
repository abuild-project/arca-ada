# Arca

**Artifact Representation and Construction in Ada**

Archive and filesystem image writers for Ada.

## Status

Arca is being bootstrapped in a private repository. It provides an independent
[CPIO `newc` writer](doc/cpio.md), a [TAR writer](doc/tar.md), an
[archive creation CLI](doc/cli.md), a minimal library client,
installation checks and development infrastructure. The client verifies
project discovery and linking; format tests create and independently inspect
archives. Named [Ahven unit suites](doc/unit-tests.md) test library contracts.
Finalizer regressions cover nonregular outputs and failed deletion without
masking caller exceptions. Library, CLI and test builds enable full validity and
stack checks alongside the existing Ada checks.
There is no stable format API or published release yet.

The initial CLI targets 64-bit Linux. After building in the reference
environment, create an archive with:

```sh
cli/bin/arca create --format cpio -C rootfs -o rootfs.cpio
cli/bin/arca create --format tar -C contents -o contents.tar --mtime 0
```

CPIO and TAR retain Abuild's format behaviour and add standalone resource
ownership. VFAT, EXT2 and ISO are later candidates. OCI requires
additional infrastructure decoupling. A native SquashFS writer remains
subject to its separate backend decision.

## Build and check

The reference environment is Debian 13 (Trixie), GNAT and GPRbuild. Build a
development image once, then run the checks without installing runtime tools:

```sh
docker/dev/build
docker/dev/run arca-dev:trixie make -j8 check NUM_CPUS=8
```

These are the same wrappers used by CI. Both select `linux/amd64` by default;
`--platform linux/arm64` selects ARM explicitly. The build wrapper also accepts
`--tag IMAGE`. See the [development guide](doc/development.md).

The launcher runs as the invoking user and supplies a writable temporary home.
Omit the command to open a Bash development shell with forwarded input and,
when launched from a terminal, a TTY:

```sh
docker/dev/run arca-dev:trixie
```

Explicit commands use batch mode. The host-side shell regression checks need
Python 3 and Docker: `python3 tests/check-dev-shell.py arca-dev:trixie`.

An existing Abuild Trixie image can also run these checks:

```sh
docker/dev/run abuild-dev make -j8 check NUM_CPUS=8
```

Inside the reference environment, the individual commands are:

```sh
make -j8 all NUM_CPUS=8
make -j8 check NUM_CPUS=8
make install PREFIX=/absolute/path/to/prefix
```

`all` builds the library and CLI. `check` also builds the client, installs
the library and CLI into a temporary prefix, and builds and runs a copied
client in isolation against the installed project.
It also verifies that hiding the installed project makes discovery fail.
Preflight regression checks cover selected and missing build-tool overrides.
Installation regressions cover relative builder paths and relative PATH
entries across the isolated client's directory change.
Make recipe regressions cover selected executable paths containing spaces.
These are packaging checks, not format-conformance tests.

The same target runs Ahven suites and separately checks CPIO and TAR layout,
payloads, external readers, reproducibility, errors and lifetime behavior.
CLI checks cover directory traversal, source metadata, links, atomic
publication and cleanup after errors or handled signals. Normal tests need
no Abuild checkout, credentials or network access.
CLI failures retain low-level I/O diagnostics and reject incomplete directory
reads. No-clobber publication has a hard-link fallback for filesystems without
no-replace rename; staging cleanup is best effort and preserves command results.
`make -j8 coverage NUM_CPUS=8`
checks the production-body inventory and records executed lines. It also runs
from a fresh checkout before `make check`; it creates its scratch parent.
The [CPIO guide](doc/cpio.md) and [TAR guide](doc/tar.md) describe the APIs,
format profiles and optional predecessor comparisons.

Select alternative GPR executables with the Make variables `GPRBUILD`,
`GPRINSTALL` and `GPRCLEAN`. Each value is one executable name or path,
including paths containing spaces. The preflight checks those selected
executables; unset variables use the standard names.

Consumers import `arca.gpr` with `with "arca";` and add the installed
`<prefix>/share/gpr` directory to their GPR search path. The root Ada package
is `Arca`. See the [development guide](doc/development.md).

## Licence

Arca uses [LGPL-2.1-or-later](LICENSE); [COPYRIGHT](COPYRIGHT) identifies
project attribution and the grant. Imported CPIO, TAR and copy-helper units
and the historical ustar fixture retain upstream attribution under the
recorded additional LGPL grant. See [licensing and provenance](doc/licensing.md)
for the grant scope and static-linking distribution requirements.

## Roadmap

See the [plan index](doc/plans/README.md) and
[change records](doc/change-records/README.md). Repository visibility and
publication remain owner decisions. The intended later home is
`abuild-project/arca-ada`; the initial home is `mweidle73/arca-ada`.

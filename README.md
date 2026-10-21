# Arca

**Artifact Representation and Construction in Ada**

Archive and filesystem image writers for Ada.

## Status

Arca is being bootstrapped in a private repository. This revision provides
the library project, a minimal client, installation checks and development
infrastructure. **No archive or filesystem writer has been imported yet.**
The client demonstrates project discovery and linking; it does not create an
archive. There is no stable format API or published release yet.

The first planned writers are CPIO and TAR, extracted from Abuild with their
existing behavior and independent format tests. VFAT, EXT2 and ISO are later
candidates. OCI requires additional infrastructure decoupling. A native
SquashFS writer remains subject to its separate backend decision.

## Build and check

The reference environment is Debian 13 (Trixie), GNAT and GPRbuild. Build a
development image once, then run the checks without installing runtime tools:

```sh
docker build -t arca-dev:trixie -f docker/dev/Dockerfile .
docker/dev/run arca-dev:trixie make -j8 check NUM_CPUS=8
```

The launcher runs as the invoking user and supplies a writable temporary home.
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

`check` builds the library and client, installs into a temporary prefix, and
builds and runs a copied client in isolation against the installed project.
It also verifies that hiding the installed project makes discovery fail.
These are packaging checks, not format-conformance tests.

Consumers import `arca.gpr` with `with "arca";` and add the installed
`<prefix>/share/gpr` directory to their GPR search path. The root Ada package
is `Arca`. See the [development guide](doc/development.md).

## Licence

The newly authored bootstrap is licensed under [BSD-3-Clause](LICENSE).
This grant does not relicense any existing Abuild source. The planned writer
extraction requires a per-file provenance review and an explicit additional
BSD grant from the relevant rights holders before GPL-covered code can be
included in the BSD library. See [licensing and provenance](doc/licensing.md).

## Roadmap

See the [plan index](doc/plans/README.md) and
[change records](doc/change-records/README.md). Repository visibility and
publication remain owner decisions. The intended later home is
`abuild-project/arca-ada`; the initial home is `mweidle73/arca-ada`.

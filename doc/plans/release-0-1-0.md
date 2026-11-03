# First versioned source release

Status: Accepted in `2c57cea` (PR #21) on 2026-11-03; `v0.1.0` published.

Base revision: `b14373e45f8b550794387ca86a099459576a239c`.

## Scope and decisions on 2026-11-03

Prepare Arca's first versioned source release using the maintained
[release procedure](../release.md). Change `Arca.Version.Value` to `0.1.0`,
reduce the first-release changelog to user- and integrator-relevant changes,
and remove statements that assume no release exists. Keep implementation
history, tests and publication evidence in the indexed records and guides.

Decision: publish a source archive and SHA-256 checksum, without prebuilt
binaries. The source-only path is the documented first-release path; binaries
would require separate toolchain, artifact and corresponding-source evidence.
The supported reference remains 64-bit Linux/AMD64 on Debian Trixie.

The existing TAR lifecycle interface break remains visible under Breaking
changes because users of development revisions may have used the controlled
parent. The first release does not create another API change.

## Changelog baseline correction on 2026-11-03

The first public release has no earlier public version to compare against.
The GPL decision and TAR lifecycle encapsulation happened during private
development. Keep their current terms and migration guidance in the licensing
and TAR guides, but omit Changed and Breaking changes sections that would
misrepresent them as changes between published releases. List only the
capabilities shipped in `0.1.0`.

## Preflight on 2026-11-03

The public repository had no open pull requests, issues, version tags or
GitHub releases at the time of inspection. The required Trixie workflow
passed on base revision `b14373e` in run `41640610774`. Library source, CLI
source and `arca.gpr` are unchanged since the public source revision
`e3892da`.
The downstream Abuild integration currently pins that earlier revision;
updating its submodule URL and pin belongs to the Abuild delivery topic, not
to Arca's source-release gate.

## Steps

1. Promote the version constant and prepare a concise dated `0.1.0`
   changelog section, retaining an empty Unreleased section. If acceptance
   and tagging occur on another date, update that section before acceptance.
2. Update README and publication guidance to avoid stale pre-release claims.
   Add an indexed change record for the release preparation.
3. Build and validate the candidate in rootless AMD64 Trixie. Verify CLI and
   installed-client versions, archive checks, coverage and documentation.
4. Review and accept the release change through a pull request, then inspect
   the CI run for that exact main commit.
5. Create an annotated tag on the accepted commit, build a deterministic
   source archive and checksum, and validate the unpacked tree. Publish the
   verified tag and artifacts only after the final release decision.

## Candidate validation on 2026-11-03

The Trixie development image built from the repository Dockerfile. A Git
archive of the candidate commit contained licence notices, source, GPR
projects, build scripts and fixtures, without Git metadata or build output.
The image reported GNATLS 14.2.0 and Debian GPRbuild package 2025.0.0-4.
Its unpacked tree passed rootless AMD64 Trixie coverage before the full
check target, in separate invocations. The check includes installed-library
and CLI consumers, independent format readers and the public API boundary.
Both the built CLI and example client reported `0.1.0`. The strict docs
target passed. A `gzip -n` source archive passed its SHA-256 checksum check.
ARM64 remains selectable but unvalidated. These candidate checks do not
replace CI and unpacked-source validation for the accepted main revision.

## Version-source evaluation on 2026-11-03

Abuild and Spawn Manager generate Ada version specifications through Make
from Git metadata. Arca also supports direct GPRbuild consumers and builds
the release source archive without `.git`. A generated specification would
need separately shipped version metadata and a fallback for those paths.
Retain the tracked pure `Arca.Version` specification for this release. Its
single value is checked against CLI and installed-client output; the release
procedure checks it against the planned tag before creating that tag.

## Release guidance alignment on 2026-11-03

The security policy now accepts reports for current `main` and the latest
published release while stating the `0.y` support limits. The changelog
briefly names the consumer compiler-profile selection and the CLI's procfs
requirement because both affect use of the first release. Existing detailed
guides remain the authoritative description of those contracts.

## Published source release on 2026-11-03

The annotated tag `v0.1.0` resolves to accepted merge commit
`2c57ceaec8bc867a4b02d8134bd0ab56b49413fa`. The required main workflow
run `41669851310` and the tag-triggered run `41676660662` passed. A fresh
source archive from that commit contained the expected notices, sources,
projects, scripts and fixtures without Git metadata or build output. Its
unpacked tree passed rootless AMD64 Trixie coverage before the full check,
in separate invocations. The CLI and installed client reported `0.1.0`.
The published `arca-0.1.0.tar.gz` asset has SHA-256
`c64644280fabf43ee863249f6732d6aef798b084b00d4d61a96df91897430b48`.
GitHub reports the release immutable, Latest and not a prerelease. It
contains a source archive and checksum, without prebuilt binaries.

# First versioned source release

Status: `0.1.0` candidate prepared; exact-revision validation pending.

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

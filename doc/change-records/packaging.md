# Consumer build profiles and installation

The library defaults to `ARCA_BUILD_MODE=release` for source consumers.
Warnings remain enabled, together with overflow, validity, stack and normal
Ada runtime checks. Warnings-as-errors and compiler style checks are selected
by `ARCA_BUILD_MODE=validation`; unknown mode values are rejected. CLI, test
and example projects retain their strict compiler policy in both modes.
Make builds, installation and standalone compilation checks explicitly select
validation, including coverage and the 80/81-column style controls. CI selects
the profile through those Make targets inside the container; the launcher
does not forward the host's build-mode environment variable.

An extending project inherits the selected library profile and retains its
own additional compiler arguments. Private compilation controls exercise
both profiles through a regular static extending project with `-cargs:Ada`.
The installed record-component consumer continues to check binder ownership.
Abuild files, writer APIs, runtime bodies and archive fixtures are unchanged.

`make clean` removes the test object and executable directories directly,
so it no longer loads their Ahven-dependent project. Other projects use the
selected GPRclean executable. `build/` remains intact, preserving coverage
and unit reports and the default installation prefix.

The CLI installs under manifest name `arca-cli`, alongside the library's
`arca` manifest. `make uninstall PREFIX=...` removes the CLI and then the
library using GPRinstall's manifests. Installation checks use the actual
Make recipes, verify both names and installed consumers, remove all installed
files while preserving an unrelated prefix file, and install again. Earlier
development installations with manifest name `cli` need that manifest removed
explicitly before upgrading; the development guide gives the command.

The TAR year-2300 check now also requires the existing conversion diagnostic.
The installed-consumer guide paragraph is rebalanced. CPIO and TAR format
contracts need no further guide changes because their behavior is retained;
the CLI guide describes only the installation change.

## Validation

Focused checks and the complete check pass in rootless AMD64 Debian Trixie
with GNAT 14.2. Against baseline
`089b32b766b142fff8ce5ffc1b78401789f690d9`, the default and explicit release
controls fail because strict style checks remain active. The cleanup control
fails while loading an intentionally unavailable test dependency. The
installation control fails because the CLI manifest is named `cli`, and an
unknown library mode does not receive the new typed-scenario rejection.
The baseline validation profile passes its positive control. The corrected
profiles retain runtime-check flags and visible warnings; explicit scenario
selections override the opposite environment setting.

Coverage completed first on fresh committed sources without a build directory
or Git metadata, followed by the complete normal check. Both targets pass
even with `ARCA_BUILD_MODE=release` in the container environment because builder
arguments explicitly select validation. All inventoried production bodies
have executed coverage. Every project's 80/81-column controls and the installed
ordinary and extending-project consumers pass. Recursive Make invocations
retain the outer jobserver; standalone checks use the normal job budget.

The preserved valid archive corpus remains byte-identical, including GNU
reference output. In isolated source copies, changing only the TAR conversion
message is rejected by the year-2300 assertion, and omitting CLI uninstall is
rejected after library removal because installed CLI files remain.

Author review verified compiler-policy inheritance, exact diagnostic controls,
private fixture ownership, manifest removal, selected tool paths with spaces,
guide consistency and commit attribution. The changes introduce no production
concurrency or per-entry work. Semantic analysis loads the library project
and its complete symbol index; the separate Ahven test project is unavailable
to that analysis environment. The TAR test relies on source review and the
reference compiler and runtime suite. No ARM64 or newer-GNAT execution is
established by these checks.

Removing the unused host-side CI variable retains the existing container
commands and their explicit validation arguments. The launcher argument
checks pass on the host. The reference compiler and runtime results above
cover the unchanged build inputs.

Co-Authored-By: GPT-6 <noreply@openai.com>

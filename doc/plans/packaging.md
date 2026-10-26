# Consumer build profiles and installation

Status: Implemented and verified locally on `codex/packaging`.

Base revision: `089b32b766b142fff8ce5ffc1b78401789f690d9`.

## Decisions on 2026-10-26

- Default the library to `ARCA_BUILD_MODE=release`: retain warnings and all
  runtime checks, but omit warnings-as-errors and compiler style checks.
  `validation` retains the strict profile. Make targets, CI and compilation
  checks select validation explicitly, independently of the environment.
- Keep the CLI, tests and example client strict in both modes because they
  are maintained together. Source consumers can select the library profile;
  an extending project can still provide its own compiler arguments.
- Remove test object and executable directories directly during `clean` so
  missing Ahven cannot prevent cleanup. Retain `build/`, including reports
  and the default installation prefix; use manifest-based uninstall for the
  installed library and CLI.
- Install the CLI under manifest name `arca-cli` and add an `uninstall`
  target for `arca-cli` followed by `arca`. Verify that unrelated prefix
  contents survive and that installing again succeeds.
- Preserve writer APIs and archive bytes. Add the exact TAR year-2300
  diagnostic assertion and rebalance the installed-consumer guide paragraph.

## Implementation

1. Add focused profile, dependency-free cleanup and installation controls;
   demonstrate rejection of the baseline or a targeted regression.
2. Implement the build and manifest changes. Update affected guides,
   changelog, indexes and the canonical change record together. Assess the
   installed Abuild-style extending project without modifying Abuild.
3. Run coverage first on fresh sources, then the complete check, in rootless
   AMD64 Trixie. Confirm byte parity for valid archive scenarios and retain
   compiler 80/81-column controls for all four projects.
4. Complete author review, commit, push and open the topic pull request.
   Request Copilot review and wait. Merge remains a separate maintainer
   decision; the CLI topic starts only after this topic is accepted.

## Progress

Consumer, validation and extending-project compiler controls pass with
runtime checks retained. The baseline is rejected for consumer policy,
missing-test-dependency cleanup and CLI manifest naming. Coverage and the
complete check pass in that order on fresh committed sources, including an
opposite release-mode environment, installed consumers and uninstall/reinstall.
Recursive Make keeps the outer jobserver. The preserved valid archive corpus
is byte-identical. Isolated changes to the TAR conversion message and CLI
removal are rejected by their intended assertions. Source review, message and
documentation checks are complete; ARM64 and newer GNAT remain untested.

## CI validation on 2026-10-26

CI selects validation through the explicit arguments in its container-side
Make targets. The launcher does not forward the host build-mode environment,
so the unused job-level variable is removed. The release-mode environment
countercheck sets its value inside the container. Launcher behavior and
Abuild integration remain unchanged.

Co-Authored-By: GPT-6 <noreply@openai.com>

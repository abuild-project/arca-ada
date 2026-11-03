# Changelog

## Unreleased

### Breaking changes

- Hide the controlled parent and lifecycle hooks of `TAR_Archive_Type`.
  Callers using parent conversions or explicit `Initialize`/`Finalize` calls
  or overrides must use the writer API and implicit cleanup instead.

### Changes

- Record the accepted CLI staging fix and the public repository transition;
  align reporting, contribution and release guidance. Retain permanent
  downstream links and a Pages documentation site as later tasks.
- Retain CLI output-directory identities through archive creation,
  publication and bounded cleanup; accept read-only staging access while
  preserving primary failure diagnostics.
- Add a single public development-version constant and use it in CLI and
  installed-client output; document compatibility, platforms and releases.
- Guard centralized CLI exception raises against accidental bypasses.
- Retain complete CLI diagnostic context, escape control bytes for display
  and reject directory-only output spellings as argument errors.
- Read target errno and rename constants through the C bridge; handle SIGHUP
  with cleanup and exit 129 while retaining SIGINT/SIGTERM behavior.
- Complete CLI help with long options, value forms and exit statuses.
- Default source-library consumers to a release compiler profile while
  retaining strict repository validation and runtime checks in both modes.
- Clean test outputs without Ahven, retain reports and installations under
  `build/`, and support manifest-based uninstall with CLI name `arca-cli`.
- Retain Makefile-defined tool selections in recursive installation checks.
- Normalize CPIO permission bits and report unrepresentable timestamps through
  the format-specific metadata exception.
- Check installed GNU long-name initialization and writer record components
  through ordinary and extending library projects.
- Record accepted topics by merge commit and clarify reader, integration
  and architecture guidance while preserving historical documentation.
- Use GPL-2.0-or-later for the whole project; the CPIO, TAR and stream-copy
  units derived from Abuild keep their original licence and attribution.
- Use tool-neutral agent guidance and platform-independent change records.
- Add security reporting guidance, a publication checklist and a reviewed
  publication assessment; clarify provenance and remaining release gates.
- Document repository-wide Ada style and require agents to read it; enable
  compiler style checks for library, CLI, tests and examples with positive
  and negative project controls.
- Replace remaining older aspect pragmas, ASCII and numeric image spellings;
  align declarations and separate logical phases without changing writer APIs.
- Add a Linux CLI for creating uncompressed CPIO and TAR archives, preserving
  metadata and links with deterministic ordering and atomic publication.
- Test installed CLI execution, independent readers, metadata overrides,
  relative paths, option forms, cancellation, source changes and output
  preservation; cover CLI Ada/C bodies.
- Synchronize phase-sensitive CLI tests with an acknowledged child barrier
  and completed signal dispatch instead of staging polling and delayed SIGSTOP.
- Handle CLI signals in Ada and bind simple system calls directly, retaining
  C only for the lstat metadata wrapper.
- Express CLI foreign interfaces with Ada 2012 aspects.
- Preserve CLI I/O diagnostics, reject directory-read failures, make staging
  finalization nonthrowing and enable the stronger runtime checks for the CLI.
- Add a hard-link no-clobber fallback and regression checks for publication,
  cleanup, source metadata/size bounds, FIFO outputs, ordering and mode bits.
- Preserve caller exceptions during writer finalization and attempt stream
  closure when unfinished-output deletion fails; cleanup is best effort.
- Add finalizer-failure Ahven cases and enable full validity, stack and
  additional exception-information checks for library/test builds.
- Add named Ahven unit suites with shared direct checks, writer-reuse and
  copy-helper cases, XML reports and runner failure controls.
- Pin the remaining predecessor CPIO/TAR raw-field, padding, long-metadata
  and reader assertions with an individual test-case mapping.
- Add the standalone TAR writer with retained ustar/GNU bytes, controlled
  output ownership and independent format/reader checks.
- Preserve the historical GNU ustar fixture and verify the installed TAR API.
- Add the independent CPIO `newc` writer and private stream-copy helper.
- Remove unfinished CPIO outputs on scope exit and preserve writer state when
  a second Create is rejected.
- Add raw-layout, reader, lifecycle and coverage checks.
- Run standalone coverage from a fresh checkout and check that order in CI.
- Use shared development build/run wrappers locally and in CI, with explicit
  architecture selection and consistent AMD64 defaults.
- Bootstrap the Arca library project, independent client and installation check.
- Add a Trixie development image and GitHub Actions build checks.
- Record the licensing boundary and staged writer-extraction plan.
- Forward input and provide a terminal for the default development shell,
  while preserving noninteractive explicit commands.
- Check selected GPR executable overrides during build-tool preflight.
- Preserve relative builder selections when checking the installed client.
- Preserve selected GPR executable paths containing spaces in Make recipes.

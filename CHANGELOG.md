# Changelog

## Unreleased

- Add a Linux CLI for creating uncompressed CPIO and TAR archives, preserving
  metadata and links with deterministic ordering and atomic publication.
- Test installed CLI execution, independent readers, metadata overrides,
  cancellation, source changes and output preservation; cover CLI Ada/C bodies.
- Handle CLI signals in Ada and bind simple system calls directly, retaining
  C only for the lstat metadata wrapper.
- Preserve caller exceptions during writer finalization and attempt stream
  closure when unfinished-output deletion fails; cleanup is best effort.
- Add finalizer-failure Ahven cases and enable full validity, stack and
  additional exception-information checks for library/test builds.
- Add named Ahven unit suites with shared direct checks, writer-reuse and
  copy-helper cases, XML reports and runner failure controls.
- Pin the remaining predecessor CPIO/TAR raw-field, padding, long-metadata
  and reader assertions with an individual test-case mapping.
- Add the standalone TAR writer with retained ustar/GNU bytes, controlled
  output ownership, independent format/reader checks and predecessor parity.
- Preserve the historical GNU ustar fixture and verify the installed TAR API.
- Adopt LGPL-2.1-or-later before writer imports, record the additional import
  grant and install the complete licence and project copyright notice.
- Add the independent CPIO `newc` writer and private stream-copy helper.
- Remove unfinished CPIO outputs on scope exit and preserve writer state when
  a second Create is rejected.
- Add raw-layout, reader, parity, lifecycle and coverage checks.
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

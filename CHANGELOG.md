# Changelog

## Unreleased

- Adopt LGPL-2.1-or-later before writer imports, record the additional import
  grant and install the complete licence and project copyright notice.
- Add the independent CPIO `newc` writer and private stream-copy helper.
- Remove unfinished CPIO outputs on scope exit and preserve writer state when
  a second Create is rejected.
- Add raw-layout, reader, parity, lifecycle and coverage checks.
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

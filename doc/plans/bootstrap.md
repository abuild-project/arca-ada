# Repository bootstrap

Status: Implemented on 2026-10-21. Authorized on 2026-10-21.

## Accepted decisions

- Project name: Arca, expanded as Artifact Representation and Construction
  in Ada.
- Initial repository: private `mweidle73/arca-ada`.
- Intended later home: `abuild-project/arca-ada`, through a separate transfer.
- Root package: `Arca`; project: `arca.gpr`.
- Licence target: BSD-3-Clause, with a separate grant required for existing
  GPL-covered source.

## Bootstrap scope

Prepare the library project, client, installation check, Trixie environment,
GitHub CI, contribution guidance and the extraction/licensing plan. Keep the
current Abuild checkout unchanged. Do not import writers, publish a release,
register an Alire crate or change repository visibility in this step.

## Acceptance checks

- Build without warnings in the supported Trixie environment.
- Run a source-tree client and an installed-project client.
- Validate clean rebuilding under outer Make parallelism.
- Inspect Ada project loading, anchored symbols and file-scoped diagnostics.
- Review the final diff, source style, licensing claims and generated files.
- Confirm the GitHub repository is private and read actual CI results.

## Progress

The private repository has been created and the bootstrap is published on
`codex/bootstrap` for review against `main`. The local Trixie build, clean
rebuild, installed-consumer check and missing-install negative control pass.
Ada MCP loads both projects completely and reports no diagnostics for either
Ada source.

The [GitHub bootstrap workflow](https://github.com/mweidle73/arca-ada/actions/runs/39592187985)
also passes. Its job status and logs confirm the fresh checkout, construction
of the repository's Trixie image, warning-free build, installed-consumer check
and negative control. No format source has been imported, no Abuild dependency
has been changed and no release or public publication has been made.

## Review follow-up

The owner requested both Copilot corrections on 2026-10-21. Keep the existing
format and licensing boundaries while correcting the launcher and preflight.

| Item | Status | Evidence |
| --- | --- | --- |
| Default shell input and TTY | Implemented | Real-container tests reject the old launcher for pipe and terminal input; the explicit batch case already passes |
| Selected preflight tools | Implemented | Restricted-PATH tests reject the old preflight's handling of valid and missing selections; Makefile and command-line values now pass through explicitly |

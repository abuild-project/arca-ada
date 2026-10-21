# Repository bootstrap

Status: In progress. Authorized on 2026-10-21.

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

The private repository has been created. The local Trixie build, clean
rebuild, installed-consumer check and missing-install negative control pass.
Ada MCP loads both projects completely and reports no diagnostics for either
Ada source. Final remote initialization and CI verification remain pending.

The prepared source is committed locally on `codex/bootstrap`. The GitHub
default branch currently contains only the generated README and licence.
The session permits a host-side `git fetch`, but not a host-side `git push`;
the sandboxed push cannot resolve GitHub. The API upload also requires the
missing OAuth `workflow` scope because it includes a new Actions file.
Resume through an authorized host push or after the appropriate API grant.

# Library API and metadata contracts

Status: Planned on `codex/api-hardening`.

Base revision: `0da408688b04bfc27da4cd9072c2b513a9891679`.

## Decisions on 2026-10-25

- Hide TAR's controlled parent and lifecycle operations behind a tagged
  limited private view, matching CPIO. Keep normal writer calls and use as a
  record component available.
- Select CPIO entry kinds from the writer operation and retain only
  `8#7777#` from caller mode values. Preserve bytes for permission-only inputs.
- Map time-conversion failures to each format's Unsupported_Metadata,
  including UTC timestamps in 2300.
- Exercise GNU long-name metadata through a separately installed consumer
  and compare its output with the source-built driver. Correct elaboration
  only if that test demonstrates a missing initialization.
- Keep the begun CLI worktree, CLI behavior and Abuild sources unchanged.
  Assess Abuild's extending project and record-component use explicitly.

## Implementation

1. Commit this plan, then add focused API, mode, time and installed-consumer
   checks. Demonstrate failures against the unchanged implementation and
   preserve baseline archives for valid existing inputs.
2. Implement the library corrections and update the affected guides,
   changelog and canonical change record together.
3. Run coverage first on fresh sources, followed by the complete check, in
   rootless AMD64 Trixie. Verify archive-byte parity, the GNU fixture,
   installed initialization and an Abuild-style extending-project consumer.
4. Review and commit the completed topic, then open its pull request.
   Packaging, CLI polish and release basics start only after this topic is
   accepted. Tags, releases and the final version change remain maintainer
   actions.

Co-Authored-By: GPT-6 <noreply@openai.com>

# LGPL licensing

Status: Accepted in `1bca4a7` (PR #2) on 2026-10-22. Superseded by GPL
licensing in `2091ca9`.

## Accepted decisions

- Use `LGPL-2.1-or-later` for the project and new contributions.
- Record the owner's additional LGPL grant for the identified CPIO/TAR scope.
- Prepare a separate PR against the accepted bootstrap before writer imports.
- Remove the superseded licence text and references from the maintained tree.
- Preserve attribution, upstream source metadata and third-party terms.
- Keep repository visibility and publication unchanged.

## Acceptance

- Ship the unmodified LGPL 2.1 text and an explicit project grant.
- Use consistent SPDX identifiers and contribution/documentation guidance.
- Install and verify the licence and project notice with GPRinstall.
- Pass a clean Trixie check and complete Ada MCP project/file checks.
- Review the complete licence-only diff before creating the PR.

## Progress

Implementation is isolated on `codex/lgpl-licensing`, based on the accepted
bootstrap. The metadata-only provenance inventory is included; CPIO remains
on its separate unpublished topic. Validation and the final author review
pass and are recorded in the [change record](../change-records/lgpl-licensing.md).

## Disposition on 2026-10-23

Superseded by [GPL licensing](gpl-licensing.md). The maintained project uses
GPL-2.0-or-later, matching its Abuild-derived code. The additional LGPL grant
is no longer used by the maintained licensing policy; this earlier decision
remains historical evidence.

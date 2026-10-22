# LGPL licensing

Status: Authorized, implemented and locally validated on 2026-10-22.

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

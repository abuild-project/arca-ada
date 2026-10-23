# GPL licensing and documentation policy

Status: In progress on `codex/gpl-licensing`.

Base revision: `b5c0f114cb702686908326605913ef5e8f64a6f0`.

## Decisions on 2026-10-23

- Use GPL-2.0-or-later for project-owned maintained files. This matches the
  archive writers' original Abuild licence and the intended GPL use of the
  library, without maintaining a separate additional-licence policy.
- Retain original copyright notices and third-party terms. Record the exact
  Abuild source revision and imported operation scope in `doc/licensing.md`.
  Preserve the standard GPL text without modification.
- Retire the separate grant inventory, original-source snapshot proposal and
  predecessor-comparison machinery. Extraction parity is an initial migration
  result; ongoing checks use independent format assertions/readers and Abuild
  integration. The snapshot topic is not part of this change.
- Use the reviewed, tool-neutral agent guide for future maintained text.
  Historical records and dated sections retain their claims; obsolete links
  may become path/revision references to the immutable base revision.
- Retain the existing repository-protection policy and completed local Abuild
  integration statement. CLI behavior, repository settings, transfer,
  visibility and separate security work remain outside this topic.

## Implementation

1. Record the decisions and base revision before changing licensing files.
2. Update the licence text, notices, SPDX identifiers, agent/contributor
   guidance and maintained documentation together. Remove predecessor-only
   scripts/options/tests and obsolete provenance files. Preserve fixture
   bytes, runtime source tokens and GPR installation behavior.
3. Update historical reference targets without rewriting historical claims.
   Mark superseded licensing material in the indexes and append its dated
   disposition. Add the neutral change record.
4. Verify SPDX coverage, exact GPL text, unchanged runtime code, remaining
   references, relative links, source style and commit formatting. Run
   coverage first on fresh sources, then the complete normal check in
   rootless AMD64 Trixie. Confirm installation preserves the licence files.
5. Review the completed committed range and record observed evidence and
   limits. Keep the result local until a push or pull request is requested.

## Progress

The implementation starts from the accepted main revision. The separate
snapshot topic remains unchanged and unmerged.

Co-Authored-By: GPT-6 <noreply@openai.com>

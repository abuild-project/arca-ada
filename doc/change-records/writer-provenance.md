# Archive writer provenance

The first writer extraction now has an immutable source inventory and an
explicit additional LGPL-2.1-or-later grant, authorized on 2026-10-22 by the
repository owner acting for the upstream rights holder. It identifies the source
revision, individual source and fixture bytes, and recorded contributors.
It distinguishes candidate material from licensing context that stays
outside the import.

The provenance record
(`doc/provenance/cpio-tar.md` at revision
`b5c0f114cb702686908326605913ef5e8f64a6f0`) records the grant, CPIO's
upstream inspiration, fixture producer limits and the test split. Existing
GPL availability is preserved; no third-party source is relicensed.

This record imports no writer source. The separate licensing change includes
this metadata inventory before implementation. The user guide still accurately
reports that no writer exists. The licensing guide, extraction plan and
changelog record the completed prerequisite.

## Validation and review

Every inventory size, Git blob and SHA-256 digest was checked against the
accepted source commit. Per-file contributor lists were derived with rename
following; they are not represented as proof of rights ownership. The direct
writer/transformation distinction was checked against the test bodies.

The original inventory analysis on 2026-10-21 used Ada MCP against Abuild:
it loaded the source project completely, found CPIO declarations and call
sites with a complete index, and reported no CPIO body diagnostics. The selected
production files matched the recorded source revision. This is historical
source-navigation evidence, not a compiler or format validation result for Arca.

The final author review checked source-reference precision, grant scope,
documentation links, metadata accuracy and publication hygiene. This change
adds no executable sources, build requirements, mutable state or coverage
inventory entries, so no compiler, concurrency or performance check is added.

Co-Authored-By: GPT-6 <noreply@openai.com>

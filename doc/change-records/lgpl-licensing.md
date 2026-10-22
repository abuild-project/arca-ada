# LGPL licensing

Arca uses `LGPL-2.1-or-later` before introducing its first writer. The project
grant, source SPDX identifiers, contribution rules and maintained licensing
documentation use the same licence. The owner authorized this change and
expressly granted additional LGPL licensing for the identified CPIO/TAR
material on 2026-10-22; [the licensing guide](../licensing.md) records that
confirmation and the boundary for later imports.

The metadata-only CPIO/TAR provenance inventory is included with this licence
decision. It records exact source identities and the granted scope without
copying writer implementations or fixtures into the repository.

The root `LICENSE` contains the unmodified LGPL 2.1 text. `COPYRIGHT` retains
project attribution and states the version-2.1-or-later grant. GPRinstall
includes both files under `share/doc/arca`; the installation check requires
byte-identical copies. The guide explains source provision and relinking
requirements for static consumers.

This change contains no writer implementation, imported fixture or Abuild
dependency change. The existing user guide, development guide, contribution
rules, changelog and indexed plans/change records are updated together.
No Abuild User Manual change is needed because Abuild is unaffected.

## Validation

The clean source checkout passes `make -j8 check NUM_CPUS=8` in the AMD64
Trixie development image. Library and client builds are warning-free. The
installed consumer, missing-project negative control, tool overrides and
relative-builder checks pass; installed licence and copyright copies match
the originals byte for byte.

The full LGPL text matches the Trixie reference copy with SHA-256
`20e50fe7aae3e56378ebf0417d9de904f55a0e61e4df315333e632a4d3555d95`.
All 33 inventory sizes, Git blobs and SHA-256 digests match the accepted
upstream source revision. Maintained files contain no superseded licence
identifiers or text. Documentation links, final newlines, Ada line lengths
and whitespace checks pass.

Ada MCP returns complete exact project views for the library and client,
complete anchored symbol results and complete empty file diagnostics for both
Ada sources. Queries use the running server's stdio protocol. This confirms
project loading after the GPR installation change; compiler checks remain the
build authority.

The final author self-review read the complete diff, enclosing installation
logic and source inventory. It checked grant scope, attribution, licence-text
identity, documentation consistency, publication hygiene and commit limits.
The change adds no writer API, mutable state, production body or hot-path
operation, so format, concurrency, performance and coverage-inventory changes
are unnecessary. No hosted CI result is claimed before publication.

## Review lessons

- Removal completeness covers source identifiers, contributor guidance,
  plans, change records and the root licence in the same commit.
- Provenance metadata retains the original source licence, exact byte
  identities and third-party boundaries; the new grant is dated separately.
- The install assertions compare real files; existing client isolation still
  requires the specific missing-project failure when its GPR file is hidden.
- This record attributes licence notices and installation behavior to this
  change, and leaves writer implementation and runtime claims to later PRs.

Co-Authored-By: GPT-6 <noreply@openai.com>

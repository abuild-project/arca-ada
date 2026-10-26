# Version, compatibility and release procedure

Status: Planned on `codex/release-basics`.

Base revision: `953a257c1fcc235eb78aeaa8fb39b938f54342c0`.

## Decisions on 2026-10-26

- Use SemVer with `0.1.0-dev` until the first release. A pure public package,
  `Arca.Version`, owns the single operative version constant. CLI output and
  ordinary, installed and extending-project consumers use that constant.
- Export the version unit through the library interface. It adds metadata
  without changing existing writer declarations or archive bytes. Abuild's
  regular static extending project retains its binder ownership and empty
  interface override; Abuild itself is unchanged.
- Define public writer and version interfaces. Published patch releases
  within one `0.y` line preserve documented source and CLI contracts;
  incompatible changes advance the minor line and require an explicit
  changelog entry and migration guidance. Development prereleases remain
  provisional. Consumers rebuild with the selected toolchain; no binary ABI
  promise is introduced.
- Document 64-bit Linux with 64-bit Long_Integer and Interfaces.C.long.
  AMD64 Debian Trixie with GNAT 14 is the validated reference. ARM64 can be
  selected but has no validation evidence. Do not broaden platform claims.
- Centralize the release procedure in `doc/release.md` and link it from the
  publication checklist. Version promotion, annotated tags, archive/checksum
  publication and releases remain explicit maintainer actions.
- Guard explicit CLI exception raises outside the diagnostic owner. Ignore
  comments and literals, retain positive controls and demonstrate rejection
  with isolated valid-Ada mutations.

## Implementation

1. Add version and diagnostic-source controls. Observe baseline outcomes,
   then add the public constant, CLI/client usage and interface export.
2. Document compatibility, platforms and the release procedure. Update the
   affected guides, changelog, indexes and canonical change record together.
3. Run coverage first on fresh committed sources, then the complete check,
   in rootless AMD64 Trixie. Verify installed version visibility, extending
   consumers, mutation sensitivity and unchanged CLI/writer archive bytes.
4. Complete author review, push and open a separate pull request; request
   Copilot and wait. Do not merge, tag, publish, transfer or change visibility.

Co-Authored-By: GPT-6 <noreply@openai.com>

# Ahven unit tests

Status: Implemented, locally validated and author-reviewed on 2026-10-22;
ready for external review.

## Scope

Add named Ahven suites for CPIO, TAR and the private stream-copy helper before
developing the separate CLI. Share existing direct Ada checks with archive
drivers; retain independent Python decoders, external readers, historical
fixtures and optional predecessor comparisons. No production API or writer
changes are planned.

Ahven is a test-only dependency supplied by Arca's own Trixie image. Build,
installation and library consumers must not import it. Normal tests and CI
must remain self-contained, with no Abuild source or credentials.

## Steps

1. Factor direct checks into reusable Ada scenario packages. Add named Ahven
   cases and focused failed-Create/closed-writer reuse checks. Keep temporary
   files private to each run and clean fixtures during exception unwinding.
2. Supply Ahven in the development image and wire the runner into normal and
   coverage checks. Verify text/XML reports and failure exit status.
3. Map the relevant predecessor tests to Arca's unit and independent format
   checks. Validate from fresh sources, update documentation and perform the
   final author review before submitting the separate PR.

## Acceptance

- Named, directly callable CPIO, TAR and copy-helper tests pass sequentially.
- A deliberately failing probe is reported and returns a failing exit code.
- Existing raw, reader, parity, parallel, ownership and packaging checks pass.
- Fresh-source coverage includes all production bodies; installed consumers
  remain independent of Ahven and Abuild.
- Ada MCP views and file diagnostics are complete for changed Ada units.

## Progress

Named suites, shared scenarios, failure controls, image dependency and CI XML
reports are implemented. Fresh-source coverage and normal checks pass without
network or Abuild access; both optional predecessor comparisons pass. A
missing-Ahven negative control and installed-consumer isolation confirm the
test-only dependency boundary. Final author review and two independent static
passes are complete. The XML-report finding is corrected and re-reviewed;
there are no remaining blocking or fix-before-PR findings. CLI development
stays separate; see the
[change record](../change-records/ahven-unit-tests.md) for evidence and limits.

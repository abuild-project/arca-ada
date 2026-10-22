# Ahven unit suites

Arca's CPIO, TAR and private-copy contracts have named Ahven cases. The test
project imports Ahven; the production library, public APIs and installed
consumer project remain unchanged. Normal tests and CI use only Arca's
sources and its development image, with no Abuild checkout or credentials.
The CLI remains a separate subsequent change.

Existing direct assertions are factored into shared scenario packages.
Ahven calls their procedures in process; the archive drivers use the same
procedures for the existing independent Python decoders and GNU/libarchive
readers. Statement comparison against the accepted TAR-import tree confirms
that those scenario bodies retain their executable statements. Optional
predecessor helpers copy the new scenario units alongside the thin drivers.

Focused new cases cover closed-writer reuse, retry after failed Create,
exact-buffer and empty copies, and missing-source copy recovery. Parallel
cases compare complete outputs on bounded worker stacks. Comparison
sensitivity checks reject changed bytes/lengths and verify descriptor cleanup.
The [unit-test guide](../unit-tests.md) maps predecessor behaviors to the
Ahven and independent format checks, including transformation-only exclusions.

Each unit run owns a private fixture root. Controlled fixtures remove their
own directories during normal exit and exception unwinding. The harness runs
text and XML modes sequentially, validates the complete suite/case inventory
and rejects failures, errors, skips and retained fixture directories. A
separate deliberately failing probe must return exit status 1 with the
assertion diagnostic and XML failure; it also verifies cleanup on failure.
The same orchestration path runs both modes and collects their failures,
retaining XML even when text-mode tests fail. Each mode has its own fixture
root. Probe reports are not retained among real test results.

Debian's `libahven-dev` is installed while building Arca's Trixie image.
Preflight checks resolve the test project before compilation and report
unavailable dependencies. Both `make check` and standalone coverage run the
Ahven harness. CI uses the same build/run wrappers and retains XML reports
through a pinned official upload action. Ahven is not vendored, and its ISC
terms remain identified separately in the licensing guide.

## Validation

The AMD64 Trixie image builds with Ahven 2.8-11. Warning-free test compilation,
normal checks and complete production coverage pass. Line counts remain
copy 42/42, CPIO 177/186 and TAR 190/193; the framework migration does not
claim increased line or exhaustive branch coverage. Both text/XML modes and
the deliberate-failure controls pass.

Coverage also passes first from a fresh source copy with no build artifacts,
no network and no Abuild mount. An initial preflight against the full test
project incorrectly required its output directories; the shared dependency-only
project removes that prerequisite. With the system GPR directory hidden,
preflight fails with the intended missing-Ahven diagnostic.

The full normal check also passes in that isolated source copy. With the
system GPR directory hidden, the library build and a freshly compiled
installed consumer still pass while the test preflight correctly rejects
missing Ahven. Both optional predecessor comparisons pass, including their
original-writer descriptor-leak negative controls.

The final validation review found that an early text-mode failure originally
prevented XML generation. The unchanged harness failed the regression with
no XML; the corrected harness retains the same failing assertion in XML and
still fails overall. Its integrated probe now pins this orchestration path.
The source/lifecycle review found no blocking or fix-before-PR findings.
Review of the report correction is pending.

The library, sources and coverage inventory have no
production changes. Abuild's User Manual, Developer Guide, dependencies and release
markers need no change because this topic only changes Arca's test setup.
Arca's README, developer guide, changelog and indexed plans describe it.

## Ada MCP

The analysis server initially could not resolve its missing Ahven project.
A private, ignored source view exported from the same Debian development
package supplies the dependency for semantic navigation; runtime/compiler
checks continue to use the installed package in the supported image. The
test project and anchored case symbols are complete. File-scoped diagnostics
are complete and empty for every new or changed Ada unit. Navigation from
the runner resolves the Ahven API in the prepared dependency view. This
confirmed the semantic dependency boundary without searching framework
sources broadly; it does not replace runtime/compiler evidence.

## Review lessons

- Independent byte decoders, historical producer data, external readers and
  corruption controls remain separate from production layout constants.
- Each fixture and writer owns its state; parallel cases share immutable
  source data and use per-instance outputs and bounded task stacks.
- UTC anchors and sparse rejected-size sources remain explicit. Full maximum
  payload completion and exhaustive filesystem faults are not claimed.
- Runner failure/report and comparator corruption controls prevent vacuous
  success. Cleanup is checked after both normal and exceptional execution.
- Coverage still runs first from fresh sources; packaging must not supply
  its scratch prerequisites. Production-body inventory is unchanged.

Co-Authored-By: GPT-6 <noreply@openai.com>

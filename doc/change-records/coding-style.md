# Repository-wide Ada coding style

Arca's layout and aspect guidance previously applied explicitly to CLI code,
while tests and examples had visible declaration/grouping differences. None
of the compiling projects enabled GNAT style checks. The remaining older
spellings also included test imports/task stacks and library control bytes.

The standalone doc/coding-style.md now governs library, CLI, tests, examples
and maintained GPR files. AGENTS.md requires agents to read it before editing;
README and the development guide link to the same reference. It specifies
three-space indentation, 80 columns, declaration/parameter alignment, separate
body is lines, blank-line grouping, adjacent semantic contracts and plain
separators. It distinguishes compiler-enforced syntax from review judgments,
current pragmas from equivalent aspects, and the Ada 2012 baseline from
deliberate GNAT runtime dependencies. Generated/third-party material retains
its producer's layout and imported public names remain unchanged.

All four compiling projects enable -gnatygAdISuxM80 with warnings as errors,
including normal and coverage builds and the independent client. This follows
Abuild's profile with Arca's explicit 80-column limit, without alphabetical
subprogram ordering. The short profile stays explicit in each project so the
copied installed client needs no source-tree build-profile dependency.

Source cleanup uses Import, Interrupt_Handler, Storage_Size and Pure aspects,
Ada.Characters.Latin_1.NUL and type-prefixed numeric Image. C symbols and ABI,
handler installation, task stack sizes and package purity are retained.
Numeric image blanks, archive control bytes and error-message spacing are
preserved. Remaining changes align declarations, expand body/handler layout,
separate phases and use GNAT's two-space comment prefix without removing
copyright or provenance notices. Public operation signatures and production
C code are unchanged.

The check target compiles private source copies through each actual project.
An 80-column comment must compile and an 81-column comment must fail at its
injected location with the GNAT style diagnostic. Forced semantic compilation
excludes stale-object success; fixtures copy bounded source directories and
do not modify the checkout. Make's selected-builder and path-with-spaces
regressions remain intact. Existing CI uses the same Docker/Make entry points.

## Validation and review

Complete normal checks and coverage pass in rootless AMD64 Trixie. Fresh
sources also pass coverage first and complete normal checks without network
or an Abuild mount. The production-body inventory is unchanged and every
body has executed coverage. Ahven, independent raw readers, external archive
readers, CLI fault/signal tests, installed-client isolation and selected-tool
controls retain their assertions. Optional predecessor comparisons remain
optional; this change does not import new predecessor source.

All four style controls pass with their project profiles. Disabling each
profile in private copies makes its control fail specifically because the
81-column source is accepted, while the 80-column control still compiles.
This proves sensitivity to missing enforcement without relying on matching
flag text or a compilation failure for an unrelated reason.

Author review checked all maintained Ada units and the complete patch:
enumerated syntax migrations and declaration ordering, unchanged archive/API
contracts and invocation ownership, bounded stacks, numeric image semantics,
test sensitivity and diagnostic anchoring, fixture cleanup, unchanged runtime
cost, source/header style, packaging and profile propagation. The CPIO/TAR
and CLI API guides need no changes because their interfaces and output
contracts are retained. Developer guide, README, agent entry point, changelog,
plans and this canonical record describe the new development contract.
Licensing/provenance grants and historical source identities remain intact;
Abuild integration and its manuals are outside this independent repository.

Ada MCP provides complete library, CLI and test project views with anchored
symbols and clean changed-file diagnostics. Test analysis uses the existing
semantic Ahven view from the reference package; compiler/runtime validation
uses installed Ahven in the standalone Trixie image. Independent static
reviews follow on the committed implementation before publication.

Co-Authored-By: GPT-6 <noreply@openai.com>

# Repository-wide Ada coding style

## Scope accepted on 2026-10-22

The owner requested a separate PR after the archive CLI merge: document an
agent-discoverable coding style, remove the identified older spellings and
layout inconsistencies, enable automatic style checks, run tests and coverage,
then publish the PR and request Copilot review.

The policy covers library, CLI, tests and examples. Keep the public APIs,
archive bytes, signal lifecycle and bounded test-task stacks unchanged. Retain
current elaboration/signal configuration pragmas and representation clauses.
Ada 2012 remains the language baseline; documented GNAT runtime APIs remain
supported. Use type-prefixed Image rather than relying on newer object syntax.

## Implementation and acceptance

1. Add doc/coding-style.md as the normative standalone reference. Require it
   from AGENTS.md and link it from README and the development guide. State
   layout, contracts, aspects, imports, language baseline and review limits.
2. Enable the Abuild-derived -gnatygAdISuxM80 profile in all four compiling
   projects, retaining Arca's explicit 80-column limit and warning-as-error
   policy. Do not add spawn_manager's alphabetical-subprogram requirement.
   Keep the copied installed client self-contained; do not introduce a build
   profile dependency on a source checkout. Verify each actual project gate
   with valid sources and a deliberately overlong source in private fixtures.
3. Replace remaining Import, Interrupt_Handler, Storage_Size and Pure pragmas
   with equivalent aspects; replace ASCII.NUL and Img and standardize numeric
   Image syntax. Apply the documented layout throughout maintained Ada code.
4. Preserve packaging, source provenance and the production-body inventory.
   Run complete checks and coverage in rootless AMD64 Trixie, including fresh
   sources without network or Abuild access. Perform author and independent
   static reviews, then publish a separate PR and request Copilot.

Compiler checks enforce their configured syntactic rules. Semantic contracts,
useful grouping and justified GNAT dependencies also require source review.

## Implementation on 2026-10-23

The standalone guide and agent/README/developer links are in place. All four
compiling projects enable the explicit style profile. Equivalent aspects,
Latin_1 control bytes and type-prefixed Image replace the inventoried older
spellings, retaining public names, ABI, signal lifecycle and test stack sizes.
Declarations, body layout, comment prefixes and processing groups follow the
project-wide guide. No production body or runtime dependency is added.

The project controls accept 80 columns and reject 81 with forced compilation
and exact diagnostic checks. Disabling the profile in each private project
copy makes that control fail at the intended missing-style-error assertion.
Complete normal checks and fresh-source coverage-first plus normal checks
pass rootless in AMD64 Trixie without network or an Abuild mount. Every
production body is covered. Final column/parameter-alignment corrections
preserve the validated token stream and do not alter statement locations.

Author review covered the complete source and documentation range, profile
scope and consumer isolation, syntax/ABI and serialization equivalence,
fixture sensitivity/ownership and unchanged concurrency/scaling. Source,
commit and publication hygiene are checked before independent static review.

## Review completed on 2026-10-23

Both independent static passes report no concrete findings. Source review
confirms the exact enumerated syntax migrations, ABI/signal/stack contracts,
unchanged literal values and retained numeric image blanks. Validation review
confirms all project profiles and coverage branches, positive/negative gate
controls, private fixture cleanup, selected-tool handling and agent discovery.

Complete normal checks and coverage pass on the final implementation after
the last horizontal alignment edits. All nine production bodies report
executed lines. Ada MCP now reports complete project views and complete empty
file diagnostics for every maintained Ada unit. Final author review confirms
that source/test inputs remain the reviewed and validated revision, commits
meet 50/72 limits and the worktree contains only the intended delivery.

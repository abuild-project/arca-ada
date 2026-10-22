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

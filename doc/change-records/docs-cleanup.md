# Documentation status and reader guidance

Plan status paragraphs and the sorted plan and change-record indexes identify
accepted topics by their immutable merge commits. The ongoing writer plan
distinguishes accepted writers, unit suites and CLI work from the completed
local integration experiment and the pending pinned Abuild integration.
Historical plan and record bodies retain their original claims.

The README introduces Abuild and the next integration and writer steps.
Build instructions use the standalone development image, and dependency
guidance requires access to the pinned revision without assuming repository
visibility or local infrastructure. Contribution guidance separates releases
and repository transfers from ordinary contributions. Publication guidance,
its assessment and security reporting policy remain unchanged.

The README and both development-wrapper help texts distinguish selectable
ARM builds from the AMD64 reference validation. Container invocation, library
and CLI behavior, build configuration, tests, licence texts and fixture bytes
are unchanged.

## Validation

Acceptance references and dates match the base revision's first-parent
merge history. File history confirms the writer-provenance acceptance
mapping. Both indexes are sorted, their existing scope text is retained and
relative Markdown links resolve. Pre-existing plan text outside its status
paragraph and historical record bodies match the base revision.

The changed-file inventory contains only Markdown and the two exact help
substitutions. Publication and security guidance, licence texts, production
and test sources and fixtures are byte-identical to the base. The legacy
wording scan leaves only an unchanged historical fixture producer record;
preserving that source evidence is intentional.

`python3 tests/check-dev-wrappers.py` passes on the host. It verifies wrapper
arguments and container invocation without a Docker engine. Compiler,
format, CLI and coverage checks were not rerun because runtime code, build
configuration and test inputs are unchanged. This change makes no new
runtime or ARM validation claim.

Co-Authored-By: GPT-6 <noreply@openai.com>

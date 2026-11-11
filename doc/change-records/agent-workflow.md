# Agent contribution workflow

Agent-led changes now have a normative coordinator, developer, tester and
independent reviewer workflow in AGENTS.md and the development guide.
The coordinator controls scope, acceptance criteria, handoffs, the active
phase and two correction counters. Only the developer edits candidate tracked
files; the tester and reviewer return findings. Local implementation, testing
and internal review allow three correction rounds after the initial
assessment. After local acceptance, the hosted-CI/Copilot PR phase starts once
per topic and allows three additional rounds after its initial assessment.
Each bundle of corrections plus revalidation counts once in the active phase;
PR fixes do not charge the retained local counter again. Both counters survive
agent changes, pushes, rebases, replacement PRs and renewed reviews. Valid
findings after round three block that phase for a maintainer decision;
unresolved local findings cannot be shifted into the PR phase.

The development guide specifies immutable base/candidate handoffs, fresh
independent review without developer dialogue, separate test/review revisions,
evidence requirements and reusable role-assignment prompts. Native delegation
may run in an active cloud or local task with the same AMD64 Trixie Docker
checks. A maintainer-supplied external review may qualify when reviewer
identity, scope, independence and revision/diff mapping are established;
labels/models or known SHAs alone do not establish independence. The guide
explains filesystem-isolation limits and reports a missing valid review route
rather than treating self-review as independent evidence.
Topic branches use `<prefix>/<topic>` with exactly one prefix segment.
Codex-created branches use `codex/<topic>`; other authors choose their own
prefixes. Topic derivation removes the first prefix segment and existing
matching plans are reused.

Submission preparation folds local fixups into coherent, independently
buildable commits before first submission of an unpublished topic. An
indivisible documentation topic can use one commit; shared, published or
another contributor's history requires explicit rewrite permission. Final
test/review handoffs follow history preparation. The guide narrowly permits
retaining local content evidence across a later history-only rewrite with
unchanged base, identical complete trees and proven independence from Git
metadata; original execution SHAs remain explicit and hosted statuses are not
carried over. Content changes retain full CI and fresh-review requirements;
pure history cleanup neither consumes a correction round nor resets either
counter.

PR preparation requires a complete local handoff with final revisions,
commit sequence, title, evidence and explicit next stages. The body is
byte-identical to the committed change record. Commit text describes the
problem, change and reason; validation details stay in the record. Submission
uses the authorized topic branch and checks for duplicate PRs. Merge readiness
requires hosted CI for the current head; local preparation can finish while
hosted CI and Copilot remain pending. Already authorized stages continue
without repeated confirmation; preparation alone grants no external write
permission.

Copilot code review is requested through a supported reviewer mechanism and
remains supplementary to internal review and CI. All review bodies, inline
threads and conversation are read and independently triaged; summaries or
comment states are not approval or runtime evidence. Valid findings retain
the PR-phase correction budget and full tests/fresh review for changed content.
Replies and thread handling require substantiated outcomes; stale or pending
reviews remain open and relevant changes require current-head hosted CI and
renewed Copilot review. Reporting merge readiness does not authorize a merge.

Tester guidance reproduces the complete existing local CI sequence: image,
coverage before `build/` exists, wrapper and shell checks, rootless checks,
the unchanged no-network cross-UID root harness with a read-only checkout,
and documentation. A subshell's `umask 022` and narrow traversal preflight
support the unprivileged children without weakening the test. Docker/proxy
sandbox failures use supported platform escalation rather than root normal
tests or privileged containers.

Reusable Cloud setup is documented as concrete environment requirements and
settings steps, separately from task-local agent assignments. No reusable
configuration, background service or self-operated server infrastructure is
created by this change. Submission and review interactions follow explicit
task scope; merge, release and settings actions retain their separate
authorization requirements.

Contribution guidance and the sorted indexes link the workflow. The changelog
is reserved for changes visible to library/CLI users or integrators, including
relevant consumer build and installation changes. This internal workflow
belongs in guides and change records and has no changelog entry.
Production and test sources, fixtures, build/CI configuration and the existing
VFAT topic are unchanged; runtime and public API behavior are unchanged.

## Validation

Static documentation checks pass: relative links and the workflow anchor
resolve, both indexes remain sorted, the documented local CI command sequence
matches the existing workflow and whitespace checks pass. The changed-file
inventory contains only the scoped Markdown files; CI and the existing VFAT
plan and record match the baseline.

A separate tester executed the complete local CI chain in a fresh detached
AMD64 Debian Trixie worktree. Every top-level CI command exited zero, with no
unexpected failures or skips. The absence-of-`build/` assertion passed before
standalone coverage, wrapper/shell checks and normal checks. Normal container
commands ran as UID/GID 1000:1000 through the unchanged wrappers. The recorded
versions are Docker 29.9.2, GNAT/GCC/gcov 14.2.0, GPRbuild package 2025.0.0-4,
Ahven 2.8-11 and MkDocs 1.6.1.

Coverage reports executed lines for all ten production bodies: 1031 of 1107
executable lines. Ahven's 19 cases pass in each normal and coverage mode;
all six retained XML reports contain zero errors, failures and skips. The
expected text/XML failure controls also pass. All 54 cross-UID scenarios pass
under the unchanged cross-UID root harness with no network and a read-only
source mount; no permission repair or test weakening was needed. Documentation
stages 14 canonical pages and passes `mkdocs build --strict`.

A separate native reviewer with fresh context found no actionable findings
in the full immutable diff or the independent comparison of the tester's
report with primary logs and artifacts. Those primary records, coverage,
XML and cross-UID results were also inspected directly.

This evidence covers the local AMD64 Trixie checks; line coverage does not
establish full branch coverage, and ARM64 or other platforms were not tested.
Hosted CI and artifact upload are outside these local results and are tracked
separately for the current PR head. Pages deployment is not part of this
validation.
No reusable Cloud configuration was saved or published.

Co-Authored-By: GPT-6 <noreply@openai.com>

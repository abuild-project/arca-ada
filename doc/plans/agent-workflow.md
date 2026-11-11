# Agent contribution workflow

Status: Implemented; local test and independent review evidence recorded.

Base revision: `baf77be432c9aa946215a2bec900e1a63f2188a0`.

## Decisions on 2026-11-10

- Decision: use coordinator, developer, tester and independent reviewer
  assignments through native agents inside an active Cloud task because
  candidate editing, runtime evidence and independent judgment need distinct
  responsibilities. Native agents share a filesystem; separate worktrees and
  read-only orders do not establish technical isolation or a different model.
- Decision: require fresh-context review without developer dialogue and full
  base/candidate SHAs because a review must assess a fixed change independently.
  Missing delegation or fresh-review capability is an unmet criterion.
- Decision: allow three bundled correction rounds after the initial candidate
  because the coordinator needs a finite stop condition across the whole task.
  Agent changes and subtasks do not reset the count; infrastructure-only
  retries without candidate changes do not consume it.
- Decision: run the complete existing local CI chain in a fresh tester
  worktree, including for this documentation topic, because ignored artifacts
  in an original checkout cannot establish coverage-first behavior. Preserve
  the rootless normal checks and unchanged cross-UID root-coordinator command,
  no-network mode and read-only checkout.
- Decision: use `codex/<topic>` globally and continue existing matching plans
  because branch/topic discovery and durable decisions should stay consistent.
  Keep operational logs and counters outside maintained records; add no second
  ticket system and leave the existing VFAT topic unchanged.
- Decision: document reusable Cloud environment requirements and settings
  steps separately from task-local role execution because no reusable source
  configuration is attached and configuration-write tools are unavailable.
  Do not publish a configuration, introduce self-operated infrastructure or
  create a persistent autonomous service. External actions remain separately
  authorized maintainer decisions.

## Implementation and acceptance

1. Add a short normative workflow in AGENTS.md and a detailed development
   guide covering roles, authority, immutable handoffs, fresh native review,
   the local and PR correction budgets and role-assignment templates.
2. Document a new detached tester worktree created under a subshell's
   `umask 022`, necessary cross-UID traversal checks and the complete existing
   CI command sequence. Retain ordinary non-root execution; a blocked Docker
   socket/proxy uses supported platform escalation, never weaker tests.
3. Link contribution guidance and add sorted plan and change-record entries.
   Keep this internal workflow out of the user- and integrator-facing
   changelog. Change documentation only, retaining source, fixtures, build
   configuration, CI and all unrelated plans/records.
4. Have a separate tester execute the complete local CI chain and preserve
   command/exit-code, version, identity, image, coverage and XML evidence.
   Have a separate fresh-context reviewer inspect the immutable candidate.
   Record only observed final evidence and material limits in the change
   record; no moving candidate-tip reference belongs in its own record.

## Validation on 2026-11-10

A separate tester's primary logs and retained artifacts establish that the
complete local CI chain passes in a fresh detached AMD64 Trixie worktree,
including coverage before `build/`, normal UID/GID 1000:1000 checks, unchanged
cross-UID controls and strict documentation generation. Coverage, Ahven XML
and cross-UID results are recorded in the change record. A separate native
fresh-context reviewer reports no actionable findings after static review and
comparison of the tester report with primary evidence. The evidence update
retains the normative workflow and does not perform any external action.

## Changelog scope decision on 2026-11-10

Decision: reserve CHANGELOG.md for changes visible to library/CLI users or
integrators because its reader contract covers their use of Arca. Relevant
consumer build and installation changes remain eligible. Purely internal
changes to agent workflows, processes or validation evidence belong in guides
and change records, so this workflow has no changelog entry.

## Submission preparation decisions on 2026-11-11

- Decision: organize new, unpublished topics into coherent independently
  buildable commits before first submission because reviewers should see
  final behavior without unnecessary local correction history. Fold fixups
  into the relevant substantive commits; an indivisible documentation topic
  can use one commit. Shared, published or another contributor's history still
  requires explicit rewrite permission; the workflow grants no force-push
  permission.
- Decision: finalize history before final test/review handoffs because
  evidence must remain bound to known revisions. A later pure history rewrite
  may retain only local content evidence proven independent of Git metadata,
  with unchanged base, identical complete tree IDs and an explicit old/new
  mapping. Preserve execution SHAs, recheck changed metadata and rerun
  SHA-dependent checks; content changes require full local CI and fresh
  independent review. History cleanup consumes no correction round and never
  resets the task counter.

## Pull request and Copilot decisions on 2026-11-11

- Decision: keep commit text focused on the problem, change and reason, with
  capitalized descriptions after the type prefix, because validation commands,
  results and limits belong in the canonical change record.
- Decision: prepare the complete local PR packet before the next regular
  handoff because submission needs concrete revisions, a final title and a
  body identical to the committed record. Respect the explicit task boundary;
  already authorized submission/review stages proceed without repeated
  confirmation, while merge and other external permissions remain distinct.
- Decision: request actual Copilot code review through supported mechanisms
  and inspect complete review bodies, threads and conversation because summary
  labels and comment states do not prove approval, CI or inspected runtime
  evidence. Triaged findings retain the global correction limit and require
  fresh local tests/internal review and current-head hosted CI after changes.
  Pending, unavailable or stale reviews remain open; Copilot is supplementary.

## Phase budget decision on 2026-11-11

Decision: supersede the single task-wide three-round budget decided on
2026-11-10 and the single-budget references in the earlier 2026-11-11
decisions with two phase budgets because hosted CI/Copilot provide a separate
review phase after local acceptance. The local implementation/testing/internal
review phase allows three corrections after its initial assessment. The PR
phase starts once per topic after local acceptance and allows three additional
corrections after its initial hosted-CI/Copilot assessment. Both assessments
start at zero; each phase's first correction is one.

Retain both counters and the active phase across pushes, rebases, replacement
PRs, renewed reviews, agent changes and subtasks. Count a developer correction
bundle plus revalidation once in the active phase; PR fixes do not charge the
local budget again. Infrastructure retries without candidate changes and pure
history cleanup consume no round. A valid finding after round three blocks
that phase for a maintainer decision; unresolved local work cannot be shifted
to the PR phase. Budget availability grants no external-action permission.

Co-Authored-By: GPT-6 <noreply@openai.com>

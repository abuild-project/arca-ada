# Agent contribution workflow

Status: Implemented; validation through 2026-11-11 recorded.

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
   guide covering roles, authority, immutable handoffs and fresh independent
   review, local and PR correction budgets and role-assignment templates.
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

## Execution and review portability decisions on 2026-11-11

- Decision: allow native delegation within an active cloud or local agent
  task because orchestration location does not alter the required AMD64
  Trixie Docker checks or supported-platform scope. This supersedes the
  Cloud-only wording in the 2026-11-10 decisions; no persistent service or
  self-operated server infrastructure is introduced.
- Decision: allow a maintainer-supplied external review from another agent or
  human when identity, scope, independence and immutable revision/diff mapping
  are established because a valid independent review need not share the
  developer's execution tool. This supersedes native-only review wording;
  known SHAs or different labels/models alone are insufficient. Earlier-head
  reviews do not cover later heads; findings retain the active phase budget.
- Decision: reserve coordinator for the workflow role and call the cross-UID
  test the root harness because the two responsibilities must remain distinct.
  Test source and invocation remain unchanged. Label Codex tool/status fields
  as examples and retain durable outcomes instead of session state in records.
- Decision: retain `codex/<topic>` as the project branch naming convention,
  independent of the agent or vendor, because the prefix identifies a topic
  workflow rather than an execution tool. The 2026-11-10 naming decision
  remains in force.

## Branch prefix decision on 2026-11-11

Decision: name topic branches `<prefix>/<topic>` with exactly one prefix
segment because different authors may use their own naming prefixes.
Codex-created branches use `codex/<topic>`; other authors may choose prefixes
such as `claude/`. This supersedes the global prefix requirement of 2026-11-10
and the project-wide `codex/` clarification in the earlier 2026-11-11
portability decisions, while retaining the Codex branch convention. Topic
derivation still removes the first prefix segment and matching existing plans
are reused.

## Review identity decision on 2026-11-11

Decision: require a review posted through a shared or maintainer account to
name its actual reviewer and immutable covered revisions in the body because
the posting account does not identify the reviewer. The existing scope and
independence criteria still apply; a declared identity alone establishes
neither scope nor independence.

## Validation on 2026-11-11

Revision `b3d6dc4435e351d52bc42071e628733bf9d2b1c3`, with complete tree
`e852c75fd3a82ad3416982ef0b3ffff026703ac5`, has its own fresh local
AMD64 Debian Trixie validation. A separate tester executed the full CI chain
in a new detached worktree at that revision: image build, coverage before
`build/` existed, wrapper and shell checks, normal checks, unchanged cross-UID
root harness and strict documentation build. Normal commands used UID/GID
1000:1000; only the cross-UID harness used root, with no network and a
read-only source mount. All top-level commands exited zero, with no unexpected
failures or skips. Coverage was 1031/1107 lines across ten production bodies;
six Ahven XML reports contained 38 cases and zero errors, failures or skips.
All 54 cross-UID scenarios passed, and documentation staged 14 canonical pages.

A separate native reviewer with fresh context inspected the full immutable
base-to-revision diff and compared the tester's report with primary logs and
artifacts, including coverage, XML and cross-UID results. That review reported
no actionable findings or evidence discrepancies. These local results were
collected for this exact revision, not transferred from an earlier candidate.

[Hosted PR CI][hosted-pr-ci] and [push CI][hosted-push-ci] also succeeded for
this revision. The hosted PR checkout was the synthetic merge
`036c059946f87243620424bb005580c576a234e9`, whose complete tree equals the
revision's tree above. Inspection of the PR job's primary log and downloaded
Ahven artifact confirmed the coverage, cross-UID, documentation and XML
results. These are distinct local and hosted observations; Pages deployment
was outside validation. Later content changes still require their own full
local chain, fresh independent review and current-head hosted CI.

[hosted-pr-ci]:
  https://github.com/abuild-project/arca-ada/actions/runs/43014658578
[hosted-push-ci]:
  https://github.com/abuild-project/arca-ada/actions/runs/43014649617

Co-Authored-By: GPT-6 <noreply@openai.com>

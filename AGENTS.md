# Arca agent guide

Arca is an Ada library of archive and filesystem image writers plus the
`arca` command-line tool. These instructions apply to every coding agent,
independent of vendor, model or user interface. Human contributors start
with [CONTRIBUTING.md](CONTRIBUTING.md); the same rules apply to them.

## Before you start

- Read `README.md`, `doc/development.md`, `doc/coding-style.md` and
  `doc/licensing.md`. Read the active plan under `doc/plans/` when the work
  belongs to one, and `SECURITY.md` before security-relevant work.
- Preserve unrelated working-tree changes; do not overwrite another topic's
  work.
- Use `codex/<topic>` for every topic branch. Continue the existing topic plan
  when one already covers the work.
- Ask the maintainer before a decision that changes scope, public API,
  compatibility, licensing or supported platforms. Record the agreed decision
  in the active plan.
- Perform external writes only within the maintainer's explicit task scope.
  Preparing a PR grants no push/create permission. A request to submit a PR
  with Copilot review can cover the necessary topic push, creation, review
  request and factual responses; do not ask again for already authorized
  steps. Merge, tag, release, publication, settings and force-push actions
  require separate authorization.
- If the documented build environment or a required tool is unavailable,
  say so. Do not replace the required evidence with a weaker environment.

## Boundaries and code

- Keep the library independent of Abuild types, configuration, logging and
  scheduling. Add a shared primitive only when two real consumers need the
  same semantics.
- Follow the [coding-style guide](doc/coding-style.md) for library, CLI,
  tests and examples. Keep compiler style checks enabled, Ada lines within
  80 columns and a contract comment beside every subprogram declaration.
- Keep writer state local to each instance. Implicit cleanup must never
  propagate an exception or replace the caller's original one.
- Open every in-process Ada file stream with `Form => "shared=no"`.
- Keep production C limited to the CLI's `cli/src/posix_bridge.c` for
  target-specific layouts and constants; prefer direct Ada system-call
  bindings. Isolated C test helpers may exercise faults and platform behavior.

## Build and tests

- Produce compiler and runtime-test evidence with `docker/dev/build` and
  `docker/dev/run` (Debian Trixie). Host compilers do not substitute for it.
  Documented launcher and host-integration checks run on their intended host.
- Run `make -j8 <one target> NUM_CPUS=8`, one target per invocation.
- Format tests use independent decoders and external readers. Never import
  production layout constants into a test oracle.
- Every new check must be able to fail for the right reason. Show that it
  rejects the old behavior or a targeted corruption.
- When production bodies are added, removed or renamed, update
  `tests/coverage-sources.txt` and run the coverage target.

## Agent workflow

Follow the [role workflow](doc/development.md#agent-workflow) for agent-led
changes, including documentation topics. The coordinator starts the role
assignments once per task; delegated role agents do not recursively start
another four-role workflow.

- The coordinator owns scope, acceptance criteria, handoffs, the active phase
  and both correction counters. The developer alone edits and commits
  candidates. The tester and reviewer report defects without correcting
  candidate files.
- Give the tester a fresh detached worktree at the immutable candidate SHA
  and require the complete local CI chain, including coverage before `build/`
  exists, rootless checks, the unchanged cross-UID coordinator and docs.
- Assign the reviewer a separate native agent with fresh context, no developer
  dialogue, immutable base/candidate SHAs and a read-only review worktree.
  Separate worktrees and instructions do not enforce filesystem isolation;
  native agents share the filesystem and need not use different models.
  Report missing delegation or fresh-review capability instead of claiming
  independent review from one agent's role-labelled responses.
- Allow at most three bundled correction rounds in the local implementation,
  testing and internal-review phase. After local acceptance, start the PR phase
  once per topic with up to three additional rounds for hosted CI/Copilot.
  Initial assessments use zero; the first correction in each phase uses one.
  Retain both counters across agents, subtasks, pushes, rebases, replacement
  PRs and repeated reviews. Count corrections plus revalidation once in the
  active phase. Infrastructure retries without candidate changes and pure
  history cleanup consume no round. Valid findings after round three block
  that phase and require a maintainer decision; unresolved local findings must
  not be shifted to the PR phase.
- Require both test evidence and independent review for the same candidate
  before acceptance, except for the strictly tree-identical history-only case
  in [submission preparation](doc/development.md#submission-preparation).
  Keep operational logs and both counters in the task log or ignored `build/`;
  append durable decisions to the topic plan. Keep session and review-round
  history out of the change record.
- Use native agents only inside the active Cloud task and existing hosted
  GitHub Actions. This workflow creates no persistent autonomous service or
  self-operated infrastructure and grants no external-action permission.
- Prepare the complete local PR packet before the next regular handoff;
  follow [PR submission and Copilot review](doc/development.md#pull-request-preparation-and-submission)
  within the authorized stages. Copilot supplements internal review and CI;
  read all review content and retain the existing PR-phase correction budget.

## Licensing

- Project-owned maintained files use GPL-2.0-or-later. Put the SPDX identifier
  near the start of source, script and build files where their syntax allows
  comments, after any required shebang. Preserve required notices and the
  original form of third-party material, generated files and fixtures; do
  not edit standard licence texts to add a header. Record applicable licence
  exceptions or metadata limitations in `doc/licensing.md`.
- Code taken from Abuild keeps GPL-2.0-or-later and its attribution. Record
  its origin revision in `doc/licensing.md`. Do not add third-party source
  without compatible licence terms.

## Commits and change records

- Use Conventional Commit subjects of at most 50 characters and wrap bodies
  at 72 columns without dangling single-word lines. Keep commits small and
  independently buildable. Capitalize the description after the type prefix.
  Describe the problem, change and reason in the commit; keep validation
  commands, results and limitations in the change record, not the commit.
- Before first submission of a new, unpublished topic, organize coherent
  commits and fold local fixups into the relevant substantive commits.
  Describe final behavior; use one commit for an indivisible documentation
  topic. Follow the development guide's submission preparation before final
  evidence handoffs.
- Rewrite shared, published or another contributor's history only with
  explicit rewrite permission. This workflow grants no force-push permission.
- Do not put ticket numbers or issue-tracker references in commits, change
  records, plans or pull request texts.
- When an agent co-authors a change, end the commit message and change
  record with an accurate `Co-Authored-By` trailer for the model actually
  used. Never invent an identity.
- Every topic updates the affected user and developer guides and adds
  `doc/change-records/<topic>.md` in the sorted index.
  Derive the topic from the branch name by removing the first slash-separated
  prefix, if present, and replacing any remaining slashes with hyphens.
  The committed record is the pull request description, so it remains
  readable after a move to another forge.
- Update `CHANGELOG.md` only for changes visible to library/CLI users or
  integrators, including relevant consumer build and installation changes.
  Keep purely internal changes to agent workflows, processes or validation
  evidence in guides and change records, not the changelog.
- Use a plan under `doc/plans/` for multi-step work. Dated sections are
  append-only; record a later deviation as a new dated entry.

## Writing plans, records and documentation

Write for a reader who knows neither the tools nor the conversation that
produced the change. Apply these writing rules to new and materially revised
maintained documentation. Preserve historical records and dated decisions;
factual corrections and reference maintenance must not silently rewrite what
was agreed or observed at the time.

- State what changed and why, compatibility, deliberate deviations, known
  limits and which checks cover the change in which environment.
- Phrase decisions as decisions with their reason ("Decision: ... because
  ..."), not as who requested or approved them.
- Leave out session history: transient tool outages, restarts, chat context,
  review rounds or which agent or bot found what. A finding and its
  resolution belong in the record; its discovery story does not. Retain
  environment restrictions and validation gaps that affect the conclusion.
- Keep delivery status (ready for review, merged, published) out of record
  bodies. It belongs in the index or a plan's status line. Add the accepted
  merge commit there after acceptance.
- Use immutable commit hashes for source and baseline references, with topic
  branches where useful. Do not pin a topic's moving tip inside its own record.
  Forge links to pull requests or CI runs may supplement revision references
  but are never the only reference.
- Claim only evidence you observed, including primary logs or artifacts you
  inspected; distinguish those from commands you ran yourself. Name what is
  not covered instead of implying completeness, and avoid stale counts.
- Keep private infrastructure URLs, internal product or customer names,
  personal or organization-specific filesystem paths and real credentials
  out of committed files and pull request texts. Generic example paths,
  public interface identifiers, clearly identified dummy test values and
  required copyright/licence notices may remain where needed.
- Do not commit or publish details of an unfixed vulnerability; follow
  `SECURITY.md`.

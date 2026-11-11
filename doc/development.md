# Development guide

## Reference environment

Validate on 64-bit AMD64 Debian 13 (Trixie), using GNAT 14 and GPRbuild. The
supported [platform scope](../README.md#supported-platforms) requires 64-bit
Long_Integer and Interfaces.C.long. The development Dockerfile installs build
tools while constructing the image. Runtime build and test steps do not
install packages. The launcher maps the invoking user
and group into the container and supplies `HOME=/tmp`.

```sh
docker/dev/build
docker/dev/run arca-dev:trixie make -j8 check NUM_CPUS=8
```

Local builds and GitHub CI use `docker/dev/build` and `docker/dev/run`.
Both default to `linux/amd64`, matching the reference CI architecture.
The build wrapper defaults to the tag `arca-dev:trixie` and accepts `--tag`.
Both wrappers accept `--platform linux/arm64` for explicit native ARM builds:

```sh
docker/dev/build --platform linux/arm64 --tag arca-dev:arm64
docker/dev/run --platform linux/arm64 arca-dev:arm64 make -j8 check NUM_CPUS=8
```

Clean generated objects before switching architectures in one checkout.
The wrappers select their containing repository from any working directory,
including paths with spaces. Normal runs use the invoking UID/GID and
`HOME=/tmp`; `--root` is an explicit exception when container root is needed.
They do not install tools during a build or test run.

The image tag follows Debian's Trixie updates; it is not an immutable image
digest and does not promise bit-reproducible toolchains. The GitHub workflow
builds this Dockerfile and runs the standalone coverage target before any
other tests. It first asserts that `build/` does not exist, verifying that
coverage creates its own scratch parent without packaging or wrapper checks.
The normal check target follows. Python 3, GNU cpio/tar, libarchive's bsdtar,
gcov, Ahven (`libahven-dev`), bzip2, mtools and dosfstools are supplied by
the development image. The latter three support test-only VFAT references;
they are not library or CLI dependencies. The test preflight reports missing
readers and an unavailable test project.

With no explicit command, the launcher starts Bash and forwards standard
input, including piped commands. It allocates a TTY only when both its input
and output are terminals. Explicit commands run without forwarded input or
a TTY, so the build and test invocations remain suitable for CI.

`GPRBUILD`, `GPRINSTALL` and `GPRCLEAN` select individual executable names or
paths, including paths containing spaces. Make passes its selected values
explicitly to the tool preflight, so values assigned by a Makefile work like
command-line overrides. Missing tools are reported together using their
selected names or paths.

`make check` includes preflight regressions with a restricted fixture PATH.
The checks cover command-line selections, Makefile selections, default-name
fallback and missing selections even when default-name executables exist.
The recursive Make calls retain the outer build's jobserver; fixtures and
diagnostics live in a private temporary directory below `build/`.

The check target also exercises the real Make recipes in an isolated fixture
with executable paths containing spaces. Recording tools verify the selected
executable identities and argument boundaries for library and client builds,
installation and cleanup commands. The fixture replaces the consumer
checks to avoid recursion; the normal check target runs those checks with the
real compiler separately. It does not change the checkout's build artifacts.
File-defined tool selections must reach installation helpers explicitly;
unlike command-line values, GNU Make does not export them automatically.
Those helpers resolve and forward all three selected GPR executables to their
recursive Make calls, including the cleaner used by installation preflight.

`python3 tests/check-dev-shell.py IMAGE` runs on the Docker host, where Python
3 and Docker must already be available. It checks a default shell with piped
input, a default shell connected to a real pseudo-terminal and an explicit
batch command. The terminal sentinel is checked as a complete output line
after the container confirms its terminal fds, so echoed command text cannot
satisfy the assertion. CI runs these checks against its freshly built image.

For an ARM image, add `--platform linux/arm64` to the host-side shell check.
`python3 tests/check-dev-wrappers.py` separately checks wrapper defaults,
platform/tag selections, paths with spaces, root rejection and command
argument boundaries without a Docker engine. CI runs it after the fresh-source
coverage check so it cannot create coverage's scratch parent in advance.

## Agent workflow

Agent-led topics use four distinct assignments: coordinator, developer, tester
and reviewer. This also applies to documentation changes. Use native agents
inside the active Cloud task and the existing hosted GitHub Actions workflow;
no self-operated runner, new server, persistent autonomous service, additional
model subscription or secret is required. Writing four role-labelled sections
in one agent's response does not provide these separate assignments.

### Roles and authority

| Role | Responsibility | Candidate access |
| --- | --- | --- |
| Coordinator | Fix scope and acceptance criteria, assign roles, consolidate findings, retain the active phase and both correction counters and decide whether the evidence meets the criteria | Manage handoffs; delegate candidate edits to the developer |
| Developer | Implement the scoped change, correct bundled findings and produce an immutable candidate commit | Sole editor of candidate tracked files |
| Tester | Execute the complete local CI chain and report results, failures and evidence limits | Fresh detached worktree; generated test artifacts only |
| Reviewer | Independently inspect the full base-to-candidate change and its contracts, tests, documentation and evidence | Separate revision/worktree under a read-only assignment |

The maintainer still decides scope, public API, compatibility, licensing and
supported-platform changes. The coordinator must seek that decision before
extending the agreed work. Acceptance means that the local evidence satisfies
the task; it grants no external write permission. Preparing a PR does not
authorize pushing or creating it. An explicit submission/Copilot-review task
can cover the necessary topic push, PR creation, review request and factual
responses; continue already authorized stages without repeated confirmation.
Merge, tag, release, publication, settings and force-push actions require
separate authorization.

Use `codex/<topic>` for every topic branch. Reuse an existing matching plan
under [plans](plans/README.md); create a new plan only for a new topic. Do not
start a parallel ticket system. Append durable technical decisions, with
their reasons, to the plan's dated sections. Keep raw logs, role messages,
candidate identities, the active phase and both counters in the task log or
ignored `build/`. Do not create `build/` in the tester's fresh worktree before the
coverage-first assertion. The canonical change record describes the final
change, evidence and material limits without session or review-round history.

### Native agents and review independence

The coordinator launches actual native role agents using the delegation tools
available in the active task; no additional orchestrator software is needed.
The role assignments are leaf tasks within this one workflow: an assigned
developer, tester or reviewer follows its role brief and does not recursively
start another four-role workflow. Give every role the scope, active phase
and both correction counters. Give the tester its own fresh worktree at the
candidate commit. Assign a separate reviewer with fresh context and an explicit
read-only review packet. When using native `spawn_agent`, start that reviewer
with `fork_turns="none"` and supply the packet explicitly; do not inherit the
developer dialogue or send a preferred conclusion. The reviewer reads the
repository guidance, agreed scope, immutable base/candidate diff and test
evidence and reaches its own conclusions.

Native agents share the filesystem. Separate worktrees and read-only orders
are procedural boundaries, not technically enforced filesystem isolation.
Do not assume a different model, hidden permissions or automatic UI startup.
Keep candidate edits with the developer and avoid concurrent mutations of a
shared checkout or Git state. If native delegation or a fresh independent
review assignment is unavailable, report the missing capability and leave
that acceptance criterion unmet; do not claim independence from a self-review.

### Candidate handoffs and phase budgets

1. The coordinator records the task, allowed files/behavior, exclusions,
   active plan, acceptance criteria and immutable base SHA. For a new topic,
   it initializes local corrections to zero and PR corrections to zero, with
   the PR phase not started, and assigns the developer in the local phase.
2. The developer produces the initial candidate commit and supplies the
   full candidate SHA, base-to-candidate diff and handoff packet. No correction
   round has been consumed yet.
3. The tester validates that exact SHA in a fresh detached worktree. The
   independent reviewer inspects that same immutable candidate against the
   base in its own revision/worktree. Neither role corrects a defect; each
   returns findings to the coordinator. Gather both reports before bundling
   corrections when possible.
4. The coordinator accepts only when both reports cover the same candidate
   (or the strictly tree-identical history-only case under
   [submission preparation](#submission-preparation)), all acceptance criteria
   are met and no blocking finding remains. Otherwise it combines actionable
   findings into one developer correction request.
   A bundle of developer corrections plus its revalidation consumes one round
   in the active phase. The first correction is round one. Run the full test
   chain and fresh independent review for the new candidate SHA; these checks
   do not each consume another round.
5. Allow at most three correction rounds locally. Only after local acceptance
   may the coordinator start the PR phase once per topic, within the authorized
   external scope. The initial hosted-CI/Copilot assessment uses PR round zero;
   up to three additional correction rounds are available in that phase.
   Retain the local count. Internal tests/reviews after a PR fix belong to its
   PR round and do not consume the local budget again.

Both counters belong to the topic. Changing agents, splitting subtasks,
renaming branches, pushing, rebasing, replacing a PR or requesting another
review resets neither counter. Once the PR phase starts, returning to local
testing or opening another PR for the same topic retains that phase and its
existing counter; the transition cannot provide a second fresh PR budget.
If valid findings remain after the active phase's third round, block that
phase and report the findings for a maintainer decision. Do not produce a
fourth correction or move unresolved local findings into the PR phase.
Budget availability itself authorizes no push, PR, review request or merge.

A pure infrastructure retry with no candidate change consumes no correction
round. Record the failed command, cause or uncertainty and retry result so it
cannot conceal a candidate defect. A change to candidate tracked files is a
new candidate and requires evidence for that revision. Tester and reviewer
reports remain tied to their immutable SHAs, even if a branch later moves.

Every handoff packet contains:

- Task, scope and exclusions, plan path, acceptance criteria, active phase,
  both correction counters and whether the PR phase has started; full base
  and candidate SHAs and the complete diff.
- Tester report with exact commands and exit codes, tool versions, host and
  container UID/GID, architecture, image identity, coverage inventory/results,
  Ahven XML locations/results, skips and limitations. Preserve primary logs
  and artifacts so another role can inspect the claims.
- Reviewer report with file/line locations, concrete impact and the affected
  acceptance criterion for each finding, or an explicit no-findings result
  with the reviewed scope and evidence limits.

The initial developer packet identifies test/review evidence as pending.
Subsequent packets include the available reports without turning the
developer's reasoning or conversation into the reviewer's starting context.

### Submission preparation

Before first submission of a new, unpublished topic, organize coherent, small,
independently buildable commits. Fold local fixups into the relevant
substantive commits and describe final behavior. Keep distinct changes
separate; one indivisible documentation topic can use one commit. Rewriting
shared, published or another contributor's history requires explicit rewrite
permission; the workflow grants no force-push permission.

Finalize history before final test and review handoffs so both roles receive
the final base/candidate SHAs and diff. For a later pure history/message
rewrite, preserve a recovery ref and record the base, old/new SHAs, complete
tree IDs and mapping in the task log or ignored `build/`. Evidence from local
checks or reviews of content may be retained only with an unchanged base,
identical complete tree IDs and demonstrated independence of each retained
check/review from Git metadata. Preserve the original execution SHAs; never
claim checks ran on the new SHA or transfer hosted commit-bound statuses.
Recheck changed metadata and rerun SHA-dependent checks. Any content change
requires the full local CI chain and fresh independent review for the new
candidate. Pure history cleanup consumes no correction round and resets
neither phase counter; it must not contain hidden fixes.

### Pull request preparation and submission

The coordinator continues until the next regular handoff has a concrete local
PR packet. Keep it in the task log or ignored `build/`, containing:

- Target repository, base branch/SHA, head branch/final SHA and complete tree
  ID, prepared commit sequence, scope and canonical change-record path.
- A concrete title describing the final result in the appropriate Conventional
  style, and a body byte-identical to the committed
  `doc/change-records/<topic>.md`, without a chat-history summary.
- Final local CI and independent review evidence, remaining limits, the active
  phase, both correction counters, PR-phase start status and next authorized
  stages. Keep raw logs, operational status and counters out of the PR prose
  and change record.

The local packet can be complete before submission. Mark hosted CI and
Copilot review as pending until authorized creation/request and actual results.

Respect the task's current boundary, which may stop before any external
write. This is an adjustable task boundary, not a mandatory confirmation
between every step. If submission and Copilot interaction were already
explicitly authorized, continue those stages within scope. Preparation alone
authorizes no push or PR; merge and other separately gated actions remain
outside submission permission.

When authorized to submit, verify the target repository, base/head and final
SHA, and check for an existing PR before creating a duplicate. Push the topic
branch without writing directly to the default branch. Create a PR ready for
review when ready; use a draft only when requested or justified. Supply the
canonical body through a structured tool argument or `--body-file`, preserving
its exact bytes, and verify the created body matches the committed record.
Keep the record and PR body synchronized after substantive changes. Retain
PR/review URLs and IDs in the operational task log.

Track hosted CI separately from local evidence. Before reporting readiness
for merge, require actual successful hosted CI for the current PR head;
results from the base or an earlier SHA do not establish it.

### Copilot review and follow-up

Within the authorized review stage, request actual Copilot code review after
the PR is ready, using a supported GitHub reviewer mechanism. Check existing
pending requests first. Do not substitute assignment to the coding agent,
invent API/chat-command shortcuts or claim success when the tool cannot
request review. Copilot is supplementary; it replaces neither internal fresh
review, CI nor the maintainer's decision.

Observe completion for a bounded period without request spam or a background
service. Pending, timed-out, unavailable or stale reviews remain open status
and must be reported, not treated as clearance. For a completed review, verify
its associated commit and read every full review body, inline thread and PR
conversation comment, following pagination. Summaries, emojis, "No open
issues" and a `COMMENTED` state establish neither formal approval nor passing
CI or independent verification of runtime evidence.

Triage each finding independently against code, contracts and tests. The
developer alone fixes valid findings in bundled requests within the PR phase's
three-round budget, including hosted-CI and Copilot corrections. Each bundle
and its local/internal revalidation count once in that PR budget, without
charging the local counter again. An exhausted PR budget with a valid finding
requires a maintainer decision; do not start an autonomous fourth PR round.
Each changed candidate receives the full local CI chain and fresh independent
review under the existing rules. New pushes, PRs and renewed Copilot reviews
do not restart the phase or its budget.

Within authorized interaction, reply briefly and factually: cite the fix
commit and relevant evidence, or explain a rejected finding with its location
and contract. Resolve a thread only after substantiated handling. Do not
delete comments or dismiss reviews to make the PR appear clear. After relevant
changes, wait for current-head hosted CI and request a real new Copilot review
when the old review is stale. The readiness report identifies the latest head,
review commit, CI results, open/resolved threads and remaining limits. A report
that the PR is ready for merge does not authorize the merge itself.

### Fresh test worktree and local CI chain

Use a new detached worktree at the full candidate SHA, even when the original
checkout looks clean: it can contain ignored objects and reports. Choose an
unused destination under a traversable parent and create it with `umask 022`
in a subshell. A task umask of `0077` otherwise creates `0700` directories
that can prevent the cross-UID children from reaching the executable.

```sh
candidate_sha=FULL_CANDIDATE_SHA
test_worktree=../arca-test
(
    umask 022
    git worktree add --detach "$test_worktree" "$candidate_sha"
)
cd "$test_worktree"
git rev-parse HEAD
git status --short
```

Confirm the checked-out SHA and absence of tracked changes. Before the
cross-UID step, inspect the worktree parent chain and executable path for
necessary search/read/execute access by UIDs 65534 and 65533; the coordinator
uses those unprivileged identities without supplementary groups. Recreate a
misconfigured fresh worktree or fix only the necessary directory traversal
permission. Do not broadly open permissions with `chmod -R`, change fixtures,
skip assertions or replace the test with a single-UID run. Permission
preparation must not weaken the existing test.

Read [.github/workflows/ci.yml](../.github/workflows/ci.yml) at the candidate
revision and execute its complete local chain in order. The following is the
existing chain; if CI changes, use that revision's commands and record the
difference. Python 3 and Docker are host requirements for the wrapper/shell
checks. Run normal container commands as the non-root task user through the
wrappers, one Make target per invocation:

```sh
docker/dev/build
test ! -e build
docker/dev/run arca-dev:trixie make -j8 coverage NUM_CPUS=8
python3 tests/check-dev-wrappers.py
python3 tests/check-dev-shell.py arca-dev:trixie
docker/dev/run arca-dev:trixie make -j8 check NUM_CPUS=8
docker run --platform linux/amd64 --rm --network none --user 0:0 \
  --mount "type=bind,source=$PWD,target=/work,readonly" \
  --workdir /work arca-dev:trixie \
  python3 tests/check-staging-security.py --cli cli/bin/arca
docker/dev/run arca-dev:trixie make -j8 docs NUM_CPUS=8
```

Retain each command's exit code; a later success does not erase an earlier
failure. The cross-UID command is the unchanged dedicated root coordinator
with no network and a read-only source mount. It starts both competing
processes under distinct unprivileged UIDs. It is the specific root exception,
not a substitute for rootless compilation, coverage, ordinary checks or docs.
Do not use `--root` or privileged containers to make those normal checks pass.

Record the development image ID/digest when available because its tag moves,
Docker and compiler/build-tool versions, effective normal-test identities and
the coverage report under `build/`. Preserve Ahven XML from
`build/unit-results-*/*.xml`, including failure reports, as CI does. Report
missing reports, skips and infrastructure restrictions explicitly. Local
validation builds the documentation; GitHub artifact upload and Pages
deployment are external workflow steps and are not local test commands.

### Reusable Cloud environment requirements

A task-local role setup does not install a reusable Cloud configuration.
Inspect the active environment status before claiming one is attached;
`source_config_id=null` means no source configuration is identified. If the
current interface has no configuration-write tools, prepare the requirements
and use the user-facing environment settings/onboarding flow. Do not claim
that documentation or a local Docker image saved or published a configuration.

To prepare a reusable environment in those settings:

1. Select this repository and a non-root Linux/AMD64 task user, with Git,
   Bash, Python 3 and working Docker access for that user. Provide capacity
   for the image, separate worktrees and the documented `-j8` checks. The
   repository Dockerfile supplies Debian Trixie, GNAT 14, GPRbuild, Ahven,
   readers and documentation dependencies; do not replace it with host builds.
2. Permit the source checkout and Docker registry/Debian package access
   needed to build the reference image, using the platform's proxy and CA
   trust. Normal tests need no credentials, network access or Abuild checkout.
   Keep repository access configured through settings; do not put credentials
   into role prompts, plans or committed files.
3. Confirm native agent delegation and fresh-context review are available in
   the active task, then verify the non-root Docker socket, AMD64 architecture
   and fresh-worktree traversal requirements. Docker is supported in the
   managed Cloud environment; the project still requires rootless normal
   checks in its Trixie image.
4. Review the proposed settings and their observed readiness through the
   supported settings flow. Saving/publishing a reusable configuration is a
   separate authorized settings action. A later task must select it and
   verify its actual status and tool access before relying on it.

The default agent sandbox can block the Docker socket or inherited proxy.
Use the platform tool's supported escalation for the same required operation
and retain the failure/escalation in the task evidence. Do not switch to a
root test user, privileged container, host networking or weaker test as a
workaround. If the required environment remains unavailable, report the
specific blocker and leave validation incomplete. This workflow installs no
background scheduler and promises no unattended work after the Cloud task.

### Role assignment templates

The coordinator fills the placeholders and supplies repository guidance with
each assignment. These are task prompts, not executable service configuration.

```text
Developer: implement TASK in ALLOWED_SCOPE on codex/TOPIC.
Base: BASE_SHA. Active plan: PLAN. Acceptance criteria: CRITERIA.
Phase: PHASE. Corrections: local L/3; PR P/3. PR phase started: YES/NO.
Read AGENTS.md and its required guides. Preserve unrelated work and existing
topic decisions. You alone edit candidate tracked files. Return the full
candidate SHA, complete diff, change summary and evidence limits. Correct
only the coordinator's bundled findings; do not push or publish.
```

```text
Tester: validate CANDIDATE_SHA against BASE_SHA for TASK/CRITERIA.
Phase: PHASE. Corrections: local L/3; PR P/3. PR phase started: YES/NO.
Use your own new detached worktree with umask 022 and verify its SHA.
Read AGENTS.md and run the complete local CI chain from doc/development.md,
checking .github/workflows/ci.yml at that revision. Preserve commands,
exit codes, versions, identities, image identity, coverage and Ahven XML.
Report findings, skips and limitations to the coordinator. Do not edit
candidate tracked files, correct defects, push or publish.
```

```text
Reviewer: independently review BASE_SHA..CANDIDATE_SHA for TASK.
Phase: PHASE. Corrections: local L/3; PR P/3. PR phase started: YES/NO.
Scope/exclusions: SCOPE. Plan: PLAN. Acceptance criteria: CRITERIA.
Test report and primary evidence: EVIDENCE. Review worktree: REVIEW_WORKTREE.
Start with fresh context and no developer dialogue. Read AGENTS.md and the
required guides. Inspect the complete immutable diff and relevant surrounding
code/docs yourself. This is read-only: report file/line, concrete impact and
affected criterion for every finding, or no findings with limits. Do not
edit candidate tracked files, correct defects, commit, push or publish.
```

## Project boundary

`arca.gpr` is a static Ada library with no Abuild or third-party project
imports. `Arca.CPIO` and `Arca.TAR` expose format-specific APIs;
`Arca.Binary_IO` is their private implementation helper containing only the
used stream-copy operation and best-effort cleanup shared by both writers.
Do not add empty API promises for proposed format packages. Introduce each API
with its writer, documented constraints and independent tests.

`Arca.Version.Value` is a pure package constant and the only operative source
of the project version. `arca.gpr` exports that unit as library metadata.
CLI output and the example client use it directly, including copied installed
consumers and the regular static extending-project consumer. Adding the pure
unit preserves the extending project's empty interface override and consumer
binder ownership. It introduces no package body or coverage-inventory entry.
The [compatibility policy](../README.md#version-and-compatibility) defines the
public API; [release.md](release.md) describes maintainer release actions.

`cli/cli.gpr` imports the library and builds `cli/bin/arca`. Argument policy,
filesystem inventory and hardlink maps belong to this CLI consumer. Its Ada
containers are invocation-local and used sequentially; integration tests run
separate CLI processes against an immutable input tree. The library remains
Ada-only and does not depend on the CLI or its C code. The CLI's initial
platform is 64-bit Linux; the reference validation uses AMD64 Trixie.

GNAT supplies path normalization and a raw directory-name iterator. The
higher-level Ada.Directories search also queries modification times through
an API that rejects dangling links and special nodes. The raw iterator lets
the CLI inspect every name with lstat. The production C bridge,
`cli/src/posix_bridge.c`, converts lstat metadata to a fixed-width record and
keeps platform stat layout, type/device macros, errno values and rename flags
behind that boundary. An independent C header probe checks exported constants.
readlink, mkdtemp, rename and renameat2 are direct Ada bindings; errno is
captured before allocating diagnostic strings, and readlink's returned byte
count determines the target slice without assuming a NUL terminator.
SIGHUP/SIGINT/SIGTERM handlers and their signal state use an Ada protected
object, following the existing Abuild pattern through independently authored
CLI code. No Abuild helper is imported. See the [CLI guide](cli.md) for the
stable-input contract, format limits and cancellation boundaries.

`Archive_CLI.Diagnostics` retains CLI-generated text outside the runtime's
bounded exception message. Run resets this process-owned state before each
sequential invocation; interrupt handlers never access it. Stored text is
associated with its CLI exception identity, while other exceptions use their
runtime text or name. Only final diagnostic output escapes control bytes and
backslash, preserving source and archive bytes. Output-basename checks run
in the argument parser before the writer can inspect the filesystem.
Explicit raises of Command_Error and Usage_Error belong in the diagnostic
owner. The CLI source check rejects these raise statements elsewhere, including
qualified names, while ignoring comments and literals. This guards the named
exception paths against bypassing full diagnostic storage.

`examples/client/client.gpr` imports the project by name. The installation
check copies this client, including CPIO and TAR writer record components,
into a private scratch directory, removes inherited Ada/GPR search paths,
and discovers Arca only through the installed prefix. Through the installed
APIs it creates and closes CPIO and TAR archives, checks the newc header and
trailer, and compares empty TAR output with exactly two zero blocks. It also
emits GNU long-name metadata, compares the archive with the source-built TAR
driver and checks its synthetic record's mtime against the UTC UNIX epoch.
This exercises package initialization through the installed static library.
It cleans that scratch directory on success, failure and handled signals.
The selected builder is resolved to an absolute executable path in the
caller's initial directory before entering the copied client. This preserves
both explicit relative overrides and tool names found through relative PATH
entries. Installation-tool regressions verify both variants and record that
the selected executable actually runs in the copied client's directory.
After the successful build, hiding the installed project must produce the
specific missing-import diagnostic. This negative control verifies that
the consumer cannot silently fall back to the original source project.
The check uses the actual Make installation recipe, verifies the `arca` and
`arca-cli` manifests, uninstalls both and installs again. An unrelated prefix
file must survive removal unchanged; no Arca-installed files may remain.

`tests/check-api.py` builds record-component clients against the ordinary
library and an installed regular static extending-project view, matching
Abuild's binder ownership without importing Abuild. Compiler negative
controls reject direct lifecycle calls, controlled-parent conversion and
attempted lifecycle overrides. Selected build and installation executables
are resolved before entering the private consumer directories.

The consumer check establishes GPR packaging and compiler/linker usability.
The separate CPIO and TAR suites check raw layout, payloads, two external
readers, parallel instances, errors, reproducibility and scope-exit cleanup.
The VFAT reference check consumes committed mtools-generated FAT12, FAT16
and FAT32 images one at a time without regenerating them. It combines
independent raw decoding with `fsck.fat`, `mdir` and `mtype`, and includes
corruption controls for FAT and long-name records. It does not test an Arca
VFAT writer yet.
See the [CPIO guide](cpio.md) and [TAR guide](tar.md) for their contracts.
TAR also retains the historical GNU ustar fixture with its original producer
record; it is checked without device-node privileges.
Named Ahven suites call the shared Ada assertion scenarios directly and add
focused writer-reuse and copy tests. The small archive drivers reuse those
scenarios for Python `unittest` and independent format checks. The
[unit-test guide](unit-tests.md) explains the suites, source-test mapping,
fixture ownership, XML reports and deliberate runner failure controls.
The [predecessor-case mapping](native-test-coverage.md) identifies each original
writer assertion and the transformation behavior intentionally left in Abuild.

`tests/tests.gpr` compiles source units into its own object directory so the
private copy helper can be tested by a private child without publishing it.
Only this test project imports Ahven; the library, CLI and installed client
do not.
Installed-library usability is checked separately by the copied client.
Coverage uses distinct object and executable directories, clears previous
execution counts and checks `tests/coverage-sources.txt` against every current
production body, including the CLI's Ada and C sources. It requires a report
with executed lines for each body; the generated counts do not promise
complete branch coverage.

Library, CLI and test compilation enable `-gnatVa`, `-fstack-check` and `-gnateE`
in addition to the existing warnings, overflow and normal Ada checks. These
match Abuild's extra validity/stack checks and exception-detail policy. GPR
imports do not inherit a parent's compiler defaults automatically.

The [coding-style guide](coding-style.md) is the normative standalone source
reference for library, CLI, tests and examples. AGENTS.md requires agents to
read it before editing code. All four compiling GPR projects enable
`-gnatygAdISuxM80` alongside warnings as errors during validation; coverage
retains the profile. The library's `ARCA_BUILD_MODE` scenario accepts `release`
and `validation`, defaulting to `release` for source consumers. Release omits
`-gnatwe` and `-gnaty` options while retaining `-gnatwa`, `-gnato`, `-gnatVa`,
`-fstack-check` and `-gnateE`. Unknown modes are rejected. The CLI, test and
example projects stay strict because they are maintained with the repository.
Every Make build and installation selects validation explicitly. CI invokes
those Make targets inside the container; the launcher does not forward the
host's build-mode environment variable. Standalone style, API and coverage
checks also pass validation explicitly to their builders.
The guide explains layout, declaration contracts, modern aspect forms and
the Ada 2012 baseline with deliberate GNAT runtime dependencies.

`make check` runs `tests/check-style.py` against private source copies through
each actual project. Forced semantic compilations must accept an 80-column
comment and reject an 81-column comment with the exact style diagnostic.
These controls detect a missing project profile without changing checkout
sources or relying on existing objects. The installed client remains
self-contained and does not import a source-checkout style project.

`tests/check-packaging.py` compiles private library copies with a harmless
81-column comment and an unused import. Release accepts both and reports the
warning; validation rejects the style violation. The observed compiler
invocation must retain runtime checks and the expected warning/style policy.
The same controls cover a regular static extending project with its own
`-cargs:Ada` argument. Abuild's extending project inherits the selected library
profile and can continue adding its compiler arguments; no Abuild file is
changed. Its installed record-component consumer is checked separately.
Cleanup is exercised with an intentionally missing imported test project,
even though the reference image itself supplies Ahven.

CLI regressions compile `tests/cli_faults.c` as a temporary preload library
with the image's GCC. Only selected CLI child processes load it; its trace
proves that each intended syscall fault was reached. Production code has no
fault switches or dependency on this library. It is test support, outside the
production-body coverage inventory. Native Linux temporary fixtures verify
timestamp storage, sparse-file sizes and special permission bits before
asserting archive behavior. Maximum-size acceptance reaches an intentionally
unreadable source; rejection at max+1 happens during inventory, without
creating multi-gigabyte archive payloads.

Phase-sensitive CLI tests use the same preload library to hold the child
after the successful staging-file open, before entry emission. One inherited
pipe acknowledges readiness; another requires an explicit release byte. The
parent checks that staging is empty and the destination is unchanged before
mutating input or sending signals. Interrupted pipe calls retry. Timeouts,
EOF and unexpected tokens fail readiness. Parent pipes and child processes
have exception-safe ownership; positive release, missing-hook and parent-error
controls check the protocol and descriptor cleanup with small input trees.
Cancellation also waits for a signal-specific acknowledgement before release.
In the supported GNAT 14 runtime, the dedicated interrupt server invokes the
protected handler between successive sigwait calls. The test shim observes
the next call on that same thread, proving the handler has returned; queuing
a signal alone is insufficient. This runtime-specific observation remains
test support and introduces no production signal hook.

The CLI output transaction retains `O_PATH` directory descriptors for its
parent and staging directory. It reserves the archive exclusively,
then lets the unchanged writers open it through `/proc/self/fd`. Linux procfs
must be mounted there. The C bridge supplies target header flags while Ada
owns the filesystem calls. Rootless checks exercise write/search-only output
parents, inherited setgid, output umask, reported-mode write exclusions and
preservation of the original diagnostic during cleanup inspection failure.
Readable staging modes are accepted for mounts that report them; this is a
local permission check, not proof of a remote server's access rules.
The CLI checks its procfs descriptor path before staging allocation; a
child-only fault injection proves that a missing path gets its own diagnostic.
Ordinary staging permission failures retain their existing message.

The dedicated `tests/check-staging-security.py` coordinator uses container
root only to start the CLI and a competing process with separate unprivileged
UIDs and no supplementary groups. Its native Linux temporary fixtures and
acknowledged barriers check setup, writer opening, publication and cleanup.
CI runs that coordinator separately after rootless build and check; neither
production code nor the ordinary checks require root.

## Commands

- `make -j8 all NUM_CPUS=8` builds the static library and CLI.
- `make -j8 cli NUM_CPUS=8` builds the CLI and its library dependency.
- `make -j8 check NUM_CPUS=8` runs packaging, unit, writer and CLI suites.
- `make -j8 coverage NUM_CPUS=8` reports executed lines for all production bodies.
- `make install PREFIX=/absolute/prefix` installs the library and CLI.
- `make uninstall PREFIX=/absolute/prefix` removes `arca-cli`, then `arca`,
  using their GPRinstall manifests. Unrelated prefix files are retained.
- `make clean` removes generated GPRbuild artifacts, including test objects
  and executables without loading the Ahven-dependent test project. It keeps
  `build/`, coverage and unit reports, and the default installation prefix.

Do not run independent top-level builds concurrently against `obj/`. Install
into an empty prefix or uninstall the existing installation first. Earlier
development installations used manifest name `cli`; remove those with
`gprinstall --uninstall --prefix=/absolute/prefix cli` before upgrading.
Tests use a fresh prefix on every run.

## Consumers

GPRinstall copies `LICENSE` and `COPYRIGHT` to `<prefix>/share/doc/arca`.
The installation check compares both notices byte for byte with their source
files. Binary distributors must also provide the corresponding source
described in the [licensing guide](licensing.md); installing licence notices
alone does not fulfil those requirements.

Add this import to the consuming GPR project:

```ada
with "arca";
```

For an installed library, pass `-aP<prefix>/share/gpr` to GPRbuild. For source
integration, pass the directory containing `arca.gpr`. Pin the dependency to
an accepted commit; do not depend on a moving branch for released builds.
Every build environment must be able to fetch the pinned Arca revision.

Abuild consumes a pinned Arca revision in its own repository. Transformation
adapters, source-file inventory, coverage, dependency checkout, release
licensing, manuals and integration tests remain that consumer's responsibility.
Arca's normal checks do not depend on an Abuild checkout.

## Documentation site

The [documentation site](https://abuild-project.github.io/arca-ada/) renders
the maintained Markdown guides without a parallel prose copy. Build it in the
reference environment with:

```sh
docker/dev/build
docker/dev/run arca-dev:trixie make -j8 docs NUM_CPUS=8
```

The generated pages and search index stay below ignored `build/docs-site/`.
The build rejects broken internal links. Pull requests validate the site;
only accepted `main` builds deploy it to GitHub Pages.
Ada and shell examples use Pygments syntax highlighting during the build and
offer copy controls without loading a browser-side highlighter.

## Publication maintenance

Read the [publication status](publication.md) and
[reviewed assessment](assessments/publication.md) when maintaining the public
repository or preparing a release. [SECURITY.md](../SECURITY.md) defines
reporting guidance; GitHub's private reporting setting is enabled separately.
Keep published documentation independent of local paths, private services and
unrelated project material. Record exact revisions and evidence limits rather
than claiming that an old audit certifies later code or repository settings.

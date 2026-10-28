# CLI output transaction identity

Status: In progress on `codex/cli-staging-fix`.

Base revision: `84f8500ff5f3fb8d10b00d65c551a27d7a811b0c`.

## Decisions on 2026-10-28

- Retain output-parent and private staging directory descriptors throughout
  the CLI output transaction. Reserve the archive exclusively before passing
  its descriptor-relative procfs path to the existing writer API.
- Keep creation, publication and cleanup relative to retained identities.
  Preserve no-clobber, replacement, hard-link fallback and ambiguous-reply
  handling. Cleanup remains bounded and nonthrowing after writer unwinding.
- Preserve write/search-only parents, inherited setgid and output umask.
  Keep target-specific constants in the C bridge and syscalls in Ada.
  Document the Linux procfs runtime requirement; library APIs remain intact.
- Retain current diagnostics, cancellation and source-consumer contracts.
  Preserve the earlier unfinished worktree while porting its implementation.

## Implementation

1. Preserve the existing working diff and tests; independently trace current
   callers, lifecycle, shared enforcement and compatibility constraints.
2. Demonstrate the original behavior with synchronized, isolated Linux
   controls, then implement and test the retained transaction identities.
3. Challenge the candidate with one independent bypass/regression review.
   Run focused checks, legitimate controls, the full check and coverage in
   the reference rootless AMD64 Trixie environment. A dedicated coordinator
   may run as root solely to launch victim/attacker children under distinct
   unprivileged UIDs; neither child retains root.
4. Update affected guides, changelog, indexes and the canonical change record.
   Keep audit artifacts private. Publishing the patch remains a separate
   maintainer action after the fix has been verified.

## Progress

The old working diff and untracked test are preserved. Current-source tracing
and an independent investigation confirm the shared transaction boundary and
the required compatibility controls. Implementation and runtime proof follow.

Co-Authored-By: GPT-6 <noreply@openai.com>

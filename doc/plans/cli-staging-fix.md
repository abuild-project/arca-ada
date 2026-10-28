# CLI output transaction identity

Status: Implemented and verified locally on `codex/cli-staging-fix`.

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

Current-source tracing and independent investigation confirmed the shared
transaction boundary and compatibility controls. Separate immutable-baseline
and fixed executables pass the expected original-behavior and
protected-behavior tests under distinct unprivileged UIDs. Cleanup inspection
could overwrite the original CLI diagnostic; raw status inspection prevents
this, and the focused test rejects the earlier candidate at that diagnostic.

Both formats and all publication routes pass setup, pre-open, post-open,
parent-renaming, writer-error and handled-signal controls. Ordinary and
forced valid archives remain byte-identical to baseline output on the
bounded corpus. The rootless CLI suite passes with permission and umask
controls. Coverage then the full check pass on freshly archived committed
sources in AMD64 Trixie.

Co-Authored-By: GPT-6 <noreply@openai.com>

# CLI output transaction identity

The CLI now binds archive creation, publication and cleanup to retained
output-parent and staging-directory objects. A second local principal able
to rename entries in a shared output parent cannot redirect the writer's
open or make a successful publication select a substituted archive. Both
CPIO and TAR use the same transaction; their public writer APIs and archive
serialization are unchanged.

`Begin_Output` opens the existing parent with target-derived no-follow
directory flags, creates a private staging directory through that parent,
and retains its descriptor. It checks effective ownership and owner-only
access while permitting inherited setgid. It reserves `archive` with
exclusive no-follow creation before the unchanged writer opens its
descriptor-backed pathname. The archive file keeps the conventional
`0666 & umask` permissions.

Forced replacement uses descriptor-relative `renameat`. Default publication
keeps `renameat2` no-replace behavior and its same-filesystem `linkat`
fallback. An ambiguous link reply is accepted only after checking the
destination's regular-file identity through the retained parent. Cleanup
removes at most the owned archive entry and one empty staging directory;
it never recurses through a replaceable name. Both descriptors are released
after writer finalization. Cleanup inspection uses a raw status result,
so a secondary failure cannot overwrite the primary CLI diagnostic.

The CLI now requires mounted Linux procfs at `/proc/self/fd` for its writer
path. The public library remains independent of procfs. Existing rootless
use with write/search-only output parents, inherited setgid, source/output
metadata, no-clobber, `--force`, handled signals and error codes is retained.
Target constants remain in the C bridge; Ada owns the calls and transaction
state. The CI coordinator is root only to launch distinct unprivileged
victim and competing processes; no production command needs root.

## Validation

The original source at baseline `84f8500ff5f3fb8d10b00d65c551a27d7a811b0c`
was built separately from the fix. Synchronized real-UID probes demonstrate
the original boundary failure across setup, opening, publication and cleanup
for both formats and default, forced and link-fallback publication. The same
probes pass after the fix. The coordinator also checks parent rebinding,
writer errors and each handled termination signal; its children have no
supplementary groups. No real user file or credential is used.

The focused rootless suite checks output permissions under several umasks,
write/search-only and setgid parents, the target-header flag bridge and the
existing CLI behavior. A cleanup-inspection regression rejects the earlier
fix candidate at the diagnostic that displaced the actual failure and passes
after raw status inspection. The independent candidate review found this
regression and no surviving path substitution route.

The complete rootless Trixie checks and fresh-source coverage are recorded
with the final implementation validation. ARM64 and filesystems lacking
both supported publication methods remain outside this evidence.

Co-Authored-By: GPT-6 <noreply@openai.com>

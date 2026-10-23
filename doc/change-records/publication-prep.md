# Publication preparation and audit

Arca needs an explicit publication decision with reviewable evidence rather
than relying on private-bootstrap status text. This change adds the exact
owner-approved root SECURITY.md, a maintainer publication checklist and an
indexed readiness assessment. README, CONTRIBUTING, AGENTS and development
guidance point to those documents. The documented original source commit is
now verified in the owner's private mirror; public verifiability remains a
gate. Irrelevant style comparisons are removed without rewriting history.

The publication review covers all locally reachable refs at accepted main
03a2a076: 63 commits, 468 distinct blobs, 58 available latest-attempt CI job
logs and all 19 retained Ahven ZIP artifacts. Every artifact's bytes match
its GitHub size and SHA-256, and all 114 XML members were read as data.
No credential, private key or private-infrastructure disclosure was found.
The assessment records methods and exclusions, including unavailable server
refs, expired/deleted artifacts and future CI outputs.

The separate completed current-source security audit covers all 114 tracked
files of 03a2a076 and reports one medium CLI staging-identity finding. Its
creation and publication operations share the same missing ownership control;
both are preserved in the finding. Private or protected sticky output parents
prevent the conditional local attack. This documentation change records the
publication block; the authorized remediation is a separate security change.
The static audit does not certify later source or execute an exploit.

## Validation and review

Rootless AMD64 Trixie passes the complete normal check and coverage targets.
This includes 19 named Ahven cases, independent CPIO/TAR raw and external
reader checks, all 31 CLI cases, installed-client isolation, selected-tool
regressions and all four compiler style controls. The two optional predecessor
comparisons remain skipped in normal standalone tests. All nine inventoried
production bodies have executed coverage; this PR changes no source or GPR
profile. Documentation link and whitespace checks pass.

The author reviewed the complete patch against source, existing grants and
the captured evidence: the policy matches the approved text, audit scope and
runtime limits are explicit, historical licensing states remain historical,
and pending publication and integration gates are not marked satisfied.
Repository settings, visibility, namespace, releases and tags are unchanged.
The Abuild proof branch remains separate and local; it is no test dependency.

Independent static review found no concrete issue across the complete patch,
reproduced historical inventory counts and checked the approved policy and
relative links. It identified a retained partial/deferred inconsistency in
the sealed scan metadata; the assessment discloses that limitation without
altering canonical artifacts or dropping the validated publication operation.

Co-Authored-By: GPT-6 <noreply@openai.com>

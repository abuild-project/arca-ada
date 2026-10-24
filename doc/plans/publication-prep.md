# Publication preparation

Status: Accepted in `b5c0f11` (PR #9) on 2026-10-23. Publication gates remain
open; see [publication guidance](../publication.md).

## Scope

Prepare a separate reviewable change before the owner transfers Arca or makes
it public. Keep both repository settings unchanged. The accepted starting
revision is `03a2a0763f1e55f3c0650ce1da8a9063c5eb4066` (PR #8).

## Steps

1. Review all locally reachable history, current source, CI logs and retained
   artifacts for publication-sensitive material. Record methods, actual
   coverage and remaining gates in an indexed assessment.
2. Complete a separate static security audit of the immutable starting tree.
   Record its revision, scope, result and limits without claiming runtime
   proof or extending it to later source changes.
3. Add the exact owner-approved root security reporting policy. Clean stale
   status/provenance text and irrelevant comparisons. Link release, reporting
   and publication guidance from the agent and contributor entry points.
4. Verify documentation links, build/test and coverage in the reference
   environment; self-review and independently review the committed change.
5. Push a normal topic and open the publication-preparation PR. Actual
   transfer, public visibility and release publication remain later actions.

## Related work

The local Abuild integration branch separately tests the pinned library
dependency, retained transformation contracts and CPIO/TAR/OCI regressions.
Arca tests remain independent of that checkout.

## Progress

- PR #8 was merged after green CI and Copilot's approval recommendation.
- The owner approved the exact SECURITY.md proposal; it is applied.
- History inspection completed: 63 reachable commits and 468 distinct blobs;
  no credential or private-infrastructure disclosure was identified.
- All 58 available workflow job logs and 19 retained Ahven ZIP artifacts were
  read; ZIP sizes/digests match GitHub and no sensitive material was found.
- The recorded source revision exists in the owner's private Abuild mirror.
  A publicly fetchable provenance reference remains a publication gate.
- Static code audit completed with one medium staging-identity finding. It
  blocks publication and has a separately authorized remediation.
- Rootless Trixie normal checks and coverage pass; all nine production bodies
  are reported. Documentation and author review are complete.
- Independent static review found no concrete issue; the assessment records
  the scan's retained partial/deferred metadata inconsistency. PR delivery
  follows. The local Abuild
  integration is a separate active experiment and remains a publication gate.

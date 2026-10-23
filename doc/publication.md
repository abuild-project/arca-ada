# Publication checklist

The owner intends to transfer `mweidle73/arca-ada` to
`abuild-project/arca-ada`, then decide on public visibility. This document
prepares that decision. No transfer, visibility change, tag, release or Alire
submission is performed by the preparation PR.

## Before the owner decision

- Read the [publication assessment](assessments/publication.md), close its
  blocking findings and review changes made since its recorded revision.
- Retain the source revisions and attribution recorded in
  [licensing](licensing.md); no separate public predecessor reference is a
  publication condition.
- The separate local Abuild CPIO/TAR/OCI integration experiment is complete
  and reviewed. Retain its evidence; Arca's normal tests must still run
  without an Abuild checkout, credentials or network access.
- Review every reachable ref/history, CI log and retained artifact for
  sensitive material, including new artifacts produced by this PR. Existing
  historical licence states do not by themselves require rewriting history.
- Run the documented rootless Trixie checks and coverage at the exact commit
  selected for publication. Read CI job status and relevant logs.
- Verify the destination organization, repository permissions, default branch,
  required CI checks, branch protection/rulesets and Actions permissions with
  the owner. Main protection is configured with strict GitHub Actions trixie
  checks, pull requests, resolved conversations, administrator enforcement
  and blocked force pushes/deletion. The
  [recorded request](repository-protection.json) preserves the policy.
  Recheck the effective settings after a transfer.
- Enable and verify GitHub private vulnerability reporting when available.
  Check that the root [SECURITY.md](../SECURITY.md) and the actual reporting
  UI agree; a Markdown file does not configure GitHub.

## Transfer and public switch

Obtain the owner's explicit instruction for each external action. Transfer
while private, verify organization access and clone/fetch permissions, and
then decide public visibility. Update explicit repository links
and downstream pinned dependency URLs to the verified destination. Test an
anonymous fresh clone and standalone build after the public switch; do not
treat GitHub redirects as the only permanent dependency configuration.

## First release

Choose an API/version policy and supported platform scope before tagging.
Document the 64-bit Linux CLI and the reference AMD64 Trixie validation;
selecting an ARM wrapper is not evidence that ARM was tested. Pin the
released source revision and review source/archive and binary inventories.
Provide the complete corresponding source of any distributed binary,
including the applicable build/install scripts, as described in the
[licensing guide](licensing.md). GPRinstall notices alone do not supply it.
Release automation and an Alire index submission are separate changes.

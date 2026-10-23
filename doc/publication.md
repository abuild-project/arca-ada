# Publication checklist

The owner intends to transfer `mweidle73/arca-ada` to
`abuild-project/arca-ada`, then decide on public visibility. This document
prepares that decision. No transfer, visibility change, tag, release or Alire
submission is performed by the preparation PR.

## Before the owner decision

- Read the [publication assessment](assessments/publication.md), close its
  blocking findings and review changes made since its recorded revision.
- Establish a publicly fetchable reference for the exact imported predecessor
  sources. Verify the manifest's blob identities and hashes; retain the
  additional LGPL grant and original attribution.
- Complete the separate Abuild integration experiment, including CPIO, TAR
  and OCI transformation regressions. Arca's normal tests must still run
  without an Abuild checkout, credentials or network access.
- Review every reachable ref/history, CI log and retained artifact for
  sensitive material, including new artifacts produced by this PR. Existing
  historical licence states do not by themselves require rewriting history.
- Run the documented rootless Trixie checks and coverage at the exact commit
  selected for publication. Read CI job status and relevant logs.
- Verify the destination organization, repository permissions, default branch,
  required CI checks, branch protection/rulesets and Actions permissions with
  the owner. The initial reviewed `main` has no protection; this PR does not
  change server settings.
- Enable and verify GitHub private vulnerability reporting when available.
  Check that the root [SECURITY.md](../SECURITY.md) and the actual reporting
  UI agree; a Markdown file does not configure GitHub.

## Transfer and public switch

Obtain the owner's explicit instruction for each external action. Transfer
while private, verify organization access and clone/fetch permissions, and
then decide public visibility. Update explicit repository/provenance links
and downstream pinned dependency URLs to the verified destination. Test an
anonymous fresh clone and standalone build after the public switch; do not
treat GitHub redirects as the only permanent dependency configuration.

## First release

Choose an API/version policy and supported platform scope before tagging.
Document the 64-bit Linux CLI and the reference AMD64 Trixie validation;
selecting an ARM wrapper is not evidence that ARM was tested. Pin the
released source revision and review source/archive and binary inventories.
Provide complete corresponding library source and the application material
needed for relinking any distributed static executable, as described in the
[licensing guide](licensing.md). GPRinstall notices alone do not supply it.
Release automation and an Alire index submission are separate changes.

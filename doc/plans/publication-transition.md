# Public repository transition

Status: Public; documentation follow-up implemented locally.

Selected source revision: `e3892da2ec4c6dbce313f5dd80866cf153ade29b`.

## Decision and evidence on 2026-11-03

The repository became public before its transfer from the personal account
to the organization. This order retained the effective `main` protection:
GitHub Free supports protected public branches but not protected private
branches in the destination organization. The source revision, open pull
requests, workflow runs and artifacts had not changed since the final
publication review. No new source or release tag was introduced by either
GitHub operation.

At the destination, verify the canonical URL, default branch, main protection,
Actions policy, private vulnerability reporting, anonymous fetch and a
standalone rootless Trixie build. Read the job and relevant logs for a workflow
dispatched after transfer. Keep the first release separate.

The organization profile links to the repository README until a dedicated
GitHub Pages documentation site is published. Replacing that link is a later
documentation task, not a condition for the repository transition.

## Documentation work

1. Update maintained publication and contributor guidance to the public
   destination. Append a dated disposition to the historical assessment.
2. Mark the previous staging-status topic accepted by its merge commit in
   its plan and both indexes. Add this plan and the canonical change record
   to their sorted indexes; update the changelog.
3. Inventory old repository links. Keep historical PR and workflow links
   readable through GitHub redirects; use the canonical destination for new
   maintained links. Track downstream pinned URLs separately where a relative
   URL still depends on the former owner namespace.
4. Check relative documentation links and whitespace. The documentation-only
   follow-up does not change library or CLI behavior.

## Completion evidence on 2026-11-03

The destination is public at the selected commit. Protection, Actions and
private vulnerability reporting remain effective. The post-transfer Trixie
workflow `41612211026` passed after fresh-checkout coverage, normal checks
and cross-UID staging tests. An anonymous HTTPS clone passed the documented
rootless AMD64 coverage and check targets. Historical PR and workflow links
were resolved through GitHub's redirect. Current publication guidance uses
the canonical destination, while the Abuild integration URL and future
Pages site remain separate follow-ups. The organization profile now lists
Arca and links to its README until the documentation site is available.

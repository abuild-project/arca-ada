# Publication status

Arca became public at
[abuild-project/arca-ada](https://github.com/abuild-project/arca-ada)
on 2026-11-03. The selected source revision was
`e3892da2ec4c6dbce313f5dd80866cf153ade29b`. Public source availability
does not constitute a versioned release; `Arca.Version.Value` remains
`0.1.0-dev`, with no release tag or asset.

## Publication evidence

- The [publication assessment](assessments/publication.md) retains the
  reviewed history, security findings, licensing disposition and dated
  resolution. A final review of the selected revision, reachable GitHub refs,
  available CI logs and retained artifacts found no new publication blocker.
- The accepted CLI staging fix is in `d715d62`. The separate post-audit code
  review found no new reportable finding through the selected revision.
  Earlier predecessor-source snapshot requirements remain retired under the
  [GPL licensing disposition](licensing.md).
- An [Actions run at the new repository](https://github.com/abuild-project/arca-ada/actions/runs/41612211026)
  passed for the exact selected commit. Its Trixie job includes fresh-checkout
  coverage, normal checks and the dedicated cross-UID staging step. An
  anonymous HTTPS clone at the new URL passed rootless AMD64 Trixie coverage
  and checks in separate invocations.
- After transfer, the [recorded protection policy](repository-protection.json)
  remains effective: changes to `main` require a pull request, the strict
  GitHub Actions `trixie` check and resolved conversations. Administrators are
  subject to the rule; force pushes and branch deletion remain blocked.
  GitHub Actions and private vulnerability reporting are enabled. The root
  [security policy](../SECURITY.md) describes the reporting channel.
- Repository-level secret-scanning alerts, push protection and Dependabot
  alerts are enabled. Actions accept only GitHub-owned actions pinned to full
  commit SHAs; workflows from external fork contributors require approval.
  The [Trixie run under these settings](https://github.com/abuild-project/arca-ada/actions/runs/41619479596)
  passed on the selected source revision.
- The former repository URL redirects to the organization. Historical plans
  and change records retain their dated links. New maintained references use
  the canonical organization URL.

## Continuing work

- Check and update downstream pinned dependency URLs when those changes are
  delivered. The local Abuild integration branch still has a relative Arca
  submodule URL whose GitHub resolution begins at the former owner; its
  redirect is not a permanent dependency configuration.
- Build a navigable GitHub Pages site from the maintained guides. The
  organization's current Documentation link intentionally points to the
  repository README until that site is published; replace it afterward.
- Follow the [release procedure](release.md) for version promotion, tags,
  source archives, checksums and corresponding-source delivery. Release and
  Alire publication require their own decisions and validation.

After future source or workflow changes, assess the new revision and CI
evidence on their own terms. The publication evidence above belongs to the
selected immutable commit.

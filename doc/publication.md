# Publication status

Arca became public at
[abuild-project/arca-ada](https://github.com/abuild-project/arca-ada)
on 2026-11-03. The selected source revision was
`e3892da2ec4c6dbce313f5dd80866cf153ade29b`. Public source availability
and versioned releases are distinct. `Arca.Version.Value` identifies the
source version; [GitHub Releases](https://github.com/abuild-project/arca-ada/releases)
lists published tags and artifacts.
The current `main` branch carries `0.2.0-dev` for the next development line.

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
- The [documentation site](https://abuild-project.github.io/arca-ada/) was
  published from merge commit `4c594da` (PR #19). Its
  [Actions run](https://github.com/abuild-project/arca-ada/actions/runs/41635919473)
  passed the Trixie documentation build, artifact upload and Pages deployment.
  Anonymous HTTPS access, guide navigation and site search passed. The
  organization's Documentation link points to the live site.
- [Arca 0.1.0](https://github.com/abuild-project/arca-ada/releases/tag/v0.1.0)
  is the first versioned source release, from merge commit `2c57cea` (PR #21).
  The [main CI](https://github.com/abuild-project/arca-ada/actions/runs/41669851310)
  and [tag CI](https://github.com/abuild-project/arca-ada/actions/runs/41676660662)
  passed. GitHub reports the release as immutable, Latest and not a
  prerelease. Its checked source asset has SHA-256
  `c64644280fabf43ee863249f6732d6aef798b084b00d4d61a96df91897430b48`;
  no binaries were published.

## Continuing work

- Check and update downstream pinned dependency URLs when those changes are
  delivered. The local Abuild integration branch still has a relative Arca
  submodule URL whose GitHub resolution begins at the former owner; its
  redirect is not a permanent dependency configuration.
- For later versions, follow the [release procedure](release.md) for version
  promotion, tags, source archives, checksums and corresponding-source
  delivery. Alire publication requires its own decision and validation.

The source and transfer evidence above belongs to the selected immutable
commit; Pages validation belongs to `4c594da`, and first-release evidence
belongs to `2c57cea`. After future source or workflow changes, assess the
new revision and CI evidence on its own terms.

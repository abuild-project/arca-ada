# Navigable documentation site

Status: Implemented locally; Pages deployment pending acceptance.

Base revision: `56b463a6e2ddb98b129e56c7a708279eaebb7b87`.

## Scope and decision on 2026-11-03

Publish a GitHub Pages site from Arca's maintained Markdown. The canonical
sources remain README, the user and developer guides, contribution and
security guidance, licensing, release and changelog documents. Build-time
copies may adapt relative links for site navigation; no parallel prose copy
is maintained. Historical plans, change records and assessments remain
reachable in the repository without crowding the primary navigation.

Use MkDocs Material supplied by the Debian Trixie development image. Its
site-wide navigation and local search fit the current documentation better
than an individual table of contents on each generated page. The build must
not fetch fonts, scripts or packages at runtime. Use the existing rootless
development wrapper for the site build and `mkdocs build --strict` to reject
broken internal document links.

Extend the current CI workflow: its required `trixie` job builds the site on
pull requests and pushes. A separate deployment job consumes the built Pages
artifact only for the default branch, with `pages: write` and `id-token: write`
scoped to that job. All added Actions remain GitHub-owned and pinned to full
commit SHAs, matching the repository's Actions policy. Configure Pages to
publish through Actions only after the source and workflow are accepted.

## Steps

1. Select and stage maintained Markdown files without committing generated
   copies. Resolve links between selected pages locally and send other
   repository-relative references to their canonical GitHub source paths.
2. Add a concise site configuration and a dedicated Make target. Keep the
   resulting site under ignored `build/`; do not bundle repository history,
   test fixtures or local artifacts into the Pages upload.
3. Validate a rootless Trixie build, required pages, navigation, search data,
   link targets and output contents. Prove the strict link check rejects a
   deliberately broken document link in an isolated copy.
4. Add the Pages build and guarded deployment jobs, document the local build
   and public URL, update the changelog and indexed change record, then
   review the PR. Deploy only after acceptance and verify the live site.
5. Replace the organization profile's temporary Documentation link with the
   live Pages URL after successful deployment; keep the first versioned
   release as a separate action.

## Local validation on 2026-11-03

The Debian Trixie image builds with MkDocs Material, and the rootless site
target renders 14 selected Markdown pages, a search index and navigation for
the CLI, both writers, development and project guidance. The generated output
contains no symlinks and does not request external font assets. A deliberately
broken local Markdown link makes `mkdocs build --strict` fail; regenerating
from unchanged sources restores a successful build. The Pages deployment and
live destination cannot be verified until the accepted workflow runs on main.
The local preview shows the expected guide navigation and site search, and
generated HTML navigation and asset targets resolve within the site.

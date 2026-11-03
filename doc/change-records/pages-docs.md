# Navigable documentation site

The documentation site renders Arca's maintained Markdown through MkDocs
Material, with site-wide navigation, search and a public repository link.
The canonical content stays in README, the format and CLI guides, developer
guidance, contribution and security policies, licensing, publication, release
and changelog files. Build-time staging copies those selected sources and
rewrites relative links. References to repository files outside the selected
site pages lead to the canonical GitHub source instead of a broken local path.
Historical plans and change records remain discoverable through the README
and repository, without crowding the site navigation.

MkDocs Material is supplied by Debian Trixie while constructing the existing
development image; the documentation build installs no runtime packages.
`make docs` keeps generated input and output below ignored `build/` and uses
MkDocs strict mode to reject broken local pages or anchors. No library or CLI
source, archive format or supported platform changes.

The existing `trixie` CI job builds the documentation site on pull requests
and pushes. Only default-branch push or manual runs upload a Pages artifact;
a separate job deploys it after `trixie` succeeds. The deploy job alone has
`pages: write` and `id-token: write`. Added Actions are GitHub-owned and pinned
to full commit SHAs, matching the repository's Actions policy. The static
upload contains selected pages, local theme assets and the search index,
without build objects, test fixtures or historical repository trees.

The README links to the site so visitors can find the guides from the
repository front page.

In rootless AMD64 Trixie, the site build produced the expected guide pages,
navigation and search index. Generated HTML navigation and asset paths resolve
within the site; the output contains no symlinks or external font requests.
An isolated deliberately broken Markdown link failed the strict build with
the expected missing-target diagnostic; restoring the canonical sources
passed again. Deployment requires the workflow on main and the repository's
GitHub Pages workflow setting. The first versioned release remains separate.

Co-Authored-By: GPT-6 <noreply@openai.com>

# Public repository transition

Arca is publicly available at `abuild-project/arca-ada` from accepted source
revision `e3892da2ec4c6dbce313f5dd80866cf153ade29b`. Public visibility
preceded the transfer to the GitHub Free organization so that the existing
`main` protection stayed effective. This change records
the resulting repository state and updates maintained reader guidance;
library and CLI code and behavior are unchanged.

The final publication review covered the selected source, all GitHub-reachable
commits and pull-request heads, available workflow logs and retained unit-test
artifacts. It found no new credential or private-infrastructure candidate.
The post-audit code diff had no new reportable security finding after manual
review of the Ada files omitted by the automatic inventory. The previous
staging finding was fixed before the public transition.

The public destination preserves strict `trixie` checks, resolved
conversations, administrator enforcement and blocked force pushes/deletion.
GitHub Actions and private vulnerability reporting are enabled. An Actions
run after transfer passed on the selected revision, including coverage,
normal tests and the cross-UID staging check. A fresh anonymous HTTPS clone
passed rootless AMD64 Trixie coverage and checks. No versioned release tag
or release asset was published.

The current publication status, assessment and contributor links now identify
the public destination. Historical dated links remain readable through
GitHub's redirect. Abuild's local integration branch still needs a permanent
dependency URL when it is delivered; this topic does not change that branch.
The public repository has topics for its Abuild family, Ada library, archive
formats and CLI. The organization profile's Documentation link temporarily
targets the Arca README. A later GitHub Pages documentation site will replace
it, without blocking this source publication or implying a versioned release.

Checks for this documentation follow-up: compare the selected commit and
post-transfer workflow to GitHub, inspect the anonymous clone results, verify
relative Markdown links, confirm the prior dated assessment text was only
extended, and run `git diff --check`. No runtime tests are added for these
Markdown-only changes; the runtime evidence belongs to the unchanged source
revision named above.

Co-Authored-By: GPT-6 <noreply@openai.com>

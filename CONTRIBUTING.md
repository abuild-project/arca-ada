# Contributing

Read the [development guide](doc/development.md) and
[licensing policy](doc/licensing.md) before contributing. The
[coding-style guide](doc/coding-style.md) applies to every maintained Ada unit.
Report vulnerabilities through [SECURITY.md](SECURITY.md) using its private
GitHub reporting channel. Keep vulnerability details out of public issues.

Use small commits that build independently. Separate behavior-preserving
extraction from format changes and Abuild integration. Include tests that
would detect a violation of the documented contract.
Before first submission of a new, unpublished topic, follow
[submission preparation](doc/development.md#submission-preparation) to fold
local fixups into coherent commits before final test and review handoffs.

Use `codex/<topic>` for topic branches and continue the matching existing plan
when there is one. Agent-led contributions follow the
[coordinator, developer, tester and reviewer workflow](doc/development.md#agent-workflow)
required by [AGENTS.md](AGENTS.md), including independent review and separate
bounded local and PR correction budgets. Complete
[PR preparation and Copilot review](doc/development.md#pull-request-preparation-and-submission)
within the explicitly authorized stages. Preparation alone grants no
push/create permission; already authorized submission steps need no repeated
confirmation. Merge, release and settings changes need separate authorization.

Submit new project-owned contributions under GPL-2.0-or-later. Retain
copyright and licence notices for imported material. Code derived from Abuild
keeps that licence and its attribution; record its origin revision in
doc/licensing.md. Add third-party source only under compatible terms.

Releases, Alire publication and repository ownership changes are maintainer
decisions outside normal contributions. The
[publication status](doc/publication.md) records the current home; the
[release procedure](doc/release.md) covers versioned releases.

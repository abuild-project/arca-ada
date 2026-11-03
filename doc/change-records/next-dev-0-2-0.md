# Next development line

After the source-only `v0.1.0` release, the tracked pure version package
starts the next minor development line at `0.2.0-dev`. The CLI's `--version`
output and installed example client continue to derive from that one value.
The change introduces no writer API, archive-format or CLI creation behavior.

The README distinguishes the moving development branch from the immutable
`v0.1.0` release. Maintained publication guidance records the release's
accepted revision, main and tag CI, verified source-asset digest and
immutable Latest status. The release plan and both indexes now show the
accepted merge commit. Historical dated evidence remains unchanged.

The Unreleased changelog section stays empty because a development version
marker alone is not a user-facing release change. New capabilities and
compatibility changes will be recorded there as they are introduced. The
release procedure now states that distinction explicitly.

In rootless AMD64 Trixie, the full check target passed. The CLI reported
`arca 0.2.0-dev`, and the installed example client reported the same version.
The strict documentation build passed with the new links. Production bodies
and their coverage inventory are unchanged; coverage was not repeated for
this metadata and documentation topic.

Co-Authored-By: GPT-6 <noreply@openai.com>

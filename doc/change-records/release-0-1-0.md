# First versioned source release

This change prepares version `0.1.0` as Arca's first versioned source state.
`Arca.Version.Value` is the sole operative version; the CLI and installed
example client report it through their existing paths. No archive writer or
CLI creation behavior changes.

The changelog now summarizes what a user or integrator receives: the CPIO
and TAR writers, archive CLI, installation and version interfaces, and
documentation site. It does not present private development changes as
release-to-release changes when no earlier public release exists. Licensing
and TAR lifecycle contracts remain in their dedicated guides. Detailed
implementation steps, test controls and publication history stay in the
guides and indexed change records. The empty Unreleased section remains for
later work.

The README no longer claims that no release exists and links to the releases
page. The maintained publication status distinguishes public source from
versioned artifacts without pinning a mutable delivery state. The release
procedure clarifies that planning and validation do not themselves publish
a release. The first release follows the documented source-only archive and
checksum path; binary distribution has separate corresponding-source needs.

Release tags and assets are tied to the accepted main revision after its CI
and unpacked-source checks. The changelog date must match that publication
date if the release is delayed.

Co-Authored-By: GPT-6 <noreply@openai.com>

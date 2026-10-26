# Version, compatibility and release procedure

`Arca.Version.Value` supplies the project's single operative version,
`0.1.0-dev`. The pure package is exported through `arca.gpr`. CLI `--version`
prints `arca VERSION`, and the example client includes the public value in
its import confirmation. The installation check compares that client output
with the installed CLI version.

The metadata unit adds no package body or runtime initialization. Existing
writer declarations and bodies are unchanged. A regular static extending
project retains its empty interface override and consumer-owned binder;
ordinary, installed and extending-project clients import the new public
metadata. Abuild files are unchanged, and archive emission keeps its bytes.

The README defines public writer/version interfaces, published `0.y` source
compatibility within a minor line, explicit changelog/migration guidance for
breaks and rebuild requirements. Development prereleases remain provisional.
The platform scope is 64-bit Linux with 64-bit Long_Integer and
Interfaces.C.long. AMD64 Trixie with GNAT 14 is the validated reference;
selectable ARM64 has no validation claim.

`doc/release.md` centralizes version promotion, fresh-source validation,
annotated tags, source archives, checksums and corresponding-source delivery.
The publication checklist links to it. The development suffix remains in the
source; version promotion, tag and publication actions remain maintainer
decisions. The workflow documents rather than performs those actions.

The CLI source guard rejects explicit raises of Command_Error or Usage_Error
outside the diagnostic owner, including qualified names. It ignores Ada
comments, string literals and character literals and requires the owner to
retain both exception paths as positive controls. This preserves the named
raise-statement convention behind full diagnostic storage.

## Validation

The strict CLI build, version/source controls, complete CLI suite and
installation check pass in rootless AMD64 Trixie with GNAT 14.2. Against
baseline `953a257c1fcc235eb78aeaa8fb39b938f54342c0`, the version control
rejects `arca development`; the already-centralized exception source passes
its positive control. Ordinary and regular static extending-project clients
both compile, run and print the development version. The copied installed
client agrees with the installed CLI and retains archive initialization,
uninstall/reinstall and isolation checks.

Isolated source copies replace one command raise and one usage raise with
direct statements, including a qualified exception name. Both variants build
under the strict Ada profile and are rejected by the source guard at the
intended statement. Changing only the version constant to a distinct valid
prerelease updates CLI and installed-client output, proving the shared source.

A development source archive and SHA-256 checksum are generated and verified.
Coverage runs first in its freshly unpacked sources without Git metadata or
existing build output, followed by the full check. Both pass, including
compiler-style controls, public API clients, independent format checks,
installation, CLI and body-inventory coverage. No body or omission entry is
added for the pure specification. The preserved CLI and writer archive corpus,
including GNU reference output, remains byte-identical.

Author review checks the public additive interface, version coupling,
diagnostic ownership, mutation sensitivity, archive integrity, documentation
and release commands, links, source style and commit attribution. CLI and
client analysis views load with the explicit Arca search path; file-scoped
diagnostics are clear for the changed Ada sources. ARM64 and newer compilers
remain untested. The source stays at its development version; tag and release
commands are documented for a later maintainer action.

Co-Authored-By: GPT-6 <noreply@openai.com>

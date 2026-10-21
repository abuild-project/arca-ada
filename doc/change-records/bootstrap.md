# Repository bootstrap

Arca starts as an independent Ada library project with a root namespace and
a client that imports its GPR project. A packaging check builds a second copy
of the client against an isolated installation. A Trixie development image
and GitHub workflow provide the same build and check command.

The bootstrap contains no archive or filesystem writer. Existing Abuild
behavior, dependencies and documentation remain unchanged. The new files use
BSD-3-Clause; importing the existing GPL-covered writers requires the separate
provenance and additional-grant work described in `doc/licensing.md`.

The README serves as the bootstrap user guide and identifies the absence of
format functionality. The development guide documents build and integration
contracts, and the changelog records only the infrastructure introduced here.

## Validation

Local validation used an identical source snapshot in Abuild's supported
Trixie development container because the session only permits that existing
container launcher. The library and client compile without warnings. The
installed consumer passes, and hiding the installed GPR project produces the
expected missing-import diagnostic. A clean followed by the parallel check
target also passes.

Ada MCP reports complete project views for the library and client, complete
anchored symbol results and no file-scoped diagnostics for either Ada source.
Semantic analysis helped verify independent project discovery; it does not
replace the container build evidence.

Shell syntax, source line lengths, final newlines, whitespace, generated-file
exclusions and the complete proposed diff were checked during author
self-review. The review rechecked licensing and documentation claims, the
isolation test's negative control and the lack of introduced mutable writer
state. No production format behavior or performance claim needs validation
in this bootstrap. The source inventory contains no production bodies, so
there is no body-coverage omission to add.

Remote upload and CI verification remain pending. The private repository
exists, but the host push is not available to this session and the API token
lacks the `workflow` scope required to add the prepared Actions file. The
locally committed source and executable modes are ready for upload.

## Review lessons

- Claims are scoped to project packaging; no format, performance or coverage
  claim is made by the client check.
- Existing GPL code and fixtures are excluded from the BSD bootstrap.
- The installed consumer clears inherited Ada and GPR search paths.
- Hiding its installed GPR file verifies the test's project-discovery
  sensitivity; the failure must name the missing Arca import.
- Scratch paths are private to each check and cleaned on failure and signals.
- No mutable writer state, containers, file streams or production bodies are
  introduced; format lifecycle and concurrency tests belong to their imports.

Co-Authored-By: GPT-6 <noreply@openai.com>

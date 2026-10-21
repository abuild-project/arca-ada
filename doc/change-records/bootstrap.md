# Repository bootstrap

Arca starts as an independent Ada library project with a root namespace and
a client that imports its GPR project. A packaging check builds a second copy
of the client against an isolated installation. A Trixie development image
and GitHub workflow provide the same build and check command.

The default development shell forwards standard input and receives a TTY
when invoked from a terminal. Explicit commands retain batch-mode input and
terminal behavior. Host-side regression tests exercise both shell modes and
the explicit-command case with real containers.

Build-tool preflight checks the GPR executables selected by Make, including
values assigned in a Makefile. Restricted-PATH regression checks cover valid
overrides, fallback names and missing overrides masked by available defaults.
The installed-client check resolves its selected builder before changing
directories, preserving explicit relative paths and relative PATH lookups.

The bootstrap contains no archive or filesystem writer. Existing Abuild
behavior, dependencies and documentation remain unchanged. The new files use
BSD-3-Clause; importing the existing GPL-covered writers requires the separate
provenance and additional-grant work described in `doc/licensing.md`.

The README serves as the bootstrap user guide and identifies the absence of
format functionality. The development guide documents build and integration
contracts, and the changelog records only the infrastructure introduced here.

## Validation

Local validation used an identical source snapshot in Abuild's supported
Trixie development container. The library and client compile without
warnings. The installed consumer passes, and hiding the installed GPR project
produces the expected missing-import diagnostic. A clean followed by the
parallel check target also passes.

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

The bootstrap is uploaded to the private repository. The initial
[GitHub workflow](https://github.com/mweidle73/arca-ada/actions/runs/39592187985)
passes from a fresh checkout, builds the repository's own Trixie image and
runs the same consumer and installation checks. The job status and relevant
build logs have been read. The review follow-up below adds launcher coverage
that the initial workflow did not exercise.

The shell regression tests fail against the original launcher for both piped
input and terminal input, while its explicit-command test passes. With the
launcher correction, all three cases pass in the supported Trixie image.
CI runs the same cases against its freshly built development image.

The preflight regressions reject the original implementation: it rejects
valid command-line and Makefile tool selections, and accepts missing selected
tools when default names exist. The corrected implementation passes these
cases and retains default-name fallback. The complete parallel `make check`
target includes these regressions and the library installation checks.

Both relative-builder regressions fail against the previous installation
helper with the selected executable not found after the directory change.
They pass after resolving lookup results to absolute paths in the caller's
initial directory. The fixture delegates to the real compiler and verifies
that the selected wrapper actually ran in the copied client's directory.

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
- Launcher checks verify actual stdin and terminal behavior. The TTY sentinel
  cannot be satisfied by echoed test input, and explicit commands remain a
  positive control for the existing CI mode.
- Preflight fixtures prove that default GPR names are absent in override
  cases. The missing-selection case keeps defaults available and asserts the
  complete diagnostic line, excluding a success caused by checking defaults.
- Relative-builder checks require a log from the selected wrapper in the
  client directory, so ignoring the override cannot make the regression pass.

Co-Authored-By: GPT-6 <noreply@openai.com>

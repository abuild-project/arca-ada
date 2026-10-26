# CLI diagnostics, arguments and cancellation

CLI-generated diagnostics retain their full context outside GNAT's bounded
exception message. The sequential command owns a diagnostic store that Run
resets on entry; interrupt handlers access only protected cancellation state.
Stored text is associated with the CLI exception identity. Other exceptions
retain their runtime message or name. Final error output escapes bytes below
0x20 and DEL as `\xNN`, and backslash as `\\`; other bytes are unchanged.
The source names and archive names passed to the writers are unchanged.

The parser rejects directory-only output spellings before filesystem access:
`.`, `..`, `/`, a final `/.` or `/..`, and a trailing slash return argument
status 2. Missing or non-directory output parents retain command status 1
with an output-specific message. Valid output paths retain their behavior.

The existing C bridge now supplies target-header values for AT_FDCWD,
RENAME_NOREPLACE, EINVAL, ENOSYS, EOPNOTSUPP and ENOENT. Ada imports those
getters instead of embedding numeric Linux values. The metadata ABI and
no-replace fallback are unchanged. A separate C program derives expected
values from target headers without importing the bridge.

SIGHUP joins SIGINT and SIGTERM at the existing safe cancellation boundaries,
with cleanup and status 129. SIGINT and SIGTERM retain 130 and 143. Payload
copy can finish before cancellation is observed, as before. The test-only
GNAT interrupt-server acknowledgement includes SIGHUP so release cannot race
ahead of completed signal handling. Help now lists both long path options,
`=VALUE` and all documented exit statuses.

The library's public units, writer bodies and `arca.gpr` are unchanged. The
new diagnostic unit belongs only to the CLI source directory and creates no
dependency for Abuild's extending project. Abuild files are unchanged.
CPIO and TAR guides need no contract changes. The CLI, development and
unit-test guides, README and changelog describe the affected behavior.

## Validation

The strict CLI build and complete CLI integration suite pass in rootless
AMD64 Debian Trixie with GNAT 14.2. Against baseline
`d3f0574b37c68907206e59c7beff01d85b51ee88`, focused controls reject the
truncated long-path diagnostic, raw control bytes, unavailable bridge exports,
output-syntax status and precedence, generic parent diagnostics, incomplete
help and unhandled SIGHUP. The corrected implementation passes those checks.
The target-header oracle validates all exported constants; existing fallback,
fault, cleanup and SIGINT/SIGTERM checks remain active.

Relative output, separate long options and invalid SOURCE_DATE_EPOCH without
an explicit mtime were already tested on the baseline. They remain positive
controls, with additional `=VALUE` path-option coverage. A preserved valid CLI
corpus, including links, modes, payloads and control bytes in names, remains
byte-identical for both archive formats.

Coverage completed first on fresh committed sources without a build directory
or Git metadata, followed by the complete normal check. All inventoried
production bodies, including the new diagnostic body, have executed lines.
Unit, independent format/reader, CLI, style, tool-selection and installation
checks pass. Ordinary and installed extending-project clients retain their
behavior. Both the preserved writer corpus, including the GNU fixture, and
the CLI corpus match their baseline archive bytes.

Author review verified error ownership and unwinding, signal acknowledgement,
parser boundaries, C/Ada types, independent test expectations, coverage
inventory, source style, documentation, links and commit attribution. The
diagnostic store is owned by one sequential command; separate CLI processes
retain independent state. New diagnostic work occurs on error paths and
target constants are obtained at elaboration. Ada MCP loads the full CLI
view with the Arca project search path, finds the new diagnostic declarations
and reports no errors or warnings for touched Ada files. ARM64 and newer GNAT
remain untested.

Co-Authored-By: GPT-6 <noreply@openai.com>

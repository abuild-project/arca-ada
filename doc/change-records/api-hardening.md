# Library API and metadata contracts

TAR now exposes a tagged limited private writer type, matching CPIO.
Explicit lifecycle calls, controlled-parent conversion and lifecycle
overrides are rejected by the compiler. Create/Add/Close calls, limited
record components and implicit cleanup retain their behavior. Code using
the previously exposed controlled-parent interface must use the writer API.

CPIO selects each entry kind from its operation and centrally retains only
`8#7777#` from caller mode values. Conflicting file-type bits cannot change
a directory, file, link, FIFO or device into another kind. Ordinary
permission-only inputs retain their archive bytes.

Both formats map failures while converting timestamps to Unsupported_Metadata.
The conversion runs inside the relevant exception boundary, so a supplied
UTC time in 2300 no longer exposes Ada.Calendar.Time_Error. Existing valid
timestamp ranges and other format-specific exceptions are retained.

The installed client stores writers as record components and emits GNU
long-name metadata. Its complete TAR output is compared with the
source-built driver, including a raw assertion that the synthetic record's
mtime is zero. Existing static-library initialization already satisfies that
check; `arca.gpr` is unchanged.

An Abuild-style regular static extending project is built and installed,
then consumed by the same record-component client. This retains consumer
binder ownership and inherited library compiler settings. Abuild itself is
unchanged. CLI options, diagnostics and exit statuses are unchanged, so the
CLI guide needs no revision.

## Validation

The focused checks run in rootless AMD64 Debian Trixie with GNAT 14.2.
Against baseline `0da408688b04bfc27da4cd9072c2b513a9891679`, compiler lifecycle
controls fail because the operations remain accessible; full-mode CPIO
checks find incorrect entry types; both year-2300 checks receive Time_Error.
The corrected implementation passes these controls and the existing writer
suites. Ordinary and installed extending-project record clients compile and
run. The installed GNU metadata check passes against both the baseline and
the corrected source.

Coverage completed first on fresh committed sources without a build directory
or Git metadata, followed by the complete normal check. Unit, independent
format/reader, CLI, compiler-style and installation controls pass. Every
inventoried production body has executed coverage.

All preserved baseline archives from valid emission scenarios remain
byte-identical, including GNU reference output; fixture files are unchanged.
Shifting Unix_Epoch by one year in an isolated source copy makes the
installed GNU metadata check fail at its zero-mtime assertion, even when
source and installed outputs agree. This proves that the new check exercises
the package constant rather than only empty output.

No hosted pipeline result or ARM64 execution is established by these local
checks. Packaging, CLI polish and release-version work are separate topics.

Co-Authored-By: GPT-6 <noreply@openai.com>

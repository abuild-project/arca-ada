# Writer finalization and compiler checks

An unfinished CPIO or TAR writer could replace a caller's exception with
Program_Error during finalization. GNAT rejects Delete on a nonregular stream
before closing it, so outputs such as /dev/null also retained a descriptor.
Deleting a regular file can instead fail after its stream has already closed.

Both finalizers now use one private best-effort cleanup routine. It attempts
stream deletion, then still attempts Close if the stream remains open after
failure. It never separately unlinks a nonregular pathname and does not
propagate cleanup errors. Ordinary incomplete regular outputs are removed as
before; a filesystem failure can leave partial output or prevent closure.
Explicit writer Close remains the completing operation that reports I/O
errors. Public operation signatures and archive serialization are unchanged.

Library and test compilation now enable -gnatVa, -fstack-check and -gnateE
alongside existing warnings, overflow and standard Ada checks. This preserves
Abuild's extra runtime checking policy when the library is later imported;
parent-project compiler defaults do not automatically apply to imports.
Abuild's separate style-switch profile is not a runtime-check requirement and
is not adopted by this focused change. Arca's source-style policy still applies.

The direct Ahven cases exercise both writers with nonregular output, explicit
Close, normal/exceptional scope exit and a native Linux directory whose write
permission is removed. A failed probe creation first proves the permission
fault is active. Assertions pin descriptor recovery, the original exception
message, retained undeletable paths and absence of invented trailer bytes.
Private controlled fixtures restore write permission and remove their own
randomized directories, with a postcondition checking removal. State is owned
by one sequential test case; existing parallel/bounded-worker-stack tests run
with the stronger compiler checks too.

The regression cases failed on both old finalizers with Program_Error in
both text and XML modes. After correction, the complete normal target passes:
Ahven suites and failure/report controls, independent CPIO/TAR decoders,
GNU/libarchive readers, installed consumers and selected-tool regressions.
Complete production coverage passes with the unchanged body inventory. The
copy routine's payload behavior and format fixtures are retained. Compiler
ALI files confirm the three extra switches on library and test objects.

A private mutation that merely suppresses deletion errors without closing the
stream fails both new cases specifically at the descriptor-leak assertion.
Fresh sources also pass coverage first and the full normal target rootless,
with no network or Abuild mount. These checks do not claim exhaustive close
fault injection; the fallback close operation itself can still fail.

Final author review covered the complete proposed range and enclosing code:
unchanged serialization/public signatures, nonthrowing cleanup and close
ordering, failure-test sensitivity, fixture ownership, independent writer
state and bounded worker stacks, constant-cost cleanup, source/declaration
style, documentation/links, commit 50/72 wrapping and attribution. No new
production body was added, and the existing complete inventory still covers
all three bodies. This independent repository requires no Abuild ticket.

Ada MCP resolves both finalizer calls to the private helper and reports a
complete test project/index with empty file-scoped diagnostics for all changed
Ada units. Its semantic-only Ahven view comes from the reference package;
compiler/runtime validation uses the installed dependency in the Trixie image.

The topic starts from accepted main and contains no CLI implementation or
Abuild dependency switch. The separate Abuild roadmap/P7 topic records the
future repository and adapter boundaries. CPIO/TAR guides, developer/unit-test
guides, README, changelog and indexed plans describe the cleanup contract and
compiler profile; Abuild's manuals and release markers need no change for this
standalone library correction. Existing additional licensing/provenance scope
is unchanged. No new runtime dependency or performance improvement is claimed.

Co-Authored-By: GPT-6 <noreply@openai.com>

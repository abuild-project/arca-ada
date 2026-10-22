# Writer cleanup and compiler checks

Status: Implemented and locally validated on 2026-10-22 as a separate library
PR before the CLI; author review complete and external review prepared.

## Accepted scope

Keep archive serialization and public operation signatures unchanged. Both
writer finalizers must attempt removal of an unfinished regular output,
attempt stream closure when deletion fails before closing, and avoid replacing
an existing exception with a finalization failure. Nonregular destinations
remain usable without trying to unlink them after a rejected stream deletion.
Implicit cleanup is best effort; explicit Close continues to report failures.

Put the shared nonthrowing cleanup operation in the private binary helper and
call it from both finalizers. Retain independent instance ownership and the
existing bounded worker-stack tests. Add direct Ahven regression checks for
nonregular outputs, original-exception preservation and deletion failure in
a native Linux directory with write permission removed. Check descriptors,
retained paths and exception-safe fixture cleanup. Prove failure before the
production correction and success afterward.

Enable full GNAT validity checks, stack checking and additional exception
information for library and test compilation, matching Abuild's runtime
checking policy. Existing warning and source-style policies still apply;
Abuild's separate style-switch profile is not a runtime-check prerequisite.

## Delivery

Start from accepted main without CLI commits. Validate normal checks and
complete coverage in the rootless Trixie image, including a fresh-source,
network-isolated coverage-first run. Refresh Ada MCP and user/developer guides,
changelog and indexed change record. Complete author and independent static
reviews before publishing the library topic and requesting Copilot.

The Abuild roadmap/P7 reconciliation belongs to a separate documentation
topic. The owner specified TBD because no extraction ticket exists yet.

## Progress on 2026-10-22

The shared cleanup routine and runtime-check profile are implemented locally.
Both new Ahven cases failed against the unchanged finalizers in text and XML
modes, then passed after the correction. Full normal checks and production
coverage pass. Compiler artifacts confirm the stronger switches for library
and test objects. The output contract, permission-fault fixture ownership and
same-process descriptor checks are documented in the change record.

Fresh-source coverage-first and complete normal checks pass without network
or Abuild access. A mutation omitting the close fallback fails both new cases
at their descriptor assertion. Author review and complete Ada MCP diagnostics
are finished; independent static review is next, before publication.

## Final review on 2026-10-22

The validation pass reports no concrete findings. The source pass identified
minor fixture-path and index/status documentation issues, corrected before
publication; it found no runtime blocker. Source and test behavior are stable,
all required local validation is complete and the topic contains no CLI work.

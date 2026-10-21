# Writer extraction

Status: Accepted direction as discussed on 2026-10-21. The source inventory
and additional LGPL grant are recorded; CPIO is implemented locally.

## Scope and order

1. Establish the independently usable repository foundation.
2. Review provenance and record the additional LGPL grants needed for CPIO,
   TAR, their shared binary primitives, tests and fixtures.
3. Extract CPIO and TAR with their existing behavior. Move independent raw
   decoders and external-reader tests with them; keep Abuild transformation
   adapters and integration checks in Abuild.
4. Integrate an accepted, pinned library revision into Abuild in a separate
   change, preserving transformation behavior and public diagnostics.
5. Develop later VFAT, EXT2, base ISO and boot/hybrid ISO writers through
   their existing per-format compatibility and review gates.
6. Decouple OCI's hashing, compression, copying and temporary-path needs before
   importing it. Keep the SquashFS backend decision separate.

## Initial dependency inventory

Observed against Abuild revision `09a5fbf065814b5af860e0e644c88731703ef064`
on 2026-10-21. This is a point-in-time baseline, not a required future pin.

This is a planning inventory, not a claim that the listed files are imported:

| Area | Current Abuild paths | Boundary work |
| --- | --- | --- |
| CPIO | `src/abuild-file_formats-cpio.ads`, `.adb` | Rename namespace; preserve newc limits, hardlinks, copy errors and timestamps |
| TAR | `src/abuild-file_formats-tar.ads`, `.adb` | Rename namespace; preserve ustar/GNU profile, errors and deterministic metadata |
| Binary mechanics | `src/abuild-file_formats-binary_io.ads`, `.adb` | Retain only proven format-neutral consumers and their exact contracts |
| OCI | `src/abuild-file_formats-oci.ads`, `.adb` | Remove dependencies on Abuild compression, crypto, paths, utilities and randomness |
| Tests | `tests/` and `data/` | Separate pure format assertions from transformation configuration and Abuild helpers |

Refresh the inventory against the actual accepted source revision before
each extraction. Record immutable source revisions in the import record.
Historical native-writer branches are implementation evidence; do not import
them as an authoritative stack.

## API and implementation rules

- Keep filesystem layout and archive serialization in Arca. Keep product
  configuration, graph scheduling and Abuild object types in Abuild.
- Accept metadata and reproducibility timestamps from callers. Do not read
  Abuild configuration, environment policy or wall-clock time implicitly.
- Retain format-specific APIs where stream emission and planned filesystem
  layout need different lifecycles. Do not force one universal writer class.
- Share binary mechanics only when real consumers have identical semantics.
- Keep external oracles and independent raw decoders; writer self-reading is
  insufficient format evidence.
- Preserve cleanup, bounded worker-stack use and per-instance ownership.
- Measure realistic writer performance before and after the integration.

## Abuild integration checklist

The separate integration change must handle the GPR import, pinned dependency,
private checkout access in each CI environment, source and coverage inventory,
release licence inventory, User Manual, Developer Guide, changelog and indexed
change record. Keep existing source in place until parity and cleanup are
verified. Private GitHub access is not implied by sharing an owner namespace.

No extraction or Abuild backend switch has been performed by this bootstrap.

## Progress

On 2026-10-22, the owner confirmed authority and granted additional
LGPL-2.1-or-later licensing for the inventoried CPIO/TAR material. The
[provenance record](../provenance/cpio-tar.md) pins the accepted source
revision, separates direct writer tests from transformation tests and records
the fixture and third-party boundaries. CPIO is the first implementation
step; TAR follows separately. No backend switch is included in either import.

The [CPIO step](cpio-extraction.md) introduces the standalone writer and
private stream-copy subset. Its successful output profile is retained;
controlled output ownership and rejection of Create on an open writer are
explicit lifecycle additions. TAR extraction and Abuild integration remain
pending.

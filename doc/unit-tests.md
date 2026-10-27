# Unit tests

Arca's named Ahven suites exercise CPIO, TAR and the private stream-copy
helper directly. They need only Arca's sources and the test dependencies in
the development image. No Abuild checkout, executable or credentials are
used. `tests/tests.gpr` imports Ahven through `test_dependencies.gpr`;
neither `arca.gpr` nor installed library consumers depend on it. The
dependency-only project lets preflight run before object directories exist.

## Running

The complete check also runs compiler-level API controls and an installed
consumer with GNU long-name metadata. Record-component clients must compile
against the ordinary and regular static extending-project views. Explicit
TAR lifecycle access must be rejected for the intended visibility reason.
CPIO format checks include full mode values; both writer error suites check
out-of-range UTC times, including year 2300 and its format-specific message.
Packaging checks cover consumer/validation compiler profiles, dependency-free
cleanup, named installation manifests and uninstall/reinstall behavior.
CLI checks cover complete escaped diagnostics, output argument precedence,
header-derived constants, documented help and acknowledged SIGHUP cleanup.
Version controls compare CLI output with the public package constant and
require matching installed-client metadata. A source guard keeps explicit
CLI exception raises in the diagnostic owner, ignoring comments and literals.

Build the image after changes to its packages, then use the normal check:

```sh
docker/dev/build
docker/dev/run arca-dev:trixie make -j8 check NUM_CPUS=8
```

The image supplies Debian's `libahven-dev`. The test preflight checks command
availability and resolves the test project before compilation. The library's
own build and installation do not run this test preflight.

To run only the unit suites after building their prerequisites:

```sh
docker/dev/run arca-dev:trixie gprbuild -p -P tests/tests.gpr -j8
docker/dev/run arca-dev:trixie python3 tests/check-unit.py
```

The harness runs Ahven's text and XML modes sequentially. Each process gets
a private fixture root beneath `build/`; each case owns and removes its own
subdirectory. XML reports remain in `build/unit-results-bin/`. The harness
requires the complete named case inventory, zero failures/errors/skips and
no retained fixture directories. It rejects absent or duplicate reports.
It collects failures from both modes before failing the check, so an actual
text-mode test failure still leaves XML diagnostics for CI. Each mode owns
a separate fixture root so failed cleanup cannot prevent the other mode.

Finalizer-failure cases also own randomized mode-0700 directories on native
Linux /tmp storage. Docker Desktop's host sharing can bypass mode-based denial,
so these fixtures verify the denial with a real failed file creation before
testing deletion. Controlled fixture cleanup restores directory write access
and removes the private tree; each case checks that the tree is gone.

A separate deliberately failing executable verifies exit status 1, the
assertion diagnostic, XML failure reporting and fixture cleanup during
exception unwinding. The probe uses the real two-mode orchestration and
requires XML to exist even after a failed text run. Its expected failure is
printed as a harness probe;
it is excluded from the real suites and their retained XML reports.

`make -j8 coverage NUM_CPUS=8` runs the same checks against instrumented
objects, then the independent format suites. Its unit reports are kept in
`build/unit-results-bin-coverage/`. Coverage still inventories only production
bodies; neither Ahven nor test code contributes to the library coverage count.
CI retains the real suites' XML files as the `ahven-unit-results` artifact.

## Relation to existing tests

The [individual predecessor-case mapping](native-test-coverage.md) records
every registered original CPIO/TAR/copy test, its equivalent assertions and
adapter-only exclusions. The overview below is a summary of that mapping.

The scenario packages contain the pre-existing direct Ada checks shared by
the Ahven suites and the small archive drivers. Ahven calls their procedures
in process. The drivers remain inputs to independent Python decoders and
external GNU/libarchive readers. Assertions about emitted bytes therefore
retain an oracle outside the writer and outside Ahven.

Shared scenario `Program_Error` assertions are translated into Ahven failures
by the unit adapter; other exception kinds remain errors. The private-copy shared
scenario retains its original assertion exception, also producing a failing
Ahven result. The Python harness accepts neither failures nor errors.

| Behavior inspired by the predecessor tests | Arca checks |
| --- | --- |
| Unopened operations, missing sources and invalid metadata | Named CPIO/TAR error cases; independent recovery-archive decoding |
| Repeated Create and unfinished-output ownership | Named state/lifetime cases; descriptor counts, task exit/abort and independent state-output checks |
| Finalizer failures (additional Arca regression) | Named cleanup cases check /dev/null, explicit Close, normal/exceptional exits, failed unlink, original exception messages and descriptor recovery |
| Parallel native writers | Named parallel cases compare complete outputs on bounded worker stacks; independent suites also decode their reference archives |
| Timestamp/size/owner/device boundaries | Shared error cases plus independent maximum-field and first-rejected-value checks |
| Header fields, TAR prefix/long metadata, padding and end markers | Independent raw decoders, short CPIO record layout, corruption controls and historical GNU fixture |
| Payloads, entry kinds and explicit hardlinks | Independent entry matrices, multi-buffer comparisons and external extraction |
| Copy growth and short reads | Private-copy Ahven case and unchanged shared direct checks |

Closed-writer reuse, retry after failed Create, exact-buffer/empty copies and
missing-source copy recovery have focused additional Ahven cases. A comparison
sensitivity case rejects changed bytes and lengths and checks handle cleanup.
The independent suites also pin numeric TAR reader fallback, deep-path and
GNU fallback headers, block-aligned multi-buffer extraction, empty-archive
acceptance and CPIO's exact short-record padding/uppercase field profile.

Abuild's transformation-level source-path hardlink grouping, configuration,
logging and scheduling tests stay in Abuild. Endian helpers absent from Arca
are outside this suite. Full multi-gigabyte payload completion and exhaustive
filesystem fault injection are not implied by these checks.

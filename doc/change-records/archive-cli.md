# Archive creation CLI

Add `arca create --format cpio|tar -C DIRECTORY -o ARCHIVE` so standalone
consumers can create uncompressed CPIO `newc` and TAR archives from a directory.
The initial CLI targets 64-bit Linux, validated on AMD64 Debian Trixie.
The public writer APIs, library sources and imported provenance stay unchanged.

The command inventories a stable source tree and emits relative names in
bytewise full-path order. It preserves numeric owners, permission bits,
whole-second mtimes, symlink targets and selected regular-file hardlinks.
CPIO uses synthetic inodes and stores each hardlink group's payload at its
last lexical name; TAR links subsequent names to the first. Explicit
`--uid`, `--gid` and `--mtime` overrides, with `SOURCE_DATE_EPOCH` as the
mtime fallback, support byte-reproducible output for equivalent trees.

Only a successfully closed archive is published from private staging on the
destination filesystem. Default publication cannot overwrite even a late
destination: unsupported no-replace rename falls back to a hard link.
Ambiguous NFS link errors count as success only when lstat confirms the same
regular device/inode identity. `--force` atomically replaces a regular file
or symlink. Directory-read errors abort inventory, entry errors preserve
low-level diagnostics, and best-effort staging finalization cannot mask an
earlier exception or turn successful publication into failure.

Argument policy, filesystem inventory and invocation-local ordered maps
belong to the CLI. Signals use an Ada protected object; simple system calls
use direct Ada bindings. Production C contains only the lstat metadata
wrapper. The library remains Ada-only and independent of the CLI and Abuild.
New CLI code is independently authored under LGPL-2.1-or-later.

Make builds and installs the CLI alongside the library. The CLI enables the
same additional validity, stack and exception-information checks as the
library/test projects. Existing CI uses the shared Docker wrappers and Make
targets; coverage now includes every CLI Ada/C body. README, CLI/developer
guides, changelog and indexed plans describe the supported interface.

## Validation

- `make -j8 coverage NUM_CPUS=8` and `make -j8 check NUM_CPUS=8` pass in the
  supported rootless Trixie image. The runtime corrections also pass coverage
  first and normal checks from fresh sources without network or Abuild access.
  Final option-only additions pass both complete targets again.
- Ahven and native format suites remain intact. CLI output is decoded with
  independent Python readers and extracted with GNU cpio/tar and bsdtar.
  Installation checks run the installed command and isolated library client.
- Fixtures cover metadata limits and overrides, environment precedence and
  invalid epochs, relative paths and option aliases, Unicode names,
  multi-buffer payloads, symlinks, selected hardlinks, FIFOs, special mode bits,
  full-path ordering and byte equality across different source creation orders.
- Native Linux fixtures verify actual timestamp, mode and sparse-size storage.
  Exact maximum size reaches an intentionally unreadable source; max+1 is
  rejected before emission, without writing multi-gigabyte archives.
- Phase-controlled tests cover cancellation, changed sources and late targets.
  A child-only preload library injects read, write, rename, link and cleanup
  faults. It also acknowledges staging-file open through an inherited pipe
  and blocks entry emission until a second pipe delivers an explicit release.
  Small fixtures replace timing-based polling/SIGSTOP. Successful release,
  missing-hook and parent-error controls check readiness, process reaping and
  descriptor cleanup. The previous preload library fails the new readiness
  assertions deterministically. Traces and positive controls verify real
  paths, preserved output, original diagnostics, stale errno and success
  after publication. Production code contains no test hooks.
  The barrier controls and affected cases pass repeated runs; full coverage
  and normal checks also pass from fresh rootless Trixie sources without
  network or Abuild access after the synchronization correction.
- Regression assertions fail against the pre-correction CLI and pass with the
  correction. The trailer-name and no-clobber guards also have sensitivity
  evidence. Coverage's complete inventory requires executed lines for every
  production body; it does not claim complete branch coverage.

## Boundaries and review

Equivalent bytes require identical contents, relative names, recorded metadata
and link topology. Reproducibility controls do not normalize source modes or
hardlink relationships. Source identity checks detect ordinary changes;
inputs must remain stable and are not an adversarial filesystem sandbox.
Cancellation is observed between phases; a synchronous copy may finish first.
Cleanup faults can leave private staging. SIGKILL, crashes and power loss do
not guarantee cleanup, and atomic publication does not imply durable storage.

NFS-style failures are injected locally; an actual NFS-server run is not
claimed. Rootless CLI fixtures do not create device nodes, although native
writer tests cover their serialized metadata. Maximum-size full copies and
exhaustive storage faults are not claimed. Optional predecessor comparisons
were not rerun because library serialization is unchanged. Abuild integration
and its manuals remain separate. Signal re-raising/SIGHUP, installation
manifest naming and cosmetic root-output diagnostics remain follow-ups.

Author review and independent source/validation passes found no remaining
blocking or fix-before-PR issues. Review covered ABI/errno ordering, exact
bounds, no-clobber and cleanup lifetime, fixture sensitivity, independent
oracles, invocation-local state, scaling, source style, documentation and
commit hygiene. The final small option tests received author review. Ada MCP
provided complete project/index views and current semantic navigation; the
Trixie compiler caught an overload ambiguity absent from MCP diagnostics.
The named-argument correction passes compiler and runtime validation.

Co-Authored-By: GPT-6 <noreply@openai.com>

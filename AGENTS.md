# Arca agent instructions

- Read `README.md`, `doc/development.md`, `doc/coding-style.md`,
  `doc/licensing.md` and the active plan under `doc/plans/` before substantive
  work. The coding-style guide applies to library, CLI, tests and examples.
- Read `SECURITY.md` before security-related work and `doc/publication.md`
  before publication preparation. Preserve the assessment's revision scope;
  rerun affected checks after changes and never infer publication approval.
- Use `codex/<topic>` for Codex working branches. Preserve unrelated changes.
- Use `apply_patch` for hand-written edits. Keep Ada sources within 80 columns
  and document the observable contract beside every subprogram declaration.
- Follow the [coding-style guide](doc/coding-style.md), including blank-line
  grouping, declaration alignment, separate body `is` lines and aspect forms.
  Keep compiler style checks enabled; review comments and grouping manually.
- Use the documented Trixie container for build evidence. Run builds with
  `make -j8 <one target> NUM_CPUS=8`; do not race independent GPRbuild processes
  against the same object directory.
- Keep the library independent of Abuild types, configuration, logging and
  scheduler state. Add shared primitives only for demonstrated consumers.
- Format tests need independent readers and raw-format checks. Keep test
  decoding independent of production layout constants.
- Keep writer state local to each instance. Verify cleanup after failed adds
  and omitted closes, concurrent independent writers and caller-supplied time.
- Imported code retains its original notices and licence until an appropriate
  additional grant is recorded. Follow `doc/licensing.md` before copying code.
- Use Conventional Commit subjects of at most 50 characters and wrap prose
  bodies at 72 columns. This independent dependency repository does not
  require an Abuild Jira ticket in commits.
- Update the changelog, relevant plans and indexed change record with the code.
- Do not push, publish a release, change visibility or transfer the repository
  unless the user authorizes that action. Keep internal infrastructure and
  unrelated private source material out of committed files.

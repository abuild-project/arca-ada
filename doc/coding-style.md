# Coding style

This is the normative style reference for maintained Arca sources: library,
CLI, tests, examples and GPR projects. Read it before editing code. The same
readability rules apply to test helpers and production code. Retain original
copyright/licence notices, public names and recorded provenance when adapting
imported code. Generated sources and unchanged third-party fixtures retain
their producer's format; do not edit generated output to satisfy this guide.

## Ada language and interfaces

The language baseline is Ada 2012, selected explicitly by each compiling GPR
project. GNAT runtime APIs are deliberate dependencies where standard Ada
does not provide the required filesystem or process facilities. Keep those
dependencies narrow and document their platform assumptions. New syntax
should use standard Ada 2012 forms when equivalent behavior is available.

Prefer aspect specifications to their equivalent older pragmas: Import,
Convention, External_Name, Interrupt_Handler, Storage_Size and Pure. Keep
pragmas which have no equivalent aspect, including Elaborate_All and GNAT's
Interrupt_State. Representation clauses remain valid for explicit binary
layout; changing a clause to an aspect is not itself a correctness fix.

Avoid new Annex-J obsolescent features. Use Ada.Characters.Latin_1 for control
characters instead of ASCII. Use type-prefixed numeric Image, for example
Natural'Image (Count), rather than GNAT's Img or object-prefixed Image syntax.
The latter is standard in Ada 2022 but is an extension under this baseline.
Numeric Image includes a leading blank for nonnegative values: retain or
trim it deliberately according to the consumer, including test filenames.

Preserve imported C symbol names, calling conventions, parameter modes and
representation contracts when modernizing declarations. Do not rename public
writer APIs or change archive bytes as part of formatting work.

## Layout and names

- Use spaces, with three spaces per Ada/GPR nesting level. Keep maintained Ada
  source lines within 80 columns, with LF endings and a final newline. Do not
  leave trailing spaces or tabs. Start full-line Ada comments with two spaces
  after the comment marker, including SPDX and copyright comments.
- Use lower-case keywords and Mixed_Case identifiers separated by underscores.
  Retain established acronyms, external bindings and public interface names.
  Spell references consistently with their declarations.
- Put a subprogram body's is on its own line, aligned with procedure/function.
  Do the same for task and protected bodies. Package declarations/bodies may
  retain is on their opening line when no aspect or multiline profile follows.
- Align related consecutive object/record declarations at their colons.
  Align multiline formal parameter names, colons, modes and types within a
  profile. Omit the default in mode; retain in out and out explicitly.
- Separate context clauses, package renamings, use clauses and object groups
  with useful blank lines. Separate distinct processing phases and nested
  declare/begin blocks; do not compress independent steps into a dense block.
- Expand case alternatives and exception handlers into readable indented
  statements. Keep one statement per line. Wrap long calls at argument
  boundaries and align named associations within a call.
- Separate consecutive package-level subprogram bodies with one plain dashed
  line and surrounding blank lines, following the existing writer layout.
  Do not add named three-line banners. Use shorter separators at nested levels.

Use clauses are permitted, as in the existing writers. Keep their scope as
small as useful; prefer use type when only operators are needed. Use package
renamings for repeatedly referenced long names. Avoid unnecessary visibility
or renaming solely to shorten one call.

## Contracts and comments

Every new or materially modified subprogram declaration needs an immediately
adjacent semantic comment, in specifications and bodies, including local
helpers, generic formal subprograms and tests. A comment on the declaration
also covers its corresponding body; do not repeat it mechanically. A body
which serves as its own declaration needs its own contract comment.
Separate declaration/comment pairs from the next declaration with a blank
line. Describe observable behavior, ownership, constraints or test purpose.

Production comments explain invariants and non-obvious decisions. Test
comments explain the assertion and why it detects a regression. Keep comments
accurate after refactors. Archive writers retain their field maps, index
basis, byte order, padding/checksum rules and normative format references.

## Compiler and CI enforcement

All four compiling projects use -gnatygAdISuxM80 alongside their existing
warning-as-error settings. This follows Abuild's profile with an explicit
80-column limit. It does not add spawn_manager's alphabetical-subprogram
ordering requirement. GNAT checks layout, casing, token spacing, separate
specifications and the selected additional rules during normal compilation.
Coverage builds retain the same style profile.

The option is explicit in the library, CLI, test and example projects. GPR
imports do not inherit compiler defaults automatically. Keeping the copied
client project self-contained also preserves installed-consumer isolation.
Update all four profiles together when changing this policy.

Run checks in the supported rootless Trixie environment:

```sh
docker/dev/run arca-dev:trixie make -j8 check NUM_CPUS=8
docker/dev/run arca-dev:trixie make -j8 coverage NUM_CPUS=8
```

The check target also compiles private copies through every real project.
An 80-column comment must compile, and an 81-column comment must fail with
the expected GNAT style diagnostic. Forced compilation prevents stale objects
from satisfying this control. The original checkout is never modified.
CI uses the same Docker wrapper and Make targets.

Compiler checks do not prove meaningful comments, useful phase separation or
appropriate dependencies. Review these rules explicitly before submitting a
PR, including tests/examples, documentation and generated-file hygiene.
Warning-free compilation alone does not establish absence of obsolescent
features; GNAT's optional obsolescence warnings do not flag ASCII usage.

## Other source languages

Keep the existing four-space layout in C and Python helpers and the existing
shell/Make layout. C builds retain C11 and the configured strict warnings.
Use the existing test frameworks and private fixture ownership conventions;
avoid introducing a formatter dependency solely for this small codebase.
Keep licence identifiers, LF endings and final newlines in all source files.

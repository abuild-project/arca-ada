# Historical GNU ustar reference

These three files are imported without modification from the Abuild test data
at revision `136ca84f0f5c49acae5fdd22f43359a32ca26e70`, under
`data/tests_abuild_file_formats_tar/`:

- `gnu-ustar-subset.hex`: GNU tar 1.34 output as a canonical hex dump;
- `gnu-ustar-subset.README`: original producer command, scope and hash; and
- `regular_file`: the original 13-byte payload used by that command.

The original README describes historical source paths. It is retained as
producer evidence, not as a command to run from this directory. No fixture
was regenerated for this import. Tests decode the dump, verify the archived
SHA-256 and compare the writer's bytes without creating device nodes.
The imported fixture retains GPL-2.0-or-later; the GNU tar program itself
retains its own licence. See [licensing](../../../doc/licensing.md).

# Historical GNU ustar reference

These three files are imported without modification from the accepted source
revision and paths recorded in `doc/provenance/cpio-tar-sources.json`:

- `gnu-ustar-subset.hex`: GNU tar 1.34 output as a canonical hex dump;
- `gnu-ustar-subset.README`: original producer command, scope and hash; and
- `regular_file`: the original 13-byte payload used by that command.

The original README describes historical source paths. It is retained as
producer evidence, not as a command to run from this directory. No fixture
was regenerated for this import. Tests decode the dump, verify the archived
SHA-256 and compare the writer's bytes without creating device nodes.
The additional LGPL-2.1-or-later grant applies to the inventoried material;
the GNU tar program itself retains its own licence.

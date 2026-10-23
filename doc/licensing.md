# Licensing

## Project licence

Project-owned Arca source, scripts, build files, tests and documentation use
GPL-2.0-or-later: GNU General Public License version 2 or, at the recipient's
option, any later version. [LICENSE](../LICENSE) contains the unmodified
version 2 text; [COPYRIGHT](../COPYRIGHT) identifies the copyright holders and
the project grant. New project-owned contributions use the same licence.

Maintained source, script and build files carry matching SPDX identifiers
where their syntax supports comments. Standard licence texts and binary or
byte-sensitive fixtures retain their original bytes. JSON metadata has no
comment syntax; the project-wide grant covers it without an inserted header.

## Code derived from Abuild

The following units derive from Abuild revision
`136ca84f0f5c49acae5fdd22f43359a32ca26e70`. Their original attribution and
GPL-2.0-or-later licence are retained. The copyright holder for this material
is secunet Security Networks AG, as recorded in each unit.

| Arca file | Original Abuild file | Revision | Copyright | Licence |
| --- | --- | --- | --- | --- |
| `src/arca-cpio.ads` | `src/abuild-file_formats-cpio.ads` | `136ca84f` | secunet Security Networks AG | GPL-2.0-or-later |
| `src/arca-cpio.adb` | `src/abuild-file_formats-cpio.adb` | `136ca84f` | secunet Security Networks AG | GPL-2.0-or-later |
| `src/arca-tar.ads` | `src/abuild-file_formats-tar.ads` | `136ca84f` | secunet Security Networks AG | GPL-2.0-or-later |
| `src/arca-tar.adb` | `src/abuild-file_formats-tar.adb` | `136ca84f` | secunet Security Networks AG | GPL-2.0-or-later |
| `src/arca-binary_io.ads` | `src/abuild-file_formats-binary_io.ads` | `136ca84f` | secunet Security Networks AG | GPL-2.0-or-later |
| `src/arca-binary_io.adb` | `src/abuild-file_formats-binary_io.adb` | `136ca84f` | secunet Security Networks AG | GPL-2.0-or-later |

Only the stream-copy operation and its supporting declarations were taken
from Binary_IO; the original endian helpers are not part of Arca. Later
imports must add their paths, exact origin revision, attribution and licence
to this table before introducing the material.

The GNU ustar reference fixture also comes from the Abuild test data at that
revision under GPL-2.0-or-later. Its original GNU tar producer command, bounded
format scope and checksum remain in [tests/fixtures/tar](../tests/fixtures/tar/README.md).
The GNU tar program itself retains its own licence.

## Third-party components

Ahven is a test-only dependency supplied by the development image under its
ISC licence; it is not vendored or installed with Arca. The GNAT runtime,
compiler, build tools and external format readers retain their own licences.
Review compatible terms before adding any third-party source to the project.

## Distribution

Retain copyright and licence notices when distributing Arca. Distribution
of binary forms, including the statically linked CLI, must satisfy the GPL's
corresponding-source requirements for the version actually distributed.
Provide complete source, associated interface definitions and the scripts
used to control compilation and installation, including the Makefile, GPR
projects and applicable docker/dev/ build inputs. A reference to unrelated
or older source is not the corresponding source of a distributed binary.

GPRinstall copies LICENSE and COPYRIGHT to the installed documentation
directory. Those notices accompany the installed files; they do not replace
the required corresponding-source delivery. See [GPL version 2](../LICENSE),
especially sections 1, 2 and 3, for the applicable terms and delivery options.

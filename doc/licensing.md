# Licensing and provenance

## Project licence

Arca's project-owned source, examples, build files, tests and documentation
use `LGPL-2.1-or-later`: GNU Lesser General Public License version 2.1 or, at
the recipient's option, any later version. [LICENSE](../LICENSE) contains the
unmodified version 2.1 text; [COPYRIGHT](../COPYRIGHT) identifies the project
copyright holder and grant. Source SPDX identifiers use the same expression.
New project-owned contributions use that licence as well.

The owner authorized this project licence on 2026-10-22, before any archive
or filesystem writer import. This revision contains only the independent
project foundation; no Abuild writer, helper, test or fixture has been copied.
Third-party tools and dependencies retain their own terms.

## Additional grant for planned imports

On 2026-10-22, the owner confirmed authority to grant additional
`LGPL-2.1-or-later` licensing for the previously identified CPIO/TAR sources,
their shared helpers, tests and fixtures. The
[provenance record](provenance/cpio-tar.md) and its file manifest identify
the accepted revision and exact candidate scope. The owner expressly confirmed:

> Die zusätzliche LGPL-Freigabe erteile ich ebenfalls.

This confirmation applies to material owned by the represented rights holder.
It does not relicense third-party source, unrelated writers or future source
revisions. Each import must record its exact accepted source revision, file
scope, modifications and applicable grant before introducing the material.
The original `GPL-2.0-or-later` availability is preserved.

The upstream licence alone does not authorize replacing GPL terms with LGPL
terms. A repository move or namespace change does not establish such a grant.
Git authorship alone does not establish authority to relicense.

For each import, retain a record of:

- source repository, accepted revision and original paths;
- original licence and copyright notices;
- any third-party origin, adaptations and fixture-generation terms;
- the applicable additional grant and its scope; and
- destination paths and semantic changes.

The CPIO source describes inspiration from `gen_init_cpio`. Check that
provenance rather than treating inspiration as proof of copied source.
Apply the same review to TAR, binary helpers and their test infrastructure.
Keep material without a sufficient grant outside the LGPL library.

## Distribution and static linking

Retain copyright and licence notices. When distributing the library, make
its complete corresponding source, including distributed modifications and
build/install scripts, available under the applicable LGPL terms.
Purely internal modifications do not require public release.

Applications may use Arca under other licences subject to LGPL section 6.
For a statically linked executable, provide the library source and the
application's suitable object code and/or source code, together with the
material needed to modify Arca and relink the executable. The application
terms must permit the modification and reverse engineering required there.
Providing only Arca's static archive does not provide a relinkable application.
Ada consumers must retain the binder, linker and build inputs needed by their
chosen toolchain. A complete, rebuildable application source distribution is
one way to supply the application material; dynamic linking has a separate
compliance option in section 6(b).

GPRinstall includes `LICENSE` and `COPYRIGHT` under `<prefix>/share/doc/arca`.
That installation notice is not a substitute for providing complete source
and the application material required when distributing linked binaries.
See the [LGPL 2.1 text](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html),
especially sections 1, 2, 4 and 6.

Optional compression and hashing dependencies keep their own licences.
Review their concrete consumers before introducing those dependencies.

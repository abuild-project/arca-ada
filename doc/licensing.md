# Licensing and provenance

## Current grant

The newly authored bootstrap files are distributed under BSD-3-Clause; see
`LICENSE`. No Abuild writer, helper, test or fixture has been copied into this
revision. Consequently the bootstrap licence does not make a grant for any
existing Abuild source.

## Planned imports

The current Abuild grant is `GPL-2.0-or-later`. A repository move or package
rename does not change that grant. Before including its code in the BSD
library, record an explicit additional BSD grant from the relevant rights
holders and review the provenance of every imported source, helper, test and
fixture. Git authorship alone does not establish authority to relicense.

For each import, retain a record of:

- source repository, accepted revision and original paths;
- original licence and copyright notices;
- any third-party origin, adaptations and fixture-generation terms;
- the applicable additional grant and its scope; and
- the destination paths and any semantic changes.

The CPIO source describes inspiration from `gen_init_cpio`. That is a reason
to check its provenance, not proof that a particular source was copied.
Apply the same review to TAR, binary helpers and their test infrastructure.

If a grant cannot be established, keep the affected material outside the BSD
library. A separately labelled GPL extraction is possible under the original
terms, but must not be represented as BSD-covered by this repository's root
licence. Choose and record that alternative before importing such files.

Optional compression and hashing dependencies keep their own licences.
Adding a native format writer does not imply a dependency-free compression
implementation. Review those dependencies when their concrete consumers are
introduced.

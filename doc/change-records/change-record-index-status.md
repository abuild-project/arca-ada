# Change record acceptance status

Record the merge commits for nine entries in the
[change record index](README.md) that still showed `pending` after their
records entered `main`. The VFAT entry covers the format inventory and
bounded reference fixtures. The native writer, parity validation and the
Abuild backend switch remain future work.

## Validation

GitHub pull request metadata identified each merged change and its merge
commit. Local Git inspection confirmed that all nine commits are on the
first-parent history of `774921f0d581c675c5c5993556dbf8023c67ae42` and that
each introduced the indexed record relative to its first parent. Git checks
also verified both indexes' sort order and resolved their links.

The complete local CI chain passed from a fresh detached checkout of
`a1ab02704dd150c200cfbe34dbe70b83c90a8b90` in AMD64 Debian Trixie.
Independent review of that revision against the base above reported no
actionable findings. Omitting this canonical record yields Git tree
`cb7fa156891e13ea826626f40a5b9a2be0bae5ee` for both the tested revision and
the evidence update.

Standalone coverage ran before `build/` existed and executed 1,031 of
1,107 lines across all 10 production bodies. Ahven passed 19 cases each
in the normal and coverage runs, with no errors, failures or skips.
The development wrapper, shell and batch, Claude workflow and PR record
harnesses passed 6, 3, 13 and 19 cases respectively. The cross-UID staging
harness passed all 54 cases, and strict MkDocs built 14 staged pages.
Local probes of the exact base PR checker accepted a matching synthetic
PR body and rejected a substantive mismatch.

Co-Authored-By: GPT-6 <noreply@openai.com>

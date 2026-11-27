# Change record acceptance status

## Merge verification on 2026-11-27

Check each pending entry in the
[change record index](../change-records/README.md) on `main` at
`774921f0d581c675c5c5993556dbf8023c67ae42`.

Use the merge commit reported by GitHub for each pull request merged into
`main` because the index identifies the revision that accepted the topic.
Confirm that the commit is on the first-parent history of `main` and that
its Git tree contains the matching record. Keep the existing abbreviated
commit format and sort the new entries by filename. Treat VFAT inventory
acceptance and its native writer follow-up as distinct milestones.

Validate the documentation in the complete local CI chain in AMD64 Debian
Trixie and independently review the same immutable candidate.

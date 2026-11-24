# Optional architecture assignment

The coordinator may commission a read-only architect before implementation
when several changes or repositories need a shared design. The architect
proposes requirements, design decisions, independently reviewable PRs and
validation. The proposal identifies dependencies, parallel work and merge
order so each slice has clear acceptance criteria.

The maintainer retains decisions on scope, API, compatibility, licensing and
supported platforms. The developer records the agreed decisions in the
active plan and owns candidate edits. The coordinator keeps both correction
counters across PR splits, and the independent reviewer is separate from
the architect.

Each slice uses its branch-derived change record and shares the topic's plan
and counters. Every Arca slice receives complete local CI and independent
review at the candidate revision before submission. Initial implementations
use zero correction rounds. Corrections use the active phase's shared
budget. Other repositories retain their own approval and validation rules.

## Validation

Validation covers the change against base commit
`00216335a6bfad40f6ce3ba5ee0eae2f7ef63843`. The candidate's Git tree with
this record omitted is `bffa7e3c173183826c87800fb84a933c45494e7f`.

The complete local CI chain passed in a fresh detached worktree using AMD64
Debian 13.8 Trixie. Rootless coverage ran before `build/` existed and reached
1,031 of 1,107 lines across ten production bodies. Both Ahven runs passed 19
tests each with zero errors, failures or skips. The 6 wrapper, 3 shell and 5
Claude review harness checks passed on the host, and all 43 CLI tests passed
in the container. The root harness passed all 54 cross-UID scenarios using
UIDs 65534 and 65533. Strict MkDocs built the site from 14 canonical Markdown
pages.

Fresh independent review covered the full base-to-candidate diff and primary
local CI evidence and reported no actionable findings.

Co-Authored-By: GPT-6 <noreply@openai.com>

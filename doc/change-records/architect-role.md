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

The complete local CI chain passed at
`fdbcd8d0f0d5bc41305c3e6fa975e371bc0866e9` from a fresh detached worktree
using AMD64 Debian 13.8 Trixie. Coverage ran before `build/` existed and reached
1,031 of 1,107 lines across ten bodies. Both Ahven runs passed 19 tests
each with zero failures, errors or skips. The wrapper, shell, rootless
installation, CLI and format checks passed. The root harness passed all 54
scenarios using UIDs 65534 and 65533. Strict MkDocs built 14 pages. A
separate independent review of that revision checked the full documentation
diff and primary test evidence and reported no actionable findings.

Co-Authored-By: GPT-6 <noreply@openai.com>

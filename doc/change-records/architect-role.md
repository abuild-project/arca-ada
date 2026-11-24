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
and counters. Every slice receives complete local CI and independent review
at the candidate revision before submission. For slices validated during
the PR phase, resulting corrections use the current PR budget.

The local diff check confirms the patch is limited to workflow
documentation. The existing local CI and independent review requirements
apply to this documentation change.

Co-Authored-By: GPT-6 <noreply@openai.com>

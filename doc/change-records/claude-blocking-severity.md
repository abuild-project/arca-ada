# Claude review blocking severity

The pilot labels each new finding `blocking` when it matches a blocking
rule from the captured base or shows a concrete observable failure. It
cites the file and section for rules it applies and labels other new
findings `nit`. It puts every new finding under **New findings**. Claims
about PR intent, temporary or draft status, and planned closure have no
effect on the label. The final line states whether a blocking finding
remains at the captured head, counting new blockers and earlier blockers
that are still open, even when there are no new findings.

The **Code Review Rules** treat undisclosed gaps in the required local CI
chain or independent review as blocking. The canonical change record
identifies any missing evidence.

## Validation

The complete local CI chain passed from a fresh detached checkout of
`bc30de23691eda6419aaeab4be010160b26d40c2` in the AMD64 Debian Trixie
reference environment. Independent review of the same revision against
base `18587c2857dab9572f0a53a623824cc8fa22dfff` reported no actionable
findings. With this record omitted, the validated Git tree is
`98b4283df119fbd3e694ee8de59a5646c3ffb017`.

Standalone coverage ran before `build/` existed and covered 1,031 of 1,107
executable lines across 10 production bodies. The normal and coverage Ahven
runs each passed 19 tests with zero failures, errors or skips. The wrapper,
shell/batch and Claude review harnesses passed 6, 3 and 9 tests respectively.
The normal checks passed, including all 43 CLI tests. All 54 cross-UID
staging checks and the strict MkDocs build of 14 canonical pages passed.

In isolated fixtures, the harness from
`826f6129a500624490588ab1a624eae55a6f0a7c` failed six severity assertions
against the workflow from base `18587c2857dab9572f0a53a623824cc8fa22dfff`.
The updated harness failed only the final-line assertion against the
workflow from `826f6129a500624490588ab1a624eae55a6f0a7c`. The other tests
in each fixture passed. The workflow diff is confined to prompt text.

The harness checks the prompt and uses a stub GitHub CLI for workflow
steps. The post-merge smoke test will check the live review's severity,
placement, citation, final line and revisions. See the
[Claude review pilot guide](../development.md#claude-review-pilot).

Co-Authored-By: GPT-6 <noreply@openai.com>

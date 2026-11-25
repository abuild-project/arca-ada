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

All nine tests in `python3 tests/check-claude-review.py` passed locally.
The full local CI chain and independent review are pending for this
revision.

In isolated fixtures, the harness from
`826f6129a500624490588ab1a624eae55a6f0a7c` failed six severity assertions
against the workflow from base `18587c2857dab9572f0a53a623824cc8fa22dfff`.
The updated harness failed only the final-line assertion against the
workflow from `826f6129a500624490588ab1a624eae55a6f0a7c`. The other tests
in each fixture passed. The workflow diff is confined to prompt text.

The harness checks the prompt and uses a stub GitHub CLI for workflow
steps. The post-merge [smoke test](../development.md#claude-review-pilot)
checks the live review's severity, placement, citation, final line and
revisions.

Co-Authored-By: GPT-6 <noreply@openai.com>

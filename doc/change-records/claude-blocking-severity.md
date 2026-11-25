# Claude review blocking severity

The pilot labels each new finding `blocking` when it matches a blocking
rule from the captured base or shows a concrete observable failure. It
cites the file and section for rules it applies and labels other new
findings `nit`. It puts every new finding under **New findings**. Claims
about PR intent, temporary or draft status, and planned closure have no
effect on the label.

## Validation

All eight tests in `python3 tests/check-claude-review.py` passed locally.
Against the workflow from base `18587c2857dab9572f0a53a623824cc8fa22dfff`
in an isolated fixture, the six updated prompt assertions failed as
expected and the seven other tests passed. The workflow diff is confined
to the prompt's instructions for new findings.

The harness checks the prompt and uses a stub GitHub CLI for workflow
steps. The post-merge [smoke test](../development.md#claude-review-pilot)
checks the live review's severity, placement, citation and revisions.

Co-Authored-By: GPT-6 <noreply@openai.com>

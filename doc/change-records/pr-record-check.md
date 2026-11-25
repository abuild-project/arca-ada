# Canonical PR record check

The dedicated PR workflow compares the submitted body with the canonical
change record at the PR head. It reruns on body edits and head updates.
It normalizes CRLF and ignores whitespace at the end of the whole text.
It reports the expected record path on failure and shows a short unified
diff for a mismatch. The rule applies to all PRs. Required-check settings
are a separate repository action.

## Validation

The standard-library harness passes 10 tests. Without normalization it
rejects all three trailing-whitespace or CRLF cases. Keeping the branch
prefix makes both prefixed-branch cases fail.

The complete local CI chain and independent review are pending for this
candidate. Hosted validation of the PR event and result is also pending.

Co-Authored-By: GPT-6 <noreply@openai.com>

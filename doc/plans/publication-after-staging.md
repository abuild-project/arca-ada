# Publication status after CLI staging acceptance

Status: Accepted in `e3892da` (PR #17) on 2026-10-29.

Base revision: `d715d6295df56c5948d419458a5853df31dcf079`.

## Decisions on 2026-10-29

- Record accepted topic status by the immutable merge commit in the plan,
  plan index and change-record index.
- Append a dated disposition to the historical publication assessment. The
  resolved CLI finding is supported by the required CI run for that exact
  merge commit; earlier assessment text retains its original scope.
- Close the staging publication gate. Keep the separate public
  repository-source reference gate pending until the private transfer and
  verification of permanent links and pinned dependency URLs. The retired
  predecessor-source snapshot condition is not reinstated.

## Validation

1. Verify the accepted merge commit and its rootless Trixie job, including
   coverage, normal checks and the dedicated cross-UID staging step.
2. Check that only maintained Markdown status and publication guidance
   changes, that relative links resolve, and that historical dated text is
   preserved with a new appended disposition.
3. Record scope, observed checks and the remaining transfer dependency in
   the canonical change record. Publish through a separate review topic;
   transfer and visibility remain later maintainer actions.

Co-Authored-By: GPT-6 <noreply@openai.com>

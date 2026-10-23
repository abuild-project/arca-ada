# Publication readiness

Reviewed on 2026-10-23 at accepted Arca
`03a2a0763f1e55f3c0650ce1da8a9063c5eb4066` (PR #8). This is preparation
evidence; the repository remains private and has not moved. Publication is
blocked by the CLI staging issue and public source-reference gate below.

## Current code security audit

A completed repository-wide static scan covered all 114 tracked files, with
an independent baseline, architecture mapping, focused native/filesystem
investigation and parent source validation. Its scan identity is
`3c3bde81-9eb6-4e93-80e4-1b802062a18b`. The sealed report is retained in the
owner's security workbench; it is not a dependency of this repository.
No application or exploit was executed as part of that source audit.
The workbench marks the scan complete, but its sealed coverage metadata
retains a partial disposition and a deferred duplicate publication candidate.
The validated finding includes both creation and publication operations;
this reporting inconsistency is not evidence that either operation is fixed.
The 114-file review inventory is complete; canonical deferred metadata has
not been rewritten or represented as a clean security clearance.

One medium-severity, high-confidence finding remains open: the CLI retains
the staging pathname rather than an owned directory/file identity. In an
output parent where another local principal can rename child entries, that
principal can replace the staging directory. Before the writer opens its
output, substitution can redirect truncation to another victim-writable file;
after opening, it can cause successful publication of attacker-selected bytes.
Both formats are affected. Default publication still preserves an already
existing final target. Private or appropriately protected sticky parents
prevent this attack; a stable input tree alone does not.

The relevant control is `Transaction` in `cli/src/archive_cli-filesystem.ads`,
its `Begin_Output`, `Staging_Name` and `Publish` operations, and both branches
of `Archive_CLI.Writer.Create`. Resolve this before publication with retained
filesystem capabilities or an enforced narrower output-parent contract, plus
synchronized regressions for creation and publication substitution. This PR
records the issue without claiming remediation. Abuild's proposed library
integration does not invoke the CLI.

The audit otherwise found no reportable native-buffer, exact-copy-length,
format-bound, ordinary source-change, default final-target no-clobber or
exception-cleanup vulnerability. Direct library paths and member names remain
caller-owned; no extractor, network service or privileged deployment is
established. This static result is limited to the recorded revision and
documented stable-input contract.

## Reachable history and provenance

The nonshallow local repository had 21 refs, 63 reachable commits, 284 trees,
468 distinct blobs, 2,329,968 blob bytes and 114 distinct tracked paths.
Accepted main has 62 commits; the sole additional commit is the unmerged
historical provenance topic `ba1128bc9d55dcd91281daec73c2ee5483dd4f4d`.
All reachable commit/blob contents and tree paths/modes were inspected.
Credential/provider-token, private-key, assignment, entropy, domain, URL,
host-path and infrastructure searches were followed by contextual review.
No access credential, private key, private infrastructure URL, IP literal or
personal filesystem path was identified. Heuristics cannot prove absence of
every sensitive value. Server-only refs, reflogs and unreachable objects are
outside this locally reachable inventory.

The historical ustar hex fixture was decoded and inspected: seven generic
members, empty user/group names, numeric root ownership and the explicit
`regular_file` payload. Its decoded SHA-256 is
`4a57dfbf22f27b4829a79b814342b8efda7e05fb03e5c5930c525f2941cf4bfc`.
The test named `secret` contains demonstrable dummy bytes; test tokens are
pipe/signal markers. Copyright and contributor names provide attribution.
Earlier BSD notices are historical licensing states, superseded on accepted
main by the owner's additional LGPL grant. They do not require a new grant
or history rewrite. Two irrelevant project comparisons are neutralized in
this PR; their historical mentions remain reachable and are not established
as secrets.

The exact imported Abuild revision is now present in the owner's private
GitHub mirror. It is not publicly verifiable there. Establish a publicly
fetchable reference to the exact recorded material before public delivery;
do not publish unrelated predecessor source/history to satisfy this gate.
The [provenance manifest](../provenance/cpio-tar-sources.json) and existing
LGPL grant remain unchanged.

## CI logs and artifacts

All 58 available workflow runs and their 58 latest-attempt job logs were
reviewed: 64,255 lines and 5,345,044 text characters. The review includes
normal Trixie and Copilot jobs and contextual credential/infrastructure
searches. No provider token, private key, credential-bearing URL, JWT-like
credential or private infrastructure reference was identified.

Nineteen retained, nonexpired `ahven-unit-results` ZIPs were downloaded and
read without extraction or executing their contents. All byte sizes and
SHA-256 digests match GitHub metadata: 48,556 ZIP bytes, 114 regular XML files,
78,502 uncompressed bytes and 702 repeated test-result entries. Full content
review reduces to five templates after removing numeric execution durations.
No credential, private key, token, private-infrastructure, URL, email or host
path candidate was identified. Latest-main artifact `12481225904` belongs
to run `39906382452`; its SHA-256 is
`352186fa388a4582914d4dce2eb0893474b774ff07a84e51af8554818c5bf996`.
New runs and retained artifacts must be reviewed again before the public
switch. Expired/deleted artifacts and earlier job attempts are not covered.

## Remaining owner and integration gates

- Resolve the staging finding and revalidate its original operations.
- Establish public predecessor-source verifiability.
- Complete the separate pinned Abuild integration and review its evidence.
- Review the final selected revision, new CI outputs, organization access,
  required checks and branch protections; enable/verify private reporting.
- Obtain the owner's later transfer and public-visibility instructions.

The [publication checklist](../publication.md) makes these gates discoverable
without depending on local scan paths or private services.

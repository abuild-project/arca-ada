# Security policy

## Supported versions

Please report security issues affecting the current `main` branch or the
latest published release. The `0.y` series does not promise cross-minor API
stability or long-term support. Reports about older revisions are welcome
when the issue remains in current code; no fixed response or remediation
time is promised.

## Reporting a vulnerability

Use [Report a vulnerability](https://github.com/abuild-project/arca-ada/security/advisories/new)
to send a private report to the repository maintainers. The reporting channel
is enabled for this public repository; this file does not configure it.

If the private reporting action is unavailable, open an issue asking for a
private contact channel without including vulnerability details. Do not put
credentials, confidential inputs or an exploit in a public issue or PR.
Include the affected revision, environment, minimal reproduction, expected
behavior and practical impact in the subsequent private report.

## System and review scope

The project includes an Ada archive-writing library, a local archive-creation
CLI, a small native filesystem bridge and project-owned build/test helpers.
It does not extract archives or run a network service. The CLI runs with its
caller's filesystem permissions. Its documented input contract requires a
stable source tree; metadata and names supplied to the library are explicit
caller inputs.

Report defects in validation, native boundaries, publication, resource
ownership or cleanup with their actual attacker influence and impact.
Documented usage assumptions do not excuse violations of promised controls.
Third-party dependencies retain their own reporting channels, but defects in
Arca's use of those dependencies are within this project's review scope.

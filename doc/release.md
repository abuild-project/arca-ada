# Release procedure

This procedure is for a maintainer preparing an explicitly authorized release.
Version promotion, tags, publication, repository transfer and visibility are
separate actions. Preparation work leaves the source at its development
version and does not perform them.

## Select and validate the release

1. Complete the applicable [publication gates](publication.md) before a first
   public release. Review the [compatibility and platform policy](../README.md#version-and-compatibility)
   and [licensing requirements](licensing.md).
2. Prepare a release change that promotes `Arca.Version.Value` to the chosen
   normal SemVer version, removing the development suffix. The first planned
   release is `0.1.0`. Move the relevant changelog entries from Unreleased to
   a section with that version and date; retain an empty Unreleased section
   for later work. Mark API breaks under Breaking changes and provide the
   migration path. Update README status and any version-specific examples.
3. Merge that change through the normal review process. Select the exact
   resulting `main` commit. Read the required CI jobs and logs for that
   revision; a green result for an earlier commit is insufficient.
4. Validate fresh sources in the documented rootless AMD64 Trixie environment.
   Run `make -j8 coverage NUM_CPUS=8` before `make -j8 check NUM_CPUS=8`,
   in separate invocations. Check installed library and CLI use, version
   agreement, archive fixtures and the public API. Retain the evidence with
   its source revision and toolchain. Do not infer ARM64 validation from a
   selectable wrapper argument.

`Arca.Version.Value` is the single operative version source; CLI and example
client output derive from it. Rebuild consumers when changing it. No Git
metadata is needed to query the version from a source archive.

## Tag and prepare source artifacts

Only after the selected revision is accepted and green, create an annotated
tag on that commit. The following example is for the first release and runs
in the maintainer's clean `main` checkout after the version change above:

```sh
set -eu
release_version=0.1.0
release_revision=$(git rev-parse HEAD)
test "$(git branch --show-current)" = main
test -z "$(git status --porcelain)"
test "$(cli/bin/arca --version)" = "arca $release_version"
git tag -a "v$release_version" "$release_revision" -m "Arca $release_version"

release_dir=build/release
mkdir -p "$release_dir"
git archive --format=tar --prefix="arca-$release_version/" \
    --output="$release_dir/arca-$release_version.tar" "$release_revision"
gzip -n -c "$release_dir/arca-$release_version.tar" \
    >"$release_dir/arca-$release_version.tar.gz"
python3 - "$release_dir/arca-$release_version.tar.gz" <<'PY'
import hashlib
from pathlib import Path
import sys

archive = Path(sys.argv[1])
digest = hashlib.sha256(archive.read_bytes()).hexdigest()
archive.with_name(archive.name + ".sha256").write_text(
    digest + "  " + archive.name + "\n")
PY
```

Confirm that the tag resolves to the selected commit and that its name agrees
with the source version. Keep a released tag and its contents immutable;
corrections require a new version.

Unpack the source artifact into a new directory and validate its contents,
including LICENSE, COPYRIGHT, source units, GPR projects, build/install
scripts and format fixtures. Run coverage and check in that order through
the unpacked tree's `docker/dev/run`, using the already built development
image. This verifies standalone sources without Git metadata or existing
objects. Verify the published SHA-256 digest against the exact artifact.

## Publish and retain evidence

Publish the annotated tag and source archive/checksum only after an explicit
maintainer decision and successful artifact validation. Confirm the verified
destination, permissions and effective repository protection. Keep the
source revision, tag, artifact digest and validation evidence together.

If binaries are distributed, provide their complete corresponding source for
the exact shipped version, including the applicable build/install inputs,
as described in [licensing.md](licensing.md). Installed licence notices alone
are insufficient. Treat a changed binary build as its own artifact with its
toolchain and source identity recorded.

A later development change advances the version to the next planned
prerelease and starts its changelog entries. Release automation and Alire
submission are separate work; neither is implied by this procedure.

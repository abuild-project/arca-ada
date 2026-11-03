#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later

"""Stage selected canonical Markdown files for the public documentation site."""

from pathlib import Path
from urllib.parse import quote, unquote, urlsplit
import os
import re
import shutil


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "build/docs-source"
REPOSITORY = "https://github.com/abuild-project/arca-ada"

PAGES = {
    Path("README.md"): Path("index.md"),
    Path("CONTRIBUTING.md"): Path("contributing.md"),
    Path("SECURITY.md"): Path("security.md"),
    Path("CHANGELOG.md"): Path("changelog.md"),
    Path("doc/cli.md"): Path("cli.md"),
    Path("doc/cpio.md"): Path("cpio.md"),
    Path("doc/tar.md"): Path("tar.md"),
    Path("doc/development.md"): Path("development.md"),
    Path("doc/unit-tests.md"): Path("unit-tests.md"),
    Path("doc/native-test-coverage.md"): Path("native-test-coverage.md"),
    Path("doc/coding-style.md"): Path("coding-style.md"),
    Path("doc/licensing.md"): Path("licensing.md"),
    Path("doc/publication.md"): Path("publication.md"),
    Path("doc/release.md"): Path("release.md"),
}

LINK = re.compile(r"(\[[^\]]+\]\()([^)]*)(\))")
FENCE = re.compile(r"^\s*(`{3,}|~{3,})")


def rewrite_target(source: Path, destination: Path, target: str) -> str:
    """Keep site pages local and send other relative links to GitHub source."""
    if target.startswith(("#", "//")):
        return target

    parts = urlsplit(target)
    if parts.scheme or parts.netloc or not parts.path:
        return target

    path = (ROOT / source.parent / unquote(parts.path)).resolve()
    try:
        relative = path.relative_to(ROOT)
    except ValueError as error:
        raise ValueError(
            f"link escapes repository: {source}: {target}") from error

    if not path.exists():
        raise ValueError(f"broken repository link: {source}: {target}")

    if relative in PAGES:
        output_target = os.path.relpath(OUTPUT / PAGES[relative],
                                        (OUTPUT / destination).parent)
        result = output_target.replace(os.sep, "/")
    else:
        kind = "tree" if path.is_dir() else "blob"
        result = (f"{REPOSITORY}/{kind}/main/"
                  f"{quote(relative.as_posix(), safe='/')}")

    if parts.query:
        result += "?" + parts.query
    if parts.fragment:
        result += "#" + parts.fragment
    return result


def stage_page(source: Path, destination: Path) -> None:
    """Rewrite only rendered Markdown links, leaving code fences untouched."""
    text = (ROOT / source).read_text(encoding="utf-8")
    rendered = []
    fence = None
    for line in text.splitlines(keepends=True):
        marker = FENCE.match(line)
        if marker:
            character = marker.group(1)[0]
            if fence is None:
                fence = character
            elif fence == character:
                fence = None
        if fence is None and not marker:
            line = LINK.sub(lambda match: match.group(1)
                            + rewrite_target(source, destination,
                                             match.group(2))
                            + match.group(3), line)
        rendered.append(line)
    (OUTPUT / destination).write_text("".join(rendered), encoding="utf-8")


def main() -> None:
    """Replace only the generated staging tree and stage selected pages."""
    if OUTPUT.exists():
        shutil.rmtree(OUTPUT)
    OUTPUT.mkdir(parents=True)
    for source, destination in PAGES.items():
        stage_page(source, destination)
    print(f"Staged {len(PAGES)} canonical Markdown pages in {OUTPUT}")


if __name__ == "__main__":
    main()

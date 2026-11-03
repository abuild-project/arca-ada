# Changelog

This document lists user- and integrator-relevant changes. Implementation,
validation and publication details are in the
[change records](doc/change-records/README.md) and guides. The first release
summarizes the capabilities shipped together instead of every step taken
before publication.

## Unreleased

## 0.1.0 - 2026-11-03

### Added

- `Arca.CPIO` and `Arca.TAR` create uncompressed `newc` and ustar/GNU archives
  with files, directories, links, FIFOs and device metadata. Each writer owns
  its output and attempts to remove an unfinished archive on scope exit.
- The 64-bit Linux `arca create` command archives directory trees with stable
  ordering, preserved hardlinks and metadata, owner and time overrides, and
  atomic publication that does not replace an existing output by default.
  Handled signals request cleanup; `--force` allows replacement.
- The library and CLI can be installed and uninstalled with GPRinstall. The
  public `Arca.Version` package and `arca --version` report the source version.
- A searchable [documentation site](https://abuild-project.github.io/arca-ada/)
  covers the writers, CLI, development and project guidance.

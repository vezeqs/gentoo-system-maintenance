# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-10-30

### Added
- `Makefile`, `tests/` and a GitHub Actions check workflow.
- README sections for verification and limits.

### Verified
- `emerge --ask=n` is accepted (checked with `emerge --ask=n --version`).
- `revdep-rebuild` does not prompt before emerging; `--pretend` is opt-in, and
  `emerge` without `--ask` runs unattended.

## [0.1.0] - 2026-10-30

### Added
- Initial release for Gentoo.
- Sync with `emerge --sync`, falling back to `emerge-webrsync`.
- Preview of `emerge -puDN @world` and depclean candidates before the confirmation prompt.
- `--check` syncs and prints the plan, then stops before building anything.
- Repair with `@preserved-rebuild` and `revdep-rebuild` when gentoolkit is installed.
- World update with `emerge -uDN @world --keep-going`, depclean, `eclean-dist` or `emerge --clean`.
- Reboot detection by comparing `/usr/src/linux` with the running kernel.
- `-y/--yes`, `-n/--dry-run`, `--check` and `-h/--help`.

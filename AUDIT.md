# Audit — 2026-10-30

Scope: `gentoo-system-maintenance.sh`, `README.md`, `assets/`, plus the tests
and CI added by this audit.

Baseline before changes:

```console
$ bash -n gentoo-system-maintenance.sh
(no output, pass)
$ shellcheck -x -S warning gentoo-system-maintenance.sh
(no output, rc=0)
$ make check
make: *** No rule to make target 'check'.  Stop.
```

History read: `bbe8c58` initial release. Pull requests: none. There is no
`origin` remote, so `gh pr list` has nothing to read.

Findings: 4 (2 fixed, 2 not bugs).

## F1 — No tests, CI or Makefile (Medium)

**Evidence:** `ls Makefile tests` returned nothing.
**Fix:** `Makefile`, `tests/`, and a GitHub Actions check workflow.
**Status:** fixed, `make check` passes.

## F2 — README had no way to verify its claims (Low)

**Fix:** added "Verify it yourself" and "Limits".
**Status:** fixed, test `tests/docs.sh`.

## F3 — emerge --ask=n validity (Not a bug)

**Evidence:** `emerge --ask=n --version` prints the Portage version and exits 0
in a `gentoo/stage3` container. `--ask=n` is accepted.
**Status:** not a bug. No change.

## F4 — revdep-rebuild prompting under -y (Not a bug)

**Evidence:** the revdep-rebuild man page documents `--pretend` as an opt-in
dry run and `--` to pass options to emerge; it does not ask before emerging.
`emerge` without `--ask` does not prompt either.
**Status:** not a bug. No change.

## Post-audit verification

- `tests/emerge_runtime.sh` passes: the mock `emerge` logs `--sync`,
  `-puDN @world`, `@preserved-rebuild --ask=n`,
  `-uDN @world --keep-going --ask=n`, `--depclean --ask=n`, `--clean`.
- `--check` against `gentoo/stage3` synced the tree and produced a plan of 11
  packages.

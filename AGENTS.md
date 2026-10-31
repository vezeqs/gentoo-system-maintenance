# AGENTS.md

Gentoo System Maintenance is a single bash script that syncs, updates and cleans
Gentoo. It prints a build plan and changes nothing until the user answers `y`,
and it has a `--check` mode that stops after the plan. There is no build step
and no dependency beyond bash and Portage.

## Entry points

| Question | File |
| --- | --- |
| The maintenance script | `gentoo-system-maintenance.sh` |
| Checks | `make check` |
| Screenshot | `assets/preview.png` (`--check` output) |

## Invariants

- Nothing mutating runs before the `[y/N]` prompt returns `y`.
- `--check` syncs and previews, then stops before any build or removal.
- `--dry-run` prints every mutating command and executes none.
- `emerge` always gets `--ask=n` so it cannot prompt in `--yes` mode.
- The world update uses `--keep-going` and reports failures at the end.
- `eclean-dist` and `revdep-rebuild` are only used when gentoolkit is installed.

## Commands

```bash
make check    # bash -n, shellcheck, smoke tests, assets
make lint     # bash -n + shellcheck
make test     # smoke tests
```

The real proof is a container run:

```bash
podman run --rm -v "$PWD:/repo:ro,Z" gentoo/stage3 \
  bash /repo/gentoo-system-maintenance.sh --check
```

## Sharp edges

- A world update builds from source and can take hours. `--check` exists so the
  plan can be read before committing to that.
- `emerge --sync` can fail without git; the script falls back to
  `emerge-webrsync`.
- `revdep-rebuild` and `eclean-dist` need `gentoolkit`; both are guarded.
- The full `emerge -uDN @world` was not run in the audit. `tests/emerge_runtime.sh`
  proves the command sequence with a mock `emerge`; the sync and pretend path is
  proven for real.
- `--ask=n` is valid (checked with `emerge --ask=n --version`).

## Definition of done

- [ ] `make check` passes.
- [ ] The change has a test in `tests/` that fails without it.
- [ ] `README.md` still matches behaviour.
- [ ] `CHANGELOG.md` has an entry for user-visible changes.
- [ ] If the script changed, regenerate `assets/preview.png` and update
      `assets/source.sha256`.
- [ ] No secrets, no `rm -rf`, no new dependency.

## Do not touch

- `LICENSE`.
- `assets/*.png` by hand; they are captures of a real run.
- Formatting of unrelated files.

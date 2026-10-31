#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
mock=$(mktemp -d); trap 'rm -rf "$mock"' EXIT
cat > "$mock/emerge" <<'MOCK'
#!/usr/bin/env bash
case "$*" in
  --sync) exit 0 ;;
  *-puDN*) echo "invalid atom in @world" >&2; exit 1 ;;
  *"--depclean --pretend"*) exit 0 ;;
esac
exit 0
MOCK
chmod +x "$mock/emerge"
out=$(podman run --rm -v $repo:/repo:ro,Z -v $mock:/mock:ro,Z gentoo/stage3 bash -c 'PATH=/mock:$PATH bash /repo/gentoo-system-maintenance.sh -y' 2>&1)
grep -q 'Could not build the update plan' <<<"$out"
if grep -q 'Packages to build: .*0' <<<"$out"; then echo "failed plan reported as zero" >&2; exit 1; fi
echo "ok plan failure is reported"

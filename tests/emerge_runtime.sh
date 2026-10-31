#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
mock=$(mktemp -d)
trap 'rm -rf "$mock"' EXIT

cat > "$mock/emerge" <<'MOCK'
#!/usr/bin/env bash
echo "emerge $*" >> /tmp/emerge.log
case "$*" in
  *-puDN*) printf 'These are the packages that would be merged:\n[ebuild U ] dev-lang/python-3.14.10 [3.14.7]\n' ;;
esac
exit 0
MOCK
chmod +x "$mock/emerge"

out=$(podman run --rm -v "$repo:/repo:ro,Z" -v "$mock:/mock:ro,Z" gentoo/stage3 \
  bash -c 'PATH=/mock:$PATH bash /repo/gentoo-system-maintenance.sh -y; echo ===LOG===; cat /tmp/emerge.log')

grep -q '^emerge --sync$' <<<"$out"
grep -q '^emerge -puDN @world$' <<<"$out"
grep -q '^emerge @preserved-rebuild --ask=n$' <<<"$out"
grep -q '^emerge -uDN @world --keep-going --ask=n$' <<<"$out"
grep -q '^emerge --depclean --ask=n$' <<<"$out"
grep -q '^emerge --clean$' <<<"$out"

echo "ok emerge runtime"

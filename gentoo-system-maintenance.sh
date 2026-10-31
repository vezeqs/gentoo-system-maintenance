#!/usr/bin/env bash
#
# FOR GENTOO!!
# System Maintenance - codefactory
#

set -euo pipefail

ASSUME_YES=0
DRY_RUN=0
CHECK_ONLY=0

#color
if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; NC=$'\033[0m'; BLUE=$'\033[0;34m'
  YELLOW=$'\033[1;33m'; PURPLE=$'\033[0;35m'; PINK=$'\033[38;5;213m';
  GREEN=$'\033[0;32m'
else
  RED=''; NC=''; BLUE=''; YELLOW=''; PURPLE=''; PINK=''; GREEN='';
fi

#message
info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
warn() { printf "${YELLOW}[WARNING]${NC} %s\n" "$*" >&2; }
ok() { printf "${PURPLE}[OK]${NC} %s\n" "$*"; }
yay() { printf "${PINK}[SYS]${NC} %s\n" "$*"; }
success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$*"; }

#options
usage() {
  printf 'Usage: sudo %s [-y|--yes] [-n|--dry-run] [-h|--help]\n' "$0"
  printf '  -y, --yes      skip the confirmation prompt (unattended runs)\n'
  printf '  -n, --dry-run  print every command without running it\n'
  printf '  -h, --help     show this help\n'
}

while (( $# )); do
  case "$1" in
    -y|--yes) ASSUME_YES=1 ;;
    -n|--dry-run) DRY_RUN=1 ;;
    --check) CHECK_ONLY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) error "Unknown option: $1"; usage >&2; exit 2 ;;
  esac
  shift
done

#run a command, or print it in dry-run mode
run() {
  if (( DRY_RUN )); then
    printf '%s[DRY-RUN]%s %s\n' "$YELLOW" "$NC" "$*"
    return 0
  fi
  "$@"
}

#runs checks
if [[ $EUID -ne 0 ]]; then
  error "Please run as root: sudo $0"
  exit 1
fi

if ! command -v emerge >/dev/null 2>&1; then
  error "emerge not found. This script is for Gentoo"
  exit 1
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ ${ID:-} != gentoo ]]; then
    warn "This does not look like Gentoo (ID=${ID:-unknown}), continuing anyway"
  fi
fi

#banner
printf '%s\n' "${YELLOW}-------- SYSTEM MAINTENANCE --------${NC}"
info "==> Made by ${RED}codefactory${NC}"
info "==> Please check more of my scripts and code in https://github.com/vezeqs"
yay "Thanks for using this! ${PINK}( ˶⚈Ɛ⚈˵)${NC}"
printf '%s\n' "${YELLOW}------------------------------------${NC}"

#Reports errors
trap 'error "Aborted (status $?): $BASH_COMMAND"' ERR

info "[$(date -Is)] starting maintenance"
warn "==> Gentoo builds from source: an upgrade can take hours and a lot of disk"

info "==> Syncing the Portage tree"
if ! run emerge --sync; then
  warn "==> emerge --sync failed, falling back to a webrsync snapshot"
  run emerge-webrsync
fi

info "==> Checking what would change"
if (( DRY_RUN )); then
  info "==> Dry run, skipping the preview queries"
else
  rc=0
  preview=$(emerge -puDN @world 2>&1) || rc=$?
  if (( rc == 0 )); then
    upgrades=$(grep -c '^\[' <<<"$preview" || true)
    info "==> Packages to build: ${PURPLE}${upgrades}${NC}"
    if (( upgrades > 0 )); then
      grep '^\[' <<<"$preview" | head -10 | sed 's/^/    /'
      if (( upgrades > 10 )); then
        info "==> ... and $((upgrades - 10)) more"
      fi
    fi
  else
    warn "==> Could not build the update plan (emerge exit $rc)"
    printf '%s\n' "$preview" | tail -5 | sed 's/^/    /'
  fi

  rc=0
  depclean_preview=$(emerge --depclean --pretend 2>/dev/null) || rc=$?
  if (( rc != 0 )); then
    warn "==> Could not list depclean candidates (emerge exit $rc)"
  else
    depclean_count=$(grep -c '^\[' <<<"$depclean_preview" || true)
    if (( depclean_count > 0 )); then
      warn "==> Packages to depclean: ${depclean_count}"
    fi
  fi
fi

if (( CHECK_ONLY )); then
  info "==> --check was passed, stopping before any changes"
  exit 0
fi

if (( ASSUME_YES )); then
  info "==> Running unattended (--yes)"
else
  if [[ ! -t 0 ]]; then
    error "==> No terminal to confirm on, re-run with --yes for unattended use"
    exit 1
  fi
  printf '%s' "${YELLOW}==> Proceed with these changes? [y/N] ${NC}"
  read -r reply || reply=""
  case "$reply" in
    y|Y|yes|YES) ;;
    *) info "==> Aborted, nothing was changed."; exit 0 ;;
  esac
fi

#the updating part
info "==> Rebuilding preserved libraries"
if ! run emerge @preserved-rebuild --ask=n; then
  warn "==> @preserved-rebuild reported nothing to do or failed, continuing"
fi

if command -v revdep-rebuild >/dev/null 2>&1; then
  info "==> Checking for reverse dependency breakage"
  if ! run revdep-rebuild --quiet; then
    warn "==> revdep-rebuild reported problems, review its output"
  fi
fi

info "==> Updating the world set"
run emerge -uDN @world --keep-going --ask=n

info "==> Removing packages that are no longer needed"
run emerge --depclean --ask=n

info "==> Taking out cache from the packages"
if command -v eclean-dist >/dev/null 2>&1; then
  run eclean-dist --destructive
else
  info "==> eclean-dist is not installed (emerge app-portage/gentoolkit), skipping distfiles"
fi
run emerge --clean

running=$(uname -r)
running_ver=${running%%-*}
reboot=1
if [[ -L /usr/src/linux ]]; then
  target=$(basename "$(readlink -f /usr/src/linux)")
  if [[ $target == "linux-${running_ver}"* ]]; then
    reboot=0
  fi
elif compgen -G "/usr/src/linux-*" >/dev/null; then
  for dir in /usr/src/linux-*; do
    if [[ $(basename "$dir") == "linux-${running_ver}"* ]]; then
      reboot=0
    fi
  done
fi

if (( DRY_RUN )); then
  info "==> Dry run, skipping the reboot check"
elif (( reboot )); then
  warn "==> Reboot required: no kernel sources match the running $running"
else
  ok "==> No reboot required."
fi

success "Maintenance completed with no errors."

printf '%s\n' "${YELLOW}------------------------------------${NC}"

info "==> System update is over."
info "==> Find more scripts in ${PINK}https://github.com/vezeqs${NC}"
yay "Thanks for using this! ${PINK}( ˶⚈Ɛ⚈˵)${NC}"

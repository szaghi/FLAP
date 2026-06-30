#!/usr/bin/env bash
# install.sh — Download and/or build a GitHub Fortran project.
#
# Usage:
#   install.sh [--repo owner/project] [--download git|wget]
#              [--build fobis|make|cmake] [--mode <fobos-mode>]
#              [--tag <tag>] [--verbose]
#
# Repo resolution order:
#   1. --repo argument
#   2. GITHUB_REPOSITORY environment variable
#   3. git remote of the current directory
#
# Examples:
#   install.sh --download wget --build make
#   install.sh --download wget --build cmake --tag v1.2.3
#   install.sh --repo owner/project --download git --build fobis

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*" >&2; exit 1; }

# ── Defaults ──────────────────────────────────────────────────────────────────
REPO="${GITHUB_REPOSITORY:-}"
DOWNLOAD=0
BUILD=0
MODE="tests-gnu"
TAG="${TAG:-latest}"
VERBOSE=0
readonly E_BAD_OPTION=254

# ── Usage ─────────────────────────────────────────────────────────────────────
usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "  --repo,     -r <owner/project>   GitHub repository (default: auto-detect)"
  echo "  --download, -d <git|wget>         Download the project"
  echo "  --build,    -b <fobis|make|cmake|fpm> Build the project"
  echo "  --mode,     -m <mode>             FoBiS.py build mode (default: tests-gnu)"
  echo "  --tag,      -t <tag>              Release tag for wget (default: latest)"
  echo "  --verbose,  -v                    Verbose output"
  echo "  --help,     -?                    Print this help"
  echo ""
  echo "Examples:"
  echo "  $0 --download wget --build make"
  echo "  $0 --download wget --build cmake --tag v1.2.3"
  echo "  $0 --repo owner/project --download git --build fobis"
}

# ── Arguments ─────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --repo     | -r ) REPO="$2";     shift 2 ;;
    --download | -d ) DOWNLOAD="$2"; shift 2 ;;
    --build    | -b ) BUILD="$2";    shift 2 ;;
    --mode     | -m ) MODE="$2";     shift 2 ;;
    --tag      | -t ) TAG="$2";      shift 2 ;;
    --verbose  | -v ) VERBOSE=1;     shift   ;;
    --help     | -? ) usage; exit 0          ;;
    --         )      shift; break           ;;
    -*         ) echo "Unrecognized option: $1" >&2; usage; exit $E_BAD_OPTION ;;
    *          ) break ;;
  esac
done

if [[ "$DOWNLOAD" == "0" && "$BUILD" == "0" ]]; then
  usage
  exit 0
fi

# ── Resolve repository ────────────────────────────────────────────────────────
if [[ -z "$REPO" ]]; then
  if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
    REPO="$(echo "$REMOTE_URL" | sed -E 's|.*[:/]([^/]+/[^/]+)$|\1|' | sed 's|\.git$||')"
  fi
fi
[[ -z "$REPO" ]] && error "Cannot determine repository. Use --repo owner/project or set GITHUB_REPOSITORY."

PROJECT="${REPO##*/}"
GITHUB="https://github.com/$REPO"

[[ $VERBOSE -eq 1 ]] && info "Repository: ${BOLD}${REPO}${RESET}"

# ── Download ──────────────────────────────────────────────────────────────────
projectdownload() {
  [[ $VERBOSE -eq 1 ]] && info "Downloading ${PROJECT}…"

  if [[ "$DOWNLOAD" == "git" ]]; then
    command -v git &>/dev/null || error "git not found."
    git clone "$GITHUB"
    cd "$PROJECT"
    if [[ -f .deps_config.ini || -f src/third_party/.deps_config.ini ]]; then
      command -v FoBiS.py &>/dev/null || error "FoBiS.py not found (needed for fetch)."
      FoBiS.py fetch
    fi
    cd -

  elif [[ "$DOWNLOAD" == "wget" ]]; then
    command -v wget &>/dev/null || error "wget not found."
    command -v curl &>/dev/null || error "curl not found."
    command -v jq   &>/dev/null || error "jq not found."

    if [[ "$TAG" == "latest" ]]; then
      API_URL="https://api.github.com/repos/$REPO/releases/latest"
    else
      API_URL="https://api.github.com/repos/$REPO/releases/tags/$TAG"
    fi

    TARBALL_URL=$(curl -s "$API_URL" | jq -r '.assets[] | select(.name | endswith(".tar.gz")) | .browser_download_url')
    [[ -z "$TARBALL_URL" ]] && error "No tarball found for ${TAG} in ${REPO}."

    TARBALL="${TARBALL_URL##*/}"
    EXTRACTED="${TARBALL%.tar.gz}"
    wget "$TARBALL_URL"
    tar xf "$TARBALL"
    rm -f "$TARBALL"
    [[ $VERBOSE -eq 1 ]] && info "Extracted into: ${EXTRACTED}"
  fi

  success "Downloaded"
}

# ── Build ─────────────────────────────────────────────────────────────────────
projectbuild() {
  [[ $VERBOSE -eq 1 ]] && info "Building ${PROJECT} with ${BUILD}…"

  case "$BUILD" in
    fobis | FoBiS.py )
      command -v FoBiS.py &>/dev/null || error "FoBiS.py not found."
      FoBiS.py build -mode "$MODE"
      ;;
    make )
      command -v make &>/dev/null || error "make not found."
      make
      ;;
    cmake )
      command -v cmake &>/dev/null || error "cmake not found."
      if [[ ! -f CMakeLists.txt ]]; then
        warn "CMakeLists.txt not found — skipping cmake build."
        return
      fi
      cmake -B build
      cmake --build build
      ;;
    fpm )
      command -v fpm &>/dev/null || error "fpm not found."
      if [[ ! -f fpm.toml ]]; then
        warn "fpm.toml not found — skipping fpm build."
        return
      fi
      fpm install
      ;;
    * )
      error "Unknown build tool: ${BUILD}. Use fobis, make, cmake, or fpm."
      ;;
  esac

  success "Built"
}

# ── Main ──────────────────────────────────────────────────────────────────────
if [[ "$DOWNLOAD" != "0" && "$BUILD" == "0" ]]; then
  projectdownload

elif [[ "$DOWNLOAD" == "0" && "$BUILD" != "0" ]]; then
  projectbuild

elif [[ "$DOWNLOAD" != "0" && "$BUILD" != "0" ]]; then
  projectdownload
  if [[ "$DOWNLOAD" == "wget" ]]; then
    cd "$EXTRACTED"
    if [[ -f .deps_config.ini || -f src/third_party/.deps_config.ini ]]; then
      command -v FoBiS.py &>/dev/null || error "FoBiS.py not found (needed for fetch)."
      info "Fetching dependencies…"
      FoBiS.py fetch
      success "Dependencies fetched"
    fi
  else
    cd "$PROJECT"
  fi
  projectbuild
fi

exit 0

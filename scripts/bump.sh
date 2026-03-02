#!/usr/bin/env bash
# bump.sh — Bump version, update CHANGELOG.md, commit, tag and push.
#
# Usage:
#   scripts/bump.sh <patch|minor|major>   # auto-compute next version
#   scripts/bump.sh v1.2.4               # explicit version
#
# What it does:
#   1. Computes the new version from the latest git tag
#   2. Runs git-cliff to regenerate CHANGELOG.md up to the new version
#   3. Commits CHANGELOG.md with a conventional "chore(release)" message
#   4. Creates an annotated git tag
#   5. Pushes commit + tag  →  triggers the release.yml workflow on GitHub
#
# Requirements:
#   git-cliff  →  cargo install git-cliff
#                 or: https://github.com/orhun/git-cliff/releases
#
# Examples:
#   scripts/bump.sh patch   # v1.2.3 → v1.2.4
#   scripts/bump.sh minor   # v1.2.3 → v1.3.0
#   scripts/bump.sh major   # v1.2.3 → v2.0.0
#   scripts/bump.sh v2.0.0  # explicit

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*" >&2; exit 1; }

# ── Requirements ──────────────────────────────────────────────────────────────
command -v git-cliff &>/dev/null || error \
  "git-cliff not found.\n  Install: cargo install git-cliff\n  Or download from: https://github.com/orhun/git-cliff/releases"

command -v git &>/dev/null || error "git not found."

# ── Must be run from repo root ────────────────────────────────────────────────
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# ── Detect repo slug (owner/name) from remote ────────────────────────────────
REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
REPO_SLUG="$(echo "$REMOTE_URL" | sed -E 's|.*[:/]([^/]+/[^/]+)$|\1|' | sed 's|\.git$||')"

# ── Guard: clean working tree ─────────────────────────────────────────────────
if [[ -n "$(git status --porcelain)" ]]; then
  error "Working tree is dirty. Commit or stash changes before bumping."
fi

# ── Argument ──────────────────────────────────────────────────────────────────
BUMP="${1:-}"
if [[ -z "$BUMP" ]]; then
  echo "Usage: $0 <patch|minor|major|vX.Y.Z>"
  exit 1
fi

# ── Resolve current version ───────────────────────────────────────────────────
CURRENT_TAG="$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' | sort -V | tail -1)"
[[ -z "$CURRENT_TAG" ]] && CURRENT_TAG="v0.0.0"
CURRENT_VER="${CURRENT_TAG#v}"
MAJOR="$(echo "$CURRENT_VER" | cut -d. -f1)"
MINOR="$(echo "$CURRENT_VER" | cut -d. -f2)"
PATCH="$(echo "$CURRENT_VER" | cut -d. -f3)"

info "Current version: ${CURRENT_TAG}"

# ── Compute new version ───────────────────────────────────────────────────────
if [[ "$BUMP" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  NEW_TAG="$BUMP"
elif [[ "$BUMP" == "patch" ]]; then
  NEW_TAG="v${MAJOR}.${MINOR}.$((PATCH + 1))"
elif [[ "$BUMP" == "minor" ]]; then
  NEW_TAG="v${MAJOR}.$((MINOR + 1)).0"
elif [[ "$BUMP" == "major" ]]; then
  NEW_TAG="v$((MAJOR + 1)).0.0"
else
  error "Invalid argument: '$BUMP'. Use patch, minor, major, or vX.Y.Z."
fi

info "New version:     ${NEW_TAG}"

# ── Confirm ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}This will:${RESET}"
echo -e "  1. Regenerate ${CYAN}CHANGELOG.md${RESET} up to ${BOLD}${NEW_TAG}${RESET}"
echo -e "  2. Update ${CYAN}VERSION${RESET} to ${BOLD}${NEW_TAG}${RESET}"
echo -e "  3. Commit with message: ${CYAN}chore(release): ${NEW_TAG}${RESET}"
echo -e "  4. Create annotated tag ${BOLD}${NEW_TAG}${RESET}"
echo -e "  5. Push commit and tag to origin  →  triggers GitHub release workflow"
echo ""
read -rp "Proceed? [y/N] " CONFIRM
[[ "${CONFIRM,,}" == "y" ]] || { warn "Aborted."; exit 0; }

# ── Update CHANGELOG.md ───────────────────────────────────────────────────────
echo ""
info "Generating CHANGELOG.md with git-cliff…"
git cliff --tag "$NEW_TAG" --output CHANGELOG.md
success "CHANGELOG.md updated"

# ── Update VERSION ────────────────────────────────────────────────────────────
info "Updating VERSION…"
echo "$NEW_TAG" > VERSION
success "VERSION updated"

# ── Commit ────────────────────────────────────────────────────────────────────
info "Committing changelog and version…"
git add CHANGELOG.md VERSION
git commit -m "chore(release): ${NEW_TAG}"
success "Committed"

# ── Tag ───────────────────────────────────────────────────────────────────────
info "Creating annotated tag ${NEW_TAG}…"
git tag -a "$NEW_TAG" -m "Release ${NEW_TAG}"
success "Tagged"

# ── Push ─────────────────────────────────────────────────────────────────────
info "Pushing to origin…"
git push origin HEAD
git push origin "$NEW_TAG"
success "Pushed"

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}${BOLD} Released ${NEW_TAG}!${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  GitHub Actions release workflow triggered."
echo -e "  Follow progress at:"
echo -e "  ${CYAN}https://github.com/${REPO_SLUG}/actions${RESET}"
echo ""

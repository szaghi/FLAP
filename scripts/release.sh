#!/usr/bin/env bash
# release.sh — Bump version, update CHANGELOG.md, commit, tag and push.
#
# Usage:
#   scripts/release.sh (--patch | --minor | --major | vX.Y.Z | X.Y.Z)
#
#   --patch, -p     X.Y.Z → X.Y.Z+1
#   --minor, -m     X.Y.Z → X.Y+1.0
#   --major, -M     X.Y.Z → X+1.0.0
#   vX.Y.Z          set an explicit version (v prefix optional)
#
# What it does:
#   1. Pre-flight: branch, remote freshness, clean tree, tag uniqueness
#   2. Runs git-cliff to regenerate CHANGELOG.md up to the new version
#   3. Updates VERSION file
#   4. Commits CHANGELOG.md + VERSION with a conventional "chore(release)" message
#   5. Creates an annotated git tag
#   6. Pushes commit + tag  →  triggers the release.yml workflow on GitHub
#
# Requirements:
#   git-cliff  →  cargo install git-cliff
#                 or: https://github.com/orhun/git-cliff/releases

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
die()     { echo -e "${RED}[error]${RESET} $*" >&2; exit 1; }

usage() {
  echo -e "Usage: $0 (--patch | --minor | --major | vX.Y.Z)"
  echo -e ""
  echo -e "  --patch, -p     X.Y.Z → X.Y.Z+1"
  echo -e "  --minor, -m     X.Y.Z → X.Y+1.0"
  echo -e "  --major, -M     X.Y.Z → X+1.0.0"
  echo -e "  vX.Y.Z          set explicit version (v prefix optional)"
  exit 1
}

# ── Stage tracking + recovery trap ───────────────────────────────────────────
STAGE="preflight"
NEW_TAG=""

on_error() {
  echo ""
  echo -e "${RED}${BOLD}================================================================${RESET}"
  echo -e "${RED}${BOLD}  release.sh FAILED at stage: ${STAGE}${RESET}"
  echo -e "${RED}${BOLD}================================================================${RESET}"
  case "$STAGE" in
    preflight | confirm)
      echo "  Nothing was changed. Fix the issue above and re-run."
      ;;
    bumped)
      echo "  Files were modified locally but not committed."
      echo "  To discard and start over:"
      echo "    git checkout -- VERSION CHANGELOG.md"
      ;;
    committed)
      echo "  Commit was made but not tagged/pushed. To resume:"
      echo "    git tag -a ${NEW_TAG} -m \"Release ${NEW_TAG}\""
      echo "    git push origin ${TRUNK} --follow-tags"
      ;;
    tagged)
      echo "  Tag ${NEW_TAG} was created locally but not pushed. To resume:"
      echo "    git push origin ${TRUNK} --follow-tags"
      ;;
  esac
  echo -e "${RED}${BOLD}================================================================${RESET}"
}

trap 'on_error' ERR

# ── Requirements ──────────────────────────────────────────────────────────────
command -v git-cliff &>/dev/null || die \
  "git-cliff not found.\n  Install: cargo install git-cliff\n  Or download from: https://github.com/orhun/git-cliff/releases"
command -v git &>/dev/null || die "git not found."

# ── Must be run from repo root ────────────────────────────────────────────────
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# ── Detect trunk branch from remote HEAD (set automatically by git clone) ────
TRUNK="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')"
[[ -n "$TRUNK" ]] || TRUNK="main"

# ── Detect repo slug (owner/name) from remote ────────────────────────────────
REMOTE_URL="$(git remote get-url origin 2>/dev/null || true)"
REPO_SLUG="$(echo "$REMOTE_URL" | sed -E 's|.*[:/]([^/]+/[^/]+)$|\1|' | sed 's|\.git$||')"

# ── Argument parsing ──────────────────────────────────────────────────────────
[[ $# -ge 1 ]] || usage

BUMP_ARG=""
for arg in "$@"; do
  case "$arg" in
    --major | -M)                          BUMP_ARG=major ;;
    --minor | -m)                          BUMP_ARG=minor ;;
    --patch | -p)                          BUMP_ARG=patch ;;
    v[0-9]*.[0-9]*.[0-9]* | [0-9]*.[0-9]*.[0-9]*)  BUMP_ARG="$arg" ;;
    *) usage ;;
  esac
done
[[ -n "$BUMP_ARG" ]] || usage

# ── Resolve current version from latest git tag ───────────────────────────────
CURRENT_TAG="$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' | sort -V | tail -1)"
[[ -z "$CURRENT_TAG" ]] && CURRENT_TAG="v0.0.0"
CURRENT_VER="${CURRENT_TAG#v}"
MAJOR="$(echo "$CURRENT_VER" | cut -d. -f1)"
MINOR="$(echo "$CURRENT_VER" | cut -d. -f2)"
PATCH="$(echo "$CURRENT_VER" | cut -d. -f3)"

case "$BUMP_ARG" in
  major)   NEW_TAG="v$((MAJOR + 1)).0.0" ;;
  minor)   NEW_TAG="v${MAJOR}.$((MINOR + 1)).0" ;;
  patch)   NEW_TAG="v${MAJOR}.${MINOR}.$((PATCH + 1))" ;;
  v*)      NEW_TAG="$BUMP_ARG" ;;
  [0-9]*)  NEW_TAG="v${BUMP_ARG}" ;;
esac

# ── Pre-flight checks ─────────────────────────────────────────────────────────
STAGE="preflight"

CURRENT_BRANCH="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
[[ "$CURRENT_BRANCH" == "$TRUNK" ]] \
  || die "must be on '${TRUNK}' branch (currently on '${CURRENT_BRANCH}')"

[[ -z "$(git status --porcelain)" ]] \
  || die "working tree is dirty — commit or stash changes before bumping"

git fetch --tags --quiet
[[ -z "$(git tag -l "${NEW_TAG}")" ]] || die "tag ${NEW_TAG} already exists"

BEHIND="$(git rev-list --count HEAD..origin/${TRUNK} 2>/dev/null || echo 0)"
[[ "$BEHIND" -eq 0 ]] \
  || die "${TRUNK} is ${BEHIND} commit(s) behind origin/${TRUNK} — run: git pull origin ${TRUNK}"

# ── Confirm ───────────────────────────────────────────────────────────────────
STAGE="confirm"
echo ""
echo -e "  Current version : ${BOLD}${CURRENT_TAG}${RESET}"
echo -e "  New version     : ${BOLD}${NEW_TAG}${RESET}"
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
STAGE="bumped"
echo ""
info "Generating CHANGELOG.md with git-cliff…"
git cliff --tag "$NEW_TAG" --output CHANGELOG.md
success "CHANGELOG.md updated"

# ── Update VERSION ────────────────────────────────────────────────────────────
info "Updating VERSION…"
echo "$NEW_TAG" > VERSION
grep -q "^${NEW_TAG}$" VERSION || die "VERSION update failed — file content mismatch"
success "VERSION updated to ${NEW_TAG}"

# ── Commit ────────────────────────────────────────────────────────────────────
STAGE="committed"
info "Committing changelog and version…"
git add CHANGELOG.md VERSION
git commit -m "chore(release): ${NEW_TAG}"
success "Committed"

# ── Tag ───────────────────────────────────────────────────────────────────────
STAGE="tagged"
info "Creating annotated tag ${NEW_TAG}…"
git tag -a "$NEW_TAG" -m "Release ${NEW_TAG}"
success "Tagged"

# ── Push ──────────────────────────────────────────────────────────────────────
info "Pushing ${TRUNK} + tag to origin…"
git push origin "${TRUNK}" --follow-tags
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

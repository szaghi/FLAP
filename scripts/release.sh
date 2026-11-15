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
#   3. Updates VERSION file, and the version of fpm.toml when the project has one
#   4. Runs the project's scripts/release_hook.sh when it has one (see below)
#   5. Commits CHANGELOG.md + VERSION (+ fpm.toml, + the hook's files) with a conventional "chore(release)" message
#   6. Creates an annotated git tag
#   7. Pushes commit + tag  →  triggers the release.yml workflow on GitHub
#
# Project hook (optional, the project's own: the scaffold never writes it): an executable scripts/release_hook.sh for
# the files a release must also update (a version in the README, a CMake project(VERSION), a roadmap section).
#   scripts/release_hook.sh --check vX.Y.Z   in the pre-flight: non-zero stops the release before anything changes
#   scripts/release_hook.sh vX.Y.Z           after VERSION: updates its files and prints their paths, one per line,
#                                            relative to the repository root; they are committed with the release
# Both run from the repository root; their standard error is shown, a non-zero exit stops the release.
#
# CMake: a version written into project() of CMakeLists.txt (project(Name VERSION X.Y.Z ...)) is not updated by this
# script and would go stale: the release refuses it, before any change. Read it from VERSION instead:
#   file(STRINGS "${CMAKE_CURRENT_LIST_DIR}/VERSION" name_version LIMIT_COUNT 1)
#   string(REGEX REPLACE "^v" "" name_version "${name_version}")
#   project(Name VERSION ${name_version} LANGUAGES Fortran)
# or keep the literal with the project hook: it must then equal the new version once the hook has run.
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
# after the confirmation something may already be changed: show how to recover (exit bypasses the ERR trap)
die()     { echo -e "${RED}[error]${RESET} $*" >&2; [[ "${STAGE:-preflight}" =~ ^(preflight|confirm)$ ]] || on_error; exit 1; }

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
# STAGE names the last step COMPLETED: a failure while committing is still "bumped" (no commit was
# made), while tagging still "committed", while pushing "tagged"; the recovery hint relies on it.
STAGE="preflight"
NEW_TAG=""
RELEASE_FILES=(CHANGELOG.md VERSION) # files modified and committed by the release
RELEASE_HOOK="scripts/release_hook.sh" # the project's hook (see the header)
HAS_HOOK=false

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
      echo "  Files were modified locally (maybe staged) but not committed."
      echo "  To discard and start over:"
      echo "    git checkout HEAD -- ${RELEASE_FILES[*]}"
      if $HAS_HOOK; then
        echo "  ${RELEASE_HOOK} may have changed other files before it failed: see git status"
      fi
      ;;
    committed)
      echo "  Commit was made but not tagged/pushed. To resume:"
      echo "    git tag -a ${NEW_TAG} -m \"Release ${NEW_TAG}\""
      echo "    git push origin ${TRUNK} ${NEW_TAG}"
      ;;
    tagged)
      echo "  Tag ${NEW_TAG} was created locally but not pushed. To resume:"
      echo "    git push origin ${TRUNK} ${NEW_TAG}"
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

# ── Detect trunk branch ───────────────────────────────────────────────────────
# 1. local symref refs/remotes/origin/HEAD (set automatically by `git clone`)
# 2. ask the remote directly (works when the local symref is missing)
# 3. fallback: master if it exists locally, else main
TRUNK="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || true)"
if [[ -z "$TRUNK" ]]; then
  TRUNK="$(git remote show origin 2>/dev/null | sed -n 's/.*HEAD branch: //p' || true)"
fi
if [[ -z "$TRUNK" || "$TRUNK" == "(unknown)" ]]; then
  if git show-ref --verify --quiet refs/heads/master; then
    TRUNK="master"
  else
    TRUNK="main"
  fi
fi

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

FETCH_ERR="$(git fetch --tags 2>&1)" || die "git fetch --tags failed:\n${FETCH_ERR}\n\nIf a local tag diverges from the remote, inspect with:\n  git ls-remote --tags origin <tagname>\n  git show <tagname>\nThen either delete the local tag (git tag -d <tagname>) or force-update (git fetch --tags --force) once you've confirmed the remote is authoritative."
[[ -z "$(git tag -l "${NEW_TAG}")" ]] || die "tag ${NEW_TAG} already exists"

BEHIND="$(git rev-list --count HEAD..origin/${TRUNK} 2>/dev/null || echo 0)"
[[ "$BEHIND" -eq 0 ]] \
  || die "${TRUNK} is ${BEHIND} commit(s) behind origin/${TRUNK} — run: git pull origin ${TRUNK}"

# ── Project hook: --check ─────────────────────────────────────────────────────
if [[ -e "$RELEASE_HOOK" ]]; then
  if [[ -x "$RELEASE_HOOK" ]]; then
    HAS_HOOK=true
    "./${RELEASE_HOOK}" --check "$NEW_TAG" \
      || die "${RELEASE_HOOK} --check ${NEW_TAG} failed (see above): nothing was changed"
  else
    warn "${RELEASE_HOOK} is not executable: not run (chmod +x ${RELEASE_HOOK} to use it)"
  fi
fi

# ── CMake project version ─────────────────────────────────────────────────────
# a version written into project() goes stale (see the header): refused, unless the project hook keeps it
CMAKE_VERSION_RE='^[[:space:]]*project\([^)]*VERSION[[:space:]]+[0-9]+(\.[0-9]+)*'
cmake_literal_version() { # the version written into project() of CMakeLists.txt, empty if none
  [[ -f CMakeLists.txt ]] || return 0
  grep -Eo "$CMAKE_VERSION_RE" CMakeLists.txt | head -n 1 | grep -Eo '[0-9]+(\.[0-9]+)*$' || true
}
CMAKE_LITERAL="$(cmake_literal_version)"
if [[ -n "$CMAKE_LITERAL" ]] && ! $HAS_HOOK; then
  die "CMakeLists.txt declares project(... VERSION ${CMAKE_LITERAL}), which this script does not update: read it from
  VERSION (see the header of this script), or keep it with ${RELEASE_HOOK}; nothing was changed"
fi

# ── fpm manifest ──────────────────────────────────────────────────────────────
# fpm.toml carries its own copy of the version (X.Y.Z, without the v prefix that
# fpm does not accept): it is kept aligned when the manifest declares one.
FPM_VERSION_RE='^version[[:space:]]*='
HAS_FPM_VERSION=false
if [[ -f fpm.toml ]] && grep -Eq "$FPM_VERSION_RE" fpm.toml; then
  HAS_FPM_VERSION=true
  RELEASE_FILES+=(fpm.toml)
fi

# ── Confirm ───────────────────────────────────────────────────────────────────
STAGE="confirm"
echo ""
echo -e "  Current version : ${BOLD}${CURRENT_TAG}${RESET}"
echo -e "  New version     : ${BOLD}${NEW_TAG}${RESET}"
echo ""
echo -e "${BOLD}This will:${RESET}"
echo -e "  1. Regenerate ${CYAN}CHANGELOG.md${RESET} up to ${BOLD}${NEW_TAG}${RESET}"
echo -e "  2. Update ${CYAN}VERSION${RESET} to ${BOLD}${NEW_TAG}${RESET}"
$HAS_FPM_VERSION && echo -e "     and the version of ${CYAN}fpm.toml${RESET} to ${BOLD}${NEW_TAG#v}${RESET}"
$HAS_HOOK && echo -e "     then run ${CYAN}${RELEASE_HOOK} ${NEW_TAG}${RESET}, committing the files it changes"
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

# ── Update fpm.toml ───────────────────────────────────────────────────────────
if $HAS_FPM_VERSION; then
  info "Updating fpm.toml…"
  # only the first match: the version of the package, not the one of a dependency
  awk -v version="${NEW_TAG#v}" -v re="$FPM_VERSION_RE" \
    '!done && $0 ~ re { print "version = \"" version "\""; done = 1; next } { print }' \
    fpm.toml > fpm.toml.tmp
  mv fpm.toml.tmp fpm.toml
  grep -q "^version = \"${NEW_TAG#v}\"$" fpm.toml || die "fpm.toml update failed — version mismatch"
  success "fpm.toml updated to ${NEW_TAG#v}"
fi

# ── Project hook ──────────────────────────────────────────────────────────────
if $HAS_HOOK; then
  info "Running ${RELEASE_HOOK} ${NEW_TAG}…"
  HOOK_OUT="$("./${RELEASE_HOOK}" "$NEW_TAG")" || die "${RELEASE_HOOK} ${NEW_TAG} failed (see above)"
  HOOK_COUNT=0
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    # a path of this repository, so that a stray line of output cannot add anything else to the release commit
    [[ "$f" != /* && "$f" != ../* && "$f" != */../* && -f "$f" ]] \
      || die "${RELEASE_HOOK} printed '${f}', which is not a file of the repository (relative to its root)"
    RELEASE_FILES+=("$f")
    HOOK_COUNT=$((HOOK_COUNT + 1))
  done <<< "$HOOK_OUT"
  success "${RELEASE_HOOK}: ${HOOK_COUNT} file(s) to commit"
fi
if [[ -n "$CMAKE_LITERAL" ]]; then # kept by the hook: it must now be the new version
  [[ "$(cmake_literal_version)" == "${NEW_TAG#v}" ]] \
    || die "CMakeLists.txt still declares project(... VERSION $(cmake_literal_version)) after ${RELEASE_HOOK}:" \
           "${NEW_TAG#v} expected"
fi

# ── Commit ────────────────────────────────────────────────────────────────────
info "Committing changelog and version…"
git add "${RELEASE_FILES[@]}"
git commit -m "chore(release): ${NEW_TAG}"
STAGE="committed"
success "Committed"

# ── Tag ───────────────────────────────────────────────────────────────────────
info "Creating annotated tag ${NEW_TAG}…"
git tag -a "$NEW_TAG" -m "Release ${NEW_TAG}"
STAGE="tagged"
success "Tagged"

# ── Push ──────────────────────────────────────────────────────────────────────
info "Pushing ${TRUNK} + tag to origin…"
# push the new tag only: --follow-tags would also publish any other local annotated tag reachable from the trunk
git push origin "${TRUNK}" "${NEW_TAG}"
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

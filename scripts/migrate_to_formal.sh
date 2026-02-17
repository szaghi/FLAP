#!/usr/bin/env bash
# migrate_to_formal.sh
#
# Migrate a Fortran project's documentation from FORD to formal + VitePress.
#
# Usage:
#   scripts/migrate_to_formal.sh [OPTIONS]
#
# Run from the project root, or pass --project-root.
#
# Options:
#   -n, --name NAME          Project name (default: current directory name)
#   -a, --author AUTHOR      Author name (default: git config user.name)
#   -f, --ford-file PATH     Existing FORD project file to reuse
#                            (default: auto-detect)
#   -d, --docs-dir DIR       VitePress site output directory (default: docs)
#   -r, --project-root DIR   Project root directory (default: .)
#       --no-math            Disable LaTeX math support in VitePress
#       --update-fobos       Patch the [rule-makedoc] section in fobos
#       --update-ci          Patch the Make doc step in .github/workflows/ci.yml
#       --dry-run            Print what would be done without executing
#   -h, --help               Show this help message
#
# Requirements:
#   - formal  (pip install formal-ford2vitepress)
#   - node    (>= 18)
#   - npm
#   - git     (for author auto-detection)
#
# Examples:
#   # Minimal — auto-detects everything
#   scripts/migrate_to_formal.sh
#
#   # Explicit options
#   scripts/migrate_to_formal.sh --name MyLib --author "Jane Doe" \
#     --ford-file docs/ford.md --update-fobos --update-ci
#
#   # Dry run to preview actions
#   scripts/migrate_to_formal.sh --dry-run

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
error()   { echo -e "${RED}[error]${RESET} $*" >&2; }
step()    { echo -e "\n${BOLD}$*${RESET}"; }

# ── Defaults ─────────────────────────────────────────────────────────────────
PROJECT_ROOT="."
PROJECT_NAME=""
AUTHOR=""
FORD_FILE=""
DOCS_DIR="docs"
MATH_FLAG=""
UPDATE_FOBOS=false
UPDATE_CI=false
DRY_RUN=false

# ── Argument parsing ─────────────────────────────────────────────────────────
usage() {
  sed -n '/^# Usage:/,/^[^#]/{ s/^# \{0,1\}//; /^[^#]/d; p }' "$0"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--name)         PROJECT_NAME="$2";  shift 2 ;;
    -a|--author)       AUTHOR="$2";        shift 2 ;;
    -f|--ford-file)    FORD_FILE="$2";     shift 2 ;;
    -d|--docs-dir)     DOCS_DIR="$2";      shift 2 ;;
    -r|--project-root) PROJECT_ROOT="$2";  shift 2 ;;
    --no-math)         MATH_FLAG="--no-math"; shift ;;
    --update-fobos)    UPDATE_FOBOS=true;  shift ;;
    --update-ci)       UPDATE_CI=true;     shift ;;
    --dry-run)         DRY_RUN=true;       shift ;;
    -h|--help)         usage ;;
    *) error "Unknown option: $1"; exit 1 ;;
  esac
done

# ── Helpers ───────────────────────────────────────────────────────────────────
run() {
  if $DRY_RUN; then
    echo -e "  ${YELLOW}(dry-run)${RESET} $*"
  else
    eval "$@"
  fi
}

require() {
  if ! command -v "$1" &>/dev/null; then
    error "Required tool not found: $1"
    error "  Install with: $2"
    exit 1
  fi
}

# ── Resolve project root ──────────────────────────────────────────────────────
PROJECT_ROOT="$(realpath "$PROJECT_ROOT")"
cd "$PROJECT_ROOT"

# ── Check requirements ────────────────────────────────────────────────────────
step "Checking requirements…"
require formal  "pip install formal-ford2vitepress"
require node    "https://nodejs.org"
require npm     "https://nodejs.org"
success "formal $(formal --version 2>/dev/null | head -1)"
success "node $(node --version)"

# ── Auto-detect project name ──────────────────────────────────────────────────
if [[ -z "$PROJECT_NAME" ]]; then
  PROJECT_NAME="$(basename "$PROJECT_ROOT")"
  info "Project name auto-detected: $PROJECT_NAME"
fi

# ── Auto-detect author ────────────────────────────────────────────────────────
if [[ -z "$AUTHOR" ]]; then
  AUTHOR="$(git config user.name 2>/dev/null || echo "")"
  if [[ -z "$AUTHOR" ]]; then
    warn "Could not detect author from git config. Proceeding without --author."
  else
    info "Author auto-detected: $AUTHOR"
  fi
fi

# ── Auto-detect FORD project file ────────────────────────────────────────────
if [[ -z "$FORD_FILE" ]]; then
  for candidate in doc/formal.md doc/vitepress.md doc/main_page.md doc/ford.md; do
    if [[ -f "$candidate" ]]; then
      FORD_FILE="$candidate"
      info "FORD project file auto-detected: $FORD_FILE"
      break
    fi
  done
fi

FORD_FILE_EXISTS=false
if [[ -n "$FORD_FILE" && -f "$FORD_FILE" ]]; then
  FORD_FILE_EXISTS=true
fi

# ── Build formal init arguments ───────────────────────────────────────────────
INIT_ARGS=(. --name "$PROJECT_NAME" --docs-dir "$DOCS_DIR")
[[ -n "$AUTHOR" ]]    && INIT_ARGS+=(--author "$AUTHOR")
[[ -n "$FORD_FILE" ]] && INIT_ARGS+=(--ford-file "$FORD_FILE")
[[ -n "$MATH_FLAG" ]] && INIT_ARGS+=("$MATH_FLAG")

# ── Step 1: formal init ───────────────────────────────────────────────────────
step "Step 1/4 — Scaffolding VitePress site with formal init…"

if $FORD_FILE_EXISTS; then
  # formal init will overwrite the existing ford file; preserve it first.
  FORD_BACKUP="$(mktemp)"
  cp "$FORD_FILE" "$FORD_BACKUP"
  info "Backed up $FORD_FILE → $FORD_BACKUP"
fi

# formal init exits non-zero due to a cosmetic bug in the "next steps" print,
# but the scaffold files are created successfully before the crash.
# Use printf '%q' to preserve quoting for values with spaces (e.g. author names).
run "formal init $(printf '%q ' "${INIT_ARGS[@]}") 2>&1 || true"

if $FORD_FILE_EXISTS; then
  run "cp '$FORD_BACKUP' '$FORD_FILE'"
  run "rm -f '$FORD_BACKUP'"
  info "Restored original $FORD_FILE"
fi

success "VitePress scaffold created in $DOCS_DIR/"

# ── Patch package.json: pin esbuild to avoid audit vulnerability ──────────────
# esbuild <=0.24.2 allows dev-server requests from any origin (GHSA-67mh-4wv8-2f99).
# npm audit fix --force would downgrade VitePress to 0.1.1 — the override is the
# correct fix until VitePress bumps its own esbuild dependency.
PKGJSON="${DOCS_DIR}/package.json"
if [[ -f "$PKGJSON" ]]; then
  if $DRY_RUN; then
    echo "  (dry-run) Would add esbuild override to $PKGJSON"
  else
    python3 - "$PKGJSON" <<'PYEOF'
import sys, json
path = sys.argv[1]
with open(path) as f:
    pkg = json.load(f)
if "overrides" not in pkg:
    pkg["overrides"] = {}
if "esbuild" not in pkg["overrides"]:
    pkg["overrides"]["esbuild"] = ">=0.25.0"
    with open(path, "w") as f:
        json.dump(pkg, f, indent=2)
        f.write("\n")
    print("  patched esbuild override in package.json")
else:
    print("  esbuild override already present — skipping")
PYEOF
  fi
fi

# ── Patch config.mts: set base for GitHub Pages deployment ───────────────────
# Without base: '/REPO_NAME/', all asset URLs are rooted at '/' which works
# locally but breaks on GitHub Pages where the site lives at /REPO_NAME/.
CONFIG="${DOCS_DIR}/.vitepress/config.mts"
if [[ -f "$CONFIG" ]]; then
  if $DRY_RUN; then
    echo "  (dry-run) Would add base: '/${PROJECT_NAME}/' to $CONFIG"
  else
    python3 - "$CONFIG" "$PROJECT_NAME" <<'PYEOF'
import sys, re
path, name = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()
if f"base: '/{name}/'" in content:
    print("  base already set — skipping")
else:
    content = content.replace(
        "export default defineConfig({",
        f"export default defineConfig({{\n  base: '/{name}/',",
        1
    )
    with open(path, "w") as f:
        f.write(content)
    print(f"  set base: '/{name}/' in config.mts")
PYEOF
  fi
fi

# ── Step 2: formal generate ───────────────────────────────────────────────────
step "Step 2/4 — Generating API documentation with formal generate…"

GEN_ARGS=(--output "$DOCS_DIR/api")
[[ -n "$FORD_FILE" ]] && GEN_ARGS+=(--project "$FORD_FILE")

run "formal generate ${GEN_ARGS[*]}"
success "API Markdown pages written to $DOCS_DIR/api/"

# ── Step 3: update .gitignore ─────────────────────────────────────────────────
step "Step 3/4 — Updating .gitignore…"

GITIGNORE=".gitignore"
VITEPRESS_ENTRIES=(
  "# VitePress"
  "${DOCS_DIR}/node_modules/"
  "${DOCS_DIR}/.vitepress/dist/"
  "${DOCS_DIR}/.vitepress/cache/"
)

if [[ -f "$GITIGNORE" ]]; then
  ALREADY_PRESENT=false
  grep -qF "${DOCS_DIR}/node_modules/" "$GITIGNORE" 2>/dev/null && ALREADY_PRESENT=true

  if $ALREADY_PRESENT; then
    info ".gitignore already contains VitePress entries — skipping."
  else
    if $DRY_RUN; then
      echo "  (dry-run) Would append VitePress entries to $GITIGNORE"
    else
      printf '\n' >> "$GITIGNORE"
      for entry in "${VITEPRESS_ENTRIES[@]}"; do
        echo "$entry" >> "$GITIGNORE"
      done
      success "Added VitePress entries to $GITIGNORE"
    fi
  fi
else
  if $DRY_RUN; then
    echo "  (dry-run) Would create $GITIGNORE with VitePress entries"
  else
    for entry in "${VITEPRESS_ENTRIES[@]}"; do
      echo "$entry" >> "$GITIGNORE"
    done
    success "Created $GITIGNORE with VitePress entries"
  fi
fi

# ── Step 4 (optional): patch fobos ───────────────────────────────────────────
if $UPDATE_FOBOS; then
  step "Step 4a — Patching fobos [rule-makedoc]…"

  FOBOS_FILE="fobos"
  if [[ ! -f "$FOBOS_FILE" ]]; then
    warn "fobos file not found — skipping."
  else
    FORD_ARG=""
    [[ -n "$FORD_FILE" ]] && FORD_ARG=" --project $FORD_FILE"

    NEW_RULE="[rule-makedoc]
help   = Build documentation with formal + VitePress
rule_1 = formal generate${FORD_ARG} --output ${DOCS_DIR}/api
rule_2 = cd ${DOCS_DIR} && npm ci && npm run docs:build"

    # Replace from [rule-makedoc] up to (but not including) the next [rule-…] block
    if $DRY_RUN; then
      echo "  (dry-run) Would replace [rule-makedoc] in $FOBOS_FILE"
    else
      # Use python for reliable multiline replacement (avoids awk/sed portability issues)
      python3 - "$FOBOS_FILE" "$NEW_RULE" <<'PYEOF'
import sys, re
fobos_path, new_rule = sys.argv[1], sys.argv[2]
with open(fobos_path) as f:
    content = f.read()
# Replace the [rule-makedoc] block (up to the next [rule-] or EOF)
pattern = r'\[rule-makedoc\].*?(?=\n\[rule-|\Z)'
if re.search(pattern, content, re.DOTALL):
    content = re.sub(pattern, new_rule, content, flags=re.DOTALL)
    with open(fobos_path, 'w') as f:
        f.write(content)
    print("  patched")
else:
    # Block not found — append it
    with open(fobos_path, 'a') as f:
        f.write('\n' + new_rule + '\n')
    print("  appended (rule-makedoc block not found, appended)")
PYEOF
      success "fobos [rule-makedoc] updated"
    fi
  fi
fi

# ── Step 4 (optional): patch GitHub Actions CI ───────────────────────────────
if $UPDATE_CI; then
  step "Step 4b — Patching GitHub Actions CI workflow…"

  CI_FILE=".github/workflows/ci.yml"
  if [[ ! -f "$CI_FILE" ]]; then
    warn "$CI_FILE not found — skipping."
  else
    FORD_ARG=""
    [[ -n "$FORD_FILE" ]] && FORD_ARG=" --project $FORD_FILE"

    if $DRY_RUN; then
      echo "  (dry-run) Would patch $CI_FILE"
    else
      python3 - "$CI_FILE" "$DOCS_DIR" "$FORD_ARG" <<'PYEOF'
import sys, re, textwrap

ci_path, docs_dir, ford_arg = sys.argv[1], sys.argv[2], sys.argv[3]
with open(ci_path) as f:
    content = f.read()

changes = []

# 1. Inject Node.js setup before the pip install step (if not already present)
if 'setup-node' not in content:
    node_step = textwrap.dedent("""\
        - name: Setup Node.js
          uses: actions/setup-node@v4
          with:
            node-version: '20'

        """)
    # Insert just before the pip install step
    content, n = re.subn(
        r'(- name: Install [^\n]*\n\s+run: \|\n\s+pip)',
        node_step + r'\1',
        content, count=1
    )
    if n:
        changes.append("added Setup Node.js step")

# 2. Add formal-ford2vitepress to pip installs (if not already present)
if 'formal-ford2vitepress' not in content:
    content, n = re.subn(
        r'(pip install[^\n]*FoBiS[^\n]*\n)',
        r'\1        pip install --upgrade formal-ford2vitepress\n',
        content, count=1
    )
    if n:
        changes.append("added formal-ford2vitepress to pip installs")

# 3. Replace the Make doc step body
new_make_doc = (
    f"        formal generate{ford_arg} --output {docs_dir}/api\n"
    f"        cd {docs_dir} && npm ci && npm run docs:build"
)
content, n = re.subn(
    r'(- name: Make doc\s+\n\s+run: \|)\n.*?(?=\n\s+-|\Z)',
    lambda m: m.group(1) + '\n' + new_make_doc,
    content, flags=re.DOTALL, count=1
)
if n:
    changes.append("updated 'Make doc' step")

# 4. Update the gh-pages deploy folder
old_dist = r'(folder:\s*)doc/html'
new_dist = rf'\g<1>{docs_dir}/.vitepress/dist'
content, n = re.subn(old_dist, new_dist, content, count=1)
if n:
    changes.append("updated gh-pages deploy folder")

with open(ci_path, 'w') as f:
    f.write(content)

for c in changes:
    print(f"  {c}")
PYEOF
      success "$CI_FILE patched"
    fi
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}${BOLD} Migration complete!${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  Generated files:"
echo -e "    ${CYAN}${DOCS_DIR}/.vitepress/config.mts${RESET}  — VitePress config"
echo -e "    ${CYAN}${DOCS_DIR}/index.md${RESET}               — landing page"
echo -e "    ${CYAN}${DOCS_DIR}/api/*.md${RESET}               — one page per Fortran module"
echo -e "    ${CYAN}${DOCS_DIR}/package.json${RESET}           — npm scripts + deps"
echo ""
echo -e "  Next steps:"
echo -e "    ${BOLD}1. Install npm dependencies:${RESET}"
echo -e "       cd ${DOCS_DIR} && npm install"
echo ""
echo -e "    ${BOLD}2. Preview locally:${RESET}"
echo -e "       cd ${DOCS_DIR} && npm run docs:dev"
echo -e "       → http://localhost:5173/"
echo ""
echo -e "    ${BOLD}3. Rebuild API docs after source changes:${RESET}"
if [[ -n "$FORD_FILE" ]]; then
  echo -e "       formal generate --project ${FORD_FILE} --output ${DOCS_DIR}/api"
else
  echo -e "       formal generate --output ${DOCS_DIR}/api"
fi
echo ""
echo -e "    ${BOLD}4. Production build:${RESET}"
echo -e "       cd ${DOCS_DIR} && npm run docs:build"
echo ""

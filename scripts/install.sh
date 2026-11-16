#!/usr/bin/env bash
# install.sh: download a release of FLAP and install it, with the build system of your choice.
#
#   curl -fsSL https://github.com/szaghi/FLAP/releases/latest/download/install.sh | bash -s -- [options]
#
# Usage: install.sh [--build fobis|fpm|cmake|make] [--fc FC | --gnu | --intel | --nvidia] [--prefix DIR]
#                   [--tag TAG] [--source DIR] [--deps] [--dry-run] [--uninstall] [--keep] [--verbose]
#                   [--version] [-h | --help]
#
#   --build B     the build system, among those the release ships (fobis, fpm, cmake, make): with one, it is used;
#                 with several and no --build, a menu on the terminal, else the first of fobis, fpm, cmake, make
#   --fc FC       the Fortran compiler, by name or path (default: $FC, else gfortran); --gnu, --intel and --nvidia
#                 are gfortran, ifx and nvfortran
#   --prefix DIR  where to install (default: ~/.local); per compiler: lib/<name>/<compiler-version>/ and
#                 include/<name>/<compiler-version>/, with lib/pkgconfig/<name>-<compiler-version>.pc and <name>.pc
#   --tag TAG     the release (default: the latest)
#   --source DIR  build a local tree instead of downloading a release
#   --deps        install the system packages the project needs (shown first; sudo on Linux)
#   --dry-run     download, detect and check, print what would be done, build nothing
#   --uninstall   remove what this script installed in --prefix (one compiler's install with --fc/--gnu/...; all
#                 otherwise)
#   --keep        keep the build directory (it is kept anyway when a stage fails)
#   --verbose     show the build output (otherwise it goes to a log, shown when a stage fails)
#   --version     print the installer's interface version
#
# Only the chosen build system is needed besides the compiler: FoBiS, when needed and missing, is installed in a
# private virtual environment under the prefix (python3 >= 3.11). The release tarball carries the project's
# dependencies, so CMake and make builds need neither FoBiS nor a network. No GitHub API call: the latest release is
# found by its redirect. Rendered by `fobis scaffold` from the project's fobos ([project], [installer]): do not edit,
# change the fobos and run `fobis scaffold sync`. Bash 3.2 compatible (macOS).
#
# Exit status: 0 done, 1 a stage failed (its name and the end of its log are shown), 2 a usage error.

set -euo pipefail

INSTALLER_VERSION=2

# ---- the project (fobis scaffold renders these from the fobos) ----------------------------------------------------
REPO='szaghi/FLAP'         # owner/name on GitHub
NAME='FLAP'               # the release tarball is NAME-TAG.tar.gz
MODE_GNU='static-gnu'       # the fobos mode of each compiler family (fobis builds)
MODE_INTEL='static-intel'
MODE_NVIDIA='static-nvf'
PRE_RULE=''            # a fobos rule run before the build, any build system
CHECK_RULE=''        # a fobos rule run after the install
APT_PACKAGES=''        # system packages for --deps
BREW_PACKAGES=''
PKGCONFIG='true'     # true: write <name>.pc
MAKE_LIB='static'       # make builds without an install target: where the libraries and modules are
MAKE_MOD='static/mod'
HEADERS=''         # files (globs) the project's users include: installed next to the modules

# ---- messages -------------------------------------------------------------------------------------------------------
if [ -t 2 ]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; CYAN=$'\033[0;36m'; RESET=$'\033[0m'
else
  RED=''; GREEN=''; CYAN=''; RESET=''
fi
say()  { printf '%s\n' "${CYAN}[install]${RESET} $*" >&2; }
ok()   { printf '%s\n' "${GREEN}[ok]${RESET}      $*" >&2; }
usage_error() { printf '%s\n' "${RED}[error]${RESET}   $*" >&2; exit 2; }
die()  {
  printf '%s\n' "${RED}[error]${RESET}   $*" >&2
  if [ -n "${LOG:-}" ] && [ -s "${LOG}" ]; then
    printf '%s\n' "--- the end of ${LOG} ---" >&2; tail -n 40 "$LOG" >&2
    KEEP=1
  fi
  exit 1
}
usage() {
  cat <<USAGE
install.sh $INSTALLER_VERSION: download a release of $NAME and install it, with the build system of your choice.

  curl -fsSL https://github.com/$REPO/releases/latest/download/install.sh | bash -s -- [options]

  --build B     fobis, fpm, cmake or make, among those the release ships (default: the only one; else a menu on the
                terminal; else the first of fobis, fpm, cmake, make)
  --fc FC       the Fortran compiler (default: \$FC, else gfortran); --gnu, --intel, --nvidia: gfortran, ifx, nvfortran
  --prefix DIR  where to install (default: ~/.local), per compiler: lib/<name>/<compiler-version>/, include/...
  --tag TAG     the release (default: the latest)
  --source DIR  build a local tree instead of downloading a release
  --deps        install the system packages the project needs (shown first)
  --dry-run     detect and check, print what would be done, build nothing
  --uninstall   remove what this script installed (one compiler's with --fc/--gnu/...; all otherwise)
  --keep        keep the build directory        --verbose  show the build output
  --version     the installer's interface version
USAGE
}

# ---- arguments ------------------------------------------------------------------------------------------------------
BUILD=''; FC_ARG=''; PREFIX="${HOME}/.local"; TAG='latest'; SOURCE=''; DEPS=0; DRY_RUN=0; UNINSTALL=0; KEEP=0
VERBOSE=0
while [ $# -gt 0 ]; do
  case $1 in
    --build)     [ $# -ge 2 ] || usage_error "--build needs fobis, fpm, cmake or make"; BUILD=$2; shift 2 ;;
    --fc)        [ $# -ge 2 ] || usage_error "--fc needs a compiler"; FC_ARG=$2; shift 2 ;;
    --gnu)       FC_ARG=gfortran; shift ;;
    --intel)     FC_ARG=ifx; shift ;;
    --nvidia)    FC_ARG=nvfortran; shift ;;
    --prefix)    [ $# -ge 2 ] || usage_error "--prefix needs a directory"; PREFIX=$2; shift 2 ;;
    --tag)       [ $# -ge 2 ] || usage_error "--tag needs a tag"; TAG=$2; shift 2 ;;
    --source)    [ $# -ge 2 ] || usage_error "--source needs a directory"; SOURCE=$2; shift 2 ;;
    --deps)      DEPS=1; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --keep)      KEEP=1; shift ;;
    --verbose)   VERBOSE=1; shift ;;
    --version)   echo "install.sh $INSTALLER_VERSION"; exit 0 ;;
    -h|--help)   usage; exit 0 ;;
    *)           usage_error "unknown option $1 (see --help)" ;;
  esac
done
case $BUILD in ''|fobis|fpm|cmake|make) ;; *) usage_error "--build $BUILD: fobis, fpm, cmake or make" ;; esac
case $PREFIX in /*) ;; *) PREFIX="$(pwd)/$PREFIX" ;; esac
LOWER_NAME=$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]')

# ---- the compiler: family and version tag ---------------------------------------------------------------------------
FC_USED=${FC_ARG:-${FC:-gfortran}}
compiler_tag() { # family-version of $FC_USED, e.g. gnu-16.2.0
  local base family version
  base=$(basename "$FC_USED")
  case $base in
    nvfortran*|pgfortran*)  family=nvidia ;;   # before *gfortran*: pgfortran contains it
    *gfortran*)             family=gnu ;;
    ifx*|ifort*)            family=intel ;;
    *)                      family=${base%%[-.0-9]*} ;;
  esac
  if [ "$family" = gnu ]; then
    version=$("$FC_USED" -dumpfullversion 2>/dev/null || "$FC_USED" -dumpversion 2>/dev/null || true)
  else
    version=$("$FC_USED" --version 2>/dev/null | grep -Eo '[0-9]+(\.[0-9]+)+' | sed -n 1p || true)
  fi
  [ -n "$version" ] || version=unknown
  printf '%s %s\n' "$family" "$version"
}

# ---- uninstall ------------------------------------------------------------------------------------------------------
if [ "$UNINSTALL" = 1 ]; then
  share="$PREFIX/share/$LOWER_NAME"
  manifests=()
  if [ -n "$FC_ARG" ]; then
    command -v "$FC_USED" > /dev/null || usage_error "$FC_USED not found (needed to name the install to remove)"
    read -r family version <<< "$(compiler_tag)"; tag_dir="$share/$family-$version"
    [ -f "$tag_dir/manifest" ] && manifests+=("$tag_dir/manifest")
  else
    for m in "$share"/*/manifest; do [ -f "$m" ] && manifests+=("$m"); done
  fi
  [ ${#manifests[@]} -gt 0 ] || { say "nothing of $NAME installed in $PREFIX"; exit 0; }
  for m in "${manifests[@]}"; do
    say "removing the files listed in $m"
    dirs=$(grep / "$m" | sed 's|/[^/]*$||' | sort -ru)
    while IFS= read -r f; do
      case $f in ''|/*|*..*) continue ;; esac       # the manifest lists paths relative to the prefix, nothing else
      if [ "$DRY_RUN" = 1 ]; then echo "rm $PREFIX/$f"; else rm -f -- "$PREFIX/$f"; fi
    done < "$m"
    [ "$DRY_RUN" = 1 ] && continue
    for d in $dirs; do                              # the directories left empty, and their parents while empty
      while [ -n "$d" ] && [ "$d" != . ] && rmdir -- "$PREFIX/$d" 2> /dev/null; do d=$(dirname "$d"); done
    done
  done
  ok "$NAME removed from $PREFIX"
  exit 0
fi

# ---- the working directory and the log ------------------------------------------------------------------------------
WORK=$(mktemp -d "${TMPDIR:-/tmp}/install-$LOWER_NAME.XXXXXX")
LOG="$WORK/install.log"
: > "$LOG"
cleanup() { if [ "$KEEP" = 1 ]; then say "build directory kept: $WORK"; else rm -rf -- "$WORK"; fi; }
trap cleanup EXIT
run() { # run a command of the current stage, its output in the log (or on the terminal with --verbose)
  printf '+ %s\n' "$*" >> "$LOG"
  if [ "$VERBOSE" = 1 ]; then "$@" 2>&1 | tee -a "$LOG"; return "${PIPESTATUS[0]}"; fi
  "$@" >> "$LOG" 2>&1
}

# ---- stage 1: the sources -------------------------------------------------------------------------------------------
if [ -n "$SOURCE" ]; then
  [ -d "$SOURCE" ] || usage_error "--source $SOURCE: not a directory"
  say "sources: $SOURCE"
  mkdir -p "$WORK/src"
  (cd "$SOURCE" && tar --exclude=./.git -cf - .) | (cd "$WORK/src" && tar -xf -) || die "copying $SOURCE failed"
  SRC="$WORK/src"
  [ "$TAG" = latest ] && TAG=local
else
  command -v curl > /dev/null || usage_error "curl not found (needed to download the release)"
  if [ "$TAG" = latest ]; then
    url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest") \
      || die "cannot reach https://github.com/$REPO/releases/latest"
    TAG=${url##*/}
    case $url in */releases/tag/*) ;; *) die "$REPO has no release yet ($url)" ;; esac
  fi
  tarball="$NAME-$TAG.tar.gz"
  say "downloading $REPO $TAG ($tarball)"
  run curl -fsSL -o "$WORK/$tarball" "https://github.com/$REPO/releases/download/$TAG/$tarball" \
    || die "the release $TAG of $REPO has no $tarball"
  run tar -xzf "$WORK/$tarball" -C "$WORK" || die "unpacking $tarball failed"
  SRC="$WORK/$NAME-$TAG"
  [ -d "$SRC" ] || die "$tarball does not unpack into $NAME-$TAG/"
fi
cd "$SRC"

# ---- stage 2: the build system --------------------------------------------------------------------------------------
available=()
[ -f fobos ] && available+=(fobis)
[ -f fpm.toml ] && available+=(fpm)
[ -f CMakeLists.txt ] && available+=(cmake)
{ [ -f makefile ] || [ -f Makefile ] || [ -f GNUmakefile ]; } && available+=(make)
[ ${#available[@]} -gt 0 ] || die "the sources ship no build system (fobos, fpm.toml, CMakeLists.txt, makefile)"
if [ -n "$BUILD" ]; then
  found=0; for b in "${available[@]}"; do [ "$b" = "$BUILD" ] && found=1; done
  [ "$found" = 1 ] || usage_error "--build $BUILD: $NAME ships ${available[*]} only"
elif [ ${#available[@]} -eq 1 ]; then
  BUILD=${available[0]}
elif (: < /dev/tty) 2> /dev/null && exec 3< /dev/tty; then
  { echo "$NAME can be built with:"; i=1; for b in "${available[@]}"; do echo "  $i) $b"; i=$((i + 1)); done
    printf 'Choose [1-%d, default 1]: ' "${#available[@]}"; } > /dev/tty
  read -r answer <&3 || answer=''
  exec 3<&-
  case $answer in ''|*[!0-9]*) answer=1 ;; esac
  [ "$answer" -ge 1 ] && [ "$answer" -le ${#available[@]} ] || answer=1
  BUILD=${available[$((answer - 1))]}
else
  BUILD=${available[0]} # the order: fobis, fpm, cmake, make
fi
say "build system: $BUILD (available: ${available[*]})"

# ---- stage 3: the toolchain -----------------------------------------------------------------------------------------
command -v "$FC_USED" > /dev/null || usage_error "the Fortran compiler $FC_USED was not found (--fc, --gnu, ...)"
read -r FAMILY FC_VERSION <<< "$(compiler_tag)"; FC_TAG="$FAMILY-$FC_VERSION"
LIBDIR="lib/$LOWER_NAME/$FC_TAG"; INCDIR="include/$LOWER_NAME/$FC_TAG"
say "compiler: $FC_USED ($FC_TAG); prefix: $PREFIX"
need_fobis=0
{ [ "$BUILD" = fobis ] || [ -n "$PRE_RULE" ] || [ -n "$CHECK_RULE" ]; } && need_fobis=1
case $BUILD in
  fpm)   command -v fpm > /dev/null || usage_error "fpm not found (https://fpm.fortran-lang.org), or choose --build among ${available[*]}" ;;
  cmake) command -v cmake > /dev/null || usage_error "cmake not found, or choose --build among ${available[*]}" ;;
  make)  command -v make > /dev/null || usage_error "make not found, or choose --build among ${available[*]}" ;;
esac
if [ "$need_fobis" = 1 ] && ! command -v fobis > /dev/null; then
  venv="$PREFIX/share/$LOWER_NAME/venv"
  if [ -x "$venv/bin/fobis" ]; then
    PATH="$venv/bin:$PATH"
  elif [ "$DRY_RUN" = 0 ]; then
    command -v python3 > /dev/null || usage_error "FoBiS is needed and python3 (>= 3.11) was not found to install it"
    python3 -c 'import sys; sys.exit(sys.version_info < (3, 11))' \
      || usage_error "FoBiS needs python3 >= 3.11 ($(python3 --version 2>&1))"
    say "installing FoBiS in $venv"
    run python3 -m venv "$venv" || die "creating the virtual environment $venv failed"
    run "$venv/bin/pip" install --quiet FoBiS.py || die "installing FoBiS failed"
    PATH="$venv/bin:$PATH"
  fi
fi
MODE=''
if [ "$BUILD" = fobis ]; then
  case $FAMILY in
    gnu)    MODE=$MODE_GNU ;;
    intel)  MODE=$MODE_INTEL ;;
    nvidia) MODE=$MODE_NVIDIA ;;
    *)      usage_error "no fobos mode for the compiler family $FAMILY: choose another --build or compiler" ;;
  esac
fi

# ---- stage 4: system packages ---------------------------------------------------------------------------------------
if [ "$DEPS" = 1 ]; then
  if [ "$(uname -s)" = Darwin ] && [ -n "$BREW_PACKAGES" ]; then
    say "system packages: brew install $BREW_PACKAGES"
    [ "$DRY_RUN" = 1 ] || brew install $BREW_PACKAGES || die "brew install failed"
  elif command -v apt-get > /dev/null && [ -n "$APT_PACKAGES" ]; then
    sudo=''; [ "$(id -u)" = 0 ] || sudo=sudo
    say "system packages: $sudo apt-get install -y $APT_PACKAGES"
    if [ "$DRY_RUN" = 0 ]; then
      if ! { $sudo apt-get update -q > /dev/null && $sudo apt-get install -y -q $APT_PACKAGES; }; then
        die "apt-get install failed"
      fi
    fi
  else
    say "no system package to install on this system"
  fi
fi

if [ "$DRY_RUN" = 1 ]; then
  say "dry run: would build $NAME $TAG with $BUILD${MODE:+ (mode $MODE)} and install it in $PREFIX/{$LIBDIR,$INCDIR}"
  exit 0
fi

# ---- stage 5: build and install -------------------------------------------------------------------------------------
snapshot() { (cd "$PREFIX" && find . \( -type f -o -type l \) -print | sed 's|^\./||' | sort); }
mkdir -p "$PREFIX"
snapshot > "$WORK/before"
export FC="$FC_USED"
if [ -n "$PRE_RULE" ]; then
  say "pre-build: fobis rule --ex $PRE_RULE"
  run fobis rule --ex "$PRE_RULE" || die "the pre-build rule $PRE_RULE failed"
fi
say "building and installing with $BUILD (log: $LOG)"
case $BUILD in
  fobis)
    fobis build --lmodes 2> /dev/null | grep -qw -- "$MODE" \
      || die "the fobos has no mode $MODE (set [installer] mode_$FAMILY to one of: fobis build --lmodes)"
    run fobis build --mode "$MODE" --fc "$FC_USED" --track-build || die "fobis build failed"
    run fobis install --mode "$MODE" --prefix "$PREFIX" --lib "$LIBDIR" --include "$INCDIR" || die "fobis install failed"
    ;;
  fpm)
    run fpm install --profile release --compiler "$FC_USED" --prefix "$PREFIX" --libdir "$LIBDIR" \
      --includedir "$INCDIR" || die "fpm install failed"
    ;;
  cmake)
    run cmake -S . -B "$WORK/cmake" -DCMAKE_BUILD_TYPE=Release -DCMAKE_Fortran_COMPILER="$FC_USED" \
      -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_INSTALL_LIBDIR="$LIBDIR" -DCMAKE_INSTALL_INCLUDEDIR="$INCDIR" \
      -DBUILD_TESTING=OFF || die "cmake configure failed"
    run cmake --build "$WORK/cmake" --parallel || die "cmake build failed"
    run cmake --install "$WORK/cmake" || die "cmake install failed"
    ;;
  make)
    if make -n install > /dev/null 2>&1; then
      run make FC="$FC_USED" || die "make failed"
      run make install FC="$FC_USED" PREFIX="$PREFIX" prefix="$PREFIX" || die "make install failed"
    elif [ -n "$MAKE_LIB" ]; then
      run make FC="$FC_USED" || die "make failed"
      mkdir -p "$PREFIX/$LIBDIR" "$PREFIX/$INCDIR"
      for f in "$MAKE_LIB"/lib*.a "$MAKE_LIB"/lib*.so*; do [ -e "$f" ] && cp -P "$f" "$PREFIX/$LIBDIR/"; done
      for f in "${MAKE_MOD:-$MAKE_LIB}"/*.mod "${MAKE_MOD:-$MAKE_LIB}"/*.smod; do
        [ -e "$f" ] && cp "$f" "$PREFIX/$INCDIR/"
      done
    else
      die "the makefile has no install target: declare [installer] make_lib (and make_mod) in the fobos"
    fi
    ;;
esac

# ---- stage 5b: the header files ---------------------------------------------------------------------------------------
# a build that does not install them itself (FoBiS, fpm and make install modules only) gets them in every directory it
# installed module files in, so the -I of the pkg-config file finds them
if [ -n "$HEADERS" ]; then
  snapshot > "$WORK/after"
  comm -13 "$WORK/before" "$WORK/after" > "$WORK/new"
  moddirs=$(grep -E '\.s?mod$' "$WORK/new" | sed -e '/\//!s|.*|.|' -e 's|/[^/]*$||' | sort -u)
  [ -n "$moddirs" ] || die "[installer] headers: the build installed no module file to put them next to"
  read -r -a patterns <<< "$HEADERS"   # split on blanks; the globs are expanded below, in the sources
  for pattern in "${patterns[@]}"; do
    matched=0
    for f in $pattern; do
      [ -f "$f" ] || continue
      matched=1
      awk -F/ -v b="${f##*/}" '$NF == b {found = 1} END {exit !found}' "$WORK/new" && continue   # the build installed it
      for d in $moddirs; do cp "$f" "$PREFIX/$d/" || die "installing $f failed"; done
    done
    [ "$matched" = 1 ] || die "[installer] headers: $pattern matches no file of the sources"
  done
fi

# ---- stage 6: pkg-config --------------------------------------------------------------------------------------------
snapshot > "$WORK/after"
if [ "$PKGCONFIG" = true ]; then
  pcdir="$PREFIX/lib/pkgconfig"
  pc="$pcdir/$LOWER_NAME-$FC_TAG.pc"
  comm -13 "$WORK/before" "$WORK/after" > "$WORK/new"
  if ! grep -qx "lib/pkgconfig/$LOWER_NAME.pc" "$WORK/new"; then
    # where the build put the libraries and the modules (fpm ignores --includedir for modules; CMake projects install
    # them in subdirectories of their own): every such directory, the project's library first
    libdirs=''; incdirs=''; libs=''; first=''
    grep -E '(^|/)lib[^/]*\.(a|so[.0-9]*|dylib)$' "$WORK/new" | grep -v "^share/" | sort -u > "$WORK/libs" || true
    grep -E '\.s?mod$' "$WORK/new" | sort -u > "$WORK/mods" || true
    while IFS= read -r f; do
      d=$(dirname "$f"); case " $libdirs " in *" $d "*) ;; *) libdirs="$libdirs $d" ;; esac
      l=$(basename "$f"); l=${l#lib}; l=${l%%.*}
      case " $first $libs " in *" -l$l "*) continue ;; esac
      if [ "$(printf '%s' "$l" | tr '[:upper:]' '[:lower:]')" = "$LOWER_NAME" ]; then first="-l$l"; else libs="$libs -l$l"; fi
    done < "$WORK/libs"
    while IFS= read -r f; do
      d=$(dirname "$f"); case " $incdirs " in *" $d "*) ;; *) incdirs="$incdirs $d" ;; esac
    done < "$WORK/mods"
    # static archives must come before the ones they need: order them by their symbols (nm), dependents first
    # (tsort; POSIX, on Linux and macOS); without nm or tsort, the project's library first, then the others
    names=$(echo "$first $libs" | sed 's/-l//g')
    if command -v nm > /dev/null && command -v tsort > /dev/null && [ "$(echo "$names" | wc -w)" -gt 1 ]; then
      : > "$WORK/pairs"
      while IFS= read -r f; do
        l=$(basename "$f"); l=${l#lib}; l=${l%%.*}
        nm -g "$PREFIX/$f" 2> /dev/null | awk '$1 == "U" {print $2 > "'"$WORK"'/und.tmp"} NF == 3 && $2 != "U" {print $3}' \
          | sort -u > "$WORK/def.$l" || true
        sort -u "$WORK/und.tmp" > "$WORK/und.$l" 2> /dev/null || : > "$WORK/und.$l"; rm -f "$WORK/und.tmp"
      done < "$WORK/libs"
      for a in $names; do
        echo "$a $a" >> "$WORK/pairs"
        for b in $names; do
          [ "$a" != "$b" ] && [ -n "$(comm -12 "$WORK/und.$a" "$WORK/def.$b" | sed -n 1p)" ] && echo "$a $b" >> "$WORK/pairs"
        done
      done
      sorted=$(tsort "$WORK/pairs" 2> /dev/null || true)
      if [ "$(echo "$sorted" | wc -w)" -eq "$(echo "$names" | wc -w)" ]; then
        first=''; libs=''; for l in $sorted; do libs="$libs -l$l"; done
      fi
    fi
    lflags=''; for d in $libdirs; do lflags="$lflags -L\${prefix}/$d"; done
    cflags=''; for d in $incdirs; do cflags="$cflags -I\${prefix}/$d"; done
    mkdir -p "$pcdir"
    {
      echo "prefix=$PREFIX"
      echo ""
      echo "Name: $LOWER_NAME"
      echo "Description: $NAME built by $FC_USED $FC_VERSION"
      echo "Version: ${TAG#v}"
      echo "Libs:$lflags${first:+ $first}$libs"
      echo "Cflags:$cflags"
    } > "$pc"
    cp "$pc" "$pcdir/$LOWER_NAME.pc"
  fi
fi

# ---- stage 7: the manifest, the check -------------------------------------------------------------------------------
share="$PREFIX/share/$LOWER_NAME/$FC_TAG"
mkdir -p "$share"
snapshot > "$WORK/after"
comm -13 "$WORK/before" "$WORK/after" | grep -v "^share/$LOWER_NAME/venv/" > "$share/manifest" || true
echo "share/$LOWER_NAME/$FC_TAG/manifest" >> "$share/manifest"
if [ -n "$CHECK_RULE" ]; then
  say "check: fobis rule --ex $CHECK_RULE"
  export PREFIX PKG_CONFIG_PATH="$PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
  run fobis rule --ex "$CHECK_RULE" || die "the check $CHECK_RULE failed"
fi

ok "$NAME $TAG installed in $PREFIX ($(grep -c . "$share/manifest") files; $LIBDIR, $INCDIR)"
if [ "$PKGCONFIG" = true ]; then
  echo "  use it: PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig pkg-config --cflags --libs $LOWER_NAME-$FC_TAG" >&2
fi
echo "  remove it: install.sh --uninstall --prefix $PREFIX --fc $FC_USED" >&2

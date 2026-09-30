#!/usr/bin/env bash
# Build and run the documentation examples, regenerating everything the pages include from them.
#
#   docs/examples/src/*.f90    the example programs (hand-written), with two kinds of marker comments:
#                                !run ID COMMAND        a run shown in the pages (!run -s: with its exit status)
#                                !region NAME ... !endregion NAME   a part of the program included on its own
#   docs/examples/files/       input files, copied into the directory where the runs happen
#   docs/examples/snippets/    generated: <program>.f90 without the markers, and <program>-<region>.f90
#   docs/examples/output/      generated: <ID>.ansi, "$ COMMAND" then its output (standard output and error, colours
#                              kept), the scratch run directory shown as /home/user and the current month (the date of
#                              the man page and of the Markdown) as <month> <year>
#
# The library is rebuilt from scratch by FoBiS (mode static-gnu) and the examples are built by the same compiler, gfortran
# or $FC: the outputs must not depend on the compiler (use explicit formats). A run happens in a scratch directory, with HOME pointing there and
# a minimal environment, so nothing outside it is read or written. The Compiler matrix workflow fails when the
# committed snippets or outputs differ from the regenerated ones.
#
# Usage: bash scripts/docs_examples.sh            (FC=gfortran-14 bash scripts/docs_examples.sh: another compiler)
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ex=$root/docs/examples
build=$root/build/docs-examples # git-ignored
run_dir=$build/run
home=/home/user                 # how the run directory is shown
month=$(LC_ALL=C date +'%b %Y') # the date of the generated man page and Markdown

fc=${FC:-gfortran}
mkdir -p "$root/build"
(cd "$root" && fobis clean --mode static-gnu && fobis build --mode static-gnu --fc "$fc") \
  > "$root/build/docs-examples.log" 2>&1 || {
  cat "$root/build/docs-examples.log"; echo "docs_examples: library build failed" >&2; exit 1; }
rm -rf -- "$build"
mkdir -p "$build/bin" "$run_dir" "$ex/snippets" "$ex/output"
rm -f -- "$ex"/snippets/*.f90 "$ex"/output/*.ansi

# snippets: the whole program and each region, without the markers, dedented
dedent() { awk '{l[NR]=$0; if ($0 ~ /[^ ]/) {match($0, /^ */); if (m == "" || RLENGTH < m) m = RLENGTH}}
                END {for (i = 1; i <= NR; i++) print substr(l[i], m + 1)}' "$1"; }
for src in "$ex"/src/*.f90; do
  name=$(basename "$src" .f90)
  grep -Ev '^ *!(run|region|endregion) ' "$src" > "$ex/snippets/$name.f90" || true
  for region in $(sed -n 's/^ *!region \([A-Za-z0-9_-]*\).*/\1/p' "$src"); do
    awk -v r="$region" '$1 == "!endregion" && $2 == r {on = 0}
                        on && $0 !~ /^ *!(run|region|endregion) / {print}
                        $1 == "!region" && $2 == r {on = 1}' "$src" > "$build/region.f90"
    dedent "$build/region.f90" > "$ex/snippets/$name-$region.f90"
  done
done

# programs
for src in "$ex"/src/*.f90; do
  "$fc" -I"$root/static/mod" -o "$build/bin/$(basename "$src" .f90)" "$src" "$root/static/libflap.a"
done

# runs, in the order of the files and of the lines
if [ -d "$ex/files" ]; then cp -R "$ex/files/." "$run_dir/"; fi
run() { # run [-s] ID COMMAND
  local show=0 status=0
  if [ "$1" = -s ]; then show=1; shift; fi
  local id=$1; shift
  local cmd="$*"
  {
    printf '$ %s\n' "$cmd"
    (cd "$run_dir" && env -i HOME="$run_dir" PATH="$build/bin:/usr/bin:/bin" SHELL=/bin/bash LC_ALL=C \
                     GFORTRAN_UNBUFFERED_PRECONNECTED=y bash -c "$cmd" 2>&1) || status=$?
    if [ $show = 1 ]; then printf '[exit status %d]\n' "$status"; fi
  } | sed -e "s|$run_dir|$home|g" -e "s|$month|<month> <year>|g" > "$ex/output/$id.ansi"
}
for src in "$ex"/src/*.f90; do
  while IFS= read -r line; do
    line=${line#*!run }
    if [ "${line%% *}" = -s ]; then line=${line#-s }; run -s "${line%% *}" "${line#* }"
    else run "${line%% *}" "${line#* }"; fi
  done < <(grep -E '^ *!run ' "$src" || true)
done
echo "docs_examples: $(ls "$ex"/src/*.f90 | wc -l) programs, $(ls "$ex"/output/*.ansi | wc -l) runs"

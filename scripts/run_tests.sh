#!/usr/bin/env bash
# Run the project test suite.
#
# Usage: run_tests.sh [--np N]
#   -n, --np N   Run each test under `mpirun -np N` (for MPI-parallel projects).
#                Omit for serial execution (the default).
#
# Test classification by binary name:
#   exe/*_xfail_*   — expected-failure test. MUST exit non-zero
#                     (e.g. validates an `error stop` path). Exit 0 is treated
#                     as a regression (XPASS, counted as failure).
#   exe/*          — regular test. MUST exit 0.
#
# Output labels (autotools convention):
#   PASS   regular test passed
#   FAIL   regular test failed
#   XFAIL  expected-failure test failed as expected (success)
#   XPASS  expected-failure test passed unexpectedly (failure)

NP=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --np | -n ) NP="$2"; shift 2 ;;
    * ) printf "Unknown argument: %s\n" "$1" >&2; exit 2 ;;
  esac
done

# Serial by default; wrap in mpirun only when --np N (N>0) is requested.
runner=()
if [[ "$NP" -gt 0 ]]; then
  runner=(mpirun -np "$NP")
fi

if [[ -t 1 ]]; then
  RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
  RED=''; GREEN=''; BOLD=''; RESET=''
fi

pass=0; fail=0
tmpout=$(mktemp)
trap 'rm -f "$tmpout"' EXIT

shopt -s nullglob
for exe in exe/*; do
  [[ -f "$exe" && -x "$exe" ]] || continue
  name=$(basename "$exe")

  "${runner[@]}" "$exe" > "$tmpout" 2>&1
  rc=$?

  if [[ "$name" == *_xfail_* ]]; then
    # Expected-failure test: non-zero exit is success.
    if [[ $rc -ne 0 ]]; then
      printf "  ${GREEN}XFAIL${RESET} %s\n" "$name"
      pass=$((pass + 1))
    else
      printf "  ${RED}XPASS${RESET} %s ${BOLD}(expected non-zero exit)${RESET}\n" "$name"
      fail=$((fail + 1))
    fi
  else
    # Regular test: zero exit is success.
    if [[ $rc -eq 0 ]]; then
      printf "  ${GREEN}PASS${RESET}  %s\n" "$name"
      pass=$((pass + 1))
    else
      printf "  ${RED}FAIL${RESET}  %s\n" "$name"
      sed 's/^/       /' "$tmpout"
      fail=$((fail + 1))
    fi
  fi
done

total=$((pass + fail))
printf "\n${BOLD}%d/%d passed${RESET}\n" "$pass" "$total"
exit $fail

#!/usr/bin/env bash
# FLAP's builds on one toolchain, run by .github/workflows/matrix.yml on each toolchain of the fobos [scaffold] matrix,
# with the fortran-toolchains environment contract: FC, CC, CXX, TOOLCHAIN, TOOLCHAIN_OS and TOOLCHAIN_FAMILY (gnu,
# nvf, intel). Created by fobis scaffold, then the project's. The same script runs locally, in `docker run <image>` and
# in CI. ci.yml covers the FoBiS debug build with coverage; this covers the others, each followed by its tests:
#
#   FoBiS  tests-<family>-debug, and on gnu tests-gnu-r16p (the quadruple-precision kind)  scripts/run_tests.sh
#   CMake                                                                                   ctest
#   make STATIC=no                                                                          every exe/flap_test_*
#
# The completion tests drive bash, zsh and fish when they are installed (the fortran-toolchains images have them).
set -euo pipefail
echo "toolchain: $TOOLCHAIN ($TOOLCHAIN_OS, $TOOLCHAIN_FAMILY), FC=$FC"
fobis fetch

modes=("tests-$TOOLCHAIN_FAMILY-debug")
if [ "$TOOLCHAIN_FAMILY" = gnu ]; then modes+=(tests-gnu-r16p); fi
for mode in "${modes[@]}"; do
  echo "== FoBiS $mode"
  rm -rf exe
  fobis build --mode "$mode" --fc "$FC"
  bash scripts/run_tests.sh
done

echo "== CMake"
rm -rf build-cmake
cmake -S . -B build-cmake -DCMAKE_Fortran_COMPILER="$FC"
cmake --build build-cmake -j 4
ctest --test-dir build-cmake --output-on-failure

echo "== make"
rm -rf exe
make STATIC=no FC="$FC"
for t in exe/flap_test_*; do
  "$t" > /dev/null || { echo "FAIL $t"; exit 1; }
done
echo "make: $(ls exe/flap_test_* | wc -l) tests passed"

---
title: Installation
---

# Installation

## Requirements

- A **Fortran 2018** compiler. FLAP is tested on every push with gfortran 13, 14 and 15 (and the gfortran 16 trunk),
  with FoBiS, fpm, CMake and make. It also builds and passes its tests with nvfortran 26.5 and Intel ifx 2025.3 (except
  one processor-dependent case: ifx reports a directory as not existing, see [path checks](./advanced#path-checks)).
  gfortran 12 compiles the library (not tested); gfortran 11 and older do not (`stop code, quiet=` is Fortran 2018).
- Two small libraries by the same author, fetched automatically by every build system:
  [PENF](https://github.com/szaghi/PENF) (portable numeric kinds) and [FACE](https://github.com/szaghi/FACE) (ANSI
  colours).

## fpm

Add FLAP as a dependency in your project's `fpm.toml`, pinned to a release:

```toml
[dependencies]
FLAP = { git = "https://github.com/szaghi/FLAP", tag = "v2.4.1" }
```

`fpm build` fetches FLAP, PENF and FACE. To build and test FLAP itself:

```bash
git clone https://github.com/szaghi/FLAP && cd FLAP
fpm test
```

## FoBiS

[FoBiS](https://github.com/szaghi/FoBiS) (3.8+) is the reference build system of FLAP.

**As a dependency** of a FoBiS project, declare FLAP in your `fobos` and fetch it:

```ini
[dependencies]
deps_dir = src/third_party
FLAP     = https://github.com/szaghi/FLAP
```

```bash
fobis fetch            # fetch FLAP (and its dependencies)
fobis fetch --update   # update them
```

**Standalone**:

```bash
git clone https://github.com/szaghi/FLAP && cd FLAP
fobis fetch                             # PENF and FACE into src/third_party (pinned by fobos.lock)
fobis build --mode static-gnu           # static/libflap.a, modules in static/mod
fobis build --mode shared-gnu           # shared/libflap.so
fobis build --mode tests-gnu            # every test program into exe/
bash scripts/run_tests.sh               # run them
fobis build --lmodes                    # every mode (GNU, Intel, NVIDIA; debug variants; quad precision)
```

## CMake

```bash
git clone https://github.com/szaghi/FLAP && cd FLAP
fobis fetch                             # PENF and FACE (or place them in src/third_party yourself)
cmake -B build
cmake --build build
ctest --test-dir build                  # the tests are built by default in a standalone build
```

As a subproject (`add_subdirectory`), the tests are off unless `BUILD_TESTING_FLAP=ON`.

## GNU Make

```bash
git clone https://github.com/szaghi/FLAP && cd FLAP
fobis fetch
make                  # the library and some tests, into exe/
make STATIC=yes       # the static library only: exe/libflap.a
```

## Install script

Every release ships an `install.sh`, which downloads FLAP and builds it with one of the tools above:

```bash
./install.sh --download git --build fobis
./install.sh --download wget --build cmake --tag v2.4.1
```

## Compiler notes

- **nvfortran:** FLAP builds as is (since v2.2.0 `-Mbackslash` is no longer needed; passing it is harmless). nvfortran
  26.5 miscompiles a variable passed to `get` (or any `class(*)` argument) from **more than one call site** of the same
  scope, including an internal procedure using it by host association: a call executed before the first one in the
  source may leave the variable unassigned, or crash. In code built with nvfortran, give each `get` call its own
  variable (a local in each helper procedure).
- **Quad precision:** `get` into `real(R16P)` needs FLAP and PENF compiled with `-D_R16P` (FoBiS mode
  `tests-gnu-r16p`); otherwise `R16P` is the same kind as `R8P`.

## Quick start

<<< @/examples/snippets/minimal.f90

Build it against the library (here the FoBiS static build) and run it:

```bash
gfortran -I static/mod minimal.f90 static/libflap.a -o minimal
```

<<< @/examples/output/minimal.ansi{ansi}

Without its required option, it prints the error, the help and a hint, and ends with exit status 1:

<<< @/examples/output/minimal-error.ansi{ansi}

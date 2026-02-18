---
title: Installation
---

# Installation

## Requirements

- A Fortran 2003+ compiler (GNU gfortran ≥ 4.9.2, Intel ifort ≥ 12.x, or Nvidia nvfortran)
- One of the supported build tools (FPM, FoBiS.py, GNU Make, or CMake)

## Option 1 — fpm (recommended)

With [Fortran Package Manager](https://fpm.fortran-lang.org) no manual setup is needed.

Add FLAP as a dependency in your project's `fpm.toml`:

```toml
[dependencies]
FLAP = { git = "https://github.com/szaghi/FLAP.git" }
```

To pin a specific version:

```toml
[dependencies]
FLAP = { git = "https://github.com/szaghi/FLAP.git", rev = "11cb276228d678c1d9ce755badf0ce82094b0852" }
```

Then build and test:

```bash
fpm build --profile release
fpm test  --profile release
```

## Option 2 — Install script

Download `install.sh` from the [latest release](https://github.com/szaghi/FLAP/releases/latest)
and use it to clone and build in one step:

```bash
# clone with git, build with GNU Make
./install.sh --download git --build make

# clone with wget, build with CMake
./install.sh --download wget --build cmake

# clone with git, build with FoBiS.py
./install.sh --download git --build fobis
```

## Option 3 — Manual clone + FoBiS.py

```bash
git clone https://github.com/szaghi/FLAP
cd FLAP
git submodule update --init

# static library (release)
FoBiS.py build -mode static-gnu

# shared library (release)
FoBiS.py build -mode shared-gnu

# debug variants
FoBiS.py build -mode static-gnu-debug
```

## Option 4 — GNU Make

```bash
git clone https://github.com/szaghi/FLAP
cd FLAP
make -j 1            # builds all tests into exe/
make -j 1 STATIC=yes # static library only
```

## Option 5 — CMake

```bash
git clone https://github.com/szaghi/FLAP FLAP
mkdir build && cd build
cmake FLAP
cmake --build .

# with tests
cmake -DFLAP_ENABLE_TESTS=ON FLAP
cmake --build .
ctest
```

> **NVFortran note:** pass `-Mbackslash` to work around a quoted-string issue:
> `cmake -D CMAKE_Fortran_FLAGS="-Mbackslash" FLAP`

## Quick Start

Once installed, a minimal FLAP program looks like:

```fortran
program minimal
  use flap
  implicit none
  type(command_line_interface) :: cli
  character(99)                :: string
  integer                      :: error

  call cli%init(description='minimal FLAP example')
  call cli%add(switch='--string', switch_ab='-s', &
               help='a string input', required=.true., act='store', error=error)
  if (error /= 0) stop

  call cli%parse(error=error)
  if (error /= 0) stop

  call cli%get(switch='-s', val=string, error=error)
  if (error /= 0) stop

  print '(A)', 'String = ' // trim(string)
end program minimal
```

Running without arguments triggers automatic error and help output:

```shell
$ ./minimal
./minimal: error: named option "--string" is required!

usage:  ./minimal --string value [--help] [--version]

minimal FLAP example

Required switches:
   --string value, -s value
    a string input

Optional switches:
   --help, -h
    Print this help message
   --version, -v
    Print version
```

Running correctly:

```shell
$ ./minimal --string 'hello world'
String = hello world
```

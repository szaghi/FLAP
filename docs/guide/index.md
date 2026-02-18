# Getting Started

FLAP (Fortran command Line Arguments Parser for poor people) is a pure Fortran 2003+ library
for building powerful, user-friendly Command Line Interfaces (CLIs). It is inspired by Python's
`argparse` module and follows the same philosophy: define your arguments once, and FLAP handles
parsing, help generation, error reporting, and more.

## Requirements

- A Fortran 2003+ compiler (GNU gfortran ≥ 4.9.2, Intel ifort ≥ 12.x, or Nvidia nvfortran)
- One of the supported build tools (FPM, FoBiS.py, GNU Make, or CMake)

## Installation

### Fortran Package Manager (recommended)

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

### Install script

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

### Manual clone + FoBiS.py

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

### GNU Make

```bash
git clone https://github.com/szaghi/FLAP
cd FLAP
make -j 1            # builds all tests into exe/
make -j 1 STATIC=yes # static library only
```

### CMake

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

## The Four-Step Pattern

Every FLAP program follows the same four steps:

```fortran
use flap
implicit none

type(command_line_interface) :: cli
integer                      :: error

! 1. Initialise the CLI (optional but recommended)
call cli%init(progname='myprogram', description='Does something useful')

! 2. Add argument definitions
call cli%add(switch='--output', switch_ab='-o', &
             help='Output file', required=.true., act='store', error=error)
if (error /= 0) stop

! 3. Parse the command line (optional — called automatically by get if omitted)
call cli%parse(error=error)
if (error /= 0) stop

! 4. Retrieve values into your variables
character(256) :: outfile
call cli%get(switch='-o', val=outfile, error=error)
if (error /= 0) stop
```

## Minimal example

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

## What's next?

- [Defining Arguments](./arguments) — all `add` options: actions, defaults, choices, lists, env vars
- [Parsing & Getting Values](./parsing) — `parse`, `get`, `get_varying`, `is_passed`
- [Nested Subcommands](./subcommands) — groups, `add_group`, `run_command`
- [Advanced Features](./advanced) — positional args, mutually exclusive, hidden, environment variables
- [Output Formats](./output) — man page, bash completion, Markdown export
- [Error Codes](./errors) — complete error code reference

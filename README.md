# FLAP

**Fortran command Line Arguments Parser for poor people** — a pure Fortran 2003+ library for building elegant CLIs, inspired by Python's `argparse`.

[![CI](https://github.com/szaghi/FLAP/actions/workflows/ci.yml/badge.svg)](https://github.com/szaghi/FLAP/actions)
[![Coverage](https://img.shields.io/codecov/c/github/szaghi/FLAP.svg)](https://app.codecov.io/gh/szaghi/FLAP)
[![GitHub tag](https://img.shields.io/github/tag/szaghi/FLAP.svg)](https://github.com/szaghi/FLAP/releases)
[![License](https://img.shields.io/badge/license-GPLv3%20%7C%20BSD%20%7C%20MIT-blue.svg)](#license)

---

## Features

- Optional, required, boolean, positional, and list-valued arguments
- `nargs` support: fixed count (`'3'`), one-or-more (`'+'`), zero-or-more (`'*'`)
- Mutually exclusive arguments and command groups
- Nested subcommands
- Environment variable and fake-input support
- Automatic help, usage, man page, bash completion, and Markdown generation
- POSIX compliant

---

## Quick start

A minimal *plate*:

```fortran
program minimal
  use flap
  implicit none
  type(command_line_interface) :: cli
  character(99) :: string
  integer       :: error

  call cli%init(description='minimal FLAP example')
  call cli%add(switch='--string', switch_ab='-s', help='a string', &
               required=.true., act='store', error=error)
  if (error /= 0) stop
  call cli%parse(error=error)
  if (error /= 0) stop
  call cli%get(switch='-s', val=string, error=error)
  if (error /= 0) stop

  print '(A)', 'String = ' // trim(string)
end program minimal
```

Running without arguments prints an automatic help message:

```
./minimal: error: named option "--string" is required!

usage: ./minimal --string value [--help] [--version]

minimal FLAP example

Required switches:
   --string value, -s value
    a string
```

See [`src/tests/`](src/tests/) for more examples including nested subcommands, mutually exclusive groups, choices, and bash completion.

---

## Install

### FPM (recommended)

Add to your `fpm.toml`:

```toml
[dependencies]
FLAP = { git = "https://github.com/szaghi/FLAP.git" }
```

Then build and test:

```sh
fpm build
fpm test
```

### Clone and build

```sh
git clone https://github.com/szaghi/FLAP
cd FLAP
git submodule update --init
```

| Tool | Command |
|------|---------|
| FPM | `fpm build --profile release` |
| FoBiS.py | `FoBiS.py build -mode static-gnu` |
| GNU Make | `make` |
| CMake | `cmake -B build && cmake --build build` |

> **NVFortran note:** pass `-Mbackslash` to work around backslash-in-string handling, e.g. `cmake -D CMAKE_Fortran_FLAGS="-Mbackslash" ...`

---

## Documentation

- API docs: [szaghi.github.io/FLAP](http://szaghi.github.io/FLAP/index.html)
- Generate locally: `FoBiS.py rule -ex makedoc` (requires [FORD](https://github.com/cmacmackin/ford))

---

## License

FLAP is multi-licensed:

- Open source projects: [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html)
- Closed source / commercial: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause), [BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause), or [MIT](http://opensource.org/licenses/MIT)

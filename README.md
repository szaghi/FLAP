# FLAP

>#### Fortran command Line Arguments Parser for poor people
>a pure Fortran 2018 library for building elegant CLIs, inspired by Python's `argparse`.

[![GitHub tag](https://img.shields.io/github/v/tag/szaghi/FLAP)](https://github.com/szaghi/FLAP/tags)
[![GitHub issues](https://img.shields.io/github/issues/szaghi/FLAP)](https://github.com/szaghi/FLAP/issues)
[![CI](https://github.com/szaghi/FLAP/actions/workflows/ci.yml/badge.svg)](https://github.com/szaghi/FLAP/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/endpoint?url=https://szaghi.github.io/FLAP/coverage.json)](https://github.com/szaghi/FLAP/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-GPLv3%20%7C%20BSD%20%7C%20MIT-blue.svg)](#copyrights)

| 📋 **Rich arguments**<br>Options, positionals, flags and `--x/--no-x` pairs, counters, repeatable options, lists, `KEY=VALUE` maps | ✅ **Validation**<br>Required options, choices, numeric ranges, path checks, mutually exclusive sets, "did you mean" suggestions | 🔀 **Commands**<br>git-style commands with their own options and help, aliases, shared option sets | 🌱 **Values from everywhere**<br>Command line, environment variables, INI configuration files, and the source of every value |
|:---:|:---:|:---:|:---:|
| 📄 **Generated outputs**<br>Help, man page, Markdown, and completion for bash, zsh, fish and PowerShell | 🐍 **argparse-inspired**<br>A familiar Python-like API in modern Fortran | 🔓 **Multi-licensed**<br>GPL v3 · BSD 2/3-Clause · MIT | 📦 **Multiple build systems**<br>FoBiS, fpm, CMake, Make |

>#### [Documentation](https://szaghi.github.io/FLAP/)
> For full documentation (guide, API reference, examples, etc...) see the [FLAP website](https://szaghi.github.io/FLAP/).

---

## Authors

- Stefano Zaghi — [@szaghi](https://github.com/szaghi)

Contributions are welcome — see the [Contributing](https://szaghi.github.io/FLAP/guide/contributing) page.

## Copyrights

This project is distributed under a multi-licensing system:

- **FOSS projects**: [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html)
- **Closed source / commercial**: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause), [BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause), or [MIT](http://opensource.org/licenses/MIT)

> Anyone interested in using, developing, or contributing to this project is welcome — pick the license that best fits your needs.

---

## Quick start

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
  if (error /= 0) stop 1, quiet=.true.
  call cli%parse(error=error)                 ! prints the help, or the error, by itself
  if (error /= 0) stop 1, quiet=.true.
  call cli%get(switch='-s', val=string, error=error)
  if (error /= 0) stop 1, quiet=.true.

  print '(A)', 'String = ' // trim(string)
end program minimal
```

```console
$ minimal --string "hello world"
String = hello world
```

Every feature has a compiled, runnable example in [`docs/examples/src`](docs/examples/src), shown with its real output in
the [guide](https://szaghi.github.io/FLAP/guide/).

---

## Install

### FoBiS

**Standalone** — clone, fetch dependencies, and build:

```bash
git clone https://github.com/szaghi/FLAP && cd FLAP
fobis fetch                           # fetch PENF, FACE
fobis build --mode static-gnu         # build static library
```

**As a project dependency** — declare FLAP in your `fobos` and run `fetch`:

```ini
[dependencies]
deps_dir = src/third_party
FLAP = https://github.com/szaghi/FLAP
```

```bash
fobis fetch              # fetch and build
fobis fetch --update     # re-fetch and rebuild
```

### fpm

Add to your `fpm.toml`:

```toml
[dependencies]
FLAP = { git = "https://github.com/szaghi/FLAP", tag = "v2.4.0" }
```

### CMake

```bash
fobis fetch                            # PENF and FACE into src/third_party
cmake -B build && cmake --build build
```

### GNU Make

```bash
fobis fetch
make STATIC=yes                        # exe/libflap.a
```

A Fortran 2018 compiler is required: tested with gfortran 13 to 16, nvfortran 26.5 and Intel ifx 2025.3 (see
[Installation](https://szaghi.github.io/FLAP/guide/install)).

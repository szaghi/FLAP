# FLAP

>#### Fortran command Line Arguments Parser for poor people
>a pure Fortran 2003+ library for building elegant CLIs, inspired by Python's `argparse`.

[![GitHub tag](https://img.shields.io/github/v/tag/szaghi/FLAP)](https://github.com/szaghi/FLAP/tags)
[![GitHub issues](https://img.shields.io/github/issues/szaghi/FLAP)](https://github.com/szaghi/FLAP/issues)
[![CI](https://github.com/szaghi/FLAP/actions/workflows/ci.yml/badge.svg)](https://github.com/szaghi/FLAP/actions/workflows/ci.yml)
[![coverage](https://img.shields.io/endpoint?url=https://szaghi.github.io/FLAP/coverage.json)](https://github.com/szaghi/FLAP/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-GPLv3%20%7C%20BSD%20%7C%20MIT-blue.svg)](#copyrights)

| 📋 **Argument Types**<br>Optional, required, boolean, positional, list-valued, and env-var-bound arguments | 🔢 **nargs Support**<br>Fixed count (`'3'`), one-or-more (`'+'`), zero-or-more (`'*'`) | 🔀 **Groups & Subcommands**<br>Mutually exclusive argument groups and arbitrarily nested subcommands | 📄 **Auto-generated Output**<br>Help, usage, man page, bash completion, and Markdown — all automatic |
|:---:|:---:|:---:|:---:|
| 🐍 **argparse-inspired**<br>Familiar Python-like API brought to modern Fortran | ✅ **POSIX compliant**<br>Standard CLI conventions respected out of the box | 🔓 **Multi-licensed**<br>GPL v3 · BSD 2/3-Clause · MIT | 📦 **Multiple build systems**<br>fpm, FoBiS, CMake, Make |

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
  if (error /= 0) stop
  call cli%parse(error=error)
  if (error /= 0) stop
  call cli%get(switch='-s', val=string, error=error)
  if (error /= 0) stop

  print '(A)', 'String = ' // trim(string)
end program minimal
```

See [`src/tests/`](src/tests/) for more examples including nested subcommands, mutually exclusive groups, choices, and bash completion.

---

## Install

### FoBiS

**Standalone** — clone, fetch dependencies, and build:

```bash
git clone https://github.com/szaghi/FLAP && cd FLAP
FoBiS.py fetch                        # fetch PENF, FACE
FoBiS.py build -mode static-gnu       # build static library
```

**As a project dependency** — declare FLAP in your `fobos` and run `fetch`:

```ini
[dependencies]
deps_dir = src/third_party
FLAP = https://github.com/szaghi/FLAP
```

```bash
FoBiS.py fetch           # fetch and build
FoBiS.py fetch --update  # re-fetch and rebuild
```

### fpm

Add to your `fpm.toml`:

```toml
[dependencies]
FLAP = { git = "https://github.com/szaghi/FLAP" }
```

```bash
fpm build
fpm test
```

### CMake

```bash
cmake -B build && cmake --build build
```

### GNU Make

```bash
make
```

---
title: About FLAP
---

# About FLAP

FLAP (Fortran command Line Arguments Parser for poor people) is a pure Fortran 2003+ library
for building powerful, user-friendly Command Line Interfaces (CLIs). It is inspired by Python's
`argparse` module and follows the same philosophy: define your arguments once, and FLAP handles
parsing, help generation, error reporting, and more.

Fortran programs often need rich command-line interfaces — optional switches, required
parameters, boolean flags, positional arguments, mutually exclusive groups, and nested
subcommands. FLAP provides all of this with a clean, consistent API and zero external
dependencies beyond the Fortran standard library.

## Authors

- Stefano Zaghi — [@szaghi](https://github.com/szaghi)

Contributions are welcome — see the [Contributing](contributing) page.

## Copyrights

FLAP is distributed under a multi-licensing system:

| Use case | License |
|---|---|
| FOSS projects | [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html) |
| Closed source / commercial | [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause) |
| Closed source / commercial | [BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause) |
| Closed source / commercial | [MIT](http://opensource.org/licenses/MIT) |

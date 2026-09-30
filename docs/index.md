---
layout: home

hero:
  name: FLAP
  text: Fortran command Line Arguments Parser for poor people
  tagline: A pure Fortran 2018 library for building powerful, elegant command line interfaces, inspired by Python's argparse
  actions:
    - theme: brand
      text: Guide
      link: /guide/
    - theme: alt
      text: API Reference
      link: /api/
    - theme: alt
      text: View on GitHub
      link: https://github.com/szaghi/FLAP

features:
  - icon: 🖥️
    title: Argparse-style API
    details: Define your CLI with a handful of calls; FLAP parses, checks the values, and prints the help, the version and clear errors with "did you mean" suggestions.
  - icon: ✅
    title: Rich arguments
    details: Options, positionals, flags and --x/--no-x pairs, counters, repeatable options, lists, KEY=VALUE maps, choices, numeric ranges, path checks.
  - icon: 🔀
    title: Commands
    details: git-style commands with their own options and help, aliases, option sets shared between commands, mutually exclusive options and commands.
  - icon: 🌱
    title: Values from everywhere
    details: Command line, environment variables and INI configuration files, in a fixed precedence, with the source of every value reported for reproducible runs.
  - icon: 📄
    title: Generated outputs
    details: Man page, Markdown, and completion scripts for bash, zsh, fish and PowerShell, which the program can also print or install itself.
  - icon: 🆓
    title: Free & Open Source
    details: Multi-licensed (GPLv3, BSD 2/3-Clause, MIT); tested with gfortran 13 to 16, nvfortran and Intel ifx; built with FoBiS, fpm, CMake or make.
---

## Quick start

<<< @/examples/snippets/minimal.f90

<<< @/examples/output/minimal.ansi{ansi}

<<< @/examples/output/minimal-error.ansi{ansi}

See the [Guide](/guide/) for everything else; upgrading from v1.x? Read [Upgrading](/guide/migration).

## Authors

- Stefano Zaghi — [@szaghi](https://github.com/szaghi)

Contributions are welcome — see the [Contributing](/guide/contributing) page.

## Copyrights

This project is distributed under a multi-licensing system:

- **FOSS projects**: [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html)
- **Closed source / commercial**: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause), [BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause), or [MIT](http://opensource.org/licenses/MIT)

> Anyone interested in using, developing, or contributing to this project is welcome — pick the license that best fits your needs.

---
title: About FLAP
---

# About FLAP

FLAP (Fortran command Line Arguments Parser for poor people) is a pure Fortran library for building powerful,
user-friendly Command Line Interfaces (CLIs): define your arguments once, and FLAP parses the command line, reads
environment variables and configuration files, checks the values, prints the help and the errors, and writes man pages,
Markdown and shell completions. Its design borrows from the best command line libraries of other languages (Python's
argparse, click and Typer, docopt).

Fortran programs, simulation codes above all, often need rich command lines: required parameters, optional switches with
defaults, lists of values, commands (`solver run`, `solver post`), values from the environment of a batch job or from an
input file. FLAP provides all of this with a small, consistent API, in standard Fortran 2018; it depends only on two
small libraries by the same author, PENF (numeric kinds) and FACE (ANSI colours), which every build system fetches.

This documentation reads in order, and each page links to the next one:

1. [Installation](./install): get FLAP into your project.
2. The [tutorial](/manual/tutorial/01-first-cli): nine short chapters that build a complete program, step by step.
3. The [cookbook](/manual/cookbook): short recipes, one for each "how do I ...?".
4. The reference, from the [feature map](./features#feature-map) on: every keyword, every rule, every error code.

The [API](/api/) documents the source itself. Upgrading from an older release? See [Upgrading](./migration): some
releases changed a behaviour.

Every code sample of this documentation is part of a program that is compiled and run to produce the outputs shown (see
[`docs/examples`](https://github.com/szaghi/FLAP/tree/master/docs/examples)).

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

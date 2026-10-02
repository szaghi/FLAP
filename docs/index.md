---
layout: home

hero:
  name: FLAP
  text: Fortran command Line Arguments Parser
  tagline: "Describe your command line once, in pure Fortran 2018: FLAP parses it, reads the environment and the configuration files, checks every value, and writes the help, the errors, the man page and the shell completions."
  actions:
    - theme: brand
      text: Tutorial
      link: /manual/tutorial/01-first-cli
    - theme: alt
      text: Cookbook
      link: /manual/cookbook
    - theme: alt
      text: Reference
      link: /guide/features
    - theme: alt
      text: API
      link: /api/
    - theme: alt
      text: View on GitHub
      link: https://github.com/szaghi/FLAP

features:
  - icon: 🧩
    title: Every kind of argument
    details: "Options with abbreviations, positionals, flags and --x/--no-x pairs, counters (-vvv), repeatable options, optional values, inline --opt=value, value placeholders."
    link: /guide/arguments
    linkText: Defining arguments
  - icon: 🔢
    title: Typed values, lists and maps
    details: "One get for every integer and real kind, logicals and strings; fixed-size lists, runtime-sized ones into allocatable arrays, KEY=VALUE maps."
    link: /guide/parsing
    linkText: Parsing & getting values
  - icon: ✅
    title: Validation built in
    details: "Required options, choices, numeric ranges with open bounds or clamping, path checks, mutually exclusive sets, deprecation warnings: declared in the definition, checked for you."
    link: /guide/advanced
    linkText: Advanced features
  - icon: 💬
    title: Errors that help
    details: "\"Did you mean\" suggestions, a hint line, the usage after an error, a named constant for every code, and your own errors printed in the same style."
    link: /guide/errors
    linkText: Errors
  - icon: 🔀
    title: Commands
    details: "git-style commands, each with its options and its help; aliases, option sets shared between commands, mutually exclusive commands, several commands on one command line."
    link: /guide/subcommands
    linkText: Subcommands
  - icon: 🌱
    title: Values from everywhere
    details: "Command line, environment variables (named or generated from a prefix), INI configuration files and defaults, in a fixed precedence; the source of every value reported, for reproducible runs."
    link: /guide/advanced#value-sources
    linkText: Value sources
  - icon: 📄
    title: Help, man page, Markdown
    details: "The help and the usage are generated from the definitions, with colours, examples and an epilog; --man and --markdown save the same content as files."
    link: /guide/output
    linkText: Output formats
  - icon: ⌨️
    title: Shell completion
    details: "Completion scripts for bash, zsh, fish and PowerShell, which the program prints or installs by itself: --show-completion, --install-completion."
    link: /guide/output#shell-completion
    linkText: Shell completion
  - icon: 🧪
    title: Testable command lines
    details: "Parse a string instead of the real command line, parse again, get statuses back instead of stops, send the messages to the units you choose."
    link: /manual/tutorial/08-testing
    linkText: Testing
  - icon: 🙋
    title: Interactive menus
    details: "An opt-in module asks for what is missing: single or multiple choice, defaults, yes/no questions, retries; it never blocks a batch job."
    link: /guide/menu
    linkText: Interactive menus
  - icon: 🛠️
    title: Standard Fortran, any build
    details: "Fortran 2018, tested with gfortran 13 to 16, nvfortran and Intel ifx; built with FoBiS, fpm, CMake or Make. Two small dependencies, fetched for you."
    link: /guide/install
    linkText: Installation
  - icon: 🔓
    title: Multi-licensed
    details: "GPL v3 for FOSS projects; BSD 2-Clause, BSD 3-Clause or MIT for closed source and commercial ones: pick the license that fits."
    link: #copyrights
    linkText: Copyrights
---

## Quick start

A real session with a FLAP program: the help, the values and the errors all come from FLAP.

<p align="center"><img src="./examples/images/quickstart.svg" alt="a terminal session of a FLAP program: its help, some runs, a typo and an out-of-range value"></p>

This is the whole program, in four steps: initialise, define, parse, get.

<<< @/examples/snippets/quickstart.f90

## Grows with your program

The same calls scale to commands, configuration files, a man page and shell completion. This help is generated from
the definitions of the `heat` solver that the [tutorial](/manual/tutorial/07-shipping) builds step by step; the colours
are two keywords.

<p align="center"><img src="./examples/images/heat_7-help.svg" alt="the help of a FLAP program"></p>

<p align="center"><img src="./examples/images/heat_7-error.svg" alt="an error of a FLAP program"></p>

Learn FLAP step by step in the [tutorial](/manual/tutorial/01-first-cli), find quick answers in the [cookbook](/manual/cookbook), look up every detail in the [reference](/guide/features#feature-map). Upgrading from v1.x? Read [Upgrading](/guide/migration).

## Authors

- Stefano Zaghi — [@szaghi](https://github.com/szaghi)

Contributions are welcome — see the [Contributing](/guide/contributing) page.

## Copyrights

This project is distributed under a multi-licensing system:

- **FOSS projects**: [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html)
- **Closed source / commercial**: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause), [BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause), or [MIT](http://opensource.org/licenses/MIT)

> Anyone interested in using, developing, or contributing to this project is welcome — pick the license that best fits your needs.

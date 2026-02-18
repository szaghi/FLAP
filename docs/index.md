---
layout: home

hero:
  name: FLAP
  text: Fortran command Line Arguments Parser for poor people
  tagline: A KISS pure Fortran 2003+ library for building powerful, elegant Command Line Interfaces — inspired by Python's argparse
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
    details: Define your CLI with a handful of method calls. FLAP automatically generates help, usage, and version messages — no boilerplate.
  - icon: ✅
    title: Rich argument types
    details: Optional, required, boolean, positional, list-valued (fixed or runtime-sized), choices-constrained, and environment-variable arguments.
  - icon: 🔀
    title: Nested subcommands
    details: Build git-style interfaces with named command groups, each with their own arguments and auto-generated per-command help.
  - icon: 🔒
    title: Mutually exclusive arguments
    details: Declare argument pairs or entire command groups that cannot be used together — with automatic error reporting.
  - icon: 📄
    title: Multiple output formats
    details: Export your CLI as a man page, bash completion script, or Markdown usage page with a single method call.
  - icon: 🆓
    title: Free & Open Source
    details: Multi-licensed — GPLv3 for FOSS projects, BSD 2/3-Clause or MIT for commercial use. Fortran 2003+ standard compliant.
---

## Quick start

A minimal *plate*:

```fortran
program minimal
type(command_line_interface) :: cli    ! Command Line Interface (CLI).
character(99)                :: string ! String value.
integer                      :: error  ! Error trapping flag.

call cli%init(description = 'minimal FLAP example')
call cli%add(switch='--string', &
             switch_ab='-s',    &
             help='a string',   &
             required=.true.,   &
             act='store',       &
             error=error)
if (error/=0) stop
call cli%get(switch='-s', val=string, error=error)
if (error/=0) stop
print '(A)', cli%progname//' has been called with the following argument:'
print '(A)', 'String = '//trim(adjustl(string))
endprogram minimal
```

## Authors

- Stefano Zaghi — [@szaghi](https://github.com/szaghi)

Contributions are welcome — see the [Contributing](/guide/contributing) page.

## Copyrights

FLAP is distributed under a multi-licensing system:

- **FOSS projects**: [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html)
- **Closed source / commercial**: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause), [BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause), or [MIT](http://opensource.org/licenses/MIT)

Anyone interested in using, developing, or contributing to FLAP is welcome — pick the license that best fits your needs.

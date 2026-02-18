---
title: Features
---

# Features

## Argument Types

FLAP supports every argument style commonly found in Unix CLIs:

| Type | Description |
|------|-------------|
| Optional switch | `--verbose` / `-v`; not required, has a default |
| Required switch | `--output file`; error if missing |
| Boolean flag | `store_true` / `store_false`; no value consumed |
| Positional | unnamed, matched by position |
| List-valued | fixed `nargs=N` or runtime `nargs='+'` / `nargs='*'` |
| Choices-constrained | value must be one of a predefined set |
| Environment-variable | falls back to an env var when the switch is absent |
| Hidden | registered but not shown in help output |

## Subcommands

Build `git`-style interfaces by grouping arguments into named command groups.
Each group has its own argument list and gets its own auto-generated help page:

```fortran
call cli%add_group(group='commit', description='Record changes to the repository')
call cli%add(group='commit', switch='--message', switch_ab='-m', ...)
```

Use `cli%run_command(group)` to discover which subcommand was selected at runtime.
Entire groups can be declared mutually exclusive with `set_mutually_exclusive_groups`.

## Output Formats

FLAP can export your CLI definition in several formats with a single call:

| Method | Output |
|--------|--------|
| `cli%usage()` | Formatted help/usage string (printed automatically on error) |
| `cli%save_man_page(unit)` | Unix man page (troff format) |
| `cli%save_bash_completion(unit)` | Bash tab-completion script |
| `cli%save_usage_to_markdown(unit)` | Markdown usage documentation |

## The Four-Step Pattern

Every FLAP program follows the same four steps:

```fortran
use flap
implicit none

type(command_line_interface) :: cli
integer                      :: error

! 1. Initialise the CLI
call cli%init(progname='myprogram', description='Does something useful')

! 2. Add argument definitions
call cli%add(switch='--output', switch_ab='-o', &
             help='Output file', required=.true., act='store', error=error)
if (error /= 0) stop

! 3. Parse the command line
call cli%parse(error=error)
if (error /= 0) stop

! 4. Retrieve values
character(256) :: outfile
call cli%get(switch='-o', val=outfile, error=error)
if (error /= 0) stop
```

## Module Architecture

```
flap.f90                               ← public interface (use this in consuming code)
└── flap_command_line_interface_t.F90  ← main CLI type
    ├── flap_command_line_arguments_group_t.f90  ← groups / subcommands
    │   └── flap_command_line_argument_t.F90     ← individual argument
    │       ├── flap_object_t.F90                ← base class (error handling)
    │       └── flap_utils_m.f90
    └── (PENF — numeric precision kinds)
    └── (FACE — ANSI terminal colours)
```

Any feature request is welcome — open an issue on
[GitHub](https://github.com/szaghi/FLAP/issues).

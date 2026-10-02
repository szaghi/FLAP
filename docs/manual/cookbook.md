---
title: Cookbook
---

# Cookbook

Short answers to "how do I ...?". Each recipe shows the code and its real output; the [reference](/guide/features#feature-map) has the details.

[[toc]]

## A required option

<<< @/examples/snippets/minimal.f90

<<< @/examples/output/minimal-error.ansi{ansi}

## An option with a default, read into a number

<<< @/examples/snippets/myapp-define.f90

<<< @/examples/snippets/myapp-get.f90

<<< @/examples/output/myapp.ansi{ansi}

`get` converts to the type and kind of the variable; a value that is not a number is `ERROR_CASTING_NUMBER`.

## A flag, a verbosity counter, a repeatable option

<<< @/examples/snippets/actions-define.f90

<<< @/examples/output/actions.ansi{ansi}

## A value from a fixed list

<<< @/examples/snippets/choices-define.f90

<<< @/examples/output/choices.ansi{ansi}

<<< @/examples/output/choices-error.ansi{ansi}

## A number within bounds

<<< @/examples/snippets/ranges-define.f90

<<< @/examples/output/ranges.ansi{ansi}

<<< @/examples/output/ranges-error.ansi{ansi}

## A list of files

<<< @/examples/snippets/lists-define.f90

<<< @/examples/snippets/lists-get.f90

<<< @/examples/output/lists.ansi{ansi}

## An input file given without a switch

<<< @/examples/snippets/positional-define.f90

<<< @/examples/output/positional.ansi{ansi}

## A file that must exist

<<< @/examples/snippets/paths-define.f90

<<< @/examples/output/paths-missing.ansi{ansi}

## `KEY=VALUE` overrides of an input deck

<<< @/examples/snippets/map-define.f90

<<< @/examples/snippets/map-get.f90

<<< @/examples/output/map.ansi{ansi}

## Exactly one of two options

<<< @/examples/snippets/exclusive-sets.f90

<<< @/examples/output/exclusive-none.ansi{ansi}

## Values from environment variables

<<< @/examples/snippets/environment-define.f90

<<< @/examples/output/environment-env.ansi{ansi}

## Values from a configuration file

<<< @/examples/snippets/config-define.f90

<<< @/examples/files/solver.ini{ini}

<<< @/examples/output/config.ansi{ansi}

## Logging where every value comes from

<<< @/examples/snippets/config-provenance.f90

<<< @/examples/output/config-override.ansi{ansi}

## Subcommands

<<< @/examples/snippets/fake_git-define.f90

<<< @/examples/snippets/fake_git-dispatch.f90

<<< @/examples/output/fake_git-two.ansi{ansi}

## Short names for commands, options shared by commands

<<< @/examples/snippets/aliases-aliases.f90

<<< @/examples/snippets/aliases-copy.f90

<<< @/examples/output/aliases.ansi{ansi}

## An option that lists something and exits

<<< @/examples/snippets/alternate-define.f90

<<< @/examples/snippets/alternate-dispatch.f90

<<< @/examples/output/alternate.ansi{ansi}

## Retiring an option

<<< @/examples/snippets/deprecated-define.f90

<<< @/examples/output/deprecated.ansi{ansi}

## Reporting a check of the program in FLAP's style

<<< @/examples/snippets/raise_error-check.f90

<<< @/examples/output/raise_error.ansi{ansi}

## A shorter output after an error

<<< @/examples/snippets/usage_on_error-define.f90

<<< @/examples/output/usage_on_error.ansi{ansi}

## Colours

<<< @/examples/snippets/colors-define.f90

<<< @/examples/output/colors-error.ansi{ansi}

## Switches in any case

<<< @/examples/snippets/case_insensitive-define.f90

<<< @/examples/output/case_insensitive.ansi{ansi}

## A man page, Markdown, shell completion

<<< @/examples/snippets/completion-define.f90

<<< @/examples/output/completion-install.ansi{ansi}

<<< @/examples/snippets/save_outputs-save.f90

## Cleaning up before exiting on `--help`

<<< @/examples/snippets/statuses-define.f90

<<< @/examples/snippets/statuses-dispatch.f90

<<< @/examples/output/statuses.ansi{ansi}

## Testing the command line

<<< @/examples/snippets/heat_8-checks.f90

See [chapter 8 of the tutorial](./tutorial/08-testing).

## Passing arguments through to another program

Everything after `--` is collected, unparsed, in the hidden list of `--`:

```fortran
character(256), allocatable :: rest(:)

call cli%get_varying(switch='--', val=rest, error=error)   ! prog --nx 4 -- mpirun -np 8  ->  rest = [mpirun, -np, 8]
```

## Asking the user

<<< @/examples/snippets/menus-single.f90

<<< @/examples/output/menus-single.ansi{ansi}

## Coming from Python

| Python | FLAP |
|---|---|
| `parser.add_argument('--n', type=int, default=1)` | `add(switch='--n', act='store', def='1')`, then `get` into an integer |
| `required=True` | `required=.true.` |
| `action='store_true'` | `act='store_true', def='.false.'` |
| `action='count'` | `act='count'` |
| `action='append'` | `act='append'`, read with `get_varying` |
| `nargs='+'`, `nargs='*'`, `nargs=3` | `nargs='+'`, `'*'`, `'3'` |
| `choices=['a', 'b']` | `choices='a,b'` |
| `metavar='FILE'` | `metavar='FILE'` |
| `add_subparsers()` | `add_group(group=...)` and `run_command` |
| `add_mutually_exclusive_group(required=True)` | `set_mutually_exclusive_switches(switches=..., required=.true.)` |
| click `envvar=`, `auto_envvar_prefix=` | `envvar=`, `init(auto_envvar_prefix=)` |
| click `IntRange(1, 64, clamp=True)` | `min='1', max='64', clamp=.true.` |
| click `Path(exists=True, readable=True)` | `must_exist=.true.`, `readable=.true.` |
| click `--shout/--no-shout` | `switch='--shout', switch_neg='--no-shout'` |
| click `deprecated=True` | `deprecated='message'` |
| Typer `--install-completion` | `init(completion_options=.true.)` |

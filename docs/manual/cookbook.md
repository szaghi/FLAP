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

## A flag and its negation

<<< @/examples/snippets/actions-pair.f90

<<< @/examples/output/actions-pair.ansi{ansi}

## A flag that is true unless passed

<<< @/examples/snippets/store_false-define.f90

<<< @/examples/output/store_false-off.ansi{ansi}

## A verbosity counter

<<< @/examples/snippets/actions-count.f90

<<< @/examples/output/actions-count.ansi{ansi}

## A repeatable option

<<< @/examples/snippets/actions-append.f90

<<< @/examples/output/actions-append.ansi{ansi}

Read it with `get_varying`, as a [list](#a-list-of-files).

## An option whose value is optional

<<< @/examples/snippets/actions-optional.f90

<<< @/examples/output/actions-value.ansi{ansi}

A value can always be given inline, `--format=json`; for an optional value it is the only unambiguous way.

## An option hidden from the help

<<< @/examples/snippets/actions-hidden.f90

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

## Two options that cannot go together

<<< @/examples/snippets/exclusive-pair.f90

<<< @/examples/output/exclusive-pair.ansi{ansi}

## Exactly one of two options

<<< @/examples/snippets/exclusive-sets.f90

<<< @/examples/output/exclusive-none.ansi{ansi}

## Values from environment variables

<<< @/examples/snippets/environment-define.f90

<<< @/examples/output/environment-env.ansi{ansi}

## Ignoring the environment, for reproducible runs

<<< @/examples/snippets/ignore_env-define.f90

<<< @/examples/output/ignore_env.ansi{ansi}

## Values from a configuration file

<<< @/examples/snippets/config-define.f90

<<< @/examples/files/solver.ini{ini}

<<< @/examples/output/config.ansi{ansi}

## A configuration file chosen by the program

<<< @/examples/snippets/set_config-define.f90

<<< @/examples/files/defaults.ini{ini}

<<< @/examples/output/set_config-override.ansi{ansi}

## Logging where every value comes from

<<< @/examples/snippets/config-provenance.f90

<<< @/examples/output/config-override.ansi{ansi}

## Was an option passed, and where does its value come from?

<<< @/examples/snippets/passed-query.f90

<<< @/examples/output/passed-env.ansi{ansi}

<<< @/examples/output/passed-cli.ansi{ansi}

## Subcommands

<<< @/examples/snippets/fake_git-define.f90

<<< @/examples/snippets/fake_git-dispatch.f90

<<< @/examples/output/fake_git-two.ansi{ansi}

## Short names for commands, options shared by commands

<<< @/examples/snippets/aliases-aliases.f90

<<< @/examples/snippets/aliases-copy.f90

<<< @/examples/output/aliases.ansi{ansi}

## Two commands that cannot go together

<<< @/examples/snippets/exclusive_groups-define.f90

<<< @/examples/output/exclusive_groups-both.ansi{ansi}

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

## The help and the errors in a file

<<< @/examples/snippets/units-define.f90

<<< @/examples/output/units.ansi{ansi}

## The usage as text

<<< @/examples/snippets/messages-text.f90

<<< @/examples/output/messages.ansi{ansi}

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

## Arguments that are not yours

With `ignore_unknown_clas`, `parse` reports the unknown arguments on the error unit and returns
`ERROR_UNKNOWN_CLAS_IGNORED`, with every known value read:

<<< @/examples/snippets/ignore_unknown-define.f90

<<< @/examples/output/ignore_unknown.ansi{ansi}

## Passing arguments through to another program

Everything after `--` is collected, unparsed, in the hidden list of `--`:

```fortran
character(256), allocatable :: rest(:)

call cli%get_varying(switch='--', val=rest, error=error)   ! prog --nx 4 -- mpirun -np 8  ->  rest = [mpirun, -np, 8]
```

## Asking the user

<<< @/examples/snippets/menus-single.f90

<<< @/examples/output/menus-single.ansi{ansi}

## Asking for several choices

<<< @/examples/snippets/menus-multiple.f90

<<< @/examples/output/menus-multiple.ansi{ansi}

## A yes/no question

<<< @/examples/snippets/menus-yes_no.f90

<<< @/examples/output/menus-yes_no.ansi{ansi}

## Asking again after a wrong answer

<<< @/examples/snippets/menus-retry.f90

<<< @/examples/output/menus-retry.ansi{ansi}

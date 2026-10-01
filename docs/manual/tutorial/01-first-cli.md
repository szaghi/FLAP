# 1. A first command line

`heat` starts with three numbers: the cells along each direction, the time steps and the CFL number. Every FLAP program
follows the same four steps: **initialise** the command line interface, **define** the arguments, **parse** the command
line, **get** the values.

<<< @/examples/snippets/heat_1.f90

- `init` names the program and describes it; `version` is what `--version` prints.
- `add` defines an option: its `switch`, a `help` line, whether it is `required`, the action (`act='store'`: it stores
  the value that follows) and its default `def`, always a string.
- `parse` reads the command line and checks it. It returns an error code: 0 means success.
- `get` converts each value to the type of the variable you pass: an `integer`, a `real(8)`, ... There is one `get` for
  every type and kind.

## Running it

<<< @/examples/output/heat_1.ansi{ansi}

<<< @/examples/output/heat_1-options.ansi{ansi}

A value follows its switch, or is attached to it with `=` (`--steps=10`).

## Help and version for free

Every FLAP program has `--help` (`-h`), `--version` (`-v`) and `--markdown` (`-md`, the help as a Markdown file):

<<< @/examples/output/heat_1-help.ansi{ansi}

<<< @/examples/output/heat_1-version.ansi{ansi}

`--help` and `--version` end the program inside `parse`, with exit status 0: the code after `parse` never runs.

## Errors

A mistake on the command line is reported by `parse`, with suggestions for a misspelled switch and a hint pointing to
the help; a value that cannot be converted is reported by `get`:

<<< @/examples/output/heat_1-typo.ansi{ansi}

<<< @/examples/output/heat_1-cast.ansi{ansi}

FLAP prints the message and returns the error code; it never stops the program on an error. `heat` stops with exit
status 1, so that a shell script or a batch system sees the failure.

::: tip What you learned
The four steps `init`, `add`, `parse`, `get`; the free builtins; error codes instead of crashes.
Reference: [Defining Arguments](/guide/arguments), [Parsing & Getting Values](/guide/parsing).
:::

Next: [2. Options of every kind](./02-options).

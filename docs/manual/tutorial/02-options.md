# 2. Options of every kind

A real solver needs more than numbers: a choice of scheme, a stability limit, a verbosity level, an optional output.

<<< @/examples/snippets/heat_2-define.f90

| Option | What it shows |
|---|---|
| `--nx`, `--steps`, `--cfl` | `metavar`: the placeholder of the value in the help (`N`, `CFL` instead of `value`) |
| `--cfl` | a numeric **range**, `(0, 0.5]`: the explicit scheme is unstable above 0.5 |
| `--scheme` | **choices**, matched in any case (`case_sensitive=.false.`), with an abbreviation `-s` |
| `--threads` | a **clamped** range: 1000 threads become 64, without an error |
| `--verbose` | a **counter** (`act='count'`): `-v`, `-vv`, `-v -v` |
| `--save` | an **optional value** (`act='store*'`): `--save` alone uses the default format |

The values are read as before; `is_passed` tells whether an option was on the command line:

<<< @/examples/snippets/heat_2-get.f90

<<< @/examples/output/heat_2.ansi{ansi}

<<< @/examples/output/heat_2-clamp.ansi{ansi}

`CN` became `cn`, the declared spelling: the program compares with one spelling only. The help shows every rule:

<<< @/examples/output/heat_2-help.ansi{ansi}

Since `-v` is now `--verbose`, the builtin `--version` keeps only its long name.

## When a value breaks a rule

Choices and ranges are checked by `get`, when the value is converted:

<<< @/examples/output/heat_2-choice.ansi{ansi}

<<< @/examples/output/heat_2-range.ansi{ansi}

::: tip What you learned
Choices, ranges and clamping, counters, optional values, placeholders, `is_passed`.
Reference: [Defining Arguments](/guide/arguments#actions-act), [Numeric ranges](/guide/advanced#numeric-ranges).
:::

Next: [3. Lists and parameters](./03-lists).

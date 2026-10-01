# 3. Lists and parameters

`heat` records the temperature at a probe (two coordinates), saves some fields, and lets the user override the physical
parameters of the problem without editing an input file.

<<< @/examples/snippets/heat_3-define.f90

- `nargs='2'`: exactly two values, read into an array of two elements with `get`.
- `nargs='*'`: any number of values, also none; read into an allocatable array with `get_varying`, which allocates it to
  the right size. `choices` apply to every value.
- `map=.true.`: `KEY=VALUE` pairs; `map_keys` lists the keys allowed. `get_map_value` reads one key, and leaves the
  variable untouched (`found=.false.`) when the key was not given: the built-in value stays.

<<< @/examples/snippets/heat_3-get.f90

<<< @/examples/output/heat_3.ansi{ansi}

<<< @/examples/output/heat_3-default.ansi{ansi}

`--fields` alone is an empty list, not the default:

<<< @/examples/output/heat_3-nofields.ansi{ansi}

A misspelled key is caught by `parse`, with a suggestion:

<<< @/examples/output/heat_3-map.ansi{ansi}

<<< @/examples/output/heat_3-help.ansi{ansi}

::: tip What you learned
Fixed and variable lists, `get_varying`, maps with `get_map_value`.
Reference: [List-valued arguments](/guide/arguments#list-valued-arguments-nargs), [Key=value options](/guide/arguments#key-value-options-map).
:::

Next: [4. Commands](./04-commands).

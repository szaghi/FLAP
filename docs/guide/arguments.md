# Defining Arguments

A FLAP program first describes its command line: `init` sets up the CLI (program name, help texts, behaviour), `add`
declares each argument. Every code sample on this page is part of a program in
[`docs/examples/src`](https://github.com/szaghi/FLAP/tree/master/docs/examples/src) that is built and run to produce the
outputs shown.

## Initialising the CLI — `cli%init`

```fortran
call cli%init(progname, version, help, description, license, authors, examples, epilog, disable_hv,        &
              usage_lun, error_lun, version_lun, error_color, error_style, ignore_unknown_clas, standalone, &
              error_hint, no_args_is_help, ignore_env, auto_envvar_prefix, case_insensitive,               &
              completion_options, usage_on_error, man_option, man_file, markdown_file)
```

Every argument is optional; pass them by keyword. Call `init` before `add`: it resets the CLI, and some settings
(`case_insensitive`, `auto_envvar_prefix`) apply to the arguments added after it.

**Texts**

| Argument | Type | Default | Purpose |
|---|---|---|---|
| `progname` | `character(*)` | the name the program was invoked with (`argv[0]`), else `'program'` | Program name in the usage line and in the messages |
| `version` | `character(*)` | `'unknown'` | Printed by `--version` |
| `help` | `character(*)` | `'usage: '` | Text before the usage line |
| `description` | `character(*)` | `''` | Shown below the usage line |
| `license` | `character(*)` | `''` | License note (`cli%license`) |
| `authors` | `character(*)` | `''` | Authors (`cli%authors`) |
| `examples` | `character(*), dimension(:)` | none | Usage examples, shown at the end of the help |
| `epilog` | `character(*)` | `''` | Printed after the help |

**Behaviour**

| Argument | Type | Default | Purpose |
|---|---|---|---|
| `standalone` | `logical` | `.true.` | After `--help`, `--version`, `--markdown`, ... end the program (exit status 0); `.false.`: `parse` returns a status instead (see [Error Codes](./errors#handling-status-codes)) |
| `disable_hv` | `logical` | `.false.` | Do not add the builtins `--help`, `--version`, `--markdown` |
| `no_args_is_help` | `logical` | `.false.` | With no arguments, print the help instead of parsing (`STATUS_NO_ARGS`; exit status 2 in standalone mode) |
| `error_hint` | `logical` | `.true.` | After a failed `parse`, print `Try 'prog --help' for help.` (see [Error Codes](./errors#error-hint)) |
| `usage_on_error` | `character(*)` | `'full'` | What a missing required option prints after its message: the whole help (`'full'`), the usage line (`'usage'`) or nothing (`'none'`); see [Errors](./errors#output-after-an-error) |
| `ignore_unknown_clas` | `logical` | `.false.` | Unknown arguments are not an error (`parse` returns `ERROR_UNKNOWN_CLAS_IGNORED`, 1004, and goes on); also unknown configuration keys |
| `case_insensitive` | `logical` | `.false.` | Match switches (abbreviations and negations included) and command names in any case: `--MESH` is `--mesh`. Values and choices keep their case; two switches differing only by case are a consistency error (100) |
| `ignore_env` | `logical` | `.false.` | Turn every environment lookup off (see [Advanced](./advanced#ignoring-the-environment)) |
| `auto_envvar_prefix` | `character(*)` | none | Give every option an environment variable `PREFIX[_COMMAND]_NAME` (see [Advanced](./advanced#generated-variable-names)) |

**Builtins and outputs**

| Argument | Type | Default | Purpose |
|---|---|---|---|
| `completion_options` | `logical` | `.false.` | Add `--show-completion [SHELL]` and `--install-completion [SHELL]` (see [Output](./output#shell-completion-from-the-program)) |
| `man_option` | `logical` | `.false.` | Add `--man`: save the man page and stop (see [Output](./output#from-the-command-line-man)) |
| `man_file` | `character(*)` | `<progname>.1` | File written by `--man` |
| `markdown_file` | `character(*)` | `<progname>.md` | File written by `--markdown` |
| `usage_lun`, `error_lun`, `version_lun` | `integer` | standard error, standard error, standard output | Units of the help, of the errors and of the version (and of `--show-completion`) |
| `error_color`, `error_style` | `character(*)` | none | Colour of the `error`/`warning` labels (see [Output](./output#colours)) |

The `examples` of a character array constructor must all have the same length: pad the shorter ones with blanks.

<<< @/examples/snippets/myapp-define.f90

### Public attributes

The texts are public components of the CLI: `cli%progname`, `cli%version`, `cli%description`, `cli%license`,
`cli%authors`, `cli%epilog`, and the examples `cli%examples(i)%s`; `cli%error` and `cli%error_message` hold the last
error.

### The builtin switches

FLAP adds to every CLI (the top level and each command):

| Switch | Action |
|---|---|
| `--help`, `-h` | Print the help (`STATUS_PRINT_H`) |
| `--version`, `-v` | Print the version (`STATUS_PRINT_V`) |
| `--markdown`, `-md` | Save the help as Markdown, `<progname>.md` (`STATUS_PRINT_M`) |
| `--` | Hidden: the arguments after it are not parsed, but collected in its own list (see [Parsing](./parsing#values-that-start-with-a-dash)) |

and, when asked by `init`, the top-level `--man` (`man_option`), `--show-completion` and `--install-completion`
(`completion_options`). Your own switches take precedence: if you define `--version`, the builtin is not added; if you
take only its abbreviation (`-v` for verbosity), the builtin keeps just `--version`. `disable_hv=.true.` removes the
three of them.

---

## Adding arguments — `cli%add`

```fortran
call cli%add(pref, group, group_index, switch, switch_ab, switch_neg, help, help_markdown, help_color, help_style, &
             required, val_required, positional, position, hidden, act, def, nargs, choices, exclude, envvar,    &
             must_exist, readable, writable, allow_dash, deprecated, min, max, min_open, max_open, clamp,         &
             case_sensitive, map, map_keys, metavar, error)
```

A named argument needs `switch`; a positional one `positional=.true.` and `position`. Every other argument is optional.

### Core parameters

| Argument | Type | Default | Purpose |
|---|---|---|---|
| `switch` | `character(*)` | — | Long switch name, e.g. `'--output'` |
| `switch_ab` | `character(*)` | `switch` | Abbreviated switch, e.g. `'-o'` |
| `switch_neg` | `character(*)` | none | Negation of a flag, e.g. `'--no-restart'` (see [Flag pairs](#flag-pairs-switch-neg)) |
| `help` | `character(*)` | `'Undocumented argument'` | Description in the help |
| `required` | `logical` | `.false.` | The argument must be given (on the command line, or by the environment or a configuration file) |
| `act` | `character(*)` | `'store'` | Action, see below (any case) |
| `def` | `character(*)` | none | Default value, as a string; blank separated for a list |
| `metavar` | `character(*)` | `'value'` | Placeholder of the value in the usage, help, man page and Markdown (see [Metavar](#metavar)) |
| `group` | `character(*)` | top level | The command the argument belongs to (see [Subcommands](./subcommands)) |
| `hidden` | `logical` | `.false.` | Parsed, but not shown in the help, the usage and the completion |
| `help_markdown` | `character(*)` | `''` | Longer help, used by the Markdown output |
| `help_color`, `help_style` | `character(*)` | none | Colour of the switch names in the help (see [Output](./output#colours)) |
| `error` | `integer` | — | Error code of the definition (0 = success) |

An optional argument (`required=.false.`) **must** have a default (`def=...`, even `def=''`): otherwise `add` returns
`ERROR_OPTIONAL_NO_DEF` (1). Only `count` (`'0'`) and `alternate` (`.false.`) have an implicit default: a flag needs
`def='.false.'` (or `'.true.'`).

The validation keywords (`choices`, `min`/`max`, the path checks, `exclude`, `deprecated`) and the value sources
(`envvar`, configuration files) have their own sections below and in [Advanced Features](./advanced).

### Actions (`act`)

| Action | Effect |
|---|---|
| `'store'` | Stores the value(s) passed after the switch |
| `'store*'` | The value is optional: the switch alone gives the default |
| `'store_true'` | A flag: `.true.` when passed, otherwise its `def` |
| `'store_false'` | A flag: `.false.` when passed, otherwise its `def` |
| `'count'` | Counts the occurrences (`-v -v`, `-vv`, `--verbose -v` give 2); read into an integer; `def` defaults to `'0'` |
| `'append'` | One value per occurrence (`-I src --include=lib` gives `[src, lib]`); read with `get_varying`. Passed values **replace** the default |
| `'alternate'` | An auxiliary action (`--list-models`): `parse` returns `STATUS_ALTERNATE` and skips the value checks (see [Advanced](./advanced#alternate-actions)) |
| `'config'` | Names the configuration file (see [Advanced](./advanced#configuration-files)) |
| `'print_help'`, `'print_version'` | Print the help, the version (the actions of the builtins) |

<<< @/examples/snippets/actions-define.f90

<<< @/examples/snippets/actions-get.f90

<<< @/examples/output/actions.ansi{ansi}

<<< @/examples/output/actions-defaults.ansi{ansi}

`-vv` is two `-v`; `--format=json` gives a value inline (see [Parsing](./parsing#inline-values-option-value)); the hidden
`--debug-internal` does not appear in the help:

<<< @/examples/output/actions-help.ansi{ansi}

### Metavar

`metavar` names the value in the usage, the help, the man page and the Markdown output, instead of the generic `value`.
A list numbers it (`NAME#1 ...`); for a map it replaces `KEY=VALUE`; a flag ignores it (it takes no value); a positional
shows it alone. The shell completion never shows placeholders.

<<< @/examples/snippets/lists-define.f90

<<< @/examples/output/lists-help.ansi{ansi}

### Flag pairs (`switch_neg`)

A `store_true` or `store_false` flag can have a negation, which sets the opposite value (`--restart`/`--no-restart` in
the example above):

| Command line | `restart` |
|---|---|
| (absent) | the default, or the environment or configuration value |
| `--restart` | `.true.` |
| `--no-restart` | `.false.` |
| `--restart --no-restart` | `.false.`: the last one wins |
| `--no-restart --restart` | `.true.` |
| `--restart --restart` | `ERROR_DUPLICATED_CLAS` (23) |

The last spelling wins, as in click and GNU tools, so a preset can be overridden: with `alias run='solver --restart'`,
`run --no-restart` does not restart. Each spelling may appear once. The help shows the pair as
`[--restart/--no-restart]`; the completion offers both names; `get` and `is_passed` accept either name. The negation
belongs to a named scalar flag and differs from its switch names: otherwise `add` reports
`ERROR_SWITCH_NEG_INCONSISTENT` (36); a negation equal to the switch of another argument is a group consistency error
(100).

### Restricted choices (`choices`)

`choices` is a comma-separated list of the allowed values, checked by `get` (and by `get_varying`, on every value of a
list, the default included). With `case_sensitive=.false.`, a `character` value matches its choice in any case and `get`
returns the **declared spelling**. `choices` cannot be used with logical values (`ERROR_CHOICES_LOGICAL`, 11).

<<< @/examples/snippets/choices-define.f90

<<< @/examples/output/choices.ansi{ansi}

<<< @/examples/output/choices-error.ansi{ansi}

### List-valued arguments (`nargs`)

| `nargs` | Meaning | Read with |
|---|---|---|
| `'N'` (a positive integer) | Exactly N values: the switch takes the next N arguments; a further one is the next argument | `get` into an array of N elements |
| `'+'` | One or more values | `get_varying` |
| `'*'` | Zero or more values: the switch alone is an empty list, the default applies only when the switch is absent | `get_varying` |

<<< @/examples/snippets/lists-get.f90

<<< @/examples/output/lists.ansi{ansi}

<<< @/examples/output/lists-empty.ansi{ansi}

<<< @/examples/output/lists-short.ansi{ansi}

A list with a variable number of values (`'+'`, `'*'`) ends at the next switch or at the first command name. With
`nargs='N'` the default must have exactly N values (`ERROR_DEF_NARGS`, 48); `'+'` and `'*'` accept a default of any
length. A list cannot take an inline value (`--coords=1`, `ERROR_INLINE_VALUE_NARGS`).

### Key=value options (`map`)

With `map=.true.`, a list option takes `KEY=VALUE` pairs, typically to override the parameters of an input deck;
`map_keys` restricts the keys:

<<< @/examples/snippets/map-define.f90

<<< @/examples/snippets/map-get.f90

<<< @/examples/output/map.ansi{ansi}

<<< @/examples/output/map-default.ansi{ansi}

<<< @/examples/output/map-unknown.ansi{ansi}

- A pair is split at the **first** `=`: `label=a=b` is the key `label` with the value `a=b`; `a=` has an empty value.
- A map is a named `act='store'` option with `nargs` (`'+'`, `'*'` or a number), or `act='append'`
  (`--set a=1 --set b=2`); `--set=a=1` is one pair. Positionals, flags and `choices` are not allowed
  (`ERROR_MAP_INCONSISTENT`, 42).
- `parse` checks the pairs, whatever their source (command line, environment as comma-separated pairs, configuration
  file as blank-separated pairs, default): `ERROR_MAP_FORMAT` (38), `ERROR_MAP_DUPLICATE_KEY` (39), and, with
  `map_keys`, `ERROR_MAP_UNKNOWN_KEY` (40). Keys are case-sensitive.
- Passed pairs **replace** the default ones, they are not merged.
- `cli%get_map(switch, keys, values, group, error)` returns all the pairs, in order, into `character(len=...),
  allocatable` arrays. `cli%get_map_value(switch, key, val, found, group, error)` converts one value to the type of `val`
  (any kind `get` supports); a missing key leaves `val` untouched and sets `found=.false.`, or is
  `ERROR_MAP_KEY_MISSING` (41) without `found`.
- The usage shows `[--set KEY=VALUE [KEY=VALUE...]]`, and the help lists `keys: cfl, nx, ny, t_end`.

### Mutually exclusive arguments (`exclude`)

`exclude` names another switch of the group that cannot be passed together with this one:

<<< @/examples/snippets/exclusive-pair.f90

<<< @/examples/output/exclusive-pair.ansi{ansi}

`exclude` is pairwise and cannot be combined with `required=.true.`: for more than two switches, or to require exactly
one of them, use a [mutually exclusive set](./advanced#mutually-exclusive-sets).

### Environment variables (`envvar`)

`envvar` names a variable supplying the value when the switch is not on the command line (see
[Advanced](./advanced#environment-variables) for the lists, the flags and the generated names):

<<< @/examples/snippets/environment-define.f90

Resolution order, highest priority first: the command line, the environment variable (set and not blank), a
configuration file, the default. A value from the environment satisfies a required argument; `is_passed` stays `.false.`
(it means "on the command line").

### Positional arguments

A positional argument is matched by its position among the values that are not switches (nor switch values), wherever
they appear: `prog in.dat --verbose 2.0` and `prog --verbose in.dat 2.0` are the same.

<<< @/examples/snippets/positional-define.f90

<<< @/examples/snippets/positional-get.f90

<<< @/examples/output/positional.ansi{ansi}

<<< @/examples/output/positional-mixed.ansi{ansi}

<<< @/examples/output/positional-extra.ansi{ansi}

An argument that looks like a switch (a dash followed by anything but a digit or a dot) is never taken as a positional
value, so `-3.5` and `-` are values while `--bogus` is an unknown switch. A value beyond the last position is an unknown
argument.

Restrictions: a positional must use `act='store'` and cannot use `exclude`, `envvar` or `nargs`. Positions may be
declared in any order, but they must be `1..N` without duplicates: a position declared twice is an error at `add`
(`ERROR_POSITION_DUPLICATE`, 105), a missing position (`1` and `3` without `2`) is an error when parsing starts
(`ERROR_POSITION_GAP`, 106).

# Defining Arguments

Arguments are added to the CLI with the `add` method. Before adding arguments you should
initialise the CLI with `init`. Both steps are covered here.

## Initialising the CLI — `cli%init`

```fortran
call cli%init(progname, version, help, description, license, authors, examples, epilog, disable_hv)
```

All arguments are optional. Calling `init` is not strictly required, but it lets you
customise the help and version messages.

| Argument | Type | Default | Purpose |
|---|---|---|---|
| `progname` | `character(*)` | `'program'` | Program name shown in usage line |
| `version` | `character(*)` | `'unknown'` | Version string printed by `--version` |
| `help` | `character(*)` | `'usage: '` | Introductory string before the usage line |
| `description` | `character(*)` | `''` | Detailed program description below usage |
| `license` | `character(*)` | `''` | License note |
| `authors` | `character(*)` | `''` | Author list (accessible as `cli%authors`) |
| `examples` | `character(*), dimension(:)` | not set | Usage examples shown at the end of help |
| `epilog` | `character(*)` | `''` | Message printed after the help |
| `disable_hv` | `logical` | `.false.` | Suppress the automatic `--help`/`--version` flags |
| `standalone` | `logical` | `.true.` | Stop after printing help/version/Markdown; `.false.` makes `parse` return `STATUS_PRINT_H`/`V`/`M` instead (see [Error Codes](./errors#handling-status-codes)) |
| `error_hint` | `logical` | `.true.` | After a failed `parse`, print `Try 'prog --help' for help.` (see [Error Codes](./errors#error-hint)) |
| `no_args_is_help` | `logical` | `.false.` | With no arguments, print the help instead of parsing (`STATUS_NO_ARGS`; exit status 2 in standalone mode) |
| `completion_options` | `logical` | `.false.` | Add `--show-completion [SHELL]` and `--install-completion [SHELL]` to the top level (see [Output](./output#shell-completion-from-the-program)) |
| `usage_on_error` | `character` | `'full'` | What a missing required option prints after its message: the whole help (`'full'`), the usage line (`'usage'`) or nothing (`'none'`); see [Errors](./errors#output-after-an-error) |
| `case_insensitive` | `logical` | `.false.` | Match switches (abbreviations and negations included) and command names in any case: `--MESH` is `--mesh`, `COMPILE` is `compile`. Values and choices keep their case; two switches differing only by case are a consistency error (100). Call `init` before `add` |

> **Note on `examples`:** Fortran requires all elements of a character array to have the
> same length, so pad shorter examples with trailing spaces.

### Full example

```fortran
call cli%init(progname    = 'myapp',                        &
              version     = 'v1.0.0',                       &
              description = 'A toy Fortran program',        &
              license     = 'MIT',                          &
              authors     = 'Jane Doe',                     &
              examples    = ['myapp --input foo.dat        ', &
                             'myapp --input foo.dat -v     ', &
                             'myapp --help                 '], &
              epilog      = 'Report bugs at github.com/…', &
              disable_hv  = .false.)
```

### Public attributes

After `init`, these `command_line_interface` attributes are accessible directly:

```fortran
cli%progname      ! program name
cli%version       ! version string
cli%description   ! description string
cli%license       ! license string
cli%authors       ! authors string
cli%epilog        ! epilog string
cli%error         ! last error code
cli%error_message ! last error message
```

### Automatic `--help` and `--version` flags

FLAP automatically appends two special arguments to every CLI:

- `--help` / `-h` — prints the usage message
- `--version` / `-v` — prints the version string

Your own switches take precedence: if you define `--version`, the builtin is not added; if you only take its
abbreviation (`-v` for verbosity), the builtin keeps just `--version`. The same holds for `--help`/`-h` and
`--markdown`/`-md`. To suppress them, use `disable_hv=.true.`.

---

## Adding arguments — `cli%add`

```fortran
call cli%add(switch, switch_ab, switch_neg, help, required, act, def, &
             nargs, choices, case_sensitive, map, map_keys,   &
             metavar,                                         &
             exclude, envvar,                                 &
             positional, position, hidden,                &
             must_exist, readable, writable, allow_dash,  &
             deprecated, min, max, min_open, max_open,    &
             clamp,                                       &
             group, group_index, pref, error)
```

All arguments are optional except that either `switch` (for named arguments) or
`position` (for positional arguments) must be provided.

### Core parameters

| Argument | Type | Default | Purpose |
|---|---|---|---|
| `switch` | `character(*)` | — | Long switch name, e.g. `'--output'` |
| `switch_ab` | `character(*)` | same as `switch` | Abbreviated switch, e.g. `'-o'` |
| `switch_neg` | `character(*)` | not set | Negation of a flag, e.g. `'--no-restart'` (see [Flag pairs](#flag-pairs-switch-neg)) |
| `metavar` | `character(*)` | `'value'` | Placeholder of the value in the usage, help, man page and Markdown, e.g. `'FILE'` (see [Metavar](#metavar)) |
| `help` | `character(*)` | `'Undocumented argument'` | Description shown in help |
| `required` | `logical` | `.false.` | If `.true.`, the argument must be supplied |
| `act` | `character(*)` | `'store'` | Action (see below) |
| `def` | `character(*)` | not set | Default value as a string |
| `error` | `integer` | — | Error code on return (0 = success) |

> **Rule:** every optional argument (`required=.false.`) **must** have a default value
> (`def=…`), even if it is an empty string `def=''`.

### Actions (`act`)

| Action | Effect |
|---|---|
| `'store'` | Stores the value(s) passed after the switch |
| `'store*'` | Stores a single optional value; the default is used when the switch is present but no value follows |
| `'store_true'` | Stores `.true.` when the switch appears (boolean flag) |
| `'store_false'` | Stores `.false.` when the switch appears |
| `'count'` | Counts the occurrences of the switch (repeatable, no value): `-v -v`, `-v --verbose` or the compact `-vv` give 2; read it into any integer. `def` defaults to `'0'` |
| `'alternate'` | An auxiliary action of the program (`--list-models`), a flag: when passed, `parse` returns `STATUS_ALTERNATE` and skips the value validation (see [Advanced](./advanced#alternate-actions)) |
| `'config'` | Names the configuration file: a value like `'store'`, resolved command line > environment > default, then the file is read (see [Advanced](./advanced#configuration-files)) |
| `'append'` | Collects one value per occurrence (repeatable): `-I src -I lib` or `--include=src -I lib` give `[src, lib]`; read it with `get_varying` (or `get` into an array of the right size). Passed values **replace** the default (`def='a b'` is the list used only when the option is absent) |
| `'print_help'` | Prints the help message and exits |
| `'print_version'` | Prints the version and exits |

Actions are case-insensitive.

```fortran
! boolean flag: present → .true., absent → .false.
call cli%add(switch='--verbose', switch_ab='-v', &
             help='Enable verbose output',       &
             required=.false., act='store_true', def='.false.', error=error)

! counter: -v -v, -vv or --verbose --verbose → 2, absent → 0
call cli%add(switch='--verbose', switch_ab='-v', &
             help='Verbosity (repeatable)',      &
             required=.false., act='count', error=error)

! collector: -I src -I lib → ['src', 'lib'], absent → ['.']
call cli%add(switch='--include', switch_ab='-I', &
             help='Include directory (repeatable)', &
             required=.false., act='append', def='.', error=error)

! optional value: present without a value → default used
call cli%add(switch='--format', &
             help='Output format (default: text)',      &
             required=.false., act='store*', def='text', error=error)
```

### Metavar

`metavar` names the value in the usage, the help, the man page and the Markdown output, instead of the generic `value`:

```fortran
call cli%add(switch='--mesh',   help='Mesh file', required=.true.,  act='store', metavar='FILE', error=error)
call cli%add(switch='--cfl',    help='CFL',       required=.false., act='store', def='0.8', metavar='CFL', error=error)
call cli%add(switch='--fields', help='Fields',    required=.false., act='store', nargs='+', def='u', metavar='NAME', &
             error=error)
```

```text
usage: solver --mesh FILE [--cfl CFL] [--fields NAME#1 [NAME#2 NAME#3...]] ...
```

A list numbers it (`NAME#1 ...`); for a map it replaces `KEY=VALUE`; a flag ignores it (it takes no value); a positional
shows it alone. Without `metavar` the outputs are unchanged. The bash completion never shows placeholders.

### Flag pairs (`switch_neg`)

A `store_true` or `store_false` flag can have a negation, which sets the opposite value:

```fortran
call cli%add(switch='--restart', switch_ab='-r', switch_neg='--no-restart', &
             help='Restart from the checkpoint',                            &
             required=.false., act='store_true', def='.true.', error=error)
```

| Command line | `restart` |
|---|---|
| (absent) | the default, or the environment or configuration value |
| `--restart`, `-r` | `.true.` |
| `--no-restart` | `.false.` |
| `--restart --no-restart` | `.false.`: the last one wins |
| `--no-restart --restart` | `.true.` |
| `--restart --restart` | `ERROR_DUPLICATED_CLAS` (23) |

The last spelling wins, as in click and GNU tools, so a preset can be overridden: with `alias run='solver --restart'`,
`run --no-restart` does not restart. Each spelling may appear once. A `store_false` flag is the mirror image
(`--no-color`/`--color`). The help shows the pair as `[--restart/--no-restart]`; the bash completion offers both names.
`get` and `is_passed` accept either name. The negation belongs to a named scalar flag and differs from its switch names:
otherwise `add` reports `ERROR_SWITCH_NEG_INCONSISTENT` (36); a negation equal to the switch of another argument is a
group consistency error (100).

### Restricted choices (`choices`)

Pass a comma-separated list of allowed values. FLAP validates the supplied value at
`get` time and reports an error if it is not in the list.

```fortran
call cli%add(switch='--level', switch_ab='-l',            &
             help='Verbosity level',                      &
             required=.false., act='store', def='1',      &
             choices='1,3,5', error=error)
```

```shell
$ ./myapp --level 2
myapp: error: the value "2" is not in the choices list (1,3,5)
```

For a list-valued argument (`nargs`), every value is checked, by both `get` and `get_varying`, and so is the default
when it is used. `choices` cannot be used with logical values.

With `case_sensitive=.false.`, a `character` value matches its choice in any case and `get` returns the **declared
spelling**: with `choices='weno5,muscl'`, `--scheme WENO5` gives `weno5`. Numeric choices are unaffected.

### List-valued arguments (`nargs`)

Use `nargs` to consume multiple values from a single switch.

| `nargs` value | Meaning | Retrieval method |
|---|---|---|
| `'N'` (positive integer) | Exactly N values, fixed at compile time: the switch takes the next N values, and a further value is the next argument (a positional, or an unknown argument) | `cli%get` with an allocated array |
| `'+'` | One or more values, length known at runtime | `cli%get_varying` |
| `'*'` | Zero or more values, length known at runtime: the switch alone is an empty list, the default applies only when the switch is absent | `cli%get_varying` |

```fortran
! exactly 3 integers
call cli%add(switch='--coords', switch_ab='-c',    &
             help='X Y Z coordinates',             &
             required=.false., act='store',        &
             nargs='3', def='0 0 0', error=error)

! runtime list of any size
call cli%add(switch='--files', switch_ab='-f', &
             help='Input file list',           &
             required=.false., act='store',    &
             nargs='*', def='', error=error)
```

With `nargs='N'` the default must have exactly N values: `nargs='3', def='0 0'` is a definition error
(`ERROR_DEF_NARGS`). `'+'` and `'*'` accept a default of any length.

### Key=value options (`map`)

With `map=.true.`, a list option takes `KEY=VALUE` pairs, typically to override input-deck parameters:

```fortran
call cli%add(switch='--set', switch_ab='-s', help='Override input-deck parameters', required=.false., &
             act='store', nargs='+', map=.true., map_keys='cfl,nx,ny,t_end', def='cfl=0.8', error=error)
call cli%parse(error=error)
read(deck_unit, nml=params)                                          ! values from the input deck
call cli%get_map_value(switch='--set', key='cfl', val=cfl, found=found) ! override only if given
call cli%get_map_value(switch='--set', key='nx',  val=nx,  found=found)
```

```console
$ solver --set cfl=0.5 nx=256          # cfl=0.5, nx=256, the others from the deck
$ solver --set cfl=0.5 cfl=0.6         # error: key "cfl" of "--set" given twice!
$ solver --set cfll=0.5                # error: unknown key "cfll" for "--set" (allowed: cfl, nx, ny, t_end)! Did you mean "cfl"?
$ solver --set nx                      # error: "--set" expects KEY=VALUE, got "nx"!
$ solver                               # the default: cfl=0.8
```

- A pair is split at the **first** `=`: `label=a=b` is the key `label` with the value `a=b`; `a=` has an empty value.
- A map is a named `act='store'` option with `nargs` (`'+'`, `'*'` or a number), or `act='append'`
  (`--set a=1 --set b=2`); `--set=a=1` is one pair. Positionals, flags and `choices` are not allowed
  (`ERROR_MAP_INCONSISTENT`, 42).
- `parse` checks the pairs, whatever their source (command line, environment as comma-separated pairs, configuration
  file as blank-separated pairs, default): `ERROR_MAP_FORMAT` (38), `ERROR_MAP_DUPLICATE_KEY` (39), and, with
  `map_keys`, `ERROR_MAP_UNKNOWN_KEY` (40, listing the allowed keys and suggesting the closest). Keys are case-sensitive.
- Passed pairs **replace** the default ones, they are not merged.
- `cli%get_map(switch, keys, values, group, error)` returns all the pairs, in order, into `character(len=...),
  allocatable` arrays. `cli%get_map_value(switch, key, val, found, group, error)` converts one value to the type of `val`
  (any kind `get` supports); a missing key leaves `val` untouched and sets `found=.false.`, or is
  `ERROR_MAP_KEY_MISSING` (41) without `found`. A failed conversion keeps its error code and names the key.
- The usage shows `[--set KEY=VALUE [KEY=VALUE...]]`, and the help lists `keys: cfl, nx, ny, t_end`.

### Mutually exclusive arguments (`exclude`)

Declare that two arguments cannot be used together:

```fortran
call cli%add(switch='--integer_ex', switch_ab='-ie', &
             help='Exclusive integer',               &
             required=.false., act='store', def='-1', error=error)

call cli%add(switch='--integer', switch_ab='-i',  &
             help='Integer (excludes --integer_ex)', &
             required=.false., act='store', def='1', &
             choices='1,3,5', exclude='-ie', error=error)
```

If both are passed, FLAP reports an error automatically. For more than two switches, or to require
exactly one of them, use a [mutually exclusive set](./advanced#mutually-exclusive-sets).

### Environment variable fallback (`envvar`)

```fortran
call cli%add(switch='--token', switch_ab='-t',          &
             help='API token (or set MY_TOKEN env var)', &
             required=.false., act='store', def='',      &
             envvar='MY_TOKEN', error=error)
```

Resolution order (highest priority first):
1. Value passed directly on the command line
2. Value of the environment variable `MY_TOKEN`, when it is set and not blank (also read by the bare switch `-t`)
3. Default value

A value from the environment satisfies a required argument. `is_passed` stays `.false.`: it means "on the command line".

Restrictions: `envvar` is valid for named `act='store'` (lists with `nargs` included), `store_true` and `store_false`
arguments; not for positionals, `store*`, `count` and `append`. A list reads its variable as comma-separated values
(see [Advanced](./advanced#list-values-from-the-environment)). A flag reads its value from the variable: `1/0`, `true/false`, `t/f`, `yes/no`, `y/n`,
`on/off`, in any case; anything else makes `get` fail with `ERROR_CASTING_LOGICAL`.

### Hidden arguments (`hidden`)

```fortran
call cli%add(switch='--debug-internal', &
             help='Internal debug flag', &
             required=.false., act='store_true', def='.false.', &
             hidden=.true., error=error)
```

Hidden arguments are fully functional but do not appear in the help or usage messages.

### Positional arguments

A positional argument is matched by position on the command line rather than by a switch name:

```fortran
call cli%add(positional=.true., position=1,       &
             help='Input filename',               &
             required=.true., act='store', error=error)

call cli%add(positional=.true., position=2,   &
             help='Scaling factor',           &
             required=.false., act='store', def='1.0', error=error)
```

The values that are not switches (nor switch values) are assigned in order: the first one to `position=1`, the second
to `position=2`, and so on, wherever they appear on the command line (`prog in.dat -v 2.0` and `prog -v in.dat 2.0` are
equivalent). An argument that looks like a switch (a dash followed by anything but a digit or a dot) is never taken as a
positional value, so `-3.5` and `-` are values while `--bogus` is an unknown switch. A value beyond the last position is
an unknown argument. Retrieve a positional with `cli%get(position=n, ...)`.

Restrictions: positional arguments cannot use `exclude`, `envvar` or `nargs` (each positional takes one value), and must
use `act='store'`.

Positions may be declared in any order, but they must be `1..N` without duplicates: declaring a position twice is an
error at `add` (`ERROR_POSITION_DUPLICATE`), and a missing position (`1` and `3` without `2`) is an error when parsing
starts (`ERROR_POSITION_GAP`).

# Advanced Features

Where values come from besides the command line (environment variables, configuration files), and the checks FLAP can
run on them (exclusive sets, paths, ranges), plus deprecations, alternate actions and case-insensitive matching.

## Value sources

A value comes from the first source that has one, in this order:

```mermaid
flowchart LR
  CL[command line] --> ENV[environment variable] --> CFG[configuration file] --> DEF[default]
```

The command line always wins; a value from any explicit source (command line, environment, configuration file)
satisfies a required option. `cli%get_source` and `cli%provenance` tell where each value comes from (see
[Parsing](./parsing#where-a-value-comes-from)).

## Environment variables

`envvar` names the variable of an option; `init(auto_envvar_prefix=...)` generates one for every option:

<<< @/examples/snippets/environment-define.f90

<<< @/examples/output/environment-env.ansi{ansi}

<<< @/examples/output/environment-both.ansi{ansi}

- A variable counts when it is set and not blank; the bare switch (`--token` alone) reads it too.
- `envvar` is valid for named `store` options (lists included), `store_true` and `store_false`; not for positionals,
  `store*`, `count` and `append` (`ERROR_ENVVAR_NOT_STORE`, 17).
- A flag reads `1/0`, `true/false`, `t/f`, `yes/no`, `y/n`, `on/off`, in any case; anything else makes `get` fail with
  `ERROR_CASTING_LOGICAL` (10).
- The help shows the name of the variable of each option.

<<< @/examples/output/environment-help.ansi{ansi}

### Lists from the environment

A list option (`nargs`) reads its variable as one line of **comma-separated values**, not blank-separated as on the
command line and in `def=`: an environment value is a single shell word, where commas are the convention.

<<< @/examples/output/environment-list.ansi{ansi}

| Variable | List |
|---|---|
| `WORKERS='1,99'` | `1`, `99` |
| `WORKERS='1, 2 , 3'` | `1`, `2`, `3` (blanks around a value trimmed) |
| `FILES='"my file.h5", other.h5'` | `my file.h5`, `other.h5` (a quoted value may hold commas and blanks) |
| `TITLES='"say ""hi""",x'` | `say "hi"`, `x` (`""` inside quotes is a `"`) |
| `WORKERS='1,,3'` | `1`, empty, `3` (a numeric `get` then fails its cast) |
| `WORKERS='1,"99'` | error `ERROR_ENVVAR_CSV` (43): unterminated quote |

A scalar option takes its variable verbatim, commas included. The number of values of `nargs='N'` is checked by `get`.

### Generated variable names

With `init(auto_envvar_prefix='SOLVER')`, every named `store`, `store_true` or `store_false` option added without an
`envvar` gets one, `PREFIX[_COMMAND]_NAME` in upper case, NAME being the long switch without its dashes and `-` becoming
`_`: `--mesh-file` is `SOLVER_MESH_FILE`, the `--format` of the command `post` is `SOLVER_POST_FORMAT`. An explicit
`envvar=` wins over the generated name; positionals, `store*`, `count` and `append` get none. `init` must come before
the `add` calls.

### Ignoring the environment

For reproducible runs (a batch job whose environment must not leak in, tests, CI sandboxes), `init(ignore_env=.true.)`
turns every environment lookup off. The `envvar` definitions are unchanged and still shown in the help:

<<< @/examples/snippets/ignore_env-define.f90

<<< @/examples/output/ignore_env.ansi{ansi}

## Configuration files

`cli%set_config(file, required, error)` names an INI file supplying values below the environment and above the
defaults; an option with `act='config'` lets the user choose the file:

<<< @/examples/snippets/config-define.f90

<<< @/examples/files/solver.ini{ini}

<<< @/examples/output/config.ansi{ansi}

<<< @/examples/output/config-override.ansi{ansi}

- Keys are the long switches without the dashes; keys before any section belong to the top level, a `[section]` holds
  the options of that command.
- A value is the text after `=`, blanks trimmed; one pair of quotes (`'` or `"`) is stripped, and a quoted value keeps its
  `#` and `;`. An inline comment starts at a `#` or `;` preceded by a blank. An empty value counts as unset.
- A list (`nargs`) is blank separated, as in `def=`; a flag reads `yes/no`, `on/off`, `1/0`, `true/false`, ...
- An unknown key or section, a key naming an option that takes no value (`count`, `append`, `store*`), or a line that is
  not `key = value`, `[section]` or a comment is `ERROR_CONFIG_UNKNOWN_KEY` (1007), naming the line; with
  `init(ignore_unknown_clas=.true.)` such lines are ignored. The last of repeated keys wins.
- The file is the one named on the command line (`--config my.ini`), else in the environment variable of the `config`
  option, else the one of `set_config`, else the default of the `config` option. A file named on the command line or in
  the environment must exist (`ERROR_CONFIG_NOT_FOUND`, 1006); a missing default is skipped, unless
  `set_config(..., required=.true.)`. `get` of the `config` option returns the file name.
- The file is read by `parse` after `--help`/`--version`, so a broken file never blocks the help. A value from it
  satisfies a required option and is checked against `choices` and ranges by `get`.

<<< @/examples/output/config-missing.ansi{ansi}

## Mutually exclusive sets

`cli%set_mutually_exclusive_switches(switches, required, group, pref, error)` declares a set of switches of which **at
most one** may be given; with `required=.true.`, **exactly one**. This is argparse's `add_mutually_exclusive_group`, and
the recommended mechanism over the pairwise `exclude`:

<<< @/examples/snippets/exclusive-sets.f90

<<< @/examples/output/exclusive.ansi{ansi}

<<< @/examples/output/exclusive-both.ansi{ansi}

<<< @/examples/output/exclusive-none.ansi{ansi}

The usage shows the sets in docopt notation, `(a | b)` for a required set and `[a | b]` otherwise. Rules:

- the members are comma separated, named by switch or abbreviation, and must be **already added** to the group (pass
  `group=` for the options of a command); a set of a command is checked only when the command is called;
- a member cannot be individually `required`, and a switch belongs to at most one set;
- every **explicit** value counts, from the command line, the environment or a configuration file; a default neither
  satisfies a required set nor violates a set. When a member is on the command line, the environment and configuration
  values of the other members fall back to their defaults: the command line wins (a variable set for a batch job never
  makes a command line alternative a violation);
- the sets are checked after help/version and after the required options, as the last validation;
- an invalid set is not added: the call returns `ERROR_M_EXCLUDE_SET_DEFINITION` (104), and `parse` returns the same
  error, so a wrong definition cannot go unnoticed.

## Path checks

`must_exist`, `readable`, `writable` and `allow_dash` make `parse` check a file name, whatever its source (command line,
environment, configuration file or default):

<<< @/examples/snippets/paths-define.f90

<<< @/examples/output/paths-missing.ansi{ansi}

| Keyword | Check |
|---|---|
| `must_exist` | the file exists (`ERROR_PATH_NOT_FOUND`, 33) |
| `readable` | it exists and opens for reading (`ERROR_PATH_NOT_READABLE`, 34, with the reason given by the system) |
| `writable` | if it exists, it opens for writing, nothing written (`ERROR_PATH_NOT_WRITABLE`, 35); a missing file passes and is not created |
| `allow_dash` | `-` passes every check (your program maps it to standard input/output); otherwise `-` is a file name |

- Every item of a list is checked; an empty value (`def=''`) is not checked. The options of a command are checked only
  when the command is called.
- Only for options taking a value (`store`, `store*`, `append`): elsewhere the keywords are `ERROR_PATH_INCONSISTENT`
  (49).
- Standard Fortran leaves the existence of a **directory** to the compiler: with gfortran a directory exists and opens for
  reading, with Intel ifx it does not exist.
- **nvfortran 26.5:** opening a read-only file for writing succeeds (the error comes at the first write), so `writable`
  does not detect a read-only file with that compiler.

## Numeric ranges

`min=` and `max=` (strings, like `def=`) give a numeric option a range; `min_open=.true.`/`max_open=.true.` exclude the
bound, `clamp=.true.` replaces an out-of-range value with the bound instead of failing:

<<< @/examples/snippets/ranges-define.f90

<<< @/examples/output/ranges.ansi{ansi}

<<< @/examples/output/ranges-error.ansi{ansi}

- The value is checked by `get`, after its conversion, in the kind of your variable, whatever its source; every element
  of a list is checked. `ERROR_OUT_OF_RANGE` is 31.
- With `clamp`, an open integer bound clamps to the next integer inside (`bound + 1` / `bound - 1`); a real cannot be
  clamped to an open bound: `get` reports `ERROR_RANGE_DEFINITION` (30) when it would have to.
- An invalid range (a bound that is not a number, `min > max`, an empty open interval, a range on a flag) is
  `ERROR_RANGE_DEFINITION` (30) at `add`; `get` into a `character` or `logical` is `ERROR_RANGE_TYPE` (32).
- The help shows it: `range (0, 1]`.

## Deprecated options and commands

`add(..., deprecated='message')` and `add_group(..., deprecated='message')` mark an option or a command as deprecated
(`deprecated=''`: without a message). Using it is **not** an error: `parse` prints a warning on the error unit and goes
on.

<<< @/examples/snippets/deprecated-define.f90

<<< @/examples/output/deprecated.ansi{ansi}

- An option warns when its value comes from the command line or from its environment variable, not when it comes from
  a configuration file or its default (as in click); a command warns when it is called.
- The help marks them: `Grid file (DEPRECATED: use --mesh instead)`.
- A required option cannot be deprecated: `ERROR_DEPRECATED_REQUIRED` (44).

## Alternate actions

An option with `act='alternate'` is an auxiliary action of the program (`--list-models`, `--dump-config`), not an input
value: when it is passed, `parse` returns `STATUS_ALTERNATE` (also in standalone mode: FLAP never stops on it) and
**skips the value validation**, so it works even without the required options. The program dispatches on `is_passed`:

<<< @/examples/snippets/alternate-define.f90

<<< @/examples/snippets/alternate-dispatch.f90

<<< @/examples/output/alternate.ansi{ansi}

- Skipped: required options, mutually exclusive sets, `exclude=` pairs, exclusive commands, path checks, unknown
  configuration keys and invalid environment lists. Still reported: syntax errors (an unknown or repeated switch);
  `--help`, `--version` and `--markdown` come first. Deprecation warnings are still printed.
- `get` works as usual after it (a value out of `choices` is still reported by `get`).
- An alternate is a flag: `nargs`, `envvar`, `choices`, `exclude`, `required` and `positional` are
  `ERROR_ALTERNATE_INCONSISTENT` (37). The usage shows it as `[--list-models]`.

## Case-insensitive matching

`init(case_insensitive=.true.)` matches switches (abbreviations and negations included) and command names in any case;
values keep their case (for choices in any case, see `case_sensitive=.false.` in
[Defining Arguments](./arguments#restricted-choices-choices)):

<<< @/examples/snippets/case_insensitive-define.f90

<<< @/examples/output/case_insensitive.ansi{ansi}

Two switches of a group differing only by case are then a consistency error (100). The "did you mean" suggestions
compare in any case too.

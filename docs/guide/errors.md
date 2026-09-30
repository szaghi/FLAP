# Error Codes

Every FLAP method that can fail accepts an optional `error` integer argument, and prints its message on the error unit
(standard error unless `init(error_lun=...)`). FLAP never stops the program on an error: the program decides.

```fortran
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.   ! the message is already printed; nvfortran: call exit(1)
```

## Code table

Every code is available as a named constant from the `flap` module, so programs can test for a specific
condition without hard-coding numbers:

```fortran
use flap, only : command_line_interface, ERROR_UNKNOWN, STATUS_PRINT_H
```

Negative values are **statuses** (FLAP did what was asked and the program should usually exit cleanly);
positive values are **errors**. Existing values never change.

| Code | Constant | Meaning | Typical cause |
|---:|---|---|---|
| `-8` | `STATUS_PRINT_MAN` | Man page saved | `--man` was passed (`init(man_option=.true.)`); in standalone mode the program ends with exit status 0 |
| `-7` | `STATUS_INSTALL_COMPLETION` | Completion script installed | `--install-completion` was passed (`init(completion_options=.true.)`); in standalone mode the program ends with exit status 0 |
| `-6` | `STATUS_SHOW_COMPLETION` | Completion script printed | `--show-completion` was passed; in standalone mode the program ends with exit status 0 |
| `-5` | `STATUS_NO_ARGS` | Help printed, no arguments | `init(no_args_is_help=.true.)` and no argument passed (or a command with `no_args_is_help` invoked alone); in standalone mode the program ends with exit status 2 |
| `-4` | `STATUS_ALTERNATE` | An alternate action was passed | An option with `act='alternate'` (e.g. `--list-models`): value validation skipped, dispatch on `is_passed`; returned also in standalone mode |
| `-3` | `STATUS_PRINT_M` | Help written as Markdown | `--markdown` was passed; not a real error |
| `-2` | `STATUS_PRINT_H` | Help printed | `--help` / `-h` was passed; not a real error |
| `-1` | `STATUS_PRINT_V` | Version printed | `--version` / `-v` was passed; not a real error |
| `0` | | Success | No error |
| `1` | `ERROR_OPTIONAL_NO_DEF` | Missing default for optional argument | Added `required=.false.` but omitted `def=` |
| `2` | `ERROR_REQUIRED_M_EXCLUDE` | Required argument cannot use `exclude` | `required=.true.` combined with `exclude=` |
| `3` | `ERROR_POSITIONAL_M_EXCLUDE` | Positional argument cannot use `exclude` | `positional=.true.` combined with `exclude=` |
| `4` | `ERROR_NAMED_NO_NAME` | Named argument has no switch | Non-positional `add` called without `switch=` |
| `5` | `ERROR_POSITIONAL_NO_POSITION` | Positional argument has no position | `positional=.true.` without `position=` |
| `6` | `ERROR_POSITIONAL_NO_STORE` | Positional argument must use `act='store'` | Incompatible action for a positional CLA |
| `7` | `ERROR_NOT_IN_CHOICES` | Value not in `choices` list | User supplied a value outside the allowed set |
| `8` | `ERROR_MISSING_REQUIRED` | Required argument missing | A `required=.true.` argument was not passed |
| `9` | `ERROR_M_EXCLUDE` | Two mutually exclusive arguments both passed | Both sides of an `exclude=` pair were given |
| `10` | `ERROR_CASTING_LOGICAL` | Cast to `logical` failed | CLA value string cannot be parsed as logical |
| `11` | `ERROR_CHOICES_LOGICAL` | `choices` not allowed for logical type | `choices=` used with a boolean argument |
| `12` | `ERROR_NO_LIST` | Argument is not list-valued | `get` used with an array on a scalar argument |
| `13` | `ERROR_NARGS_INSUFFICIENT` | Insufficient list arguments | `nargs='N'` but fewer than N values were passed |
| `14` | `ERROR_VALUE_MISSING` | Missing value | A named argument was passed but no value followed |
| `15` | `ERROR_UNKNOWN` | Unknown switch | An unrecognised switch (or argument) was passed on the command line; the message suggests the closest names (see [Did you mean](#did-you-mean)) |
| `16` | `ERROR_ENVVAR_POSITIONAL` | `envvar` not allowed for positional | `envvar=` combined with `positional=.true.` |
| `17` | `ERROR_ENVVAR_NOT_STORE` | `envvar` requires `act='store'`, `store_true` or `store_false` | Environment variable used with an incompatible action (`store*`, `count`, `append`, ...) |
| `18` | `ERROR_ENVVAR_NARGS` | `envvar` not allowed for list-valued | No longer raised: lists accept an `envvar` (comma-separated values) |
| `19` | `ERROR_STORE_STAR_POSITIONAL` | `act='store*'` not allowed for positional | Incompatible combination |
| `20` | `ERROR_STORE_STAR_NARGS` | `act='store*'` not allowed for list-valued | Incompatible combination |
| `21` | `ERROR_STORE_STAR_ENVVAR` | `act='store*'` not allowed with `envvar` | Incompatible combination |
| `22` | `ERROR_ACTION_UNKNOWN` | Unknown action | `act=` set to an unrecognised string |
| `23` | `ERROR_DUPLICATED_CLAS` | Argument passed more than once | The same switch appears twice on the command line |
| `24` | `ERROR_MISSING_REQUIRED_VAL` | Required value not passed | A switch that needs a value got none |
| `25` | `ERROR_INLINE_VALUE_NOT_ALLOWED` | Inline value for a flag | `--flag=yes` on an option that takes no value |
| `26` | `ERROR_INLINE_VALUE_NARGS` | Inline value for a list | `--list=1` on an option with `nargs`: pass the values after the switch |
| `27` | `ERROR_COUNT_INCONSISTENT` | Invalid count | A `count` option that is positional or has `nargs`, `envvar` or `choices` |
| `28` | `ERROR_APPEND_INCONSISTENT` | Invalid append | An `append` option that is positional or has `nargs` or `envvar` |
| `29` | `ERROR_APPEND_SCALAR_GET` | Scalar get of an append | An `append` option holds a list: read it with `get_varying` or into an array |
| `30` | `ERROR_RANGE_DEFINITION` | Invalid range | A non-numeric bound, `min > max`, an empty open interval, a range on a flag; or `get` of a real that would clamp to an open bound |
| `31` | `ERROR_OUT_OF_RANGE` | Value out of range | `get` of a value outside `min`/`max` (without `clamp`) |
| `32` | `ERROR_RANGE_TYPE` | Range on a non-numeric get | `get` into a `character` or `logical` of an option with a range |
| `33` | `ERROR_PATH_NOT_FOUND` | Path does not exist | `must_exist=`/`readable=` and the file is missing |
| `34` | `ERROR_PATH_NOT_READABLE` | Path not readable | `readable=` and the file cannot be opened for reading (the message gives the reason) |
| `35` | `ERROR_PATH_NOT_WRITABLE` | Path not writable | `writable=` and the existing file cannot be opened for writing |
| `36` | `ERROR_SWITCH_NEG_INCONSISTENT` | Invalid flag negation | `switch_neg=` on an argument that is not a named `store_true`/`store_false` flag without `nargs`, blank, or equal to its own switch names |
| `37` | `ERROR_ALTERNATE_INCONSISTENT` | Invalid alternate action | `act='alternate'` with `nargs`, `envvar`, `choices`, `exclude`, `required=.true.` or `positional` |
| `38` | `ERROR_MAP_FORMAT` | Map item not `KEY=VALUE` | A map pair without `=` or with an empty key (command line, environment, configuration or default) |
| `39` | `ERROR_MAP_DUPLICATE_KEY` | Map key repeated | The same key twice in a map |
| `40` | `ERROR_MAP_UNKNOWN_KEY` | Map key not allowed | A key outside `map_keys`; the message lists the allowed keys and suggests the closest |
| `41` | `ERROR_MAP_KEY_MISSING` | Map key not given | `get_map_value` of a missing key without `found=` |
| `42` | `ERROR_MAP_INCONSISTENT` | Invalid map | `map=.true.` on a positional, a flag, a scalar `store` or with `choices`; `map_keys` without `map`; `get_map` of an option that is not a map |
| `43` | `ERROR_ENVVAR_CSV` | Unterminated quote in a list from the environment | `WORKERS='1,"99'` for an option with `nargs` and `envvar='WORKERS'` |
| `44` | `ERROR_DEPRECATED_REQUIRED` | A required option cannot be deprecated | `deprecated=` combined with `required=.true.` |
| `45` | `ERROR_POSITIONAL_NARGS` | `nargs` on a positional argument | Positionals take one value each: use a named list option |
| `46` | `ERROR_UNSUPPORTED_TYPE` | Unsupported variable type | `get` into a type FLAP cannot fill (e.g. `complex`, or a non-logical for a flag) |
| `47` | `ERROR_LIST_SIZE` | List size differs from the array size | `get` into a fixed-size array with more or fewer elements than the values: use an array of the right size, or `get_varying` |
| `48` | `ERROR_DEF_NARGS` | Default count differs from `nargs` | `nargs='N'` with a default of another number of values: give the default N values |
| `49` | `ERROR_PATH_INCONSISTENT` | Path checks on an option without value | `must_exist`/`readable`/`writable`/`allow_dash` on a flag, `count`, ... |
| `100` | `ERROR_GROUP_CONSISTENCY` | Group (command) consistency broken | Two arguments of a group share a switch |
| `101` | `ERROR_GROUP_M_EXCLUDE` | Two mutually exclusive groups both passed | Both sides of `set_mutually_exclusive_groups` given |
| `102` | `ERROR_M_EXCLUDE_SET` | Two members of a mutually exclusive set passed | `--mesh m --restart r` with `set_mutually_exclusive_switches(switches='--mesh,--restart')` |
| `103` | `ERROR_M_EXCLUDE_SET_REQUIRED` | No member of a required set passed | None of the switches of a set with `required=.true.` given |
| `104` | `ERROR_M_EXCLUDE_SET_DEFINITION` | Invalid mutually exclusive set | Fewer than two switches, an undefined, repeated or `required` member, or a switch already in a set (returned by `set_mutually_exclusive_switches`, then by `parse`) |
| `105` | `ERROR_POSITION_DUPLICATE` | Position declared twice | Two positionals of a group (command) with the same `position` (raised by `add`) |
| `106` | `ERROR_POSITION_GAP` | Missing position | Positions are not `1..N`, e.g. `1` and `3` without `2` (raised when parsing starts) |
| `1000` | `ERROR_MISSING_CLA` | Argument not found in CLI | `get` or `is_passed` called for an undefined switch |
| `1001` | `ERROR_MISSING_GROUP` | Group not found in CLI | `get` or `run_command` called for an undefined group |
| `1002` | `ERROR_MISSING_SELECTION_CLA` | No argument selected | `get` called with neither `switch=` nor `position=` |
| `1003` | `ERROR_TOO_FEW_CLAS` | Insufficient arguments for CLI | Reserved: not raised by the current version |
| `1004` | `ERROR_UNKNOWN_CLAS_IGNORED` | Unknown arguments ignored | `init(ignore_unknown_clas=.true.)` and an unknown switch was passed |
| `1005` | `ERROR_USER` | Application error | Returned by `cli%raise_error` (see below) |
| `1006` | `ERROR_CONFIG_NOT_FOUND` | Configuration file not found | `set_config(file=..., required=.true.)` and the file is missing (or cannot be read) |
| `1007` | `ERROR_CONFIG_UNKNOWN_KEY` | Configuration file: unknown key | An unknown key or section, a key of an option taking no value, or a malformed line (the message names the line) |
| `1008` | `ERROR_GROUP_ALIAS` | Invalid command alias | `add_group(aliases=...)` with an alias equal to a command name or another alias, repeated, blank or equal to its command, or a command name equal to an alias; `parse` then fails too |
| `1009` | `ERROR_COPY_POSITIONAL` | Positional in `copy_options` | `copy_options(switches=...)` names a positional argument: only named options are copied |
| `1010` | `ERROR_COMPLETION_SHELL` | Unknown completion shell | `--show-completion`/`--install-completion` with a shell other than bash, zsh, fish, powershell, or none given and `$SHELL` unset; `--install-completion powershell` (install it by hand) |
| `1011` | `ERROR_COMPLETION_INSTALL` | Completion not installed | `$HOME` unset, or the script or the rc file cannot be written (the message carries the I/O error; for fish, `~/.config/fish` must exist) |
| `1012` | `ERROR_ARGUMENT_RETRIEVAL` | A command line argument cannot be read | `get_command_argument` failed (processor error; not expected in practice) |
| `1013` | `ERROR_COMMAND_REPEATED` | A command passed more than once | `prog commit -m x commit`, or a command and one of its aliases; reported before `--help` |
| `1014` | `ERROR_USAGE_ON_ERROR` | Invalid `usage_on_error` | `init(usage_on_error=...)` other than `full`, `usage`, `none` (any case); reported by `parse` |
| `2001` | `ERROR_MENU_INVALID` | Invalid menu answer | Not one of the numbers shown, an empty field, or unreadable (see [Interactive Menus](./menu#errors)) |
| `2002` | `ERROR_MENU_TOO_MANY` | Too many menu answers | Several answers to a single-choice menu |
| `2003` | `ERROR_MENU_DUPLICATE` | Duplicate menu answer | The same option chosen twice with multiple selection |
| `2004` | `ERROR_MENU_NO_RESPONSE` | Empty menu answer | The user just pressed Enter, and the menu has no default option |
| `2005` | `ERROR_MENU_EOF` | End of input in a menu | Standard input at its end (`/dev/null`, a batch job): no answer can come |
| `2006` | `ERROR_MENU_DEFINITION` | Invalid menu | `run` on a menu without options, `add_option` with an empty text or a second default (single choice), `init(tries=)` below 1 or `init(separator='')`, the scalar `run(choice)` on a menu with multiple selection, `yes_no(default=)` other than y or n |

The first two group codes are named `ERROR_GROUP_*` in the `flap` module; inside the group module they are
`ERROR_CONSISTENCY` and `ERROR_M_EXCLUDE`, which would clash with the argument-level `ERROR_M_EXCLUDE` (`9`).

## Handling status codes

Negative codes mean that FLAP did what the user asked (printed the help, saved the man page, ...). By default `parse`
ends the program itself right after, with exit status 0 (2 for `STATUS_NO_ARGS`), so these statuses are not returned
to your code; `STATUS_ALTERNATE` is always returned. With `init(standalone=.false.)` `parse` **returns** every status
instead: the program can clean up first (close files, call `MPI_Finalize`), and the help can be tested in-process.

<<< @/examples/snippets/statuses-define.f90

<<< @/examples/snippets/statuses-dispatch.f90

<<< @/examples/output/statuses.ansi{ansi}

When several of them are passed, one wins, in this order: a syntax error anywhere on the command line (an unknown or
duplicated switch, a missing value, a repeated command) is returned first, then help, version, Markdown, man page and
completion. `--version --help` prints the help; `--help compile --bogus` reports the unknown switch.

## Reporting application errors

Checks that only your program can do (*`--nx` must be even*, *`--t-end` must exceed `--t-start`*) can be reported
in FLAP's own style (program name, error colour, error unit) with `raise_error`:

```fortran
call cli%get(switch='--nx', val=nx, error=error)
if (mod(nx, 2) /= 0) error = cli%raise_error('must be even', switch='--nx')
if (error /= 0) stop 1
```

<<< @/examples/snippets/raise_error-check.f90

<<< @/examples/output/raise_error.ansi{ansi}

It returns `ERROR_USER` (1005, and sets `cli%error`) and never stops: the program decides what to do. The help follows
the message unless `show_usage=.false.` (the whole help: `init(usage_on_error=...)` does not apply to it); with
`group='post'` it is the help of that command (an undefined group returns `ERROR_MISSING_GROUP` and prints nothing). It
works before or after `parse`.

## Error hint

After a failed `parse` FLAP prints one more line to the error unit, pointing to the help (the command is named when
the error is inside one):

<<< @/examples/output/actions-typo.ansi{ansi}

It is printed once, as the last line, only when there is a `--help` to suggest (not with `disable_hv=.true.`), and
never for statuses, ignored unknown arguments or errors raised later by `get` (a value out of its choices or range).
Disable it with `init(error_hint=.false.)`.

## Output after an error

A missing required option (and a required mutually exclusive set with no member given) prints the whole help of its
group (command) after the error message. `init(usage_on_error=...)` chooses what is printed instead:

| Value | Printed after the error message |
|---|---|
| `'full'` (default) | the whole help of the group, as before |
| `'usage'` | the usage line only, the first line of `--help` |
| `'none'` | nothing |

<<< @/examples/snippets/usage_on_error-define.f90

<<< @/examples/output/usage_on_error.ansi{ansi}

With the default `'full'` (the `minimal` program of the [Installation](./install#quick-start) page):

<<< @/examples/output/minimal-error.ansi{ansi}

The error message and the hint line are always printed, and `--help` always prints the whole help. Any other value is
`ERROR_USAGE_ON_ERROR` (1014), returned by `parse`.

## Did you mean

An unknown argument gets up to three suggestions, most similar first, with click's wording:

<<< @/examples/output/actions-typo.ansi{ansi}

<<< @/examples/output/fake_git-typo.ansi{ansi}

With several candidates the message is `(Did you mean one of: "--mass", "--mach"?)`.

The candidates are the visible switches, abbreviations and negations of the command being parsed (hidden switches never),
and, at the top level, for an argument that is not a switch, the command names and aliases. A name is suggested when
its similarity `1 - d/max(len)` is at least 0.6, `d` being the Levenshtein (edit) distance; in any case with
`init(case_insensitive=.true.)`. The name of `--name=value` is the part before `=`.

## Accessing the error message

`command_line_interface` has a public `error_message` attribute that contains a
human-readable description of the last error:

```fortran
call cli%parse(error=error)
if (error /= 0) then
  write(*,'(A)') trim(cli%error_message)
  stop 1
end if
```

# Error Codes

Every FLAP method that can fail accepts an optional `error` integer argument.
Check it after each call to detect problems early.

```fortran
call cli%add(switch='--output', ..., error=error)
if (error /= 0) then
  print '(A,I0)', 'CLI definition error: ', error
  stop
end if
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
| `-5` | `STATUS_NO_ARGS` | Help printed, no arguments | `init(no_args_is_help=.true.)` and no argument passed (or a command with `no_args_is_help` invoked alone); in standalone mode the program ends with exit status 2 |
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
| `15` | `ERROR_UNKNOWN` | Unknown switch | An unrecognised switch was passed on the command line |
| `16` | `ERROR_ENVVAR_POSITIONAL` | `envvar` not allowed for positional | `envvar=` combined with `positional=.true.` |
| `17` | `ERROR_ENVVAR_NOT_STORE` | `envvar` requires `act='store'` | Environment variable used with an incompatible action |
| `18` | `ERROR_ENVVAR_NARGS` | `envvar` not allowed for list-valued | `envvar=` combined with `nargs=` |
| `19` | `ERROR_STORE_STAR_POSITIONAL` | `act='store*'` not allowed for positional | Incompatible combination |
| `20` | `ERROR_STORE_STAR_NARGS` | `act='store*'` not allowed for list-valued | Incompatible combination |
| `21` | `ERROR_STORE_STAR_ENVVAR` | `act='store*'` not allowed with `envvar` | Incompatible combination |
| `22` | `ERROR_ACTION_UNKNOWN` | Unknown action | `act=` set to an unrecognised string |
| `23` | `ERROR_DUPLICATED_CLAS` | Argument passed more than once | The same switch appears twice on the command line |
| `24` | `ERROR_MISSING_REQUIRED_VAL` | Required value not passed | A switch that needs a value got none |
| `25` | `ERROR_INLINE_VALUE_NOT_ALLOWED` | Inline value for a flag | `--flag=yes` on an option that takes no value |
| `26` | `ERROR_INLINE_VALUE_NARGS` | Inline value for a list | `--list=1` on an option with `nargs`: pass the values after the switch |
| `45` | `ERROR_POSITIONAL_NARGS` | `nargs` on a positional argument | Positionals take one value each: use a named list option |
| `46` | `ERROR_UNSUPPORTED_TYPE` | Unsupported variable type | `get` into a type FLAP cannot fill (e.g. `complex`, or a non-logical for a flag) |
| `47` | `ERROR_LIST_SIZE` | List size differs from the array size | `get` into a fixed-size array with more or fewer elements than the values: use an array of the right size, or `get_varying` |
| `48` | `ERROR_DEF_NARGS` | Default count differs from `nargs` | `nargs='N'` with a default of another number of values: give the default N values |
| `100` | `ERROR_GROUP_CONSISTENCY` | Group (command) consistency broken | Two arguments of a group share a switch |
| `101` | `ERROR_GROUP_M_EXCLUDE` | Two mutually exclusive groups both passed | Both sides of `set_mutually_exclusive_groups` given |
| `105` | `ERROR_POSITION_DUPLICATE` | Position declared twice | Two positionals of a group (command) with the same `position` (raised by `add`) |
| `106` | `ERROR_POSITION_GAP` | Missing position | Positions are not `1..N`, e.g. `1` and `3` without `2` (raised when parsing starts) |
| `1000` | `ERROR_MISSING_CLA` | Argument not found in CLI | `get` or `is_passed` called for an undefined switch |
| `1001` | `ERROR_MISSING_GROUP` | Group not found in CLI | `get` or `run_command` called for an undefined group |
| `1002` | `ERROR_MISSING_SELECTION_CLA` | No argument selected | `get` called with neither `switch=` nor `position=` |
| `1003` | `ERROR_TOO_FEW_CLAS` | Insufficient arguments for CLI | Reserved: not raised by the current version |
| `1004` | `ERROR_UNKNOWN_CLAS_IGNORED` | Unknown arguments ignored | `init(ignore_unknown_clas=.true.)` and an unknown switch was passed |
| `1005` | `ERROR_USER` | Application error | Returned by `cli%raise_error` (see below) |
| `1012` | `ERROR_ARGUMENT_RETRIEVAL` | A command line argument cannot be read | `get_command_argument` failed (processor error; not expected in practice) |

The two group codes are named `ERROR_GROUP_*` in the `flap` module; inside the group module they are
`ERROR_CONSISTENCY` and `ERROR_M_EXCLUDE`, which would clash with the argument-level `ERROR_M_EXCLUDE` (`9`).

## Handling status codes

Negative codes mean that FLAP printed help, version or Markdown text. By default `parse` ends the
program itself (`stop`, exit status 0) right after printing, so these statuses are not returned to your
code. With `init(standalone=.false.)` `parse` prints and **returns** the status instead: the program can
clean up first (close files, call `MPI_Finalize`), and help/version can be tested in-process.

```fortran
use flap, only : command_line_interface, STATUS_PRINT_H, STATUS_PRINT_M, STATUS_PRINT_V
...
call cli%init(progname='solver', version='v2.1.0', standalone=.false.)
...
call cli%parse(error=error)
select case (error)
  case (0)
    ! normal execution
  case (STATUS_PRINT_V, STATUS_PRINT_H, STATUS_PRINT_M)
    stop  ! help, version or Markdown was printed: exit cleanly
  case default
    write(*,'(A,I0)') 'Parse error: ', error
    stop 1
end select
```

When several of them are passed, one wins, in this order: a syntax error anywhere on the command line
(an unknown or duplicated switch, a missing value) is returned first, then help, then version, then
Markdown. `--version --help` prints the help; `--help compile --bogus` reports the unknown switch.

## Reporting application errors

Checks that only your program can do (*`--nx` must be even*, *`--t-end` must exceed `--t-start`*) can be reported
in FLAP's own style (program name, error colour, error unit) with `raise_error`:

```fortran
call cli%get(switch='--nx', val=nx, error=error)
if (mod(nx, 2) /= 0) error = cli%raise_error('must be even', switch='--nx')
if (error /= 0) stop 1
```

```text
solver: error: switch "--nx": must be even
usage: solver ...
```

It returns `ERROR_USER` (and sets `cli%error`) and never stops: the program decides what to do. The usage follows the
message unless `show_usage=.false.`; with `group='post'` it is the usage of that command (an undefined group returns
`ERROR_MISSING_GROUP` and prints nothing). It works before or after `parse`.

## Error hint

After a failed `parse` FLAP prints one more line to the error unit, pointing to the help (the command is named when
the error is inside one):

```text
solver: error: switch "--mehs" is unknown!
Try 'solver --help' for help.
```

It is printed once, as the last line, only when there is a `--help` to suggest (not with `disable_hv=.true.`), and
never for statuses, ignored unknown arguments or errors raised later by `get`. Disable it with
`init(error_hint=.false.)`.

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

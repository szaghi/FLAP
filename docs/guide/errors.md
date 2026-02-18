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

| Code | Meaning | Typical cause |
|---:|---|---|
| `-2` | Help printed | `--help` / `-h` was passed — not a real error |
| `-1` | Version printed | `--version` / `-v` was passed — not a real error |
| `0` | Success | No error |
| `1` | Missing default for optional argument | Added `required=.false.` but omitted `def=` |
| `2` | Required argument cannot use `exclude` | `required=.true.` combined with `exclude=` |
| `3` | Positional argument cannot use `exclude` | `positional=.true.` combined with `exclude=` |
| `4` | Named argument has no switch | Non-positional `add` called without `switch=` |
| `5` | Positional argument has no position | `positional=.true.` without `position=` |
| `6` | Positional argument must use `act='store'` | Incompatible action for a positional CLA |
| `7` | Value not in `choices` list | User supplied a value outside the allowed set |
| `8` | Required argument missing | A `required=.true.` argument was not passed |
| `9` | Two mutually exclusive arguments both passed | Both sides of an `exclude=` pair were given |
| `10` | Cast to `logical` failed | CLA value string cannot be parsed as logical |
| `11` | `choices` not allowed for logical type | `choices=` used with a boolean argument |
| `12` | Argument is not list-valued | `get` used with an array on a scalar argument |
| `13` | Insufficient list arguments | `nargs='N'` but fewer than N values were passed |
| `14` | Missing value | A named argument was passed but no value followed |
| `15` | Unknown switch | An unrecognised switch was passed on the command line |
| `16` | `envvar` not allowed for positional | `envvar=` combined with `positional=.true.` |
| `17` | `envvar` requires `act='store'` | Environment variable used with an incompatible action |
| `18` | `envvar` not allowed for list-valued | `envvar=` combined with `nargs=` |
| `19` | `act='store*'` not allowed for positional | Incompatible combination |
| `20` | `act='store*'` not allowed for list-valued | Incompatible combination |
| `21` | `act='store*'` not allowed with `envvar` | Incompatible combination |
| `22` | Unknown action | `act=` set to an unrecognised string |
| `23` | Group (command) consistency broken | Internal group definition error |
| `24` | Two mutually exclusive groups both passed | Both sides of `set_mutually_exclusive_groups` given |
| `25` | CLA not found in CLI | `get` or `is_passed` called for an undefined switch |
| `26` | Group not found in CLI | `get` or `run_command` called for an undefined group |
| `27` | CLA selection failing | Internal retrieval error |
| `28` | Insufficient arguments for CLI | Too few arguments on the command line |

## Handling status codes

Codes `-2` and `-1` indicate that FLAP printed help or version text respectively.
Depending on your program structure you may want to handle these differently from
true errors:

```fortran
call cli%parse(error=error)
select case (error)
  case (0)
    ! normal execution
  case (-1, -2)
    stop  ! help or version was printed — exit cleanly
  case default
    write(*,'(A,I0)') 'Parse error: ', error
    stop 1
end select
```

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

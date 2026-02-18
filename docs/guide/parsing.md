# Parsing & Getting Values

After defining arguments with `add`, the two remaining steps are parsing the command
line and retrieving the values.

## Parsing — `cli%parse`

```fortran
call cli%parse(pref, args, error)
```

| Argument | Type | Purpose |
|---|---|---|
| `pref` | `character(*)`, optional | Prefix string for error messages |
| `args` | `character(*)`, optional | Parse from this string instead of the real command line |
| `error` | `integer`, optional | Error code on return (0 = success) |

```fortran
call cli%parse(error=error)
if (error /= 0) stop
```

During parsing, FLAP:
- reads the actual command line arguments (or `args` if supplied);
- stores all values as strings (leading/trailing spaces stripped);
- flushes default or environment values for arguments that were not passed.

### Explicit call is optional

The `parse` call is optional. The first time you call `get`, FLAP checks the parsed
status and calls `parse` automatically if needed. An explicit call is recommended
only when you want finer control over error handling.

### Testing with a fake command line

Pass `args` to parse a string instead of the real `argv`. This is useful for unit tests:

```fortran
call cli%parse(args='--level 3 --verbose', error=error)
```

---

## Retrieving values — `cli%get`

```fortran
call cli%get(val, switch, position, group, args, pref, error)
```

| Argument | Type | Purpose |
|---|---|---|
| `val` | `class(*)` or `class(*), dimension(:)` | Variable to fill (type inferred automatically) |
| `switch` | `character(*)`, optional | Switch name (long or abbreviated) |
| `position` | `integer`, optional | Position for positional arguments |
| `group` | `character(*)`, optional | Group (subcommand) name |
| `args` | `character(*)`, optional | Parse from string (passed to `parse` if not yet called) |
| `pref` | `character(*)`, optional | Prefix for error messages |
| `error` | `integer`, optional | Error code on return |

`get` is a generic interface: the type of `val` is determined at the call site, so no
explicit type casting is needed. Supported types: `integer` (any kind), `real` (any kind),
`logical`, and `character`.

### Scalar values

```fortran
character(256) :: filename
integer        :: count
real(8)        :: threshold
logical        :: verbose

call cli%get(switch='--output',    val=filename,  error=error)
call cli%get(switch='-n',          val=count,     error=error)
call cli%get(switch='--threshold', val=threshold, error=error)
call cli%get(switch='--verbose',   val=verbose,   error=error)
```

### Positional arguments

```fortran
real :: scale_factor

call cli%get(position=1, val=scale_factor, error=error)
```

### Fixed-size list arguments (`nargs='N'`)

Pass an allocated or automatic array:

```fortran
integer :: coords(3)

call cli%get(switch='--coords', val=coords, error=error)
```

### Arguments belonging to a subcommand group

```fortran
character(256) :: commit_message

call cli%get(group='commit', switch='-m', val=commit_message, error=error)
```

---

## Runtime-sized lists — `cli%get_varying`

When `nargs='+'` or `nargs='*'` was used in `add`, the list length is unknown at
compile time. Use `get_varying` instead of `get`:

```fortran
call cli%get_varying(val, switch, position, group, args, pref, error)
```

The key difference: `val` is **allocatable** with `intent(OUT)` — it is always
deallocated on entry and reallocated to the exact list size.

```fortran
character(256), allocatable :: files(:)
integer,        allocatable :: ids(:)

call cli%get_varying(switch='--files', val=files, error=error)
call cli%get_varying(switch='--ids',   val=ids,   error=error)

! iterate over results
do i = 1, size(files)
  print '(A)', trim(files(i))
end do
```

> **Note:** `choices` is not supported for `get_varying`.

---

## Checking whether an argument was passed — `cli%is_passed`

```fortran
logical :: was_passed

was_passed = cli%is_passed(switch='--output')
was_passed = cli%is_passed(switch='-o')           ! abbreviated form works too
was_passed = cli%is_passed(position=1)            ! positional
was_passed = cli%is_passed(group='commit', switch='-m')  ! in a group
```

This is useful when you need to distinguish between "the user explicitly supplied the
default value" and "the argument was omitted":

```fortran
if (cli%is_passed(switch='--config')) then
  ! load from user-specified config file
else
  ! use built-in defaults
end if
```

---

## Checking whether an argument is defined — `cli%is_defined`

Queries whether a switch has been **registered** in the CLI (not whether it was passed):

```fortran
logical :: defined

defined = cli%is_defined(switch='--output')
defined = cli%is_defined(switch='-o')           ! abbreviated form
defined = cli%is_defined(position=1)            ! positional
```

Similarly for groups:

```fortran
defined = cli%is_defined_group(group='commit')
```

This is useful in generic code that operates on a CLI object it did not build itself.

---

## Freeing and redefining the CLI — `cli%free`

```fortran
call cli%free()
```

Destroys all internal state of the `command_line_interface` object and resets it to
the default-initialised state. Use this when you need to redefine the CLI from scratch
within the same program execution — for example in a test suite that exercises multiple
CLI configurations.

```fortran
type(command_line_interface) :: cli
integer                      :: error

! first configuration
call cli%init(progname='config-a')
call cli%add(switch='--alpha', ...)
call cli%parse(error=error)
! ... use alpha config ...

! reset and redefine
call cli%free()
call cli%init(progname='config-b')
call cli%add(switch='--beta', ...)
call cli%parse(error=error)
```

---

## Complete parse-and-get example

```fortran
program example
  use flap
  implicit none

  type(command_line_interface) :: cli
  character(256) :: input, output
  integer        :: n
  real(8)        :: tol
  logical        :: verbose
  integer        :: error

  call cli%init(progname    = 'example',                  &
                version     = 'v1.0',                     &
                description = 'Demonstration program',    &
                examples    = ['example -i a.dat -o b.dat', &
                               'example -i a.dat -n 100   '])

  call cli%add(switch='--input',   switch_ab='-i', help='Input file',  &
               required=.true.,  act='store', error=error)
  call cli%add(switch='--output',  switch_ab='-o', help='Output file', &
               required=.false., act='store', def='out.dat', error=error)
  call cli%add(switch='--niter',   switch_ab='-n', help='Iterations',  &
               required=.false., act='store', def='100', error=error)
  call cli%add(switch='--tol',     switch_ab='-t', help='Tolerance',   &
               required=.false., act='store', def='1.0e-6', error=error)
  call cli%add(switch='--verbose', switch_ab='-v', help='Verbose output', &
               required=.false., act='store_true', def='.false.', error=error)

  call cli%parse(error=error)
  if (error /= 0) stop

  call cli%get(switch='-i', val=input,   error=error) ; if (error /= 0) stop
  call cli%get(switch='-o', val=output,  error=error) ; if (error /= 0) stop
  call cli%get(switch='-n', val=n,       error=error) ; if (error /= 0) stop
  call cli%get(switch='-t', val=tol,     error=error) ; if (error /= 0) stop
  call cli%get(switch='-v', val=verbose, error=error) ; if (error /= 0) stop

  if (verbose) print '(A)', 'Input:  ' // trim(input)
  if (verbose) print '(A)', 'Output: ' // trim(output)
end program example
```

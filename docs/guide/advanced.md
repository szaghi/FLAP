# Advanced Features

This page covers the more specialised argument types and CLI features.

## Positional arguments

Positional arguments are matched by their position on the command line rather than by
a switch name. They are defined with `positional=.true.` and a `position` index.

```fortran
! first positional: required input file
call cli%add(positional=.true., position=1,    &
             help='Input data file',           &
             required=.true., act='store', error=error)

! second positional: optional scale factor
call cli%add(positional=.true., position=2,    &
             help='Scale factor',              &
             required=.false., act='store', def='1.0', error=error)
```

Retrieving positional values uses `position=` in `get`:

```fortran
character(256) :: infile
real           :: scale

call cli%get(position=1, val=infile, error=error)
call cli%get(position=2, val=scale,  error=error)
```

Mixed usage (named + positional):

```shell
$ ./myapp input.dat --output result.dat
$ ./myapp 2.5 --output result.dat      ! positional scale factor first
```

**Restrictions:** positional arguments cannot use `exclude`, `envvar`, or any action
other than `store`.

---

## Environment variable fallback

Any named, non-list, `act='store'` argument can fall back to an environment variable:

```fortran
call cli%add(switch='--api-url', switch_ab='-u',               &
             help='API endpoint (or set MYAPP_URL env var)',    &
             required=.false., act='store', def='http://localhost', &
             envvar='MYAPP_URL', error=error)
```

**Resolution order (highest priority first):**

1. Value supplied explicitly on the command line
2. Value of the named environment variable
3. Default value (`def=`)

This pattern is useful for configuration that belongs in CI secrets or shell profiles
rather than command line flags.

---

## Mutually exclusive argument pairs

Use `exclude` in `add` to declare two named arguments mutually exclusive. Either
argument can name the other by its full or abbreviated switch:

```fortran
call cli%add(switch='--json',  switch_ab='-j', &
             help='Output JSON format',        &
             required=.false., act='store_true', def='.false.', &
             exclude='--csv', error=error)

call cli%add(switch='--csv',   switch_ab='-c', &
             help='Output CSV format',         &
             required=.false., act='store_true', def='.false.', &
             exclude='--json', error=error)
```

If both are passed, FLAP prints an error before your code runs:

```shell
$ ./myapp --json --csv
myapp: error: switches "--json" and "--csv" are mutually exclusive!
```

For mutually exclusive **subcommands** (groups), use `set_mutually_exclusive_groups` —
see the [Subcommands](./subcommands) page.

---

## Optional-value arguments (`act='store*'`)

`store*` (note the asterisk) is a middle ground between `store` and `store_true`:
the switch can appear with or without a value.

- Present **with** a value → stores that value
- Present **without** a value → stores the default
- **Absent** → stores the default

```fortran
call cli%add(switch='--format',                              &
             help='Output format; omit value for "text"',   &
             required=.false., act='store*', def='text', error=error)
```

```shell
$ ./myapp --format json    ! stores 'json'
$ ./myapp --format        ! stores 'text' (default)
$ ./myapp                 ! stores 'text' (default)
```

**Restrictions:** `store*` cannot be used with `nargs`, `envvar`, or positional
arguments. A default is mandatory.

---

## Hidden arguments

Hidden arguments participate in parsing normally but are invisible in help and usage:

```fortran
call cli%add(switch='--dump-internals',                       &
             help='Dump internal state to stderr (debug)',    &
             required=.false., act='store_true', def='.false.', &
             hidden=.true., error=error)
```

This keeps expert or debugging flags out of user-visible help without disabling them.

---

## Choices constraint

```fortran
call cli%add(switch='--solver', switch_ab='-s',                   &
             help='Linear solver',                                &
             required=.false., act='store', def='cg',             &
             choices='cg,gmres,bicgstab', error=error)
```

The check happens at `get` time:

```shell
$ ./myapp --solver lu
myapp: error: the value "lu" is not in the choices list (cg,gmres,bicgstab)
```

> **Note:** `choices` is not supported for `get_varying` (runtime-sized lists).

---

## Runtime-sized list arguments

For lists whose length is not known at compile time, combine `nargs='+'` or `nargs='*'`
with `get_varying`:

```fortran
! one or more input files
call cli%add(switch='--inputs', switch_ab='-i',   &
             help='One or more input files',       &
             required=.false., act='store',        &
             nargs='+', def='', error=error)

! zero or more filter strings
call cli%add(switch='--filters', switch_ab='-f',  &
             help='Zero or more filters to apply', &
             required=.false., act='store',        &
             nargs='*', def='', error=error)
```

Retrieval:

```fortran
character(256), allocatable :: inputs(:), filters(:)

call cli%get_varying(switch='--inputs',  val=inputs,  error=error)
call cli%get_varying(switch='--filters', val=filters, error=error)

do i = 1, size(inputs)
  print '(A)', 'Processing: ' // trim(inputs(i))
end do
```

---

## Disabling automatic `--help` / `--version`

If your program already defines `-h` or `-v` for other purposes:

```fortran
call cli%init(disable_hv=.true., ...)
```

FLAP will not add its default help/version switches. You remain responsible for
printing help and version information yourself.

---

## Fake command-line input (`args`)

Pass a string to `parse` or `get` to test your CLI without modifying `argv`:

```fortran
! simulate: ./myprogram --solver gmres --niter 200
call cli%parse(args='--solver gmres --niter 200', error=error)
```

This is particularly useful in unit tests and doctests.

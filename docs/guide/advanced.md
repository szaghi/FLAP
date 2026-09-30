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

Any named `act='store'`, `store_true` or `store_false` argument (not a list) can take its value from an environment
variable:

```fortran
call cli%add(switch='--api-url', switch_ab='-u',               &
             help='API endpoint (or set MYAPP_URL env var)',    &
             required=.false., act='store', def='http://localhost', &
             envvar='MYAPP_URL', error=error)
```

**Resolution order (highest priority first):**

1. Value supplied explicitly on the command line
2. Value of the named environment variable, when it is set and not blank; the bare switch (`-u` alone) reads it too
3. Default value (`def=`)

A value from the environment satisfies a required argument. A flag (`store_true`/`store_false`) takes the variable as
its value: `1/0`, `true/false`, `t/f`, `yes/no`, `y/n`, `on/off`, in any case.

> **Changed in v2.0.0:** the environment is read also when the switch is absent. Before, an absent switch always gave
> its default and only the bare switch read the variable.

This pattern is useful for configuration that belongs in CI secrets or shell profiles
rather than command line flags.

### List values from the environment

A list option (`nargs`) reads its variable as one line of **comma-separated values**, not blank-separated as on the
command line and in `def=`: an environment value is a single shell word, where commas are the convention.

| Variable | List |
|---|---|
| `WORKERS='1,99'` | `1`, `99` |
| `WORKERS='1, 2 , 3'` | `1`, `2`, `3` (blanks around a value trimmed) |
| `FILES='"my file.h5", other.h5'` | `my file.h5`, `other.h5` (a quoted value may hold commas and blanks) |
| `TITLES='"say ""hi""",x'` | `say "hi"`, `x` (`""` inside quotes is a `"`) |
| `WORKERS='1,,3'` | `1`, empty, `3` (a numeric `get` then fails its cast) |
| `WORKERS='1,"99'` | error `ERROR_ENVVAR_CSV` (43): unterminated quote |

A scalar option takes its variable verbatim, commas included. The number of values of `nargs='N'` is checked by `get`.

### Generated variable names — `init(auto_envvar_prefix=...)`

With a prefix, every named `store`, `store_true` or `store_false` option added without an `envvar` gets one,
`PREFIX[_COMMAND]_NAME` in upper case, NAME being the long switch without its dashes and `-` becoming `_`:

```fortran
call cli%init(progname='solver', auto_envvar_prefix='SOLVER')
call cli%add(switch='--mesh-file', help='Mesh', required=.true., act='store')              ! SOLVER_MESH_FILE
call cli%add(group='post', switch='--format', help='Format', required=.false., act='store', def='vtk')
                                                                                          ! SOLVER_POST_FORMAT
```

```shell
$ SOLVER_MESH_FILE=wing.grd ./solver                        # mesh = wing.grd (required satisfied)
$ SOLVER_MESH_FILE=wing.grd ./solver --mesh-file body.grd   # the command line wins: body.grd
```

An explicit `envvar=` wins over the generated name. Positionals, `store*`, `count` and `append` get no name.
The help shows the generated names.

### Ignoring the environment — `init(ignore_env=.true.)`

For reproducible runs (a batch job whose environment must not leak in, tests, CI sandboxes),
`ignore_env=.true.` turns every environment lookup off. The `envvar` definitions are unchanged
and still shown in the help; a switch that would read its variable behaves as if it were unset:

```fortran
call cli%init(progname='solver', ignore_env=.true.)
call cli%add(switch='--threads', help='Threads', required=.false., act='store', def='1', envvar='OMP_NUM_THREADS')
```

```shell
$ OMP_NUM_THREADS=64 ./solver --threads    # error: "--threads" needs a value (the environment is ignored)
```

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

`exclude` is pairwise and cannot be combined with `required=.true.`: for more than two
switches, or for "exactly one of", use a mutually exclusive set (below).

For mutually exclusive **subcommands** (groups), use `set_mutually_exclusive_groups` —
see the [Subcommands](./subcommands) page.

---

## Mutually exclusive sets

`cli%set_mutually_exclusive_switches` declares a set of switches of which **at most one** may be passed; with `required=.true.`,
**exactly one** must be passed. This is argparse's `add_mutually_exclusive_group`, and
the recommended mechanism over pairwise `exclude`:

```fortran
call cli%add(switch='--mesh',    switch_ab='-m', help='Mesh file',    required=.false., act='store', def='')
call cli%add(switch='--restart', switch_ab='-r', help='Restart file', required=.false., act='store', def='')
call cli%add(switch='--left',  help='Go left',  required=.false., act='store_true', def='.false.')
call cli%add(switch='--right', help='Go right', required=.false., act='store_true', def='.false.')
call cli%set_mutually_exclusive_switches(switches='--mesh,--restart', required=.true., error=error)
call cli%set_mutually_exclusive_switches(switches='--left,--right', error=error)
```

```shell
$ ./solver -m m.grd                  # ok
$ ./solver -m m.grd -r r.h5
solver: error: switches "--mesh", "--restart" are mutually exclusive!
$ ./solver
solver: error: one of "--mesh", "--restart" is required!
$ ./solver --help                    # the help is printed: a set never blocks --help/--version
```

The usage shows the sets in docopt notation, `(a | b)` for a required set and `[a | b]` otherwise:

```
usage: solver (--mesh value | --restart value) [--left | --right] [--help] [--markdown] [--version]
```

Rules:

- the members are comma separated, named by switch or abbreviation, and must be **already added**
  to the group (pass `group=` for the options of a command); a set of a command is checked only
  when the command is called;
- a member cannot be individually `required`, and a switch belongs to at most one set;
- only **passed** members count: a default neither satisfies a required set nor violates a set;
- the sets are checked after help/version and after the required options, as the last validation;
- an invalid set is not added: the call returns `ERROR_M_EXCLUDE_SET_DEFINITION` (`104`), and
  `parse` returns the same error, so a wrong definition cannot go unnoticed.

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

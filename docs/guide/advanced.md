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

### Configuration files

`cli%set_config` names an INI file supplying values below the environment and above the defaults, so the full order is
**command line > environment variable > configuration file > default**:

```fortran
call cli%init(progname='solver')
call cli%add(switch='--mesh-file', help='Mesh', required=.true., act='store')
call cli%add(switch='--cfl', help='CFL', required=.false., act='store', def='0.5')
call cli%add_group(group='post', description='Post processing')
call cli%add(group='post', switch='--format', help='Format', required=.false., act='store', def='vtk')
call cli%set_config(file='solver.ini')              ! required=.true. makes a missing file an error
call cli%parse(error=error)
```

```ini
# solver.ini
mesh-file = wing.grd        ; keys are the long switches without the dashes
cfl       = 0.8
[post]                      # a section is a command
format    = vtu
```

- Keys before any section belong to the top level; a `[section]` holds the options of that command.
- A value is the text after `=`, blanks trimmed; one pair of quotes (`'` or `"`) is stripped, and a quoted value keeps its
  `#` and `;`. An inline comment starts at a `#` or `;` preceded by a blank. An empty value counts as unset.
- A list (`nargs`) is blank separated, as in `def=`; a flag reads `yes/no`, `on/off`, `1/0`, `true/false`, ...
- An unknown key or section, a key naming an option that takes no value (`count`, `append`, `store*`), or a line that is
  not `key = value`, `[section]` or a comment is an error, `ERROR_CONFIG_UNKNOWN_KEY` (1007), naming the line; with
  `init(ignore_unknown_clas=.true.)` such lines are ignored. The last of repeated keys wins.
- A missing file is skipped, unless `set_config(..., required=.true.)`: then `ERROR_CONFIG_NOT_FOUND` (1006).
- The file is read by `parse` after `--help`/`--version`, so a broken file never blocks the help. A value from it
  satisfies a required option and is checked against `choices` by `get`.

To let the user choose the file, add a top-level option with `act='config'`:

```fortran
call cli%add(switch='--config', help='Configuration file', required=.false., act='config', def='solver.ini', &
             envvar='SOLVER_CONFIG')
```

The file is the one named on the command line (`--config my.ini`), else in the environment variable, else the one of
`set_config`, else the default. A file named on the command line or in the environment must exist
(`ERROR_CONFIG_NOT_FOUND`); a missing default file is skipped. `get` of the option returns the file name.

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
- every **explicit** value counts, from the command line, the environment or a configuration file; a default neither
  satisfies a required set nor violates a set. When a member is on the command line, the environment and configuration
  values of the other members fall back to their defaults: the command line wins (a variable set for a batch job never
  makes a command line alternative a violation);
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

## Path checks — `must_exist`, `readable`, `writable`, `allow_dash`

An option whose value is a file name can have it checked by `parse`, whatever its source (command line, environment,
configuration file or default):

```fortran
call cli%add(switch='--mesh', help='Mesh file', required=.true.,  act='store', readable=.true.)
call cli%add(switch='--log',  help='Log file',  required=.false., act='store', def='-', writable=.true., allow_dash=.true.)
```

```shell
$ ./solver --mesh wnig.grd      # error: option "--mesh": path "wnig.grd" does not exist!
$ ./solver --mesh secret.grd    # error: option "--mesh": path "secret.grd" is not readable: <reason>!
```

| Keyword | Check |
|---|---|
| `must_exist` | the file exists (`ERROR_PATH_NOT_FOUND`, 33) |
| `readable` | it exists and opens for reading (`ERROR_PATH_NOT_READABLE`, 34, with the reason given by the system) |
| `writable` | if it exists, it opens for writing, nothing written (`ERROR_PATH_NOT_WRITABLE`, 35); a missing file passes and is not created |
| `allow_dash` | `-` passes every check (your program maps it to standard input/output); otherwise `-` is a file name |

- Every item of a list is checked; an empty value (`def=''`) is not checked. The options of a command are checked only
  when the command is called.
- Only for options taking a value (`store`, `store*`, `append`): elsewhere the keywords are `ERROR_PATH_INCONSISTENT` (49).
- Standard Fortran only, so **directories are not told apart**: a directory exists and opens for reading.
- **nvfortran 26.5:** opening a read-only file for writing succeeds (the error comes at the first write), so `writable`
  does not detect a read-only file with that compiler.

## Deprecated options and commands — `deprecated`

`add(..., deprecated='message')` and `add_group(..., deprecated='message')` mark an option or a command as deprecated
(`deprecated=''`: without a message). Using it is **not** an error: `parse` prints a warning on the error unit and goes on.

```fortran
call cli%add(switch='--grid', help='Old grid', required=.false., act='store', def='g.grd', &
             deprecated='use --mesh instead')
call cli%add_group(group='legacy', description='the old run', deprecated='use run')
```

```shell
$ ./solver --grid w.grd
solver: warning: option "--grid" is deprecated: use --mesh instead
```

- An option warns when its value comes from the command line or from its environment variable, not when it comes from
  a configuration file or its default (as in click); a command warns when it is called.
- The help marks them: `Old grid (DEPRECATED: use --mesh instead)`.
- A required option cannot be deprecated: `ERROR_DEPRECATED_REQUIRED` (44).

## Alternate actions

An option with `act='alternate'` is an auxiliary action of the program (`--list-models`, `--dump-config`), not an input
value: when it is passed, `parse` returns `STATUS_ALTERNATE` (also in standalone mode: FLAP never stops on it) and
**skips the value validation**, so it works even without the required options. The program dispatches on `is_passed`:

```fortran
use flap, only : command_line_interface, STATUS_ALTERNATE
call cli%add(switch='--mesh',        help='Mesh file',                       required=.true., act='store')
call cli%add(switch='--list-models', help='List turbulence models and exit', act='alternate')
call cli%parse(error=error)
if (error == STATUS_ALTERNATE) then
  if (cli%is_passed(switch='--list-models')) call print_models()
  stop
elseif (error /= 0) then
  stop 1
end if
```

- Skipped: required options, mutually exclusive sets, `exclude=` pairs, exclusive commands, path checks, unknown
  configuration keys and invalid environment lists. Still reported: syntax errors (an unknown or repeated switch);
  `--help`, `--version` and `--markdown` come first. Deprecation warnings are still printed.
- `get` works as usual after it (a value out of `choices` is still reported by `get`).
- An alternate is a flag: `nargs`, `envvar`, `choices`, `exclude`, `required` and `positional` are
  `ERROR_ALTERNATE_INCONSISTENT` (37). The usage shows it as `[--list-models]`.

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

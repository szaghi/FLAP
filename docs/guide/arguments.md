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

FLAP checks for name collisions before adding them, so your own `-h` or `-v` switches
take precedence. To suppress both, use `disable_hv=.true.`.

---

## Adding arguments — `cli%add`

```fortran
call cli%add(switch, switch_ab, help, required, act, def, &
             nargs, choices, exclude, envvar,             &
             positional, position, hidden,                &
             group, group_index, pref, error)
```

All arguments are optional except that either `switch` (for named arguments) or
`position` (for positional arguments) must be provided.

### Core parameters

| Argument | Type | Default | Purpose |
|---|---|---|---|
| `switch` | `character(*)` | — | Long switch name, e.g. `'--output'` |
| `switch_ab` | `character(*)` | same as `switch` | Abbreviated switch, e.g. `'-o'` |
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
| `'print_help'` | Prints the help message and exits |
| `'print_version'` | Prints the version and exits |

Actions are case-insensitive.

```fortran
! boolean flag: present → .true., absent → .false.
call cli%add(switch='--verbose', switch_ab='-v', &
             help='Enable verbose output',       &
             required=.false., act='store_true', def='.false.', error=error)

! optional value: present without a value → default used
call cli%add(switch='--format', &
             help='Output format (default: text)',      &
             required=.false., act='store*', def='text', error=error)
```

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

### List-valued arguments (`nargs`)

Use `nargs` to consume multiple values from a single switch.

| `nargs` value | Meaning | Retrieval method |
|---|---|---|
| `'N'` (positive integer) | Exactly N values, fixed at compile time | `cli%get` with an allocated array |
| `'+'` | One or more values, length known at runtime | `cli%get_varying` |
| `'*'` | Zero or more values, length known at runtime | `cli%get_varying` |

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

If both are passed, FLAP reports an error automatically.

### Environment variable fallback (`envvar`)

```fortran
call cli%add(switch='--token', switch_ab='-t',          &
             help='API token (or set MY_TOKEN env var)', &
             required=.false., act='store', def='',      &
             envvar='MY_TOKEN', error=error)
```

Resolution order (highest priority first):
1. Value passed directly on the command line
2. Value of the environment variable `MY_TOKEN`
3. Default value

Restrictions: `envvar` is only valid for named, non-list, `act='store'` arguments.

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

Restrictions: positional arguments cannot use `exclude` or `envvar`, and must use
`act='store'`.

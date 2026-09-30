# Subcommands

FLAP builds git-style interfaces, where a program dispatches on a named command: `fake_git commit -m "fix"`,
`fake_git tag -a v1`. In FLAP's own terms a command is a **group** of command line arguments.

## Concepts

- The **top level** (the unnamed group) holds the arguments given before any command name.
- Each **command** is a named group with its own arguments, its own help and its own builtins (`--help`, ...).
- The arguments after a command name belong to that command, up to the next command name.
- Commands are not nested: a command has no subcommands of its own. A command line can call **several** commands, one
  after the other (`fake_git init commit -m first`), each at most once; `set_mutually_exclusive_groups` forbids a pair.

<<< @/examples/snippets/fake_git-define.f90

<<< @/examples/output/fake_git-help.ansi{ansi}

Each command has its own help:

<<< @/examples/output/fake_git-commit-help.ansi{ansi}

## Adding a command — `cli%add_group`

```fortran
call cli%add_group(group, description, help, exclude, examples, no_args_is_help, deprecated, aliases, error)
```

| Argument | Type | Purpose |
|---|---|---|
| `group` | `character(*)` | The command name |
| `description` | `character(*)`, optional | Shown in the top-level help and in the help of the command |
| `help` | `character(*)`, optional | Text before the usage line of the command (default `'usage: '`) |
| `examples` | `character(*), dimension(:)`, optional | Examples shown in the help of the command |
| `exclude` | `character(*)`, optional | A command that cannot be called together with this one (as `set_mutually_exclusive_groups`) |
| `no_args_is_help` | `logical`, optional | `prog <command>` alone prints the help of the command (`STATUS_NO_ARGS`) |
| `deprecated` | `character(*)`, optional | The command is deprecated: calling it prints a warning (see [Advanced](./advanced#deprecated-options-and-commands)) |
| `aliases` | `character(*)`, optional | Other names of the command, comma separated (see [Aliases](#aliases)) |
| `error` | `integer`, optional | Error code (0 = success) |

The arguments of a command are added with `group=`; `add` creates the command if it does not exist yet.

## Which command was called — `cli%run_command`

`cli%run_command('commit')` is `.true.` when the command (or one of its aliases) is on the command line:

<<< @/examples/snippets/fake_git-dispatch.f90

<<< @/examples/output/fake_git-commit.ansi{ansi}

<<< @/examples/output/fake_git-two.ansi{ansi}

### Values that look like command names

A value is never mistaken for a command: in `fake_git commit -m tag` the message is `tag` and the `tag` command is not
called, because `-m` takes exactly one value. This holds for every option with a fixed number of values (one value, or
`nargs='N'`). A list with a variable number of values (`nargs='+'` or `nargs='*'`) ends at the first command name: in
`prog --files a b init`, the list is `a b` and `init` is called.

<<< @/examples/output/fake_git-value.ansi{ansi}

A command passed twice (directly, or through an alias) is `ERROR_COMMAND_REPEATED` (1013), reported before `--help`:

<<< @/examples/output/fake_git-repeated.ansi{ansi}

An unknown command gets the closest names as suggestions:

<<< @/examples/output/fake_git-typo.ansi{ansi}

## Aliases

`aliases` gives a command other names: invoking an alias is invoking the command.

<<< @/examples/snippets/aliases-aliases.f90

Every query accepts an alias too: `run_command('co')` is `run_command('compile')`, `get(group='co', ...)` reads the
`compile` options, and mutually exclusive commands can be declared through an alias. The help lists `compile, co, c`
under `Commands:`, and the completion scripts offer the aliases. With `init(case_insensitive=.true.)` aliases match in
any case, as command names do.

An alias equal to a command name or to another alias, repeated, blank, or equal to its own command, and a command name
equal to an existing alias, are `ERROR_GROUP_ALIAS` (1008): printed, returned by `error=`, and kept on the command, so
that `parse` fails too.

## Reusable option sets — `cli%copy_options`

```fortran
call cli%copy_options(to_group, from_group, switches, pref, error)
```

Options defined once (at the top level by default, or in `from_group`) are copied into a command:

<<< @/examples/snippets/aliases-copy.f90

<<< @/examples/output/aliases.ansi{ansi}

<<< @/examples/output/aliases-compile-help.ansi{ansi}

- The definitions are copied **by value**, at the call: help, action, default, `nargs`, choices, envvar, hidden, negation,
  range, map, path checks, deprecation, ... Later changes to the source do not propagate.
- Each copy has its own value: `compile -j 4` sets the `--jobs` of `compile` only.
- Only named options are copied; the builtins never (each command has its own). Naming a positional in `switches` is
  `ERROR_COPY_POSITIONAL` (1009), an unknown name `ERROR_MISSING_CLA` (nothing is copied then), an unknown group
  `ERROR_MISSING_GROUP`; a switch the target already defines is the group consistency error (100).
- An explicit `envvar` is copied verbatim (every copy reads the same variable); a name generated by
  `init(auto_envvar_prefix=)` is generated again for the target (`APP_COMPILE_JOBS`).
- A pairwise `exclude=` keeps working when both options are copied; with only one, the link is inert. Mutually exclusive
  sets (`set_mutually_exclusive_switches`) belong to a group and are not copied.

## Mutually exclusive commands — `cli%set_mutually_exclusive_groups`

```fortran
call cli%set_mutually_exclusive_groups(group1='commit', group2='init')
```

Both commands must be defined before the call. Calling both is `ERROR_GROUP_M_EXCLUDE` (101), reported by `parse`.

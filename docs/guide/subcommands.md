# Nested Subcommands

FLAP supports git-style subcommand interfaces where a single program dispatches to
different behaviours based on a named command (e.g. `myapp commit`, `myapp tag`).

In FLAP terminology, a subcommand is called a **group** — a named collection of
Command Line Arguments (CLAs).

## Concepts

- The **default group** (group 0, unnamed) holds top-level arguments that apply
  regardless of which subcommand is chosen.
- Each **named group** corresponds to one subcommand and holds its own arguments.
- Named groups and the default group can be freely combined.

## Adding a group — `cli%add_group`

```fortran
call cli%add_group(group, description, help)
```

| Argument | Type | Purpose |
|---|---|---|
| `group` | `character(*)` | Unique subcommand name |
| `description` | `character(*)`, optional | Short description shown in top-level help |
| `help` | `character(*)`, optional | Extended help for per-command help |

```fortran
call cli%add_group(group='init',   description='Initialise a new repository')
call cli%add_group(group='commit', description='Record changes to the repository')
call cli%add_group(group='tag',    description='Create, list or delete tags')
```

## Adding arguments to a group

Pass the `group` keyword to `add`:

```fortran
call cli%add(group='commit', switch='--message', switch_ab='-m', &
             help='Commit message', required=.false., act='store', def='', error=error)

call cli%add(group='tag', switch='--annotate', switch_ab='-a', &
             help='Tag annotation', required=.false., act='store', def='', error=error)
```

### Implicit group creation

If the group name passed to `add` is not yet defined, FLAP creates it on the fly:

```fortran
! 'push' group is created automatically here
call cli%add(group='push', switch='--remote', switch_ab='-r', &
             help='Remote name', required=.false., act='store', def='origin', error=error)
```

## Checking which subcommand was invoked — `cli%run_command`

```fortran
logical_result = cli%run_command('group_name')
```

This pure function returns `.true.` if the named group was the subcommand passed on
the command line:

```fortran
call cli%parse(error=error)
if (error /= 0) stop

if (cli%run_command('init')) then
  call do_init()
elseif (cli%run_command('commit')) then
  call cli%get(group='commit', switch='-m', val=message, error=error)
  call do_commit(message)
elseif (cli%run_command('tag')) then
  call cli%get(group='tag', switch='-a', val=annotation, error=error)
  call do_tag(annotation)
else
  print '(A)', 'No command given — try --help'
end if
```

## Mutually exclusive groups — `cli%set_mutually_exclusive_groups`

```fortran
call cli%set_mutually_exclusive_groups(group1='commit', group2='init')
```

Both groups must be defined before this call. If the program is invoked with both
subcommands, FLAP prints a clear error and exits.

## Complete git-toy example

```fortran
program fake_git
  use flap
  implicit none

  type(command_line_interface) :: cli
  character(256) :: message, annotation
  logical        :: print_authors
  integer        :: error

  call cli%init(progname    = 'fake_git',                                    &
                version     = 'v2.1.5',                                      &
                authors     = 'Stefano Zaghi',                               &
                license     = 'MIT',                                         &
                description = 'A toy git-like program demonstrating FLAP',   &
                examples    = ['fake_git                        ', &
                               'fake_git -h                     ', &
                               'fake_git init                   ', &
                               'fake_git commit -m "fix bug #1" ', &
                               'fake_git tag -a "v2.1.5"        '])

  ! top-level argument (default group)
  call cli%add(switch='--authors', switch_ab='-a',         &
               help='Print author names',                  &
               required=.false., act='store_true', def='.false.', error=error)

  ! subcommands
  call cli%add_group(group='init',   description='Initialise versioning')
  call cli%add_group(group='commit', description='Commit changes to current branch')
  call cli%add_group(group='tag',    description='Tag the current commit')

  ! subcommand arguments
  call cli%add(group='commit', switch='--message', switch_ab='-m', &
               help='Commit message', required=.false., act='store', def='', error=error)
  call cli%add(group='tag', switch='--annotate', switch_ab='-a', &
               help='Tag annotation', required=.false., act='store', def='', error=error)

  call cli%parse(error=error)
  if (error /= 0) stop

  call cli%get(switch='-a', val=print_authors, error=error)
  if (error /= 0) stop

  if (print_authors) then
    print '(A)', 'Authors: ' // cli%authors
  elseif (cli%run_command('init')) then
    print '(A)', 'Initialising versioning'
  elseif (cli%run_command('commit')) then
    call cli%get(group='commit', switch='-m', val=message, error=error)
    if (error /= 0) stop
    print '(A)', 'Committing with message: "' // trim(message) // '"'
  elseif (cli%run_command('tag')) then
    call cli%get(group='tag', switch='-a', val=annotation, error=error)
    if (error /= 0) stop
    print '(A)', 'Tagging with annotation: "' // trim(annotation) // '"'
  else
    print '(A)', 'No command given — try --help'
  end if
end program fake_git
```

### Help output

```shell
$ ./fake_git -h
usage: fake_git  [--authors] [--help] [--version] {init,commit,tag} ...

A toy git-like program demonstrating FLAP

Optional switches:
   --authors, -a
          default value .false.
          Print author names
   --help, -h
          Print this help message
   --version, -v
          Print version

Commands:
  init
          Initialise versioning
  commit
          Commit changes to current branch
  tag
          Tag the current commit

For more detailed commands help try:
  fake_git init -h,--help
  fake_git commit -h,--help
  fake_git tag -h,--help

Examples:
   fake_git
   fake_git -h
   fake_git init
   fake_git commit -m "fix bug #1"
   fake_git tag -a "v2.1.5"
```

### Per-command help

Each subcommand has its own `--help` page:

```shell
$ ./fake_git commit -h
usage:  fake_git commit [--message value] [--help] [--version]

Commit changes to current branch

Optional switches:
   --message value, -m value
          default value
          Commit message
   --help, -h
          Print this help message
   --version, -v
          Print version
```

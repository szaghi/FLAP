# Output Formats

In addition to the automatic help and version messages, FLAP can export your CLI
definition in three structured formats: man page, bash completion script, and
Markdown.

## Automatic help and usage

Help is printed automatically when `--help` (or `-h`) is passed. The message includes:

- The usage line derived from all defined arguments
- The program description (from `cli%init`)
- Required and optional switches, each with their help text and default values
- The list of subcommands (if any) with per-command help hints
- Examples (if provided to `cli%init`)
- The epilog (if provided)

```shell
$ ./myapp --help
usage:  myapp --input value [--output value] [--verbose] [--help] [--version]

A demonstration program

Required switches:
   --input value, -i value
          Input file path

Optional switches:
   --output value, -o value
          default value out.dat
          Output file path
   --verbose, -v
          default value .false.
          Enable verbose output
   --help, -h
          Print this help message
   --version, -v
          Print version

Examples:
   myapp -i data.dat
   myapp -i data.dat -o result.dat --verbose
```

## Man page — `cli%save_man_page`

Generate a Unix man page from your CLI definition:

```fortran
call cli%save_man_page(man_file='myapp.1', error=error)
```

The produced file (`myapp.1` by convention for section 1 commands) can be installed
in the system man path or shipped with your software package.

Full example:

```fortran
program myapp
  use flap
  implicit none
  type(command_line_interface) :: cli
  integer                      :: error

  call cli%init(progname='myapp', version='v1.0', &
                description='A demonstration program')
  call cli%add(switch='--input', switch_ab='-i', &
               help='Input file', required=.true., act='store', error=error)

  call cli%parse(error=error)
  if (error /= 0) stop

  ! export man page
  call cli%save_man_page(man_file='myapp.1', error=error)
  if (error /= 0) stop
end program myapp
```

Install and view:

```bash
man ./myapp.1
```

## Bash completion — `cli%save_bash_completion`

Generate a bash completion script so users get tab-completion for your program:

```fortran
call cli%save_bash_completion(completion_file='myapp.bash', error=error)
```

To activate it in the current shell:

```bash
source myapp.bash
```

For permanent installation, place the file in `/etc/bash_completion.d/` or
`~/.bash_completion.d/`:

```bash
cp myapp.bash ~/.bash_completion.d/myapp
```

## Markdown usage export — `cli%save_usage_to_markdown`

Export the usage message as a Markdown file, suitable for embedding in documentation
or wikis:

```fortran
call cli%save_usage_to_markdown(md_file='usage.md', error=error)
```

The output is formatted Markdown with code blocks for the usage line and argument
tables.

## Printing usage programmatically — `cli%print_usage`

Print the usage message to `stdout` at any point in your program:

```fortran
call cli%print_usage()
```

This is equivalent to the user passing `--help`, but it does not trigger program exit —
you control the flow.

## Summary of export methods

| Method | Output | Typical filename |
|---|---|---|
| `cli%save_man_page` | Unix man page (troff format) | `myapp.1` |
| `cli%save_bash_completion` | Bash completion script | `myapp.bash` |
| `cli%save_usage_to_markdown` | Markdown usage page | `usage.md` |
| `cli%print_usage` | Prints help to `stdout` | — |

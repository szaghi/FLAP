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

### From the command line (`--man`)

`init(man_option=.true.)` adds a top-level `--man` switch that saves the man page and ends the program (exit status 0,
like `--help`), without checking the other arguments: `myapp --man` writes `myapp.1`. In non-standalone mode `parse`
returns `STATUS_PRINT_MAN` (−8) instead. `init(man_file='share/man/man1/myapp.1')` names the file; the built-in
`--markdown` switch has its own `init(markdown_file=...)` (default `<progname>.md`).

## Bash completion — `cli%save_bash_completion`

Generate a bash completion script so users get tab-completion for your program:

```fortran
call cli%save_bash_completion(bash_file='myapp.bash', error=error)
```

The script completes switches, command names and `choices`. It is registered with `complete -o default`: where it has
nothing to offer (a free value such as `--mesh <TAB>`), bash completes file names.

To activate it in the current shell:

```bash
source myapp.bash
```

For permanent installation, place the file in `/etc/bash_completion.d/` or
`~/.bash_completion.d/`:

```bash
cp myapp.bash ~/.bash_completion.d/myapp
```

## Zsh completion — `cli%save_zsh_completion`

```fortran
call cli%save_zsh_completion(zsh_file='myapp.zsh', error=error)
```

The zsh script is the bash one run through zsh's `bashcompinit` (it loads `compinit` and `bashcompinit` itself), with the
same file-name fallback. Source it, for example from `~/.zshrc`:

```zsh
source /path/to/myapp.zsh
```

## Fish completion — `cli%save_fish_completion`

```fortran
call cli%save_fish_completion(fish_file='myapp.fish', error=error)
```

A native fish script: one `complete` line per option, with its help as the description. Long switches (`--mesh`) map to
`-l`, one-letter ones (`-m`) to `-s`, multi-letter single-dash ones (`-opt`) to fish's old-style `-o`. Choices are
offered exclusively, a free value completes file names, and commands and their aliases are completed first, their
options once one is typed. Hidden options are left out. Install it where fish looks for it:

```bash
cp myapp.fish ~/.config/fish/completions/myapp.fish
```

## PowerShell completion — `cli%save_powershell_completion`

```fortran
call cli%save_powershell_completion(powershell_file='myapp.ps1', error=error)
```

The script registers a native argument completer (`Register-ArgumentCompleter -Native`) holding the table of the
commands (names and aliases) and of the options of each command, with their help as tooltips. It completes the choices
after an option, nothing after another option taking a value (PowerShell then completes paths), otherwise the options
and, at the top level, the commands. Dot-source it, for example from your `$PROFILE`:

```powershell
. /path/to/myapp.ps1
```

## Shell completion from the program

With `init(completion_options=.true.)` the program itself offers its completion, as Typer does:

```console
$ myapp --show-completion bash > myapp.bash     # print the script of a shell
$ myapp --install-completion                    # install it for $SHELL
completion script installed in "/home/me/.myapp-completion.bash", loaded by "/home/me/.bashrc"
```

- The shell is optional (`bash`, `zsh`, `fish`, `powershell`); without it, the basename of `$SHELL`. An unknown or unset
  shell is `ERROR_COMPLETION_SHELL` (1010).
- `--show-completion` writes the script to the version unit (standard output by default), `--install-completion` writes it
  to `$HOME/.<prog>-completion.<shell>` and appends one line sourcing it, marked `# FLAP completion: <prog>`, to
  `~/.bashrc`, `~/.zshrc` or `~/.config/fish/config.fish`, only if that marker is absent: the rc file is never
  rewritten, and running it again refreshes the script. No directory is created: fish must have been run once. PowerShell
  is not installed automatically (its profile path needs `pwsh`): save `--show-completion powershell` and dot-source it
  from your `$PROFILE`. A failure is `ERROR_COMPLETION_INSTALL` (1011), with the I/O error.
- In standalone mode the program then ends (exit status 0), as for `--help`; otherwise `parse` returns
  `STATUS_SHOW_COMPLETION` (−6) or `STATUS_INSTALL_COMPLETION` (−7).
- `cli%completion_script(shell)` returns the script of a shell as a string ('' for an unknown one).

## Markdown usage export — `cli%save_usage_to_markdown`

Export the usage message as a Markdown file, suitable for embedding in documentation
or wikis:

```fortran
call cli%save_usage_to_markdown(markdown_file='usage.md', error=error)
```

The output is formatted Markdown with code blocks for the usage line and argument
tables.

The built-in `--markdown` (`-md`) switch does the same from the command line, writing `<progname>.md`, or the file
named by `init(markdown_file=...)`.

## Printing usage programmatically — `cli%print_usage`

Print the usage message to `stdout` at any point in your program:

```fortran
call cli%print_usage()
```

This is equivalent to the user passing `--help`, but it does not trigger program exit —
you control the flow.

## Colours

Help and error messages can be coloured with ANSI escape sequences (through the FACE library). Nothing is coloured
unless you ask:

```fortran
call cli%init(description='my program', error_color='red', error_style='bold_on')
call cli%add(switch='--input', switch_ab='-i', help='input file', required=.true., act='store', &
             help_color='blue', help_style='italics_on')
```

| Keyword | Of | Colours |
|---|---|---|
| `error_color`, `error_style` | `cli%init` | the `error` label of every error message and the `warning` label of the warnings |
| `help_color`, `help_style` | `cli%add` | the switch names of that option in the usage line and in the help |

Colours are FACE names (`red`, `green`, `blue`, `yellow`, `cyan`, `magenta`, `white`, `black`, and their `_intense`
variants); styles are `bold_on`, `italics_on`, `underline_on`, `inverse_on`, `strikethrough_on` and more (see the
FACE documentation). An unknown name is ignored. The interactive menus take their own colours (see
[Interactive Menus](./menu#colours)).

## Summary of export methods

| Method | Output | Typical filename |
|---|---|---|
| `cli%save_man_page` | Unix man page (troff format) | `myapp.1` |
| `cli%save_bash_completion` | Bash completion script | `myapp.bash` |
| `cli%save_zsh_completion` | Zsh completion script | `myapp.zsh` |
| `cli%save_fish_completion` | Fish completion script | `myapp.fish` |
| `cli%save_powershell_completion` | PowerShell completion script | `myapp.ps1` |
| `cli%save_usage_to_markdown` | Markdown usage page | `usage.md` |
| `cli%print_usage` | Prints help to `stdout` | — |

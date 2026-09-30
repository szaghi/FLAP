# Output Formats

From the same definitions, FLAP prints the help and writes a man page, a Markdown page and completion scripts for bash,
zsh, fish and PowerShell. Every output includes the builtins, and is the same before and after `parse`.

## Help and usage

`--help` (or `-h`) prints the help of the top level, `<command> --help` the help of a command:

- the usage line, built from every visible argument (`[...]` for an optional one, `(a | b)` and `[a | b]` for the
  mutually exclusive sets, `{init,commit,tag} ...` for the commands);
- the description;
- the required and the optional arguments, each with its default, choices, range, environment variable and help;
- the commands, with their description, and how to get their help;
- the examples and the epilog.

<<< @/examples/output/myapp-help.ansi{ansi}

The help goes to the usage unit (standard error unless `init(usage_lun=...)`). In a program:

| Method | Returns / does |
|---|---|
| `cli%usage(g, pref, no_header, no_examples, no_epilog, markdown)` | The help of the group `g` (0: top level, 1..: the commands, in order of definition) as a string |
| `cli%signature()` | The arguments of the top-level usage line, without `usage: <progname>` |
| `cli%print_usage(pref)` | Prints the top-level help on the usage unit; the program goes on |

## Man page

`cli%save_man_page(man_file, error)` writes a troff man page (section 1); with `init(man_option=.true.)` the user can ask
for it with `--man`.

<<< @/examples/output/completion-man.ansi{ansi}

View it with `man ./completion.1`, or install it in a `man1` directory of your `MANPATH`.

### From the command line (`--man`)

`init(man_option=.true.)` adds a top-level `--man` switch that saves the man page and ends the program (exit status 0,
like `--help`), without checking the other arguments: `prog --man` writes `prog.1`, or the file named by
`init(man_file='share/man/man1/prog.1')`. In non-standalone mode `parse` returns `STATUS_PRINT_MAN` (−8) instead.

## Markdown

`cli%save_usage_to_markdown(markdown_file, error)` writes the help as a Markdown page, for a wiki or a documentation
site; the builtin `--markdown` (`-md`) does the same from the command line, writing `<progname>.md` or the file named by
`init(markdown_file=...)`.

<<< @/examples/output/completion-markdown.ansi{ansi}

## Shell completion

| Method | Script |
|---|---|
| `cli%save_bash_completion(bash_file, error)` | bash |
| `cli%save_zsh_completion(zsh_file, error)` | zsh |
| `cli%save_fish_completion(fish_file, error)` | fish |
| `cli%save_powershell_completion(powershell_file, error)` | PowerShell |
| `cli%completion_script(shell)` | the script of `shell` (`'bash'`, `'zsh'`, `'fish'`, `'powershell'`) as a string, `''` for an unknown one |

<<< @/examples/snippets/save_outputs-save.f90

<<< @/examples/output/save_outputs.ansi{ansi}

Every script completes the switches, the command names (and aliases) and the `choices` of an option; hidden options are
left out, and none shows value placeholders.

- **bash**: registered with `complete -o default`, so where it has nothing to offer (a free value such as
  `--mesh <TAB>`) bash completes file names. An option already typed is not offered again, unless it can be repeated
  (`append`, `count`); with several commands on the line, the options offered are those of the last one (the values of
  the options are skipped, so `commit -m tag` stays in `commit`). Load it with `source prog.bash`, or install it in
  `~/.local/share/bash-completion/completions/prog`.
- **zsh**: the bash script run through zsh's `bashcompinit` (it loads `compinit` and `bashcompinit` itself), with the
  same behaviour. Source it from `~/.zshrc`.
- **fish**: a native script, one `complete` line per option with its help as the description. Long switches (`--mesh`)
  map to `-l`, one-letter ones (`-m`) to `-s`, multi-letter single-dash ones (`-md`) to fish's old-style `-o`. Choices are
  offered exclusively, a free value completes file names, and commands and their aliases are completed first, their
  options once one is typed. Install it as `~/.config/fish/completions/prog.fish`.
- **PowerShell**: a native argument completer (`Register-ArgumentCompleter -Native`) holding the table of the commands
  and of the options of each command, with their help as tooltips. It completes the choices after an option, nothing
  after another option taking a value (PowerShell then completes paths), otherwise the options and, at the top level,
  the commands. Dot-source it from your `$PROFILE`: `. /path/to/prog.ps1`.

### Shell completion from the program

With `init(completion_options=.true.)` the program itself offers its completion, as Typer does:

<<< @/examples/snippets/completion-define.f90

<<< @/examples/output/completion-show.ansi{ansi}

<<< @/examples/output/completion-install.ansi{ansi}

- The shell is optional (`bash`, `zsh`, `fish`, `powershell`); without it, the basename of `$SHELL`. An unknown or unset
  shell is `ERROR_COMPLETION_SHELL` (1010).
- `--show-completion` writes the script to the version unit (standard output by default); `--install-completion` writes
  it to `$HOME/.<prog>-completion.<shell>` and appends one line sourcing it, marked `# FLAP completion: <prog>`, to
  `~/.bashrc`, `~/.zshrc` or `~/.config/fish/config.fish`, only if that marker is absent: the rc file is never
  rewritten, and running it again refreshes the script. No directory is created: fish must have been run once.
  PowerShell is not installed automatically (its profile path needs `pwsh`): save `--show-completion powershell` and
  dot-source it from your `$PROFILE`. A failure is `ERROR_COMPLETION_INSTALL` (1011), with the I/O error.
- In standalone mode the program then ends (exit status 0), as for `--help`; otherwise `parse` returns
  `STATUS_SHOW_COMPLETION` (−6) or `STATUS_INSTALL_COMPLETION` (−7).

## Colours

Help and error messages can be coloured with ANSI escape sequences (through the FACE library). Nothing is coloured
unless you ask:

<<< @/examples/snippets/colors-define.f90

<<< @/examples/output/colors.ansi{ansi}

<<< @/examples/output/colors-error.ansi{ansi}

| Keyword | Of | Colours |
|---|---|---|
| `error_color`, `error_style` | `cli%init` | the `error` label of every error message and the `warning` label of the warnings |
| `help_color`, `help_style` | `cli%add` | the switch names of that option in the help |

Colours are FACE names (`red`, `green`, `blue`, `yellow`, `cyan`, `magenta`, `white`, `black`, and their `_intense`
variants); styles are `bold_on`, `italics_on`, `underline_on`, `inverse_on`, `strikethrough_on` and more (see the FACE
documentation). An unknown name is ignored. The escape sequences are written whatever the output unit is (a file or a
pipe too). The interactive menus take their own colours (see [Interactive Menus](./menu#colours)).

## Summary

| Method | Builtin switch | Output | Typical file |
|---|---|---|---|
| `cli%usage`, `cli%print_usage` | `--help`, `-h` | The help | — |
| `cli%save_man_page` | `--man` (with `man_option`) | Man page (troff) | `prog.1` |
| `cli%save_usage_to_markdown` | `--markdown`, `-md` | Markdown page | `prog.md` |
| `cli%save_bash_completion` | `--show-completion bash` (with `completion_options`) | bash completion | `prog.bash` |
| `cli%save_zsh_completion` | `--show-completion zsh` | zsh completion | `prog.zsh` |
| `cli%save_fish_completion` | `--show-completion fish` | fish completion | `prog.fish` |
| `cli%save_powershell_completion` | `--show-completion powershell` | PowerShell completion | `prog.ps1` |

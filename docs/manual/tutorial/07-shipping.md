# 7. Shipping it

Before `heat` reaches its users: a complete help, colours, a man page, and completion for their shell.

<<< @/examples/snippets/heat_7-init.f90

<<< @/examples/snippets/heat_7-define.f90

<<< @/examples/output/heat_7-help.ansi{ansi}

Errors and warnings get the colour of `error_color`/`error_style`:

<<< @/examples/output/heat_7-error.ansi{ansi}

## Man page and Markdown

`man_option=.true.` adds `--man`, which writes `heat.1`; the builtin `--markdown` writes `heat.md`:

<<< @/examples/output/heat_7-man.ansi{ansi}

<<< @/examples/output/heat_7-markdown.ansi{ansi}

## Shell completion

`completion_options=.true.` adds `--show-completion` and `--install-completion`. The program prints its own completion
script for bash, zsh, fish or PowerShell, or installs it for the user's shell:

<<< @/examples/output/heat_7-bash.ansi{ansi}

<<< @/examples/output/heat_7-install.ansi{ansi}

After a new shell, `heat --sch<TAB>` completes `--scheme`, and `heat --scheme <TAB>` offers `fe cn`. The same scripts can
be written by the program itself (`save_bash_completion`, ...: see [Output Formats](/guide/output#shell-completion)), for
a package.

::: warning Two FLAP programs in bash
Today every FLAP bash script defines the same function, `_completion`: with two FLAP programs installed, the script
loaded last completes both. This is [issue #126](https://github.com/szaghi/FLAP/issues/126) (B41).
:::

::: tip What you learned
Examples, epilog, colours, `--man`, `--markdown`, `--show-completion`, `--install-completion`.
Reference: [Output Formats](/guide/output).
:::

Next: [8. Testing the command line](./08-testing).

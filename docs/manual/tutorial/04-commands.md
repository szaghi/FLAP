# 4. Commands

`heat` grows three jobs: `run` a simulation, `post`-process its results, print `info`. Each becomes a **command**, with
its own options and its own help, as in `git commit` or `docker run`.

<<< @/examples/snippets/heat_4-define.f90

- `add_group` defines a command; `aliases` gives it shorter names (`heat r` is `heat run`).
- `add(group=...)` gives a command its options; an option without `group` belongs to the top level and goes before any
  command name.
- `copy_options` copies a definition into a command: `run` and `post` both get a `--verbose`, each with its own value.

The arguments after a command name belong to that command, up to the next command name, so one command line can call
several commands. The program asks which ones were called:

<<< @/examples/snippets/heat_4-dispatch.f90

<<< @/examples/snippets/heat_4-run.f90

<<< @/examples/output/heat_4.ansi{ansi}

<<< @/examples/output/heat_4-alias.ansi{ansi}

<<< @/examples/output/heat_4-info.ansi{ansi}

The top-level help lists the commands; each command has its own help:

<<< @/examples/output/heat_4-help.ansi{ansi}

<<< @/examples/output/heat_4-run-help.ansi{ansi}

::: tip What you learned
Commands, aliases, options shared between commands, dispatch with `run_command`, several commands on one line.
Reference: [Subcommands](/guide/subcommands).
:::

Next: [5. Values from everywhere](./05-sources).

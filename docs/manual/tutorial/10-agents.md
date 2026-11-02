# 10. Calling it from other programs

So far a person has read the help and the errors of `heat`. A workflow manager, a Python script or an AI agent also calls
programs, and it has to work out what a program takes, whether a command line is valid, and what to do when a call fails.
Text meant for a person makes it guess. This chapter gives it answers it can parse, with the same definitions.

Everything here is opt-in, and a program using none of it behaves as before.

<<< @/examples/snippets/heat_10-init.f90

<<< @/examples/snippets/heat_10-define.f90

## Say what a value is

`val_type` declares the type of a value, so that `parse` can check it before the program starts, from any source. Without it
FLAP only knows a value when `get` reads it, possibly hours into a run. `--steps` and `--cfl` declare theirs; `--label` is
free text.

## Describe the program

`schema_option=.true.` adds `--schema`, a JSON description of the program. A caller reads this once and knows every option,
type, range and default. `heat run --schema` describes one command, so a caller need not load the whole program:

<<< @/examples/output/heat_10-schema.ansi{ansi}

## Check before running

`check_option=.true.` adds `--check`, before or after the command. It runs every stage of `parse` and stops:

<<< @/examples/output/heat_10-check.ansi{ansi}

It names what it could not validate: here `--label` and `--token`, which have no declared type. A wrong value is reported with no run at all:

<<< @/examples/output/heat_10-check-bad.ansi{ansi}

## Errors a program can read

`error_format_env='HEAT_ERROR_FORMAT'` lets the caller ask for JSON errors, one line each, without colours or usage. The line
has the code, what to change (`class`), the option at fault and FLAP's suggestions:

<<< @/examples/output/heat_10-json.ansi{ansi}

## Exit statuses that say what to do

End the program with `cli%exit_status()`:

<<< @/examples/snippets/heat_10-parse.f90

<<< @/examples/output/heat_10-status.ansi{ansi}

Status 2 tells the caller to fix the command line and retry; 3, to fix a file or a variable; 4, not to retry at all, because
the program itself is wrong. Your own failures keep status 1. The whole table is in [Error Codes](/guide/errors#exit-statuses).

## Try it without doing it

`dry_run_option=.true.` adds `--dry-run`, but only your program can honour it:

<<< @/examples/snippets/heat_10-dry.f90

<<< @/examples/output/heat_10-dry.ansi{ansi}

::: warning A promise FLAP cannot keep for you
A program that enables `--dry-run` and forgets to read it performs the real action while its caller believes it did not. Enable
the option only once every side effect is guarded.
:::

## Record what ran

`save_provenance` writes a manifest of the run: the program, the command line, and each value with its source. It has no date,
host or directory, so the same inputs give the same bytes. `sensitive=.true.` keeps `--token` out of it, as `***`, and out of
error messages:

<<< @/examples/snippets/heat_10-manifest.f90

<<< @/examples/output/heat_10-manifest.ansi{ansi}

## Introduce it to an agent

`save_skill` writes a `SKILL.md`, the [Agent Skills](https://agentskills.io/specification) format, from the same definitions,
so it cannot fall out of date as long as you regenerate it at build time:

<<< @/examples/snippets/heat_10-skill.f90

<<< @/examples/output/heat_10-skill.ansi{ansi}

A good `--help` already serves an agent that has been told about the program ([the measurement](/guide/machine#agent-skill)).
The skill is how an agent learns that the program exists.

## In a script

A caller needs no FLAP code. [`flap_tool.py`](https://github.com/szaghi/FLAP/blob/master/docs/examples/files/flap_tool.py), about
70 lines of Python, turns `--schema` into the tool description an LLM API expects, and checks each call with `--check`.

::: tip What you learned
`val_type`, `--schema`, `--check`, JSON errors, `exit_status`, `--dry-run`, `save_provenance`, `sensitive`, `save_skill`.
Reference: [Machine-readable Interfaces](/guide/machine).
:::

That is the whole tour. For quick answers, see the [cookbook](../cookbook).

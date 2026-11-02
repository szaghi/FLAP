---
title: Machine-readable Interfaces
---

# Machine-readable Interfaces

Everything on this page is opt-in, for a program that another program calls: an agent, a job submission script, a CI
step. A program that uses none of it behaves as it always did.

<<< @/examples/snippets/solver-define.f90

## Declared types

Values are untyped until `get`, unless you declare their type with `val_type`. Then `parse` validates them, whatever
their source (command line, environment, configuration file):

<<< @/examples/output/solver_bad.ansi{ansi}

| `val_type` | Accepted |
|---|---|
| `I1P`, `I2P`, `I4P`, `I8P` | An integer that fits the kind |
| `R4P`, `R8P`, `R16P` | A real |
| `logical` | `T`, `.true.`, `false`, ... |
| `character` | Any text |

Typed values are also checked against their `choices` and their range during `parse`, and defaults and choices when the
option is added (`ERROR_TYPE_DEFINITION`). The kind is part of the declaration, so a value accepted by `parse` also fits a
`get` of that kind. To keep that promise, a `get` into another family or a narrower kind is always `ERROR_TYPE_MISMATCH`,
whatever the value. A `get` into a wider kind is allowed, and a real is checked in the wider kinds too: `1.00000001` is `1.0`
in `R4P` but above a maximum of `1` in `R8P`, so `parse` rejects it. A `get` into a `character` is always allowed and gives
the text as passed. A real too big for its kind is an error; an explicit `inf` is a value, and `nan` is outside every range.

Not allowed with `val_type`: maps, `act='config'`, `act='alternate'` and the print actions. A flag can only be `logical`,
a count an integer, a path check a `character`.

## Describing the program

`init(schema_option=.true.)` adds `--schema`; `cli%json_schema()` and `cli%save_json_schema(file)` give the same document
without it. Hidden options and builtins are left out, and the document is the same before and after `parse`.

<<< @/examples/output/solver_schema.ansi{ansi}

It also holds `schema_version`, `program`, `capabilities` and `errors` (the meaning of every code). This is FLAP's own
format, not one JSON Schema document, because commands, aliases and exclusive sets do not map onto one. The `value` of an
option uses JSON Schema 2020-12 keywords, plus `x-flap-kind`, so it can be passed on as it is.

`"typed": false` means FLAP does not know the type: without `val_type` the value is described as a string, or as a number
when it has a range. `schema_version` rises only on a breaking change.

## Errors as JSON lines

`init(error_format='json')` fixes the format. `init(error_format_env='NAME')` lets each caller choose, so the people
running the same program keep the text:

<<< @/examples/output/solver_json.ansi{ansi}

Each message is one line on the error unit, with `level` (`error` or `warning`), `code`, `message`, and `argument` and
`suggestions` when known. There are no colours, no `Try ... --help` line and no help after the message. `cli%error_message`
stays the plain message. The variable takes `text` or `json`; any other value means text.

### One command

A program with many commands has a long description, and an agent pays for every word. `prog cmd --schema`, or
`cli%json_schema(group='cmd')`, describes one command, by its name or an alias, without the top level or the code tables.

`save_json_schema(file, group='cmd')` saves it. An unknown command gives `''`, and `ERROR_MISSING_GROUP` from `save_json_schema`.

## Validating without running

`init(check_option=.true.)` adds `--check`, at the top level, so it comes before a command, whose tokens are its own. It runs every stage of `parse`,
then stops before the program uses a value:

<<< @/examples/output/solver_check.ansi{ansi}

<<< @/examples/output/solver_check_bad.ansi{ansi}

The exit status is 0 if valid and otherwise the [status of the error](./errors#exit-statuses), even when an error comes before `--check` on the command line. With JSON errors
the verdict is a line like `{"schema_version":1,"level":"result","valid":true,"unchecked":["--label"]}`. With
`standalone=.false.`, `parse` returns `STATUS_CHECK` or the error and the program decides.

What a valid result does not tell you:

- **Untyped options.** They are listed as not type-checked, because a failure would come only at `get`. So are an untyped
  count with a range and a flag that took its value from the environment or a configuration file.
- **An alternate action.** It skips the validation, as in a normal run. The verdict says so (`"bypassed":true`) and lists
  every option as not checked.
- **Relations between values.** Those are the program's business.
- **Paths elsewhere.** The path checks ran here: a valid result on a login node says nothing about a compute node.

Like `--help`, `--check` stops the program. A program that parses after `MPI_Init` stops without `MPI_Finalize`, so parse
first, or use `standalone=.false.`.

## Run manifest

`cli%provenance(format='json')` and `cli%save_provenance(file)` record the program, the command line, the status and every
value with its source. There is no date, host or directory, so the same inputs give the same bytes:

<<< @/examples/snippets/solver-manifest.f90

<<< @/examples/output/solver_manifest.ansi{ansi}

Values are strings exactly as resolved, so nothing is lost in a conversion. Hidden options are left out, as in the text
report: a manifest may not reproduce a run that uses them.

`cli%add(sensitive=.true.)` masks a value as `***` in both reports and in the recorded command line, and leaves its default
out of the help and of the JSON description. A sensitive positional leaves the command line out altogether (`null`). An
error message quotes it as `***` too: `cannot convert "***" of option "--token" to an integer!`. FLAP can mask only what it
attributes to the option: a misspelled `--tokn=abc` is an unknown argument, quoted as typed. The keys of a sensitive map stay
visible.

## Dry run

`init(dry_run_option=.true.)` adds a `--dry-run` flag at the top level, and `cli%is_dry_run()` reads it. Unlike `--check`, the
program runs, and it is the program that must skip its side effects:

```fortran
if (cli%is_dry_run()) then
  print '(A)', 'would write '//trim(file)
else
  call write_results(file)
endif
```

FLAP cannot enforce this, nor detect a program that never reads the flag: such a program performs the real action while its
caller believes otherwise. Enable the option only once every side effect is guarded. The JSON description declares it
(`capabilities.dry_run`) and the run manifest records it (`dry_run`).

## Using it from an agent

FLAP does not include an MCP server: that would need a JSON-RPC layer in the library, and tool calls fit long parallel runs
poorly. An adapter outside the program does the same work with what is above. This one uses only the Python standard library:

<<< @/examples/files/flap_tool.py

From `--schema` it builds the tool definition:

<<< @/examples/output/solver_tool.ansi{ansi}

For a call, it builds the command line and has the program validate it, without running it:

<<< @/examples/output/solver_tool_call.ansi{ansi}

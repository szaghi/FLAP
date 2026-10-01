# 8. Testing the command line

The command line of `heat` is part of its interface: it deserves tests. FLAP is built for it:

- `parse(args='...')` parses a string instead of the real command line, split as a shell would;
- `init(standalone=.false.)` makes `--help`, `--version`, ... return a status instead of ending the program;
- `init(usage_lun=, error_lun=)` sends the messages to a unit of your choice, a scratch file in a test;
- `reset_parse` forgets a parse, keeping the definitions, so one CLI can parse many command lines.

Put the definitions in one procedure, used by the program and by its tests:

<<< @/examples/snippets/heat_8-define.f90

<<< @/examples/snippets/heat_8-setup.f90

<<< @/examples/snippets/heat_8-checks.f90

<<< @/examples/output/heat_8.ansi{ansi}

Every error and status has a named constant (`ERROR_DUPLICATED_CLAS`, `STATUS_PRINT_H`, ...), exported by `flap`, so a
test never compares with bare numbers. FLAP's own test suite works this way: see
[`src/tests`](https://github.com/szaghi/FLAP/tree/master/src/tests).

::: tip What you learned
`parse(args=)`, `standalone=.false.`, output units, `reset_parse`, `get_source`, the named error constants.
Reference: [Parsing](/guide/parsing#testing-with-a-fake-command-line), [Error Codes](/guide/errors#handling-status-codes).
:::

Next: [9. Asking the user](./09-asking).

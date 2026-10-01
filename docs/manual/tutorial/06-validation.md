# 6. Validation

A simulation that fails after an hour because of a typo in a file name is a wasted hour. `heat` checks its command line
before doing anything.

<<< @/examples/snippets/heat_6-define.f90

- The initial field comes from **exactly one** of `--init` and `--restart`: a required mutually exclusive set.
- `readable=.true.` makes `parse` check that the restart file exists and can be read.
- `--dt` is **deprecated**: still accepted, with a warning.
- `--list-schemes` is an **alternate action**: `parse` returns `STATUS_ALTERNATE`, skipping the value checks, so it works
  without `--init`.
- `usage_on_error='usage'` (in `init`) prints the usage line after a missing option, instead of the whole help.

<<< @/examples/snippets/heat_6-init.f90

<<< @/examples/snippets/heat_6-parse.f90

## The checks at work

<<< @/examples/output/heat_6.ansi{ansi}

<<< @/examples/output/heat_6-restart.ansi{ansi}

<<< @/examples/output/heat_6-none.ansi{ansi}

<<< @/examples/output/heat_6-both.ansi{ansi}

<<< @/examples/output/heat_6-path.ansi{ansi}

<<< @/examples/output/heat_6-dt.ansi{ansi}

<<< @/examples/output/heat_6-list.ansi{ansi}

A check only the program knows (`--nx` must be even) is reported with `raise_error`, in FLAP's style:

<<< @/examples/output/heat_6-odd.ansi{ansi}

::: tip What you learned
Exclusive sets, path checks, deprecations, alternate actions, `raise_error`, `usage_on_error`.
Reference: [Advanced Features](/guide/advanced), [Error Codes](/guide/errors).
:::

Next: [7. Shipping it](./07-shipping).

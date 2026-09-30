---
title: Upgrading
---

# Upgrading

Every change you can observe when moving to a new release, newest first. Additive releases only add API: existing
programs keep their behaviour. The plan behind them is issue [#125](https://github.com/szaghi/FLAP/issues/125).

## v2.4.0 (additive)

- `init(usage_on_error='usage')` (or `'none'`) prints the usage line (or nothing) after a missing required option,
  instead of the whole help; the default `'full'` keeps the old output (issue #102). New error 1014.
- `init(man_option=.true.)` adds a `--man` switch saving the man page, like `--markdown` (new status
  `STATUS_PRINT_MAN`, −8); `init(man_file=, markdown_file=)` name the files of both (issue #99).
- `cli%provenance()` no longer lists the completion builtins, and `copy_options` no longer copies them.

## v2.3.1 (fix)

- A command passed more than once (`prog commit -m x commit`, or the command and one of its aliases) is now
  `ERROR_COMMAND_REPEATED` (1013). It used to restart the command's arguments silently, losing the values given before
  it (issue #87).

## v2.3.0 (additive)

- A new, optional module for interactive menus (F23): `type(menu)` with `init`, `add_option` and `run`, exported by
  `flap`; a default option answers an empty line (`add_option(is_default=)`, `init(default_icon=)`); invalid answers
  can be asked again (`init(loop_on_invalid=, tries=)`); several options can be chosen (`init(multiple=, separator=)`,
  `run(choices)`); `yes_no` asks a yes/no question; colours via `init(option_color=, question_color=, error_color=, ...)`;
  errors 2001–2006 (see [Interactive Menus](./menu)). The parser does not use it: nothing changes for existing programs.

## v2.2.0 (additive)

- `add(..., metavar='FILE')` names the value in the usage, help, man page and Markdown (F12); the default stays `value`.
- **The bash completion script changes**: it is registered with `complete -o default`, so a free value falls back to file
  names; regenerate it. `cli%save_zsh_completion(zsh_file)`, `cli%save_fish_completion(fish_file)` and
  `cli%save_powershell_completion(powershell_file)` write zsh, fish and PowerShell scripts (F15).
- `init(completion_options=.true.)` adds `--show-completion [SHELL]` and `--install-completion [SHELL]` (F24); new
  statuses −6, −7 and errors 1010, 1011; `cli%completion_script(shell)` returns a script as a string.

## v2.1.0 (additive)

- `add(..., min=, max=, min_open=, max_open=, clamp=)` gives a numeric option a range, checked by `get` (see
  [Advanced](./advanced#numeric-ranges)).
- `add(..., switch_neg='--no-x')` gives a `store_true`/`store_false` flag a negation; the last of the two passed wins
  (see [Flag pairs](./arguments#flag-pairs-switch-neg)). New error `ERROR_SWITCH_NEG_INCONSISTENT` (36).
- `init(case_insensitive=.true.)` matches switches and command names in any case; `add(case_sensitive=.false.)` matches
  character choices in any case, returning the declared spelling.
- `add_group(..., aliases='co,ck')` gives a command aliases, resolved everywhere (F19); new error `ERROR_GROUP_ALIAS`
  (1008). `add_group` gains `error=`, and, as `add`, reports only its own definition.
- An unknown switch or command is reported with "Did you mean" suggestions (`ERROR_UNKNOWN` unchanged; the message gains
  the hint).
- `add(..., map=.true., map_keys=)` declares a `KEY=VALUE` option, read with `get_map` and `get_map_value` (F18); new
  errors 38–42. See [Key=value options](./arguments#key-value-options-map).
- `cli%copy_options(to_group, from_group, switches)` copies option definitions between commands (F21); new error
  `ERROR_COPY_POSITIONAL` (1009).
- With real quad precision (`-D_R16P`), `get` into `real(R16P)` now converts in quad precision (it converted in single
  precision, B35 of #125).

## v2.0.0 (breaking)

- An explicitly empty value (`--opt ""`, `--opt=`, an empty `append` occurrence) is accepted as the empty string (it
  was `ERROR_VALUE_MISSING`, 14); a numeric option then fails its cast in `get`. An empty environment variable or
  configuration value still counts as unset.
- `nargs='*'` passed with no values gives an empty list (`get_varying` returns a size-0 array); the default applies only
  when the option is absent. An empty list (for instance a `def=''` default) is returned as a size-0 array, not left
  unallocated.
- `init(standalone=.false.)` makes `parse` return the help/version/Markdown status instead of stopping; with several
  of them passed, a syntax error anywhere on the command line wins, then help, version, Markdown (`--help compile --bogus`
  reports the unknown switch instead of printing the help).
- A failed `parse` prints one more line, `Try 'prog --help' for help.`; `init(error_hint=.false.)` restores the old
  output.
- The `examples` component of the CLI, its groups and arguments holds `flap_string` elements: read an example as
  `cli%examples(i)%s` (it was `cli%examples(i)`). Examples are still set with `init(examples=...)` and
  `add_group(examples=...)`, unchanged. FLAP now builds and runs with nvfortran.
- Every value records its source, one of the new constants `SOURCE_COMMANDLINE` (1), `SOURCE_ENVIRONMENT` (2),
  `SOURCE_CONFIG` (3), `SOURCE_DEFAULT` (4), `SOURCE_NONE` (5), ordered from the most to the least explicit: a value
  with a source below `SOURCE_DEFAULT` is given by the user. `get` reads such a value, the default otherwise, and a
  required option is satisfied by any of these explicit sources. `is_passed` keeps its meaning: seen on the command
  line.
- `init(ignore_env=.true.)` turns every environment lookup off, for reproducible runs; `envvar` names stay in the help.
- **The environment is a value source when the switch is absent**: with `envvar='X'`, `X` set and not blank gives
  the value (it used to be read only by the bare switch, an absent switch giving the default). The command line still
  wins, a blank variable counts as unset, and the value satisfies a required option. Flags (`store_true`/`store_false`)
  accept an `envvar` too, reading `1/0`, `true/false`, `yes/no`, `on/off`, ... Lists (`nargs`) accept an `envvar` too,
  reading comma-separated values (`ERROR_ENVVAR_NARGS` is no longer raised). More (configuration files): see issue
  [#125](https://github.com/szaghi/FLAP/issues/125).
- `init(auto_envvar_prefix='APP')` gives every option without `envvar` the variable `APP[_COMMAND]_NAME`.
- `cli%set_config(file='app.ini')` reads values from an INI file, below the environment and above the defaults.
- `cli%get_source(switch=...)` tells where a value comes from; `cli%provenance()` reports every value with its source.
- `add(..., must_exist=, readable=, writable=, allow_dash=)` checks file-name values at parse time.
- `add(..., deprecated=)` and `add_group(..., deprecated=)` warn when a deprecated option or command is used.
- `act='alternate'` declares an auxiliary action (`--list-models`): `parse` returns `STATUS_ALTERNATE` and skips the
  value validation. The pairwise `exclude=` check now runs with the other value checks, after `--help`/`--version`.

## v1.3.0

v1.3.0 is the last 1.x release. It fixes the bugs registered in issue
[#125](https://github.com/szaghi/FLAP/issues/125) (B01–B29) and prepares the internals for v2.0.0; the public API is
unchanged, but some mistakes that used to pass silently are now reported. This page lists every change you can observe.

### Definitions that are now errors

These CLIs were broken before (some values were never reachable); `add`, or the start of `parse`, now says so.

| Definition | Error | Fix |
|---|---|---|
| `nargs` on a positional argument | `ERROR_POSITIONAL_NARGS` (45) | Positionals take one value each: use a named list option |
| `nargs='N'` with a default of another number of values (`nargs='3', def='a b'`) | `ERROR_DEF_NARGS` (48), at `add` | Give the default N values |
| A position declared twice | `ERROR_POSITION_DUPLICATE` (105), at `add` | One positional per position |
| Positions with a gap (`1` and `3` without `2`) | `ERROR_POSITION_GAP` (106), when parsing starts | Positions must be `1..N` |

### Parsing and getting values

| Case | Before | Now |
|---|---|---|
| A switch passed twice (`-i 1 -i 2`) | reported as unknown (15), or an out-of-bounds write for lists | `ERROR_DUPLICATED_CLAS` (23), parsing stops |
| Positionals declared out of order, or mixed with options | assigned by declaration index | assigned by their declared `position`, wherever they appear |
| An argument beyond the last position | appended a dummy argument | unknown argument (15) |
| An option value equal to a command name (`init --msg commit`) | taken as the command | the option's value |
| `nargs='N'` followed by more than N values | `ERROR_NARGS_INSUFFICIENT` (13) | the option takes N values; the next one is the next argument (argparse) |
| `choices` on a list | checked on the scalar `get` only | checked on every value, by `get` and `get_varying` (`ERROR_NOT_IN_CHOICES`, 7) |
| `get` into an unsupported type (e.g. `complex`) | variable silently untouched | `ERROR_UNSUPPORTED_TYPE` (46) |
| `get` into a fixed-size array of the wrong size | wrote past its end, or left elements unset | `ERROR_LIST_SIZE` (47), array untouched; use `get_varying` for lists of unknown length |
| A list of flags (`store_true`/`store_false` with `nargs`) left to its default | only the first default value was read | every default value |
| `get_varying` on a list of flags | unallocated array, error 0 | the defaults, or as many `.true.`/`.false.` when passed |
| `get_varying` with a non-logical value into a logical list | crash | `ERROR_CASTING_LOGICAL` (10) |
| A `get` after a failed `get` | returned the previous error without reading its value | each `get` reports only its own error |
| A list or varying `get` with an unknown `group=` | continued on an undefined group | `ERROR_MISSING_GROUP` (1001), returns at once |
| Arguments longer than 512 characters (gfortran) | truncated | read whole; `ERROR_ARGUMENT_RETRIEVAL` (1012) if the system cannot return one |
| Environment values longer than 500 characters | reported as a missing value (14) | read whole |
| Quotes in `parse(args=...)` (`--msg "it's done"`) | split or corrupted | shell-like splitting (see [Parsing](./parsing#testing-with-a-fake-command-line)) |
| A switch with blanks around it in `get`/`is_passed`/`is_defined` (`' -v'`) | not found | found, as on the command line |
| `is_defined_group(group=unknown, g=g)` | `g` = index of the last group | `g = -1` |

An explicitly empty value (`--opt ""`) is still rejected with `ERROR_VALUE_MISSING` (14), and `nargs='*'` passed with no
values still takes the default: both change in v2.0.0 (see below).

### New API

- All error and status codes are exported by the `flap` module (see [Error Codes](./errors)), including the new 45–48,
  105, 106 and 1012.
- `cli%reset_parse()` forgets the result of a parse, keeping the definitions, so the same CLI can parse another command
  line (see [Parsing more than once](./parsing#parsing-more-than-once)).
- `command_line_argument` renders each output separately: `signature_usage`, `completion_words`, `completion_values`
  (`signature` still works and dispatches to them).

### Generated outputs

- **Bash completion scripts change**: regenerate them. The script now starts with `#!/usr/bin/env bash` (the `!` was
  missing), is always a `_completion` function (also without commands), offers each switch once (the top level used to
  offer bogus words and every switch twice), and finds the command on every call instead of remembering it between
  TABs.
- `usage`, `signature` and the `save_*` outputs include the builtin switches (`--help`, `--version`, `--markdown`) also
  when called before `parse`.
- With `error=`, `save_bash_completion`, `save_man_page` and `save_usage_to_markdown` report a file that cannot be written
  instead of stopping the program.

### Compilers and builds

- gfortran 13.3 and 14.2 (the Ubuntu 24.04 defaults) corrupted character values read into a fixed-size array: worked
  around. The suite passes with gfortran 13, 14, 15 and 16, and with FoBiS, CMake, fpm and make.
- The fpm manifest pins FACE and PENF to the same commits as `fobos.lock`.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FLAP (Fortran command Line Arguments Parser for poor people) is a pure Fortran library for building CLIs, inspired by Python's `argparse`. It supports optional/required/boolean/positional/list arguments, mutually exclusive groups, nested subcommands (groups), environment-variable fallback, and automatic help/usage/man page/bash completion/markdown generation.

Roadmap: GitHub issue **#125** is the authoritative consolidated implementation plan (bug register, error-code registry, phases 0–5, release train v1.3.0 → v2.0.0 → v2.x). The per-library issues #1, #11, #25, #77, #78, #113 hold the detailed designs and test tables; where they disagree with #125, #125 wins.

## Build Commands

FoBiS (CLI `fobis`, 3.8+) is the primary build tool and the one used in CI. Use the long-form flags (`--mode`, `--ex`, `--coverage`); FoBiS 3.8.22 still accepts the legacy single-dash forms, but new scripts, rules and docs use the long form.

```bash
fobis fetch                                  # fetch PENF and FACE into src/third_party/ (pinned by fobos.lock)
fobis build --lmodes                         # list modes
fobis build --mode tests-gnu                 # build all tests into exe/
fobis build --mode tests-gnu-debug           # debug tests (-fcheck=all, coverage flags)
fobis build --mode static-gnu                # static library
fobis clean --mode tests-gnu-debug           # needed when stale gcov objects in exe/obj break the debug link
fobis rule --ex delexe                       # wipe exe/ (fobis clean keeps executables); do it when switching modes
fobis build --mode tests-gnu-r16p            # debug tests with -D_R16P: real quad precision (R16P = real128)
bash scripts/run_tests.sh                    # run every binary in exe/ (exit 0 = PASS; *_xfail_* must exit non-zero)
fobis rule --ex makedoc                      # API docs (formal) + VitePress site
```

Modes: `shared-gnu`, `static-gnu`, `shared-gnu-debug`, `static-gnu-debug`, `tests-gnu`, `tests-gnu-debug`, and the same six for `intel`, plus `static-nvf` and `tests-gnu-r16p`. All test modes share `exe/` (hard-coded in `scripts/run_tests.sh`), so wipe it with `fobis rule --ex delexe` when switching modes.

Alternative build systems (kept working, not the reference): `fpm build` / `fpm test <name>`, `make`, `cmake -B build && cmake --build build`. Their source/test lists are explicit and can drift from the tree:
- `fpm.toml` has `auto-tests=false`: every new test needs a `[[test]]` entry;
- the FACE/PENF `rev` pins in `fpm.toml` must match the commits in `src/third_party/fobos.lock` (update both together).

## Tests

Tests are standalone programs in `src/tests/flap_test_*.f90`, and every one asserts (a failed check ends with `error stop`, exit status 1). Most example-derived tests have two modes: **with arguments** they are the original example program (parsing the real command line); **without arguments** (how `run_tests.sh`, fpm and ctest run them) they check their scenarios in-process with `parse(args=...)`, capturing FLAP messages. Known bugs are asserted as they behave today, with a `! Bnn (#125)` comment: the fix must flip that assertion. New tests must assert: use `src/tests/flap_test_utils.F90` (`assert`, `assert_equal`, `assert_contains`; `capture_open`/`read_back` to capture FLAP output via `init(usage_lun=, error_lun=)`; `reinvoke`/`child_case` to re-run the test as a child process for environment variables, stdin, exit statuses and `--help`/`--version`). `flap_test_harness.f90` is the reference example. Generated outputs (usage per group, man page, markdown, bash completion, `<group> --help`) are pinned by `flap_test_golden` against `src/tests/golden/`; after an **intended** output change regenerate them with a reference compiler (`FLAP_TEST_GOLDEN_UPDATE=1 ./exe/flap_test_golden`, run from the repo root) and review the diff. The files keep significant trailing blanks (see `.gitattributes`). A new test also needs a `[[test]]` entry in `fpm.toml`; CMake and FoBiS pick it up automatically.

CI: `.github/workflows/ci.yml` (gcc-14 coverage) and the other files listed by `fobis scaffold list` are scaffold-managed (overwritten by `fobis scaffold sync`): do not edit them. Project-specific jobs go in `.github/workflows/matrix.yml` (gfortran 13/14/15 + `tests-gnu-r16p`, the gfortran-16 trunk snapshot allowed to fail, fpm/CMake/make builds).

Reference compilers: gfortran 13 and 14; the suite also passes with gfortran 15 and the 16 trunk.

## Architecture

### Module Dependency Chain

```
flap.f90                                         ← public interface (use this in consuming code)
└── flap_command_line_interface_t.F90            ← main CLI type
    └── flap_command_line_arguments_group_t.f90  ← groups / subcommands
        └── flap_command_line_argument_t.F90     ← individual argument
            ├── flap_object_t.F90                ← base class (error handling, common metadata)
            ├── flap_utils_m.f90                 ← string helpers (tokenize, unique, ...)
            ├── PENF                             ← numeric kinds, cton/str
            └── FACE                             ← ANSI colours
```

All library source is in `src/lib/`. Dependencies (PENF, FACE) are fetched with `fobis fetch` into `src/third_party/`; they are not git submodules.

### Key Types

| Type | File | Role |
|------|------|------|
| `command_line_interface` | `flap_command_line_interface_t.F90` | Top-level API: `init`, `add`, `add_group`, `parse`, `get`, `get_varying`, `usage`, `save_*` |
| `command_line_arguments_group` | `flap_command_line_arguments_group_t.f90` | Named group of CLAs: subcommands and mutually exclusive groups; token-level parsing |
| `command_line_argument` | `flap_command_line_argument_t.F90` | Single argument: switch, abbreviation, action, default, nargs, choices, envvar; value casting |
| `object` | `flap_object_t.F90` | Base class: error code/message, help, examples, progname |

### Invariants that are easy to break

- Arguments are untyped until `get`: values are stored as strings and cast in `get` via `class(*)` + `select type`.
- List values are stored as `v1||!||v2||!||` (`LIST_SEP` plus a trailing separator; sanitized defaults have no trailing one). Only the list API of `flap_utils_m` knows the format: `list_push` (parser), `list_items`/`list_count` (every list getter), `list_join` (usage). `list_items` relies on `tokenize` dropping the trailing empty token: do not "fix" it.
- Switch names are matched only by `command_line_argument%match_token` (decision D1 of #125, rule 1: exact) and `match_inline_token` (rule 2: `NAME=VALUE`, built on rule 1); the parser and its look-ahead (`is_switch_token`) use the latter, while `is_defined`/`is_passed`/`value_arity` stay exact. Never compare `switch`/`switch_ab` directly: inline values, `-vvv`, negation and case folding extend the matcher, not its callers.
- Positionals are looked up by their **declared** `position` (`positional_index`), never by an index into the CLA list or by token position.
- Builtins (`--help`, `--version`, `--markdown`, `--`) are added by `ensure_builtins`: `parse` calls it, and every output method (`usage`, `signature`, `save_*`) works on a copy with the builtins, so its output is the same before and after `parse`. A new output method must follow the same wrapper + `*_core` pattern.
- The environment is read only through `read_env` (`flap_utils_m`), whatever the value length; `flap_test_envvar` fails if another library file calls `get_environment_variable`. Every call passes `ignore=` the CLI `ignore_env` (F20), which reaches the groups as a `parse` argument, like `ignore_unknown_clas`.
- `parse` only guards (already parsed) and returns the error; the stages live in the private `parse_core`, and `is_fatal` decides whether an error stops them (an ignored unknown argument does not). Every error message starts with `object%error_prefix(pref)`.
- Group (command) names are resolved only by the private `group_index` (-1 when there is no such group, 0 is the top level `''`); `is_defined_group` wraps it. Aliases (F19) extend the resolver, not its callers.
- An argument has one renderer per output: `signature_usage` (usage text), `completion_words` (bash word list) and `completion_values` (bash `prev` test); `signature` only dispatches. A rendering change (metavar, `...`, `--x/--no-x`) goes into `signature_usage`, never into the completion renderers.
- Mutually exclusive sets (`set_mutually_exclusive_switches`, F03) are stored per group as lists of **switch names**, never as CLA indexes: adding a positional inserts it into the CLA list and shifts the indexes. They are checked by `check_exclusive_sets` in the post-parse stage of `parse_core` (after the statuses and the required check, E4), and rendered once by the group `signature` as `(a | b)`/`[a | b]` with `signature_usage(bare=.true.)`.
- Every CLA value has a `source` (`SOURCE_COMMANDLINE` < `ENVIRONMENT` < `CONFIG` < `DEFAULT` < `NONE`, R chain of F06). The getters and the required check use `has_value()` (`source < SOURCE_DEFAULT`), never `is_passed`, which keeps its meaning "seen on the command line". The source of a parsed value is set **while parsing** (where `is_passed` is set; `SOURCE_ENVIRONMENT` in the envvar branch), so it survives a parse stopped by an error; `resolve_values` (CLI `parse_core`, after the statuses, before the required check) only settles the other CLAs (default or none). `reset_parse` resets it.
- The environment is a value source (F07): the bare switch reads its variable while parsing, an absent option reads it in `resolve_values` (set and not blank: `set_env_value`, which also maps the flag words `yes/no`, `on/off`, ... to `.true.`/`.false.`). Flags take their constant value only when passed on the command line (`source == SOURCE_COMMANDLINE`); otherwise the getters read the stored value (environment or default).
- **gfortran bug (13–16):** a *section* of a deferred-length character array (`a(2:3)` with `character(len=:), allocatable :: a(:)`) passed to an assumed-shape `character(*)` dummy arrives starting at the first element of the whole array. Pass a whole-array copy instead (see the group call in `parse`).
- **nvfortran 26.5 bug (B33 of #125):** copying a derived type with a `character(len=:), allocatable :: a(:)` component writes past the allocation. Never add such a component: store arrays of strings as `type(flap_string), allocatable :: a(:)` (`flap_utils_m`; `a(i)%s`), as `examples` and the CLI `args` do. Library `stop`s go through `quiet_stop` (nvfortran rejects `stop, quiet=` and prints `FORTRAN STOP` on a plain `stop`). A second nvfortran 26.5 bug is in the **caller**: a variable passed to a `class(*)` dummy (every `get`) from several call sites of one scope (host-associated uses in internal procedures included) gets its descriptor set up at one site only, so a call executed before the first site in the source sees it uninitialised (value not set, or a crash). In tests, give each `get` call site its own variable (a local in each helper); with that, nvfortran passes the whole suite.
- **gfortran 16 trunk (r16-8100) regression:** it miscopies the CLI object with those `flap_string` components (a command name arrives with length 0), failing 5 tests; gfortran 13/14/14.2 and nvfortran are correct. Accepted (the gfortran-16 CI job may fail); B17 was the same copy.
- **gfortran 13.3 / 14.2 bug** (Ubuntu 24.04 default compilers; fixed in 13.4 and 14.3): inside `type is(character(*))` on a `class(*)` *array* dummy, element assignment uses a wrong element length. Delegate to a helper with a plain `character(*)` array dummy (see `get_cla_list_character`). CI covers these versions: the fobis gfortran-13 job and the cmake/fpm/make jobs use the Ubuntu archive compilers.
- Whole-object copies use intrinsic (deep) assignment: the types have no `assignment(=)` overloads. The one explicit copy is `object%assign_object` (the object part only): a component added to `object` must be added there too, and `flap_test_copy` fails otherwise.

### Preprocessor

`.F90` files are preprocessed, `.f90` are not. Quad precision is gated on `#if defined _R16P` in both FLAP and PENF. The fobos templates and the CMake support check define `-D_R16P_SUPPORTED`, which **does not** enable that branch: with the current build files `R16P` aliases `R8P` and the quad-precision code is never compiled. Define `-D_R16P` to compile it (mode `tests-gnu-r16p`).

### `get` Overloading

`command_line_interface%get` covers every PENF kind (`R16P`, `R8P`, `R4P`, `I8P`, `I4P`, `I2P`, `I1P`), `logical` and `character`, scalar and fixed-size arrays; `get_varying` returns allocatable arrays for `nargs='+'/'*'` lists.

## Coding Style

From `CONTRIBUTING.md`:
- Indent with 2 spaces, no tabs
- `implicit none` on all modules and programs
- Self-documenting names; FORD-style `!<` docstrings on public APIs
- Line length ≤ 132 characters

## Documentation

Docs are a **VitePress** site in `docs/` (guide in `docs/guide/`, API pages generated by `formal` into `docs/api/` from `docs/ford.md`). Build with `fobis rule --ex makedoc`, or `cd docs && npm ci && npm run docs:build`.

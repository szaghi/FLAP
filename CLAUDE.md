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
- List values are stored as `v1||!||v2||!||` (`ARGS_SEP` plus a trailing separator). `tokenize` dropping the trailing empty token is load-bearing: do not "fix" it.
- Switch names are matched only by `command_line_argument%match_token` (decision D1 of #125); the parser's look-ahead uses the group's `is_switch_token`. Never compare `switch`/`switch_ab` directly: inline values, `-vvv`, negation and case folding extend the matcher, not its callers.
- Positionals are looked up by their **declared** `position` (`positional_index`), never by an index into the CLA list or by token position.
- Builtins (`--help`, `--version`, `--markdown`, `--`) are added by `ensure_builtins`: `parse` calls it, and every output method (`usage`, `signature`, `save_*`) works on a copy with the builtins, so its output is the same before and after `parse`. A new output method must follow the same wrapper + `*_core` pattern.
- Environment variables are read only when the bare switch is passed; an absent switch yields `def` even if the variable is set.
- **gfortran bug (13–16):** a *section* of a deferred-length character array (`a(2:3)` with `character(len=:), allocatable :: a(:)`) passed to an assumed-shape `character(*)` dummy arrives starting at the first element of the whole array. Pass a whole-array copy instead (see the group call in `parse`).
- **gfortran 13.3 / 14.2 bug** (Ubuntu 24.04 default compilers; fixed in 13.4 and 14.3): inside `type is(character(*))` on a `class(*)` *array* dummy, element assignment uses a wrong element length. Delegate to a helper with a plain `character(*)` array dummy (see `get_cla_list_character`). CI covers these versions: the fobis gfortran-13 job and the cmake/fpm/make jobs use the Ubuntu archive compilers.
- The type-bound `assignment(=)` overloads are private and unreachable from other modules; whole-object copies across modules use intrinsic (deep) assignment.

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

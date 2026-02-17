# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FLAP (Fortran command Line Arguments Parser for poor people) is a pure Fortran 2003+ library for building CLIs, inspired by Python's `argparse`. It supports optional/required/boolean/positional/list arguments, mutually exclusive groups, nested subcommands, and automatic help/usage/man page/bash completion/markdown generation.

## Build Commands

FLAP supports four build systems. **FPM is recommended** for development:

```bash
# FPM (Fortran Package Manager) - recommended
fpm build                          # build library
fpm test                           # run all tests
fpm test flap_test_basic           # run a single test by name

# FoBiS.py - used in CI, supports coverage
FoBiS.py build -mode tests-gnu              # build all tests with GNU
FoBiS.py build -mode static-gnu            # build static library
FoBiS.py build -mode shared-gnu            # build shared library
FoBiS.py rule -ex makecoverage             # build + run tests + gcov coverage

# GNU Make
make                               # build with default settings

# CMake
cmake -B build && cmake --build build
```

Available FoBiS modes: `shared-gnu`, `static-gnu`, `shared-gnu-debug`, `static-gnu-debug`, `tests-gnu`, `tests-gnu-debug`, `shared-intel`, `static-intel`, `shared-intel-debug`, `static-intel-debug`, `tests-intel`, `tests-intel-debug`, `static-nvf`.

## Running Tests

Tests live in `src/tests/`. With FPM, each test corresponds to an `fpm.toml` `[[test]]` entry. The CI script for running all built test executables is `scripts/run_tests.sh`.

Test names (for `fpm test <name>`):
- `flap_test_minimal`, `flap_test_basic`, `flap_test_nested`, `flap_test_group`, `flap_test_group_examples`
- `flap_test_string`, `flap_test_choices_logical`, `flap_test_hidden`
- `flap_test_duplicated_clas`, `flap_test_ignore_unknown_clas`
- `flap_test_save_bash_completion`, `flap_test_save_man_page`, `flap_test_save_usage_to_markdown`
- `flap_test_ansi_color_style`

## Architecture

### Module Dependency Chain

```
flap.f90                             ← public interface (use this in consuming code)
└── flap_command_line_interface_t.F90  ← main CLI type
    ├── flap_command_line_arguments_group_t.f90  ← groups / subcommands
    │   └── flap_command_line_argument_t.F90     ← individual argument
    │       ├── flap_object_t.F90                ← base class
    │       ├── flap_utils_m.f90
    │       ├── PENF (precision kinds)
    │       └── FACE (ANSI color output)
    └── (same sub-deps)
```

All source is in `src/lib/`. Third-party dependencies are git submodules in `src/third_party/`: **PENF** (numeric precision kinds), **FACE** (ANSI terminal colors), **fortran_tester** (test assertions).

### Key Types

| Type | File | Role |
|------|------|------|
| `command_line_interface` | `flap_command_line_interface_t.F90` | Top-level API: `init`, `add`, `parse`, `get`, `usage`, `save_*` |
| `command_line_arguments_group` | `flap_command_line_arguments_group_t.f90` | Named group of CLAs, used for subcommands and mutually exclusive groups |
| `command_line_argument` | `flap_command_line_argument_t.F90` | Single argument: switch, abbreviation, action, default, nargs, choices, env var |
| `object` | `flap_object_t.F90` | Base class providing error handling |

### Preprocessor

The codebase uses cpp. The flag `-D_R16P_SUPPORTED` is set in all FoBiS templates and enables quad-precision (`R16P`) support from PENF. Files with `.F90` extension (capital F) are preprocessed; `.f90` are not.

### `get` Overloading

`command_line_interface%get` has overloaded variants for every PENF kind (`R16P`, `R8P`, `R4P`, `I8P`, `I4P`, `I2P`, `I1P`), plus `logical` and `character`. List variants exist via `get_varying` / action `store_*`.

## Coding Style

From `CONTRIBUTING.md`:
- Indent with 2 spaces, no tabs
- `implicit none` on all modules and programs
- Self-documenting names; FORD-style docstrings on public APIs
- Line length ≤ 132 characters

## Documentation

Generate API docs with FORD:
```bash
FoBiS.py rule -ex makedoc   # runs ford doc/main_page.md
```

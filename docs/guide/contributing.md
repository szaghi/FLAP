---
title: Contributing
---

# Contributing

Contributions to FLAP are welcome. This page covers the coding conventions and
workflow expected for contributions.

## Coding style

- **Standard**: Fortran 2003+ only; no compiler extensions.
- **Indentation**: 2 spaces. No tabs.
- **Line length**: ≤ 132 characters.
- **Implicit**: `implicit none` in every module and program.
- **Names**: self-documenting, lowercase with underscores.
- **Documentation**: FORD-style doccomments on all public procedures and types.

## Workflow

1. Fork the repository on GitHub.
2. Create a feature branch: `git checkout -b feat/my-feature`.
3. Write your changes and add or update tests in `src/tests/`.
4. Run the full test suite: `fpm test` or `FoBiS.py rule -ex makecoverage`.
5. Commit using [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat: add support for …`
   - `fix: correct off-by-one in …`
   - `docs: update getting-started guide`
6. Open a pull request against `master`.

## Running tests

```bash
# FPM (recommended)
fpm test

# Run a single test
fpm test flap_test_basic

# FoBiS.py with coverage
FoBiS.py rule -ex makecoverage
```

## Reporting issues

Please open an issue on [GitHub](https://github.com/szaghi/FLAP/issues) with:

- FLAP version (or commit hash)
- Fortran compiler and version
- A minimal reproducible example
- Expected vs. actual behaviour

## License

By contributing you agree to licence your contribution under the same multi-licence
terms as the project (GPLv3 / BSD 2-Clause / BSD 3-Clause / MIT).

---
title: Contributing
---

# Contributing

This is a FOSS project — anyone interested in using, developing, or contributing
is welcome. The project follows a KISS (Keep It Simple and Stupid) philosophy.

## Reporting Issues

- Open a ticket on the repository **GitHub Issues** page
- Clearly describe the problem, including steps to reproduce for bugs
- Note the earliest version you know has the issue

## Pull Requests

1. Fork the repository on GitHub
2. Create a topic branch from `master`:
   ```bash
   git checkout -b fix/master/my_contribution master
   ```
3. Test your changes with `FoBiS.py build -f src/tests/fobos && bash scripts/run_tests.sh`
4. Check for unnecessary whitespace: `git diff --check`
5. Submit a pull request with a clear commit message

## Fortran Coding Style

- **Clarity over brevity**: `real :: gas_ideal_air` is better than `real :: gia`
- Single-character variable names only for loop counters
- Name all constants
- `implicit none` in every module and program
- Declare `intent` for all procedure arguments, ordered: pass arg → `inout` → `in` → `out` → optional
- Indent with two spaces (not tabs)
- No trailing whitespace; blank lines must contain no spaces
- Use `>, <, ==` instead of `.gt., .lt., .eq.`
- Avoid Windows-style CRLF line endings

### Recommended git whitespace settings

```ini
[color]
  ui = true
[color "diff"]
  whitespace = red reverse
[core]
  whitespace = fix,-indent-with-non-tab,trailing-space,cr-at-eol
```

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/) so that `CHANGELOG.md` is generated automatically from the git log:

| Prefix | Purpose | Changelog section |
|--------|---------|-------------------|
| `feat:` | New feature or capability | New features |
| `fix:` | Bug fix | Bug fixes |
| `perf:` | Performance improvement | Performance |
| `refactor:` | Code restructuring | Refactoring |
| `docs:` | Documentation only | Documentation |
| `test:` | Tests | Testing |
| `build:` | Build system | Build system |
| `ci:` | CI/CD pipeline | CI/CD |
| `chore:` | Maintenance | Miscellaneous |

Append `!` for breaking changes (`feat!:`, `fix!:`). Reference issues with `#123` — they are auto-linked.

```
feat: add R32P kind parameter
fix: correct byte_size for character arrays (#42)
feat!: rename check_endian to init_endian
```

---

## Creating a release

Releases are fully automated via `scripts/bump.sh` and GitHub Actions. The only steps needed are:

```bash
# Install git-cliff once
npx git-cliff@latest

# Then, to release:
scripts/bump.sh patch   # v1.2.3 → v1.2.4
scripts/bump.sh minor   # v1.2.3 → v1.3.0
scripts/bump.sh major   # v1.2.3 → v2.0.0
scripts/bump.sh v2.1.0  # explicit version
```

`bump.sh` will ask for confirmation, then:

1. Regenerate `CHANGELOG.md` from the git log via [git-cliff](https://git-cliff.org/)
2. Commit with `chore(release): vX.Y.Z`
3. Create an annotated git tag
4. Push commit + tag

Pushing the tag triggers the GitHub Actions release workflow, which automatically:
- Runs the full test suite and uploads coverage to Codecov
- Builds this documentation site and deploys it to GitHub Pages
- Packages a versioned tarball `StringiFor-vX.Y.Z.tar.gz`
- Publishes a GitHub release with the changelog section as release notes

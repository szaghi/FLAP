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
3. Test your changes with `fobis build --mode tests-gnu-debug && bash scripts/run_tests.sh` (run `fobis fetch` once
   first)
4. If you changed an output or a documented behaviour, regenerate the documentation examples (see below)
5. Check for unnecessary whitespace: `git diff --check`
6. Submit a pull request with a clear commit message

## Documentation examples

Every code sample and every output shown in the guide comes from a program in `docs/examples/src`, which is compiled and
run by

```bash
bash scripts/docs_examples.sh
```

The script builds the library (FoBiS, mode `static-gnu`), then regenerates `docs/examples/snippets` (the programs and
their `!region NAME` ... `!endregion NAME` parts, without the markers) and `docs/examples/output` (one file per
`!run ID COMMAND` line of a program: the command and its output, colours included). The pages include them with
VitePress snippet imports (`<<< @/examples/snippets/NAME.f90`, `<<< @/examples/output/ID.ansi{ansi}`). Commit the
regenerated files with your change: the `docs-examples` job of the Compiler matrix workflow fails when they differ from
what the code produces.

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
feat(cli): --man builtin and the file names of --man and --markdown
fix(parse): a repeated command is an error
feat(parse)!: an explicitly empty value is the empty string
```

---

## Creating a release

Releases are fully automated via `scripts/release.sh` and GitHub Actions. The only steps needed are:

```bash
# git-cliff must be installed once: cargo install git-cliff (or a release binary)

# Then, to release:
scripts/release.sh --patch   # v1.2.3 → v1.2.4
scripts/release.sh --minor   # v1.2.3 → v1.3.0
scripts/release.sh --major   # v1.2.3 → v2.0.0
scripts/release.sh v2.1.0    # explicit version
```

`release.sh` will ask for confirmation, then:

1. Regenerate `CHANGELOG.md` from the git log via [git-cliff](https://git-cliff.org/)
2. Update `VERSION`, `CMakeLists.txt` and `fpm.toml`
3. Commit with `chore(release): vX.Y.Z`
4. Create an annotated git tag
5. Push commit + tag

Pushing the tag triggers the GitHub Actions release workflow, which automatically:
- Runs the full test suite and uploads coverage
- Builds this documentation site and deploys it to GitHub Pages
- Packages a versioned tarball
- Publishes a GitHub release with the changelog section as release notes

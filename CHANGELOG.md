# Changelog

All notable changes to this project are documented here.
Versions follow [Semantic Versioning](https://semver.org/).
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [1.3.0] — 2026-09-29
### Added
- **flap**: Re-export all error and status codes from the flap module

- **cli**: Add reset_parse to parse again without redefining the CLI


### Changed
- **parse**: Match switch names through one matcher

- **list**: Store and read lists through one API

- **cli**: Split parse into a wrapper and parse_core; share the error prefix

- **usage**: One renderer per output of an argument's signature

- Delete the dead assignment(=) overloads


### Documentation
- **claude**: Rewrite stale project guide for FoBiS 3.8 and VitePress

- **claude**: Document r16p mode and correct legacy flag claim

- **release**: Add the v1.3.0 upgrade guide; bump CMake and fpm versions on release


### Fixed
- **fobos**: Use --gcov-analyzer flag for current FoBiS.py version

- **fobos**: Repeat --gcov-analyzer flag for each argument value

- **cli**: Work around gfortran 16 ICE in array-of-derived-type assignment

- **docs**: Remove trailing comma in package.json devDependencies

- **docs**: Untrack package-lock and pin esbuild for lock-free vite build

- **build**: Add flap_test_utils to the makefile

- **parse**: Report a duplicated switch on its own CLA and stop parsing

- **cla**: Guard nargs before reading it in check_list_size

- **parse**: Split argument strings with a single-pass quote scanner

- **cli**: Read arguments whole and drop the gfortran fixed-length workaround

- **cla**: Raise an error when get receives an unsupported variable type

- **parse**: Assign positionals by their declared position

- **parse**: Never take the value of an option as a command name

- **cla**: Work around gfortran 13.3/14.2 corrupting character list values

- **cla**: Enforce choices on every value of a varying-size list

- **cli**: Include the builtin switches in outputs generated before parse

- **utils**: Correct count, unique and replace_all in flap_utils_m

- **output**: Correct the completion shebang and check file errors in save_*

- **object**: Handle examples in free_object, assign_object and set_examples

- **cli**: Return from get when the group is unknown

- **parse**: Let a nargs='N' option take N values when more follow

- **completion**: Generate a clean, stateless bash completion function

- **env**: Read environment variables through one helper, at any length

- **cli**: Resolve group names through one resolver, -1 when undefined

- **get**: Reject a fixed-size array whose size differs from the list

- **get**: Return the values of a list of flags from get_varying

- **add**: Reject a list default whose count differs from nargs

- **add**: Reject duplicate and missing positions


## [1.2.14] — 2026-03-02
### Documentation
- Refactor README to match StringiFor style conventions


## [1.2.12] — 2026-02-18
### Documentation
- Overhaul README and restructure VitePress guide


## [1.2.8] — 2026-02-18
### Documentation
- Add VitePress guide section and formal-generated API reference


## [1.2.7] — 2026-02-18
### Documentation
- Add CLAUDE.md with build commands and architecture guide

- Migrate documentation pipeline from FORD to formal + VitePress


## [0.6.1] — 2015-07-02
### Security
- Fix deploy.sh script




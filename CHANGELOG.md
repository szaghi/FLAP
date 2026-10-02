# Changelog

All notable changes to this project are documented here.
Versions follow [Semantic Versioning](https://semver.org/).
Format follows [Keep a Changelog](https://keepachangelog.com/).

## [2.5.1] — 2026-10-02
### Documentation
- A new first impression, with an animated quick start

- Point the install pins at v2.5.0

- **migration**: Add the v2.5.0 upgrade notes

- One reading path instead of a Guide and a Manual

- **cookbook**: Fifteen more recipes, without the Python table


### Fixed
- **cli**: Set error_message for the errors of groups and arguments

- **cli**: Do not print the unknown arguments that are ignored


## [2.5.0] — 2026-10-02
### Fixed
- **build**: Rename the quad precision macro _R16P to PENF_R16P ⚠ BREAKING CHANGE


## [2.4.1] — 2026-10-01
### Documentation
- Audit the guide against v2.4.0, samples built and run by a harness

- **manual**: A tutorial, a cookbook and terminal images

- Point the install pins and the upgrade notes at v2.4.1


### Fixed
- **cla**: Check the choices of a character value before truncating it

- **cla**: Render a store* option with its switch

- **cla**: Report a value that is not a number as ERROR_CASTING_NUMBER

- **completion**: Name the bash function after the program

- **messages**: Clearer wording of five error messages

- **help**: A consistent layout of the help, man page and Markdown ⚠ BREAKING CHANGE


## [2.4.0] — 2026-09-30
### Added
- **cli**: Usage_on_error, a shorter output after an error

- **cli**: --man builtin and the file names of --man and --markdown


### Fixed
- **completion**: Bash offers the options not yet typed, of the last command


## [2.3.1] — 2026-09-30
### Documentation
- Colours section, current build commands, upgrade page


### Fixed
- **parse**: A repeated command is an error


## [2.3.0] — 2026-09-30
### Added
- **menu**: Flap_menu_t, interactive single-choice menus

- **menu**: Default options and default icon

- **menu**: Retries, error kinds and end-of-input handling

- **menu**: Multiple selection with separator

- **menu**: Yes/no questions

- **menu**: Option, question and error colours via FACE


## [2.2.0] — 2026-09-30
### Added
- **cla**: Metavar, the placeholder of a value in the help

- **completion**: Bash file-name fallback and zsh completion

- **completion**: Native fish completion script

- **completion**: PowerShell completion script

- **completion**: --show-completion and --install-completion


## [2.1.0] — 2026-09-30
### Added
- **cla**: Numeric ranges min/max/open/clamp, checked by get

- **cla**: Switch_neg flag pairs --x/--no-x, the last one wins

- **cli**: Case-insensitive switches, commands and choices

- **cli**: Subcommand aliases, add_group(aliases=)

- **parse**: "did you mean" suggestions for unknown switches and commands

- **cla**: Key=value options, add(map=, map_keys=), get_map

- **cli**: Copy_options, reusable option sets between commands


## [2.0.0] — 2026-09-30
### Added
- **cli**: Standalone init option; parse returns the help/version/markdown status

- **cli**: Print "Try 'prog --help' for help." after a failed parse

- **cli**: Raise_error for application-level errors

- **cli**: No_args_is_help at CLI and command level

- **parse**: Accept --option=value inline values

- **parse**: Count action, with the compact -vvv form

- **parse**: Append action collecting one value per occurrence

- **cli**: Mutually exclusive sets of switches, optionally required

- **cli**: Ignore_env init option turning every environment lookup off

- **envvar**: Environment as the value source of an absent option ⚠ BREAKING CHANGE

- **cli**: Auto_envvar_prefix generating the envvar of every option

- **envvar**: List options read their variable as comma-separated values

- **config**: INI configuration files as a value source (set_config)

- **cla**: Act='config' option naming the configuration file

- **cli**: Get_source and provenance, where every value comes from

- **cla**: Path checks must_exist, readable, writable, allow_dash

- **cla**: Deprecated options and commands warn when used

- **parse**: Exclusive sets count every explicit source, command line first

- **parse**: Alternate actions returning STATUS_ALTERNATE

- **parse**: An explicitly empty value is the empty string ⚠ BREAKING CHANGE

- **parse**: Nargs='*' passed without values is an empty list ⚠ BREAKING CHANGE


### Changed
- **cla**: Record the source of every value, getters use has_value


### Fixed
- **release**: Push only the new tag, not every reachable one

- **utils**: Let nvfortran compile wstrip

- **cli**: Store strings arrays as flap_string elements, runnable with nvfortran ⚠ BREAKING CHANGE

- **cli**: A failed add no longer leaks its error into the next ones


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




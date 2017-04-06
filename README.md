<a name="top"></a>

# FLAP [![GitHub tag](https://img.shields.io/github/tag/szaghi/FLAP.svg)]() [![Join the chat at https://gitter.im/szaghi/FLAP](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/szaghi/FLAP?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![License](https://img.shields.io/badge/license-GNU%20GeneraL%20Public%20License%20v3,%20GPLv3-blue.svg)]()
[![License](https://img.shields.io/badge/license-BSD2-red.svg)]()
[![License](https://img.shields.io/badge/license-BSD3-red.svg)]()
[![License](https://img.shields.io/badge/license-MIT-red.svg)]()

[![Status](https://img.shields.io/badge/status-stable-brightgreen.svg)]()
[![Build Status](https://travis-ci.org/szaghi/FLAP.svg?branch=master)](https://travis-ci.org/szaghi/FLAP)
[![Coverage Status](https://img.shields.io/codecov/c/github/szaghi/FLAP.svg)](http://codecov.io/github/szaghi/FLAP?branch=master)

### FLAP, Fortran command Line Arguments Parser for poor people

A KISS pure Fortran Library for building powerful, easy-to-use, elegant command line interfaces

- FLAP is a pure Fortran (KISS) library for building easily nice Command Line Interfaces (CLI) for modern Fortran projects;
- FLAP is Fortran 2003+ standard compliant;
- FLAP is OOP designed;
- FLAP is a Free, Open Source Project.

#### Issues

[![GitHub issues](https://img.shields.io/github/issues/szaghi/FLAP.svg)]()
[![Ready in backlog](https://badge.waffle.io/szaghi/FLAP.png?label=ready&title=Ready)](https://waffle.io/szaghi/FLAP)
[![In Progress](https://badge.waffle.io/szaghi/FLAP.png?label=in%20progress&title=In%20Progress)](https://waffle.io/szaghi/FLAP)
[![Open bugs](https://badge.waffle.io/szaghi/FLAP.png?label=bug&title=Open%20Bugs)](https://waffle.io/szaghi/FLAP)

#### Compiler Support

[![Compiler](https://img.shields.io/badge/GNU-v4.9.2+-brightgreen.svg)]()
[![Compiler](https://img.shields.io/badge/Intel-v12.x+-brightgreen.svg)]()
[![Compiler](https://img.shields.io/badge/IBM%20XL-not%20tested-yellow.svg)]()
[![Compiler](https://img.shields.io/badge/g95-not%20tested-yellow.svg)]()
[![Compiler](https://img.shields.io/badge/NAG-not%20tested-yellow.svg)]()
[![Compiler](https://img.shields.io/badge/PGI-not%20tested-yellow.svg)]()

---

| [What is FLAP?](#what-is-flap) | [Main features](#main-features) | [Copyrights](#copyrights) | [Documentation](#documentation) | [Install](#install) |

---

## What is FLAP?

Modern Fortran standards (2003+) have introduced support for Command Line Arguments (CLA), thus it is possible to construct nice and effective Command Line Interfaces (CLI). FLAP is a small library designed to simplify the (repetitive) construction of complicated CLI in pure Fortran (standard 2003+). FLAP has been inspired by the python module _argparse_ trying to mimic it. Once you have defined the arguments that are required by means of a user-friendly method of the CLI, FLAP will parse the CLAs for you. It is worthy of note that FLAP, as _argparse_, also automatically generates help and usage messages and issues errors when users give the program invalid arguments.

Go to [Top](#top)

## Main features

FLAP is inspired by the python great module _argparse_, thus many features are taken from it. Here the main features are listed.

* [x] User-friendly methods for building flexible and effective Command Line Interfaces (CLI);
* [x] comprehensive Command Line Arguments (CLA) support:
  * [x] support optional and non optional CLA;
  * [x] support boolean CLA;
  * [x] support positional CLA;
  * [x] support list of allowable values for defined CLA with automatic consistency check;
  * [x] support multiple valued (list of values, aka list-valued) CLA:
    * [x] compiletime sized list, e.g. `nargs='3'`;
    * [x] runtime sized list with at least 1 value, e.g. `nargs='+'`;
    * [x] runtime sized list with any size, even empty, e.g. `nargs='*'`;
  * [x] support mutually exclusive CLAs;
  * [x] self-consistency-check of CLA definition;
  * [x] support fake CLAs input from a string;
  * [x] support fake CLAs input from environment variables;
* [x] comprehensive *command* (group of CLAs) support:
  * [x] support nested subcommands;
  * [x] support mutually exclusive commands;
  * [x] self-consistency-check of command definition;
* [x] automatic generation of help and usage messages;
* [x] consistency-check of whole CLI definition;
* [x] errors trapping for invalid CLI usage;
* [x] POSIX style compliant;
* [x] automatic generation of MAN PAGE using your CLI definition!;
* [x] replicate all the useful features of _argparse_;
* [ ] implement [docopt](https://github.com/docopt/docopt) features.
* [ ] implement [click](http://click.pocoo.org/4/) features.

Any feature request is welcome.

Go to [Top](#top)

## Copyrights

FLAP is an open source project, it is distributed under a multi-licensing system:

+ for FOSS projects:
  - [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html);
+ for closed source/commercial projects:
  - [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause);
  - [BSD 3-Clause](http://opensource.org/licenses/BSD-3-Clause);
  - [MIT](http://opensource.org/licenses/MIT).

Anyone is interest to use, to develop or to contribute to FLAP is welcome, feel free to select the license that best matches your soul!

More details can be found on [wiki](https://github.com/szaghi/FLAP/wiki/Copyrights).

Go to [Top](#top)

## Documentation

Besides this README file the FLAP documentation is contained into its own [wiki](https://github.com/szaghi/FLAP/wiki). Detailed documentation of the API is contained into the [GitHub Pages](http://szaghi.github.io/FLAP/index.html) that can also be created locally by means of [ford tool](https://github.com/cmacmackin/ford).

### A Taste of FLAP

A minimal *plate*:

```fortran
program minimal
type(command_line_interface) :: cli    ! Command Line Interface (CLI).
character(99)                :: string ! String value.
integer                      :: error  ! Error trapping flag.

call cli%init(description = 'minimal FLAP example')
call cli%add(switch='--string', &
             switch_ab='-s',    &
             help='a string',   &
             required=.true.,   &
             act='store',       &
             error=error)
if (error/=0) stop
call cli%get(switch='-s', val=string, error=error)
if (error/=0) stop
print '(A)', cli%progname//' has been called with the following argument:'
print '(A)', 'String = '//trim(adjustl(string))
endprogram minimal
```

That *built and run* provides:

```shell
→ ./minimal
./minimal: error: named option "--string" is required!

usage:  ./exe/test_minimal --string value [--help] [--version]

minimal FLAP example

Required switches:
   --string value, -s value
    a string

Optional switches:
   --help, -h
    Print this help message
   --version, -v
    Print version
```

A nice automatic help-message, right? Executed correctly gives.

```shell
→ ./minimal --string 'hello world'
./exe/minimal has been called with the following argument:
String = hello world
```

For more details, see the provided [tests](https://github.com/szaghi/FLAP/blob/master/src/tests).

#### Nested (sub)commands

FLAP fully supports nested (sub)commands or groups of command line arguments. For example a fake `git` toy remake can be coded as

```fortran
! initializing Command Line Interface
call cli%init(progname    = 'test_nested',                                      &
              version     = 'v2.1.5',                                           &
              authors     = 'Stefano Zaghi',                                    &
              license     = 'MIT',                                              &
              description = 'Toy program for testing FLAP with nested commands',&
              examples    = ['test_nested                      ',&
                             'test_nested -h                   ',&
                             'test_nested init                 ',&
                             'test_nested commit -m "fix bug-1"',&
                             'test_nested tag -a "v2.1.5"      '])
! set a Command Line Argument without a group to trigger authors names printing
call cli%add(switch='--authors',switch_ab='-a',help='Print authors names',required=.false.,act='store_true',def='.false.')
! set Command Line Arguments Groups, i.e. commands
call cli%add_group(group='init',description='fake init versioning')
call cli%add_group(group='commit',description='fake commit changes to current branch')
call cli%add_group(group='tag',description='fake tag current commit')
! set Command Line Arguments of commit command
call cli%add(group='commit',switch='--message',switch_ab='-m',help='Commit message',required=.false.,act='store',def='')
! set Command Line Arguments of commit command
call cli%add(group='tag',switch='--annotate',switch_ab='-a',help='Tag annotation',required=.false.,act='store',def='')
! parsing Command Line Interface
call cli%parse(error=error)
if (error/=0) then
  print '(A)', 'Error code: '//trim(str(n=error))
  stop
endif
! using Command Line Interface data to trigger program behaviour
call cli%get(switch='-a',val=authors_print,error=error) ; if (error/=0) stop
if (authors_print) then
  print '(A)','Authors: '//cli%authors
elseif (cli%run_command('init')) then
  print '(A)','init (fake) versioning'
elseif (cli%run_command('commit')) then
  call cli%get(group='commit',switch='-m',val=message,error=error) ; if (error/=0) stop
  print '(A)','commit changes to current branch with message "'//trim(message)//'"'
elseif (cli%run_command('tag')) then
  call cli%get(group='tag',switch='-a',val=message,error=error) ; if (error/=0) stop
  print '(A)','tag current branch with message "'//trim(message)//'"'
else
  print '(A)','cowardly you are doing nothing... try at least "-h" option!'
endif
```

that when invoked without arguments prompts:

```shell
cowardly you are doing nothing... try at least "-h" option!
```
and invoked with `-h` option gives:

```shell
usage: test_nested  [--authors] [--help] [--version] {init,commit,tag} ...

Toy program for testing FLAP with nested commands

Optional switches:
   --authors, -a
          default value .false.
          Print authors names
   --help, -h
          Print this help message
   --version, -v
          Print version

Commands:
  init
          fake init versioning
  commit
          fake commit changes to current branch
  tag
          fake tag current commit

For more detailed commands help try:
  test_nested init -h,--help
  test_nested commit -h,--help
  test_nested tag -h,--help

Examples:
   test_nested
   test_nested -h
   test_nested init
   test_nested commit -m "fix bug-1"
   test_nested tag -a "v2.1.5"
```

For more details, see the provided [example](https://github.com/szaghi/FLAP/blob/master/src/tests/test_nested.f90).

Go to [Top](#top)

---

## Install

FLAP is a Fortran library composed by several modules.

> Before download and compile the library you must check the [requirements](https://github.com/szaghi/FLAP/wiki/Requirements).

To download and build the project two main ways are available:

+ exploit the [install script](#install-script) that can be downloaded [here](https://github.com/szaghi/FLAP/releases/latest)
+ [manually download and build](#manually-download-and-build):
  + [download](#download)
  + [build](#build)

---

### install script

FLAP ships a bash script (downloadable from [here](https://github.com/szaghi/FLAP/releases/latest)) that is able to automatize the download and build steps. The script `install.sh` has the following usage:

```shell
→ ./install.sh
Install script of FLAP
Usage:

install.sh --help|-?
    Print this usage output and exit

install.sh --download|-d <arg> [--verbose|-v]
    Download the project

    --download|-d [arg]  Download the project, arg=git|wget to download with git or wget respectively
    --verbose|-v         Output verbose mode activation

install.sh --build|-b <arg> [--verbose|-v]
    Build the project

    --build|-b [arg]  Build the project, arg=fobis|make|cmake to build with FoBiS.py, GNU Make or CMake respectively
    --verbose|-v      Output verbose mode activation

Examples:

install.sh --download git
install.sh --build make
install.sh --download wget --build cmake
```

> The script does not cover all possibilities.

The script operation modes are 2 (*collapsible* into one-single-mode):

+ download a new fresh-clone of the latest master-release by means of:
  + [git](https://git-scm.com/);
  + [wget](https://www.gnu.org/software/wget/) (also [curl](https://curl.haxx.se/) is necessary);
+ build a fresh-clone project as static-linked library by means of:
  + [FoBiS.py](https://github.com/szaghi/FoBiS);
  + [GNU Make](https://www.gnu.org/software/make/);
  + [CMake](https://cmake.org/);

> you can mix any of the above combinations accordingly to the tools available.

Typical usages are:

```shell
# download and prepare the project by means of git and build with GNU Make
install.sh --dowload git --build make
# download and prepare the project by means of wget (curl) and build with CMake
install.sh --dowload wget --build cmake
# download and prepare the project by means of git and build with FoBiS.py
install.sh --dowload git --build fobis
```

---

### manually download and build

#### download

To download all the available releases and utilities (fobos, license, readme, etc...), it can be convenient to _clone_ whole the project:

```shell
git clone https://github.com/szaghi/FLAP
cd FLAP
git submodule update --init
```

Alternatively, you can directly download a release from GitHub server, see the [ChangeLog](https://github.com/szaghi/FLAP/wiki/ChangeLog).

#### build

The most easy way to compile FLAP is to use [FoBiS.py](https://github.com/szaghi/FoBiS) within the provided fobos file.

Consequently, it is strongly encouraged to install [FoBiS.py](https://github.com/szaghi/FoBiS#install).

| [Build by means of FoBiS](#build-by-means-of-fobis) | [Build by means of GNU Make](#build-by-means-of-gnu-make) | [Build by means of CMake](#build-by-means-of-cmake) |

---

#### build by means of FoBiS

FoBiS.py is a KISS tool for automatic building of modern Fortran projects. Providing very few options, FoBiS.py is able to build almost automatically complex Fortran projects with cumbersome inter-modules dependency. This removes the necessity to write complex makefile. Moreover, providing a very simple options file (in the FoBiS.py nomenclature indicated as `fobos` file) FoBiS.py can substitute the (ab)use of makefile for other project stuffs (build documentations, make project archive, etc...). FLAP is shipped with a fobos file that can build the library in both _static_ and _shared_ forms and also build the `Test_Driver` program. The provided fobos file has several building modes.

##### listing fobos building modes
Typing:
```bash
FoBiS.py build -lmodes
```
the following message should be printed:
```bash
The fobos file defines the following modes:
 - "shared-gnu"
  - "static-gnu"
  - "test-driver-gnu"
  - "shared-gnu-debug"
  - "static-gnu-debug"
  - "test-driver-gnu-debug"
  - "shared-intel"
  - "static-intel"
  - "test-driver-intel"
  - "shared-intel-debug"
  - "static-intel-debug"
  - "test-driver-intel-debug"
```
The modes should be self-explicative: `shared`, `static` and `test-driver` are the modes for building (in release, optimized form) the shared and static versions of the library and the Test Driver program, respectively. The other 3 modes are the same, but in debug form instead of release one. `-gnu` use the `GNU gfortran` compiler while `-intel` the Intel one.

##### building the library
The `shared` or `static` directories are created accordingly to the form of the library built. The compiled objects and mod files are placed inside this directory, as well as the linked library.
###### release shared library
```bash
FoBiS.py build -mode shared-gnu
```
###### release static library
```bash
FoBiS.py build -mode static-gnu
```
###### debug shared library
```bash
FoBiS.py build -mode shared-gnu-debug
```
###### debug static library
```bash
FoBiS.py build -mode static-gnu-debug
```

##### building the Test Driver program
The `Test_Driver` directory is created. The compiled objects and mod files are placed inside this directory, as well as the linked program.
###### release test driver program
```bash
FoBiS.py build -mode test-driver-gnu
```
###### debug test driver program
```bash
FoBiS.py build -mode test-driver-gnu-debug
```

##### listing fobos rules
Typing:
```bash
FoBiS.py rule -ls
```
the following message should be printed:
```bash
The fobos file defines the following rules:
  - "makedoc" Rule for building documentation from source files
       Command => rm -rf doc/html/*
       Command => ford doc/main_page.md
       Command => cp -r doc/html/publish/* doc/html/
  - "deldoc" Rule for deleting documentation
       Command => rm -rf doc/html/*
  - "maketar" Rule for making tar archive of the project
       Command => tar -czf FLAP.tar.gz *
  - "makecoverage" Rule for performing coverage analysis
       Command => FoBiS.py clean -mode test-driver-gnu
       Command => FoBiS.py build -mode test-driver-gnu -coverage
       Command => ./Test_Driver/Test_Driver
       Command => ./Test_Driver/Test_Driver -v
       Command => ./Test_Driver/Test_Driver -s 'Hello FLAP' -i 2
       Command => ./Test_Driver/Test_Driver 33.0 -s 'Hello FLAP' --integer_list 10 -3 87 -i 3 -r 64.123d0  --boolean --boolean_val .false.
  - "coverage-analysis" Rule for performing coverage analysis and saving reports in markdown
       Command => FoBiS.py clean -mode test-driver-gnu
       Command => FoBiS.py build -mode test-driver-gnu -coverage
       Command => ./Test_Driver/Test_Driver
       Command => ./Test_Driver/Test_Driver -v
       Command => ./Test_Driver/Test_Driver -s 'Hello FLAP' -i 2
       Command => ./Test_Driver/Test_Driver 33.0 -s 'Hello FLAP' --integer_list 10 -3 87 -i 3 -r 64.123d0  --boolean --boolean_val .false.
       Command => gcov -o Test_Driver/obj/ src/*
       Command => FoBiS.py rule -gcov_analyzer wiki/ Coverage-Analysis
       Command => rm -f *.gcov
```
The rules should be self-explicative.

---

#### build by means of GNU Make

Bad choice :-)

However, a makefile (generated by FoBiS.py...) to be used with a compatible GNU Make tool is [provided](https://github.com/szaghi/FLAP/blob/master/makefile).

It is convenient to clone the whole FLAP repository and run a *standard* make:

```shell
git clone https://github.com/szaghi/FLAP
cd FLAP
make -j 1
```

This commands build all tests (executables are in `exe/` directory). To build only the library (statically linked) type:

```shell
git clone https://github.com/szaghi/FLAP
cd FLAP
make -j 1 STATIC=yes
```

#### Build by means of CMake

Bad choice :-)

However, a CMake setup (kindly developed by [victorsndvg](https://github.com/victorsndvg)) is provided.

It is convenient to clone the whole FLAP repository and run a *standard* CMake configure/build commands:

```shell
git clone https://github.com/szaghi/FLAP $YOUR_FLAP_PATH
mkdir build
cd build
cmake $YOUR_FLAP_PATH
cmake --build .
```

If you want to run the tests suite type:

```shell
git clone https://github.com/szaghi/FLAP $YOUR_FLAP_PATH
mkdir build
cd build
cmake -DFLAP_ENABLE_TESTS=ON $YOUR_FLAP_PATH
cmake --build .
ctest
```

Go to [Top](#top)

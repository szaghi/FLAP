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

#### Table of Contents

- [What is FLAP?](#what-is-flap)
- [Main features](#main-features)
- [Copyrights](#copyrights)
- [Documentation](#documentation)
  - [A Taste of FLAP](#a-taste-of-flap)

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

Running the provided test program, `Test_Driver -h`, a taste of FLAP is served:

```man
usage:  Test_Driver [value] --string value [--integer value] [--real value] [--boolean] [--boolean_val value] [--integer_list value#1 value#2 value#3] [--help] [--version]

Toy program for testing FLAP

Required switches:
   --string value, -s value
          String input

Optional switches:
   value
          1-th argument
          default value 1.0
          Positional real input
   --integer value, -i value, value in: (1,3,5)
          default value 1
          Integer input with fixed range
   --real value, -r value
          default value 1.0
          Real input
   --boolean, -b
          default value .false.
          Boolean input
   --boolean_val value, -bv value
          default value .true.
          Valued boolean input
   --integer_list value#1 value#2 value#3, -il value#1 value#2 value#3
          default value 1 8 32
          Integer list input
   --help, -h
          Print this help message
   --version, -v
          Print version

Examples:
   Test_Driver -s 'Hello FLAP'
   Test_Driver -s 'Hello FLAP' -i -2 # printing error...
   Test_Driver -s 'Hello FLAP' -i 3 -r 33.d0
   Test_Driver -s 'Hello FLAP' --integer_list 10 -3 87
   Test_Driver 33.0 -s 'Hello FLAP' -i 5
   Test_Driver --string 'Hello FLAP' --boolean
```

Not so bad for just a very few statements as the following:

```fortran
! initializing Command Line Interface
call cli%init(progname    = 'Test_Driver',                                           &
              version     = 'v2.1.5',                                                &
              authors     = 'Stefano Zaghi',                                         &
              license     = 'MIT',                                                   &
              description = 'Toy program for testing FLAP',                          &
              examples    = ["Test_Driver -s 'Hello FLAP'                          ",&
                             "Test_Driver -s 'Hello FLAP' -i -2 # printing error...",&
                             "Test_Driver -s 'Hello FLAP' -i 3 -r 33.d0            ",&
                             "Test_Driver -s 'Hello FLAP' --integer_list 10 -3 87  ",&
                             "Test_Driver 33.0 -s 'Hello FLAP' -i 5                ",&
                             "Test_Driver --string 'Hello FLAP' --boolean          "])
! setting Command Line Argumenst
call cli%add(switch='--string',switch_ab='-s',help='String input',required=.true.,act='store',error=error)
call cli%add(switch='--integer',switch_ab='-i',help='Integer input with fixed range',required=.false.,act='store',&
             def='1',choices='1,3,5',error=error)
call cli%add(switch='--real',switch_ab='-r',help='Real input',required=.false.,act='store',def='1.0',error=error)
call cli%add(switch='--boolean',switch_ab='-b',help='Boolean input',required=.false.,act='store_true',def='.false.',&
             error=error)
call cli%add(switch='--boolean_val',switch_ab='-bv',help='Valued boolean input',required=.false., act='store',&
             def='.true.',error=error)
call cli%add(switch='--integer_list',switch_ab='-il',help='Integer list input',required=.false.,act='store',&
             nargs='3',def='1 8 32',error=error)
call cli%add(positional=.true.,position=1,help='Positional real input',required=.false.,def='1.0',error=error)
! parsing Command Line Interface
call cli%parse(error=error)
```

For more details, see the provided [example](https://github.com/szaghi/FLAP/blob/master/src/Test_Driver.f90).

For a practical example of FLAP usage see [POG](https://github.com/szaghi/OFF/blob/testing/src/POG.f90) source file at line `85`.

#### Nested (sub)commands

FLAP fully supports nested (sub)commands or groups of command line arguments. For example a fake `git` toy remake can be coded as

```fortran
! initializing Command Line Interface
call cli%init(progname    = 'Test_Driver_Nested',                                    &
              version     = 'v2.1.5',                                                &
              authors     = 'Stefano Zaghi',                                         &
              license     = 'MIT',                                                   &
              description = 'Toy program for testing FLAP with nested commands',     &
              examples    = ['Test_Driver_Nested                      ',&
                             'Test_Driver_Nested -h                   ',&
                             'Test_Driver_Nested init                 ',&
                             'Test_Driver_Nested commit -m "fix bug-1"',&
                             'Test_Driver_Nested tag -a "v2.1.5"      '])
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
usage: Test_Driver_Nested  [--authors] [--help] [--version] {init,commit,tag} ...

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
  Test_Driver_Nested init -h,--help
  Test_Driver_Nested commit -h,--help
  Test_Driver_Nested tag -h,--help

Examples:
   Test_Driver_Nested
   Test_Driver_Nested -h
   Test_Driver_Nested init
   Test_Driver_Nested commit -m "fix bug-1"
   Test_Driver_Nested tag -a "v2.1.5"
```

For more details, see the provided [example](https://github.com/szaghi/FLAP/blob/master/src/Test_Driver_Nested.f90).

Go to [Top](#top)

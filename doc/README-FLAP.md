<a name="top"></a>

# FLAP [![GitHub tag](https://img.shields.io/github/tag/szaghi/FLAP.svg)]()

[![License](https://img.shields.io/badge/license-GNU%20GeneraL%20Public%20License%20v3%20,%20GPLv3-blue.svg)]()

[![Status](https://img.shields.io/badge/status-stable-brightgreen.svg)]()
[![Build Status](https://travis-ci.org/szaghi/FLAP.svg?branch=master)](https://travis-ci.org/szaghi/FLAP)
[![Coverage Status](https://coveralls.io/repos/szaghi/FLAP/badge.svg?branch=master)](https://coveralls.io/r/szaghi/FLAP?branch=master)

### FLAP, Fortran command Line Arguments Parser for poor men
A KISS pure Fortran Library for building powerful, easy-to-use, elegant command line interfaces

+ FLAP is a pure Fortran (KISS) library for building easily nice Command Line Interfaces (CLI) for modern Fortran projects;
+ FLAP is Fortran 2003+ standard compliant;
+ FLAP is OOP designed;
+ FLAP is a Free, Open Source Project.

#### Issues
[![GitHub issues](https://img.shields.io/github/issues/szaghi/FLAP.svg)]()
[![Ready in backlog](https://badge.waffle.io/szaghi/FLAP.png?label=ready&title=Ready)](https://waffle.io/szaghi/FLAP)
[![In Progress](https://badge.waffle.io/szaghi/FLAP.png?label=in%20progress&title=In%20Progress)](https://waffle.io/szaghi/FLAP)
[![Open bugs](https://badge.waffle.io/szaghi/FLAP.png?label=bug&title=Open%20Bugs)](https://waffle.io/szaghi/FLAP)

#### Compiler Support
[![Compiler](https://img.shields.io/badge/GNU%20Gfortran%20Compiler-build%20pass%20with%20v4.9.2+-brightgreen.svg)]()

[![Compiler](https://img.shields.io/badge/Intel%20Fortran%20Compiler-build%20pass%20with%20v12.x+-brightgreen.svg)]()

[![Compiler](https://img.shields.io/badge/IBM%20XL%20Fortran%20Compiler-not%20tested-yellow.svg)]()

[![Compiler](https://img.shields.io/badge/g95%20Fortran%20Compiler-not%20tested-yellow.svg)]()

[![Compiler](https://img.shields.io/badge/NAG%20Fortran%20Compiler-not%20tested-yellow.svg)]()

[![Compiler](https://img.shields.io/badge/PGI%20Fortran%20Compiler-not%20tested-yellow.svg)]()

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
    * [x] support multiple valued (list of values) CLA;
    * [x] self-consistency-check of CLA definition;
* [x] automatic generation of help and usage messages;
* [x] consistency-check of whole CLI definition;
* [x] errors trapping for invalid CLI usage;
* [ ] support nested subcommands;
* [ ] support environment variables;
* [ ] POSIX style compliant;
* [ ] replicate all the useful features of _argparse_;
* [ ] implement [docopt](https://github.com/docopt/docopt) features.
* [ ] implement [click](http://click.pocoo.org/4/) features.

Any feature request is welcome.

Go to [Top](#top)

## Copyrights

FLAP is an open source project, it is distributed under the [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html). Anyone is interest to use, to develop or to contribute to FLAP is welcome.

Go to [Top](#top)

## Documentation

Besides this README file the FLAP documentation is contained into its own [wiki](https://github.com/szaghi/FLAP/wiki). Detailed documentation of the API is contained into the [GitHub Pages](http://szaghi.github.io/FLAP/index.html) that can also be created locally by means of [ford tool](https://github.com/cmacmackin/ford).

### A Taste of FLAP

Running the provided test program, `Test_Driver -h`, a taste of FLAP is served:
```shell
+--> Test_Driver, a testing program for FLAP library
+--> Parsing Command Line Arguments
|--> The Command Line Interface (CLI) has the following options
|-->   Test_Driver  [value] --string value [--integer value] [--real value] [--boolean] [--boolean_val value] [--integer_list value#1 value#2 value#3] [--help] [--version]
|--> Each Command Line Argument (CLA) has the following meaning:
|-->   [value]
|-->     Positional real input
|-->     It is a positional CLA having position "1-th"
|-->     It is a optional CLA which default value is "1.0"
|-->   [--string value] or [-s value]
|-->     String input
|-->     It is a non optional CLA thus must be passed to CLI
|-->   [--integer value] or [-i value] with value chosen in: (1,3,5)
|-->     Integer input with fixed range
|-->     It is a optional CLA which default value is "1"
|-->   [--real value] or [-r value]
|-->     Real input
|-->     It is a optional CLA which default value is "1.0"
|-->   [--boolean] or [-b]
|-->     Boolean input
|-->     It is a optional CLA which default value is ".false."
|-->   [--boolean_val value] or [-bv value]
|-->     Valued boolean input
|-->     It is a optional CLA which default value is ".true."
|-->   [--integer_list value#1 value#2 value#3] or [-il value#1 value#2 value#3]
|-->     Integer list input
|-->     It is a optional CLA which default value is "1 8 32"
|-->   [--help] or [-h]
|-->     Print this help message
|-->     It is a optional CLA
|-->   [--version] or [-v]
|-->     Print version
|-->     It is a optional CLA
|--> Usage examples:
|-->   -) Test_Driver -s 'Hello FLAP'
|-->   -) Test_Driver -s 'Hello FLAP' -i -2 # printing error...
|-->   -) Test_Driver -s 'Hello FLAP' -i 3 -r 33.d0
|-->   -) Test_Driver -s 'Hello FLAP' -integer_list 10 -3 87
|-->   -) Test_Driver 33.0 -s 'Hello FLAP' -i 5
|-->   -) Test_Driver -string 'Hello FLAP' -boolean
```
Not so bad for just a very few statements as the following:
```fortran
...
write(stdout,'(A)')'+--> Test_Driver, a testing program for FLAP library'
! initializing CLI
call cli%init(progname='Test_Driver',                                           &
              version ='v0.0.1',                                                &
              examples=["Test_Driver -s 'Hello FLAP'                          ",&
                        "Test_Driver -s 'Hello FLAP' -i -2 # printing error...",&
                        "Test_Driver -s 'Hello FLAP' -i 3 -r 33.d0            ",&
                        "Test_Driver -s 'Hello FLAP' -integer_list 10 -3 87   ",&
                        "Test_Driver 33.0 -s 'Hello FLAP' -i 5                ",&
                        "Test_Driver -string 'Hello FLAP' -boolean            "])
! setting CLAs
call cli%add(pref='|-->',switch='--string',      switch_ab='-s', help='String input',                  required=.true., act='store',                                  error=error)
call cli%add(pref='|-->',switch='--integer',     switch_ab='-i', help='Integer input with fixed range',required=.false.,act='store',          def='1',choices='1,3,5',error=error)
call cli%add(pref='|-->',switch='--real',        switch_ab='-r', help='Real input',                    required=.false.,act='store',          def='1.0',              error=error)
call cli%add(pref='|-->',switch='--boolean',     switch_ab='-b', help='Boolean input',                 required=.false.,act='store_true',     def='.false.',          error=error)
call cli%add(pref='|-->',switch='--boolean_val', switch_ab='-bv',help='Valued boolean input',          required=.false.,act='store',          def='.true.',           error=error)
call cli%add(pref='|-->',switch='--integer_list',switch_ab='-il',help='Integer list input',            required=.false.,act='store',nargs='3',def='1 8 32',           error=error)
call cli%add(pref='|-->',positional=.true.,position=1,           help='Positional real input',         required=.false.,                      def='1.0',              error=error)
! parsing CLI
write(stdout,'(A)')'+--> Parsing Command Line Arguments'
call cli%parse(error=error,pref='|-->')
...
```
For a practical example of FLAP usage see [POG](https://github.com/szaghi/OFF/blob/testing/src/POG.f90) source file at line `85`.

Go to [Top](#top)

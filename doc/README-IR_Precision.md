<a name="top"></a>
# IR_Precision [![GitHub tag](https://img.shields.io/github/tag/szaghi/IR_Precision.svg)]()

[![License](https://img.shields.io/badge/license-GNU%20GeneraL%20Public%20License%20v3%20,%20GPLv3-blue.svg)]()

[![Status](https://img.shields.io/badge/status-stable-brightgreen.svg)]()
[![Build Status](https://travis-ci.org/szaghi/IR_Precision.svg?branch=master)](https://travis-ci.org/szaghi/IR_Precision)

### IR_Precision, Fortran (standard 2003+) module for achieving portable codes
A KISS library for exploiting codes portability for modern (2003+) Fortran projects.

+ IR_Precision is a pure Fortran (KISS) library for achieving portable codes for modern Fortran projects;
+ IR_Precision provides many number-to-string and `viceversa` facilities;
+ IR_Precision is Fortran 2003+ standard compliant;
+ IR_Precision is a Free, Open Source Project.

#### Issues
[![GitHub issues](https://img.shields.io/github/issues/szaghi/IR_Precision.svg)]()
[![Ready in backlog](https://badge.waffle.io/szaghi/IR_Precision.png?label=ready&title=Ready)](https://waffle.io/szaghi/IR_Precision)
[![In Progress](https://badge.waffle.io/szaghi/IR_Precision.png?label=in%20progress&title=In%20Progress)](https://waffle.io/szaghi/IR_Precision)
[![Open bugs](https://badge.waffle.io/szaghi/IR_Precision.png?label=bug&title=Open%20Bugs)](https://waffle.io/szaghi/IR_Precision)

#### Compiler Support
[![Compiler](https://img.shields.io/badge/GNU%20Gfortran%20Compiler-build%20pass%20with%20v4.9.2-brightgreen.svg)]()

[![Compiler](https://img.shields.io/badge/Intel%20Fortran%20Compiler-build%20pass%20with%20v12.x+-brightgreen.svg)]()

[![Compiler](https://img.shields.io/badge/IBM%20XL%20Fortran%20Compiler-not%20tested-yellow.svg)]()

[![Compiler](https://img.shields.io/badge/g95%20Fortran%20Compiler-not%20tested-yellow.svg)]()

[![Compiler](https://img.shields.io/badge/NAG%20Fortran%20Compiler-not%20tested-yellow.svg)]()

[![Compiler](https://img.shields.io/badge/PGI%20Fortran%20Compiler-not%20tested-yellow.svg)]()

## What is IR_Precision?

Fortran is the most popular programming language for scientific computing. With Fortran it is quite simple obtain fast code and manage large multidimensional array. Because Fortran permits the achievement of high performance it is also used on great range of different computer-architectures, and often on the fastest supercomputer in the world. Therefore Fortran programs must be _portable_: portability means that the code will give the same results on every different computer-architectures. One of the most important goal of the numeric code is to control the numeric error due to finite precision of numerical operations. Fortran uses the __IEEE__ representations. Integers and reals (floating point) are represented with a finite precision. So when the code computes an operation it has a truncation error due to the truncation of the numerical finite representations. For numerical and more in general scientific applications this source of errors must be controlled. The programmer must know which is the precision associated to the code variables. Before the standard Fortran 90/95 there are not any way to select the precision of the numerical variables in a portable fashion.

Modern Fortran standards (2003+) have introduced better support for codes portability. With the possibility to specify a kind parameter for variables, the standard Fortran 90+ makes available useful functions to select the kind precision in a portable parametric way. Using these functions the programmer can accurately control the precision of its own variables in a portable manner.

IR_Precision module provides an effective KISS library to achieve portability and concurrently it provides many tools to handles parametrized numbers.

Go to [Top](#top)

## Main features

The library provides portable kind-parameters and many useful procedures to deal with them:

* [X] integer and reals parameters for 1,2,4,8,16 bytes-like representations;
* [X] integer and real formats definitions for all parameters;
* [X] integer and real minimum maximum representable numbers;
* [X] number-to-string and string-to-number casting procedures;
* [X] endianism procedures checking.

Any feature request is welcome.

Go to [Top](#top)

## Copyrights

IR_Precision is an open source project, it is distributed under the [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html). Anyone is interest to use, to develop or to contribute to IR_Precision is welcome.

Go to [Top](#top)

## Documentation

Besides this README file the IR_Precision documentation is contained into its own [wiki](https://github.com/szaghi/IR_Precision/wiki). Detailed documentation of the API is contained into the [GitHub Pages](http://szaghi.github.io/IR_Precision/index.html) that can also be created locally by means of [ford tool](https://github.com/cmacmackin/ford).

### A Taste of IR_Precision

To be written.

Go to [Top](#top)

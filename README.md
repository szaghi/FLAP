# FLAP
### FLAP, Fortran command Line Arguments Parser for poor men

A very simple and stupid tool for building easily nice Command Line Interface for modern Fortran projects.

### A Taste of FLAP

Running the provided test program, __flap_test__, a taste of FLAP is served:
```shell
+--> flap_test, a testing program for FLAP library
+--> Parsing Command Line Arguments
|--> Error: the Command Line Interface requires at least 1 arguments to be passed whereas only 0 have been!
|--> The Command Line Interface (CLI) has the following options
|-->   FLAP_Test [value] -string value [-integer value] [-real value] [-boolean] [-boolean_val value]
|--> Each Command Line Argument (CLA) has the following meaning:
|-->   [value]
|-->     Positional real input
|-->     It is a positional CLA having position "1-th"
|-->     It is a optional CLA which default value is "1.0"
|-->   [-string value] or [-s value]
|-->     String input
|-->     It is a non optional CLA thus must be passed to CLI
|-->   [-integer value] or [-i value] with value chosen in: (1,3,5)
|-->     Integer input with fixed range
|-->     It is a optional CLA which default value is "1"
|-->   [-real value] or [-r value]
|-->     Real input
|-->     It is a optional CLA which default value is "1.0"
|-->   [-boolean] or [-b]
|-->     Boolean input
|-->     It is a optional CLA which default value is ".false."
|-->   [-boolean_val value] or [-bv value]
|-->     Valued boolean input
|-->     It is a optional CLA which default value is ".true."
|--> Usage examples:
|-->   -) flap_test -s 'Hello FLAP'
|-->   -) flap_test -s 'Hello FLAP' -i -2
|-->   -) flap_test 33.0 -s 'Hello FLAP' -i -2
|-->   -) flap_test -s 'Hello FLAP' -i -2 -r 33.d0
|-->   -) flap_test -string 'Hello FLAP' -boolean
```
Not so bad for just a very few statements as the following:
```fortran
...
write(stdout,'(A)')'+--> flap_test, a testing program for FLAP library'
! setting CLAs
call cli%add(pref='|-->',switch='-string',switch_ab='-s',help='String input',required=.true.,act='store',error=error)
call cli%add(pref='|-->',switch='-integer',switch_ab='-i',help='Integer input with fixed range',required=.false.,act='store',&
             def='1',choices='1,3,5',error=error)
call cli%add(pref='|-->',switch='-real',switch_ab='-r',help='Real input',required=.false.,act='store',def='1.0',error=error)
call cli%add(pref='|-->',switch='-boolean',switch_ab='-b',help='Boolean input',required=.false.,act='store_true',def='.false.',&
             error=error)
call cli%add(pref='|-->',switch='-boolean_val',switch_ab='-bv',help='Valued boolean input',required=.false., act='store',&
             def='.true.',error=error)
call cli%add(pref='|-->',positional=.true.,position=1,help='Positional real input',required=.false.,def='1.0',error=error)
! checking consistency of CLAs
call cli%check(error=error,pref='|-->') ; if (error/=0) stop
! parsing CLI
write(stdout,'(A)')'+--> Parsing Command Line Arguments'
call cli%parse(examples=["flap_test -s 'Hello FLAP'               ",&
                         "flap_test -s 'Hello FLAP' -i -2         ",&
                         "flap_test 33.0 -s 'Hello FLAP' -i -2    ",&
                         "flap_test -s 'Hello FLAP' -i -2 -r 33.d0",&
                         "flap_test -string 'Hello FLAP' -boolean "],progname='FLAP_Test',error=error,pref='|-->')
...
```

## Table of Contents

* [Team Members](#team-members)
* [What is FLAP?](#what)
* [Main features](#main-features)
* [Todos](#todos)
* [Requirements](#requirements)
* [Copyrights](#copyrights)
* [Usage](#usage)

## <a name="team-members"></a>Team Members
* Stefano Zaghi <stefano.zaghi@gmail.com>

## <a name="what"></a>What is FLAP?

Modern Fortran standards (2003+) have introduced support for Command Line Arguments (CLA), thus it is possible to construct nice and effective Command Line Interface (CLI). FLAP is a small library designed to simplify the (repetitive) construction of complicated CLI in pure Fortran (standard 2003+). FLAP has been inspired by the python module _argparse_ trying to mimic it. Once you have defined what arguments are required setting up the CLI through a user-friendly methods, FLAP will parse the CLAs for you. It is worthy of note that FLAP, as _argparse_, also automatically generates help and usage messages and issues errors when users give the program invalid arguments.

## <a name="main-features"></a>Main features
+ user-friendly methods for building flexible and effective Command Line Interfaces (CLI);
+ handling optional and non optional Command Line Argument (CLA);
+ handling boolean CLA;
+ handling positional CLA;
+ handling list of allowable values for defined CLA with automatic consistency check;
+ automatic generation of help and usage messages;
+ errors trapping for invalid CLI usage.
+ ...

## <a name="todos"></a>Todos
+ Support for multiple valued (list of values) CLAs.
+ ...
+ any feature request is welcome!

## <a name="requirements"></a>Requirements
+ Modern Fortran Compiler (standard 2003+);
+ a lot of patience with the author.

FLAP is developed on a GNU/Linux architecture. For Windows architecture there is no support, however it should be work out-of-the-box.

## <a name="Copyrights"></a>Copyrights

FLAP is an open source project, it is distributed under the [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html). Anyone is interest to use, to develop or to contribute to FLAP is welcome.

## <a name="usage"></a>Usage

### API
FLAP is currently composed by one module, namely  __Data_Type_Command_Line_Interface.f90__, where two derived types are defined, namely __Type_Command_Line_Argument__ and __Type_Command_Line_Interface__. The first one is a back-end handling CLAs while the latter is the front-end providing all you need to handle your CLI. Two auxiliary modules, __IR_Precision.f90__ and __Lib_IO_Misc.f90__ are used for minor tasks. Finally, a testing program __flap_test__ is provided showing a basic example of FLAP usage.

The main CLI object, that is the only one you must know, is __Type_Command_Line_Interface__
```fortran
type, public:: Type_Command_Line_Interface
  integer(I4P)::                                  Na          = 0_I4P !< Number of CLA.
  integer(I4P)::                                  Na_required = 0_I4P !< Number of command line arguments that CLI requires.
  integer(I4P)::                                  Na_optional = 0_I4P !< Number of command line arguments that are optional for CLI.
  type(Type_Command_Line_Argument), allocatable:: cla(:)              !< CLA list [1:Na].
  contains
    procedure:: free     ! Procedure for freeing dynamic memory.
    procedure:: add      ! Procedure for adding CLA to CLAs list.
    procedure:: check    ! Procedure for checking CLAs data consistenc.
    procedure:: passed   ! Procedure for checking if a CLA has been passed.
    procedure:: parse    ! Procedure for parsing Command Line Interfaces by means of a previously initialized CLA list.
    procedure:: get      ! Procedure for getting CLA value from CLAs list parsed.
    final::     finalize ! Procedure for freeing dynamic memory when finalizing.
    ! operators overloading
    generic:: assignment(=) => assign_cli
    ! private procedures
    procedure, pass(self1), private:: assign_cli
endtype Type_Command_Line_Interface
```

Fews methods are provided within this derived type: _free_ for freeing the CLI memory, _add_ for adding a CLA to the CLI, _check_ for checking the CLAs definition consistency, _passed_ for checking is a particular CLA has been actually passed, _parse_ for parsing all passed CLAs accordingly to the list previously defined for building up the CLI and _get_ for returning a particular CLA value and storing it into user-defined variable.

Essentially, for building up a minimal CLI you should follow the 3 steps:

- declare a CLI variable:
```fortran
  type(Type_Command_Line_Interface):: cli
```
- adding one or more CLA definition to the CLI:
```fortran
  call cli%add(switch='-o',help='Output file name',def='myfile.md',error=err)
```
  more details on how declare a CLA are reported in the followings;
- parsing the actually passed command line arguments:
```fortran
  call cli%parse(progname='example',error=error)
```
  more details on parsing method are reported in the followings;
- getting parsed values and storing into user-defined variables:
```fortran
  call cli%get(switch='-o',val=OutputFilename,error=error)
```
  _OutputFilename_ and _error_ being previously defined variables.

#### Adding a new CLA to CLI

CLA cannot be directly defined and modified: to handle a CLA you must use CLI methods. Adding CLA to CLI is performed through the _add_ method:
```fortran
  call cli%add(pref,switch,switch_ab,help,required,positional,position,act,def,nargs,choices,error)
```
where
```fortran
  character(*), optional, intent(IN)::  pref       !< Prefixing string.
  character(*), optional, intent(IN)::  switch     !< Switch name.
  character(*), optional, intent(IN)::  switch_ab  !< Abbreviated switch name.
  character(*), optional, intent(IN)::  help       !< Help message describing the CLA.
  logical,      optional, intent(IN)::  required   !< Flag for set required argument.
  logical,      optional, intent(IN)::  positional !< Flag for checking if CLA is a positional or a named CLA.
  integer(I4P), optional, intent(IN)::  position   !< Position of positional CLA.
  character(*), optional, intent(IN)::  act        !< CLA value action.
  character(*), optional, intent(IN)::  def        !< Default value.
  character(*), optional, intent(IN)::  nargs      !< Number of arguments of CLA.
  character(*), optional, intent(IN)::  choices    !< List of allowable values for the argument.
  integer(I4P),           intent(OUT):: error      !< Error trapping flag.
```
The dummy arguments should be auto-explicative. Note that the _help_ dummy argument is used for printing a pretty help message explaining the CLI usage, thus should be always provided even if CLA is an optional argument. It is also worthy of note that the abbreviated switch is set equal to switch name (if passed) if no otherwise defined. Moreover, one between _switch_ and _position_ must be defined: if _switch_ is defined then a named CLA is initialed, otherwise _position_ must be defined (with _positional=.true._) and a positional CLA is initialized. When a CLA is added a self-consistency-check is performed, e.g. it is checked if an optional CLA has a default value or if one of _position_ and _switch_ has been passed. In case the self-consistency-check fails and error code is returned and an error message is printed to _stderr_.

Note that _choices_  must be a comma-separated list of allowable values and if it has been specified the passed value is checked to be consistent with this list when the _get_ method is invoked: an error code is returned and if the value is not into the specified range an error message is printed to _stderr_. However the value of CLA is not modified and it is equal to the passed value.

#### Parsing the CLI
The complete signature of _parse_ method is the following:
```fortran
  call cli%parse(pref,help,examples,progname,error)
```
where
```fortran
character(*), optional, intent(IN)::  pref         !< Prefixing string.
character(*), optional, intent(IN)::  help         !< Help message describing the Command Line Interface.
character(*), optional, intent(IN)::  examples(1:) !< Examples of correct usage.
character(*),           intent(IN)::  progname     !< Program name.
integer(I4P),           intent(OUT):: error        !< Error trapping flag.
```
The dummy arguments should be auto-explicative. Note that the _help_  and _examples_ dummy arguments are used for printing a pretty help message explaining the CLI usage, thus should be always provided even if they are optional arguments. It is worthy of note that when _parse_ method is invoked a consistency-check is invoked: in particular it is checked that all named CLAs (the non positional ones having defined the switch name) have a unique switch name in order to avoid ambiguity.

The help messages are print if one of the following issues arise:
- the switch name of unknown CLA is passed;
- the number of passed CLAs is less than the required CLAs previously defined.

#### Getting a CLA value from parsed CLI
After the CLI has been parsed, the user is allowed to get any of the defined CLA value. Accordingly to the user-definition, a CLA
value can be obtained either by the switch name (for named CLA) or by the CLA position (for positional CLA):
```fortran
call cli%get(switch='-r',val=rval,error=err)
```
or
```fortran
call cli%get(position=1,val=prval,error=err)
```
where _rval_ and _prval_ are two previously defined variables. Currently, the _val_ variable can be only scalar of types _integer_, _real_, _logical_ and _character_. The complete API of _cli%get_ is the following:
```fortran
  call cli%get(pref,switch,position,val,error)
```
where the signature of  _get_ is:
```fortran
  character(*), optional, intent(IN)::    pref     !< Prefixing string.
  character(*), optional, intent(IN)::    switch   !< Switch name.
  integer(I4P), optional, intent(IN)::    position !< Position of positional CLA.
  class(*),               intent(INOUT):: val      !< CLA value.
  integer(I4P),           intent(OUT)::   error    !< Error trapping flag.
```
The dummy arguments should be auto-explicative. Note that the _switch_ passed can be also the abbreviated form if defined differently from the extended one. If no _switch_ neither _position_ is passed and error is arised.

### Compile Testing Program

As a practical example of FLAP usage a testing program named __flap_test__ is provided. You can compile with Fortran compiler supporting modern standards (2003+). Note that the dependency hierarchy of modules USE statement must be respected in order to successfully compile the program. If you are tired by frustrating usage of makefiles & co. you can try [FoBiS.py](https://github.com/szaghi/FoBiS) for building the program. A _fobos_ file is provided with FLAP. To build it just type into the root directory of FLAP:
```bash
FoBiS.py build
```

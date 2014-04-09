# FLAP
### FLAP, Fortran command Line Arguments Parser for poor men

A very simple and stupid tool for building easily nice Command Line Interface for modern Fortran projects.

### A Taste of FLAP

Running the provided test program, __flap_test__, a taste of FLAP is served:
```bash
+--> flap_test, a testing program for FLAP library
+--> Parsing Command Line Arguments
|--> Error: the Command Line Interface requires at least 1 arguments to be passed whereas only 0 have been!
|--> The Command Line Interface (CLI) has the following options
|-->   FLAP_Test -string value [-integer value] [-real value] [-boolean]
|--> Each Command Line Argument (CLA) has the following meaning:
|-->   [-string value] or [-s value]
|-->     String input
|-->     It is a non optional CLA thus must be passed to CLI
|-->   [-integer value] or [-i value]
|-->     Integer input
|-->     It is a optional CLA which default value is "-1"
|-->   [-real value] or [-r value]
|-->     Real input
|-->     It is a optional CLA which default value is "1.0"
|-->   [-boolean] or [-b]
|-->     Boolean input
|-->     It is a optional CLA which default value is ".false."
|--> Usage examples:
|-->   -) flap_test -s 'Hello FLAP'
|-->   -) flap_test -s 'Hello FLAP' -i -2
|-->   -) flap_test -s 'Hello FLAP' -i -2 -r 33.d0
|-->   -) flap_test -string 'Hello FLAP' -boolean
```
Not so bad for just a very few statements as the following:
```fortran
...
write(stdout,'(A)')'+--> flap_test, a testing program for FLAP library'
! setting CLAs
call cli%add(switch='-string',     switch_ab='-s', help='String input',        required=.true.,  act='store'                   )
call cli%add(switch='-integer',    switch_ab='-i', help='Integer input',       required=.false., act='store',     def='-1'     )
call cli%add(switch='-real',       switch_ab='-r', help='Real input',          required=.false., act='store',     def='1.0'    )
call cli%add(switch='-boolean',    switch_ab='-b', help='Boolean input',       required=.false., act='store_true',def='.false.')
call cli%add(switch='-boolean_val',switch_ab='-bv',help='Valued boolean input',required=.false., act='store',     def='.true.' )
! checking consistency of CLAs
call cli%check(error=error,pref='|-->') ; if (error/=0) stop
! parsing CLI
write(stdout,'(A)')'+--> Parsing Command Line Arguments'
call cli%parse(examples=["flap_test -s 'Hello FLAP'               ",&
                         "flap_test -s 'Hello FLAP' -i -2         ",&
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
+ automatic generation of help and usage messages;
+ errors trapping for invalid CLI usage.
+ ...

## <a name="todos"></a>Todos
+ Support for positional CLAs;
+ support for multiple valued (list of values) CLAs.
+ ...

## <a name="requirements"></a>Requirements
+ Modern Fortran Compiler (standard 2003+);
+ a lot of patience with the author.

FLAP is developed on a GNU/Linux architecture. For Windows architecture there is no support, however it should be work out-of-the-box.

## <a name="Copyrights"></a>Copyrights

FLAP is an open source project, it is distributed under the [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html). Anyone is interest to use, to develop or to contribute to FLAP is welcome.

## <a name="usage"></a>Usage

### API
FLAP is currently composed by two modules, namely  __Data_Type_Command_Line_Argument.f90__ and  __Data_Type_Command_Line_Interface.f90__. The first one is such as a back-end handling CLAs while the latter is the front-end providing all you need to handle your CLI. Two auxiliary modules, __IR_Precision.f90__ and __Lib_IO_Misc.f90__ are used for minor tasks. Finally, a testing program __flap_test__ is provided showing a basic example of FLAP usage.

The main CLI object, that is the only one you must know, is __Type_Command_Line_Interface__

```fortran
type, public:: Type_Command_Line_Interface
  integer(I4P)::                                  Na          = 0_I4P !< Number of CLA.
  integer(I4P)::                                  Na_required = 0_I4P !< Number of command line arguments that CLI requires.
  integer(I4P)::                                  Na_optional = 0_I4P !< Number of command line arguments that are optional for CLI.
  type(Type_Command_Line_Argument), allocatable:: cla(:)              !< CLA list [1:Na].
  contains
    procedure:: free         ! Procedure for freeing dynamic memory.
    procedure:: add_cla      ! Procedure for adding CLA to CLAs list.
    procedure:: add_init_cla ! Procedure for adding an on-the-fly-initialized CLA to CLAs list.
    procedure:: check        ! Procedure for checking CLAs data consistenc.
    procedure:: passed       ! Procedure for checking if a CLA has been passed.
    procedure:: parse        ! Procedure for parsing Command Line Interfaces by means of a previously initialized CLA list.
    procedure:: get          ! Procedure for getting CLA value from CLAs list parsed.
    final::     finalize     ! Procedure for freeing dynamic memory when finalizing.
    generic::   add => add_cla,add_init_cla
    ! operators overloading
    generic:: assignment(=) => assign_self
    ! private procedures
    procedure, pass(self1), private:: assign_self
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
  call cli%add(switch='-o',help='Output file name',def='myfile.md')
```
  more details on how declare a CLA are reported in the followings;
- parsing the actually passed command line arguments:
```fortran
  call cli%parse(progname='example',error=error)
```
  more details on parsing method are reported in the followings;
- getting parsed values and storing into user-defined variables:
```fortran
  call cli%get(switch='-o',val=OutputFilename)
```
  _OutputFilename_ being a previously defined variable.

#### Adding a new CLA to CLI

There are two ways for adding a new definition of CLA into your CLI:

- adding and defining a CLA on-the-fly using _add_ generic type bound procedure;
- adding a previously defined CLA
```fortran
  type(Type_Command_Line_Command):: cla
```

Note that in the second case you must access also to the module __Data_Type_Command_Line_Argument.f90__  and not only to __Data_Type_Command_Line_Interface.f90__. In all cases, the definition of a new CLA has presently the following signature:
```fortran
  call cli%add(switch_ab,help,required,act,def,nargs,switch)
```
or
```fortran
  call cla%init(switch_ab,help,required,act,def,nargs,switch)
```
or
```fortran
  cla = cla_init(switch_ab,help,required,act,def,nargs,switch)
```
where
```fortran
  character(*), optional, intent(IN):: switch_ab !< Abbreviated switch name.
  character(*), optional, intent(IN):: help      !< Help message describing the CLA.
  logical,      optional, intent(IN):: required  !< Flag for set required argument.
  character(*), optional, intent(IN):: act       !< CLA value action.
  character(*), optional, intent(IN):: def       !< Default value.
  character(*), optional, intent(IN):: nargs     !< Number of arguments of CLA.
  character(*),           intent(IN):: switch    !< Switch name.
```
The dummy arguments should be auto-explicative. Note that the _help_ dummy argument is used for printing a pretty help message explaining the CLI usage, thus should be always provided even if it is an optional argument. It is also worthy of note that the abbreviated switch is set equal to switch name (the only argument non optional) is no otherwise defined.

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
The dummy arguments should be auto-explicative. Note that the _help_  and _examples_ dummy arguments are used for printing a pretty help message explaining the CLI usage, thus should be always provided even if they are optional arguments. The help messages are print is one of the following issues arise:
- the switch name of unknown CLA is passed;
- the number of passed CLAs is less than the required CLAs previously defined.

### Compile Testing Program

As a practical example of FLAP usage a testing program named __flap_test__ is provided. You can compile with Fortran compiler supporting modern standards (2003+). Note that the dependency hierarchy of modules USE statement must be respected in order to successfully compile the program. If you are tired by frustrating usage of makefiles & co. you can try [FoBiS.py](https://github.com/szaghi/FoBiS) for building the program. A _fobos_ file is provided with FLAP. To build it just type into the root directory of FLAP:
```bash
FoBiS.py build
```

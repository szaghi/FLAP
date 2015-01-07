project: FLAP
project_directory: ./src
output_dir: ./doc/html/publish/
project_github: https://github.com/szaghi/FLAP
project_website: https://github.com/szaghi/FLAP
summary: Fortran command Line Arguments Parser for poor men
author: Stefano Zaghi
github: https://github.com/szaghi
email: stefano.zaghi@gmail.com
docmark: <

### <a name="top"></a>FLAP, Fortran command Line Arguments Parser for poor men

A very simple and stupid tool for building easily nice Command Line Interface for modern Fortran projects.

### A Taste of FLAP

Running the provided test program, __flap_test__, a taste of FLAP is served:
```shell
+--> flap_test, a testing program for FLAP library
+--> Parsing Command Line Arguments
|--> The Command Line Interface (CLI) has the following options
|-->   flap_test  [value] --string value [--integer value] [--real value] [--boolean] [--boolean_val value] [--integer_list value#1 value#2 value#3] [--help] [--version]
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
|-->   -) flap_test -s 'Hello FLAP'
|-->   -) flap_test -s 'Hello FLAP' -i -2 # printing error...
|-->   -) flap_test -s 'Hello FLAP' -i 3 -r 33.d0
|-->   -) flap_test -s 'Hello FLAP' -integer_list 10 -3 87
|-->   -) flap_test 33.0 -s 'Hello FLAP' -i 5
|-->   -) flap_test -string 'Hello FLAP' -boolean
```
Not so bad for just a very few statements as the following:
```fortran
...
write(stdout,'(A)')'+--> flap_test, a testing program for FLAP library'
! initializing CLI
call cli%init(progname='flap_test',                                           &
              version ='v0.0.1',                                              &
              examples=["flap_test -s 'Hello FLAP'                          ",&
                        "flap_test -s 'Hello FLAP' -i -2 # printing error...",&
                        "flap_test -s 'Hello FLAP' -i 3 -r 33.d0            ",&
                        "flap_test -s 'Hello FLAP' -integer_list 10 -3 87   ",&
                        "flap_test 33.0 -s 'Hello FLAP' -i 5                ",&
                        "flap_test -string 'Hello FLAP' -boolean            "])
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

Go to [Top](#top) or [Toc](#toc)
## <a name="toc"></a>Table of Contents

* [Team Members](#team-members)
* [What is FLAP?](#what)
* [Main features](#main-features)
* [Todos](#todos)
* [Requirements](#requirements)
* [Copyrights](#copyrights)
* [Usage](#usage)
  + [API](#API)
      * [Initializing CLI with personalized help messages](#cli-init)
      * [Adding a new CLA to CLI](#cla-add)
      * [Parsing the CLI](#cli-parse)
      * [Getting a CLA value from parsed CLI](#cla-get)
  + [Compile Testing Program](#test)
* [Version History](#versions)

Go to [Top](#top) or [Toc](#toc)
## <a name="team-members"></a>Team Members
* Stefano Zaghi <stefano.zaghi@gmail.com>

Go to [Top](#top) or [Toc](#toc)
## <a name="what"></a>What is FLAP?

Modern Fortran standards (2003+) have introduced support for Command Line Arguments (CLA), thus it is possible to construct nice and effective Command Line Interface (CLI). FLAP is a small library designed to simplify the (repetitive) construction of complicated CLI in pure Fortran (standard 2003+). FLAP has been inspired by the python module _argparse_ trying to mimic it. Once you have defined the arguments are required by means of a user-friendly method of the CLI, FLAP will parse the CLAs for you. It is worthy of note that FLAP, as _argparse_, also automatically generates help and usage messages and issues errors when users give the program invalid arguments.

Go to [Top](#top) or [Toc](#toc)
## <a name="main-features"></a>Main features
+ User-friendly methods for building flexible and effective Command Line Interfaces (CLI);
+ support optional and non optional Command Line Argument (CLA);
+ support boolean CLA;
+ support positional CLA;
+ support list of allowable values for defined CLA with automatic consistency check;
+ support multiple valued (list of values) CLA;
+ automatic generation of help and usage messages;
+ self-consistency-check of CLA definition;
+ consistency-check of whole CLI definition;
+ errors trapping for invalid CLI usage;

Go to [Top](#top) or [Toc](#toc)
## <a name="todos"></a>Todos
+ Try [docopt](https://github.com/docopt/docopt) features;
+ any feature request is welcome!

Go to [Top](#top) or [Toc](#toc)
## <a name="requirements"></a>Requirements
+ Modern Fortran Compiler (standard 2003+);
+ a lot of patience with the author.

FLAP is developed on a GNU/Linux architecture. For Windows architecture there is no support, however it should be work out-of-the-box.

Go to [Top](#top) or [Toc](#toc)
## <a name="Copyrights"></a>Copyrights

FLAP is an open source project, it is distributed under the [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html). Anyone is interest to use, to develop or to contribute to FLAP is welcome.

Go to [Top](#top) or [Toc](#toc)
## <a name="usage"></a>Usage
FLAP is a module library.
FLAP is currently composed by one module, namely  __Data_Type_Command_Line_Interface.f90__, where two derived types are defined:
1. __Type_Command_Line_Argument__;
2. __Type_Command_Line_Interface__.

The first one is a back-end handling CLAs while the latter is the front-end providing all you need to handle your CLI. Two auxiliary modules, __IR_Precision.f90__ and __Lib_IO_Misc.f90__ are used for minor tasks. Finally, a testing program __flap_test__ is provided showing a basic example of FLAP usage.

To start using FLAP and declaring your CLI, you must import its main module:
```fortran
...
USE Data_Type_Command_Line_Interface
...

type(Type_Command_Line_Interface):: CLI
```
Now that you have your CLI declared you can start using it. The API to handle it follows.

### <a name="API">API
The main CLI object, that is the only one you must know, is __Type_Command_Line_Interface__
```fortran
type, public:: Type_Command_Line_Interface
  integer(I4P)::                                  Na          = 0_I4P !< Number of CLA.
  integer(I4P)::                                  Na_required = 0_I4P !< Number of command line arguments that CLI requires.
  integer(I4P)::                                  Na_optional = 0_I4P !< Number of command line arguments that are optional for CLI.
  type(Type_Command_Line_Argument), allocatable:: cla(:)              !< CLA list [1:Na].
  character(len=:), allocatable::                 progname            !< Program name.
  character(len=:), allocatable::                 version             !< Program version.
  character(len=:), allocatable::                 help                !< Help message introducing the CLI usage.
  character(len=:), allocatable::                 examples(:)         !< Examples of correct usage.
  logical::                                       disable_hv = .false.!< Disable automatic inserting of 'help' and 'version' CLAs.
  contains
    procedure:: free                                ! Procedure for freeing dynamic memory.
    procedure:: init                                ! Procedure for initializing CLI.
    procedure:: add                                 ! Procedure for adding CLA to CLAs list.
    procedure:: check                               ! Procedure for checking CLAs data consistenc.
    procedure:: passed                              ! Procedure for checking if a CLA has been passed.
    procedure:: parse                               ! Procedure for parsing Command Line Interfaces.
    generic::   get => get_cla_cli,get_cla_list_cli ! Procedure for getting CLA value(s) from CLAs list parsed.
    final::     finalize                            ! Procedure for freeing dynamic memory when finalizing.
    ! operators overloading
    generic:: assignment(=) => assign_cli
    ! private procedures
    procedure,              private:: get_cla_cli
    procedure,              private:: get_cla_list_cli
    procedure, pass(self1), private:: assign_cli
endtype Type_Command_Line_Interface
```
Fews methods are provided within this derived type:

+ _free_ for freeing the CLI memory;
+ _init_ for initializing CLI with user defined help messages;
+ _add_ for adding a CLA to the CLI;
+ _check_ for checking the CLAs definition consistency;
+ _passed_ for checking is a particular CLA has been actually passed;
+ _parse_ for parsing all passed CLAs accordingly to the list previously defined for building up the CLI;
+ _get_ for returning a particular CLA value and storing it into user-defined variable.

Essentially, for building up and using a minimal CLI you should follow the 4 steps:

1. declare a CLI variable:
```fortran
type(Type_Command_Line_Interface):: cli
```
2. adding one or more CLA definition to the CLI:
```fortran
call cli%add(switch='-o',help='Output file name',def='myfile.md',error=error)
```
more details on how declare a CLA are reported in the followings;
3. parsing the actually passed command line arguments:
```fortran
call cli%parse(error=error)
```
more details on parsing method are reported in the followings;
4. getting parsed values and storing into user-defined variables:
```fortran
call cli%get(switch='-o',val=OutputFilename,error=error)
```
_OutputFilename_ and _error_ being previously defined variables.

Optionally you can initialize CLI with custom help messages by means of _init_ method.

#### <a name="cli-init">Initializing CLI with personalized help messages

CLI data type can already (quasi-automatically) handle CLAs through its default values (provided from the baseline variable declaration, i.e. `type(Type_Command_Line_Interface):: cli`). However, in order to improve the clearness CLI messages you can personalized help messages by means of _init_ method (that remains an optional step):
```fortran
call cli%init(progname,version,help,examples,disable_hv)
```
where
```fortran
character(*), optional, intent(IN):: progname     !< Program name.
character(*), optional, intent(IN):: version      !< Program version.
character(*), optional, intent(IN):: help         !< Help message introducing the CLI usage.
character(*), optional, intent(IN):: examples(1:) !< Examples of correct usage.
logical,      optional, intent(IN):: disable_hv   !< Disable automatic inserting of 'help' and 'version' CLAs.
```
The dummy arguments should be auto-explicative. Note that the _help_ and _examples_ dummy arguments are used for printing a pretty help message explaining the CLI usage, thus should be always provided even if they are optional arguments. Moreover, due the Fortran limitations, the array containing the examples must have character elements with the same length, thus trailing white spaces must padded to short examples.

The only not so clear argument of _init_ method is __disable_hv__.

###### Disabling automatic Help and Version
FLAP automatically add 2 special CLA to CLI:

1. a CLA for printing a help message explaining the correct use of the CLI;
2. a CLA for printing the version (if defined when the CLI is initialized) of the program.

This two CLAs has the following default switches:

+ _help_: switch `--help`, abbreviated switch `-h`;
+ _version_: switch `--version`, abbreviated switch `-v`;

However, FLAP before adding these two CLAs to the CLI checks if these switches have been already used and in case does not add them. To disable such an automatic CLAs creation initialized the CLI with:
```fortran
call cli%init(...,disable_hv=.true.)
```

Go to [Top](#top) or [Toc](#toc)
#### <a name="cla-add">Adding a new CLA to CLI

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
character(*), optional, intent(IN)::  nargs      !< Number of arguments consumed by CLA.
character(*), optional, intent(IN)::  choices    !< List of allowable values for the argument.
integer(I4P),           intent(OUT):: error      !< Error trapping flag.
```
The dummy arguments should be auto-explicative. Note that the _help_ dummy argument is used for printing a pretty help message explaining the CLI usage, thus should be always provided even if CLA is an optional argument. It is also worthy of note that the abbreviated switch is set equal to switch name (if passed) if no otherwise defined. Moreover, one between _switch_ and _position_ must be defined: if _switch_ is defined then a named CLA is initialed, otherwise _position_ must be defined (with _positional=.true._) and a positional CLA is initialized.

The following rules apply:
+ `pref` string is used as prefixing string for any messages on standard out/err;
+ if `required` is set to `.false.` a default value must be defined, even if it is a null string;
+ no matter the type of CLA value is (real, integer, etc...) the definition of default value for an optional CLA must be always a string, e.g. `def='1'` or `def='1.0'`; the actual type casting is performed when the CLA value is gotten by means of the `get` method: the type casting is performed by means of the actual type (and kind) of the variable used for storing CLA value;
+ presently the possible actions of CLA are (all actions definitions are case insensitive):
    + `act=store`, the CLA stores a value that must be passed after the CLA switch for named CLA;
    + `act=store_true`, the CLA stores `.true.`;
    + `act=store_false`, the CLA stores `.false.`;
    + `act=print_help`, the CLA triggers the printing of the help message that is built with the help messages of all defined CLAs and the help message of CLI;
    + `act=print_version`, the CLA triggers the printing the program version; if the version is not defined when the CLI is initialized the message will contain `version unknown`.

When a CLA is added a self-consistency-check is performed, e.g. it is checked if an optional CLA has a default value or if one of _position_ and _switch_ has been passed. In case the self-consistency-check fails an error code is returned and an error message is printed to _stderr_.

Note that _choices_  must be a comma-separated list of allowable values and if it has been specified the passed value is checked to be consistent with this list when the _get_ method is invoked: an error code is returned and if the value is not into the specified range an error message is printed to _stderr_. However the value of CLA is not modified and it is equal to the passed value.

Go to [Top](#top) or [Toc](#toc)
#### <a name="cli-parse">Parsing the CLI
The complete signature of _parse_ method is the following:
```fortran
  call cli%parse(pref,error)
```
where
```fortran
character(*), optional, intent(IN)::  pref  !< Prefixing string.
integer(I4P),           intent(OUT):: error !< Error trapping flag.
```
The dummy arguments should be auto-explicative. It is worthy of note that when _parse_ method is invoked a consistency-check is performed: in particular it is checked that all named CLAs (the non positional ones having defined the switch name) have a unique switch name in order to avoid ambiguity.

The help messages are print if one of the following issues arise:
- the _help_ CLA is passed;
- the switch name of unknown CLA is passed;
- the number of passed CLAs is less than the required CLAs previously defined.

Go to [Top](#top) or [Toc](#toc)
#### <a name="cla-get">Getting a CLA value from parsed CLI
After the CLI has been parsed, the user is allowed to get any of the defined CLA value. Accordingly to the user-definition, a CLA value can be obtained either by the switch name (for named CLA) or by the CLA position (for positional CLA):
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
The dummy arguments should be auto-explicative. Note that the _switch_ passed can be also the abbreviated form if defined differently from the extended one. If no _switch_ neither _position_ is passed and error is arisen. Moreover, the type of the value returned is chosen accordingly to actual _val_ argument passed: inside the _get_ method _val_ is an unlimited polymorphic variable which type is defined only when the user passes the actual _val_ container.

Note that for multiple valued (list) CLA, the _get_ method accept also array _val_:
```fortran
character(*), optional, intent(IN)::    pref     !< Prefixing string.
character(*), optional, intent(IN)::    switch   !< Switch name.
integer(I4P), optional, intent(IN)::    position !< Position of positional CLA.
class(*),               intent(INOUT):: val(1:)  !< CLA value.
integer(I4P),           intent(OUT)::   error    !< Error trapping flag.
```
however, the _get_ method is invoked exactly with the same signature of single valued CLA as above: _get_ is a generic, user-friendly method that automatically handles both scalar and array _val_ variables.

Go to [Top](#top) or [Toc](#toc)
### <a name="test">Compile Testing Program

As a practical example of FLAP usage a testing program named __flap_test__ is provided. You can compile with Fortran compiler supporting modern standards (2003+). Note that the dependency hierarchy of modules USE statement must be respected in order to successfully compile the program. If you are tired by frustrating usage of makefiles & co. you can try [FoBiS.py](https://github.com/szaghi/FoBiS) for building the program. A _fobos_ file is provided with FLAP. To build it just type into the root directory of FLAP:
```bash
FoBiS.py build
```

Go to [Top](#top) or [Toc](#toc)
## <a name="versions"></a>Version History
In the following the changelog of most important releases is reported.
### v0.0.1
##### Download [ZIP](https://github.com/szaghi/FLAP/archive/v0.0.1.zip) ball or [TAR](https://github.com/szaghi/FLAP/archive/v0.0.1.tar.gz) one
Stable Release. Fully backward compatible.

Go to [Top](#top) or [Toc](#toc)

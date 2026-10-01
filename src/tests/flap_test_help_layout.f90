!< The layout of the help (issue #126, output defects 2, 3, 4, 8, 9, 11, 12).
program flap_test_help_layout
!< The layout of the help (issue #126, output defects 2, 3, 4, 8, 9, 11, 12).
!<
!< One blank line between the parts (2); items indented by 2, their details by 6, the environment variable and the command
!< descriptions too (3); `usage: prog [...]` with single blanks, in the help of the program and of a command (4);
!< positionals in their own part, without "1-th argument" (8); the same placeholders of a list in the usage line and in
!< the help, without a stray blank (9); the help of a command without the examples of the program (11); the choices on a
!< detail line, without Markdown backticks (12).
use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_contains
use penf, only : I4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
character(:), allocatable    :: out   !< Help.
character(:), allocatable    :: nl    !< New line.
integer(I4P)                 :: error !< Error trapping flag.

nl = new_line('a')
call cli%init(progname='prog', description='A program', examples=['prog in.dat'])
call cli%add(positional=.true., position=1, help='input', required=.true., act='store', metavar='INPUT', error=error)
call cli%add(switch='--level', help='level', required=.false., act='store', def='1', choices='1,3', envvar='LEVEL', &
             error=error)
call cli%add(switch='--box', help='box', required=.false., act='store', nargs='3', def='1 1 1', error=error)
call cli%add(switch='--fields', help='fields', required=.false., act='store', nargs='+', def='u', metavar='F', error=error)
call cli%add_group(group='run', description='run it')
call cli%add(group='run', switch='--n', help='n', required=.false., act='store', def='1', error=error)
call assert(error == 0, 'define')

out = cli%usage(g=0)
! 4: single blanks
call assert(out(1:len('usage: prog INPUT [')) == 'usage: prog INPUT [', '4: "'//out(1:20)//'"')
! 2: one blank line between the parts
call assert(index(out, nl//nl//nl) == 0, '2: never two blank lines')
call assert_contains(out, 'A program'//nl//nl//'Positional arguments:', '2: description, then the positionals')
! 8: positionals in their own part
call assert_contains(out, 'Positional arguments:'//nl//'  INPUT'//nl//'      input', '8: positional part')
call assert(index(out, '-th argument') == 0, '8: no ordinal')
! 3: indentation
call assert_contains(out, nl//'  --level value'//nl, '3: an item, 2 blanks')
call assert_contains(out, nl//'      environment variable name "LEVEL"', '3: the variable, 6 blanks')
call assert_contains(out, nl//'      default value 1', '3: a detail, 6 blanks')
call assert_contains(out, 'Commands:'//nl//'  run'//nl//'      run it', '3: a command and its description')
call assert_contains(out, 'Examples:'//nl//'  prog in.dat', '3: an example, 2 blanks')
! 12: the choices on a detail line
call assert_contains(out, nl//'      choices: 1, 3', '12: choices detail')
call assert(index(out, '`') == 0, '12: no backticks in the plain help')
! 9: lists
call assert_contains(out, '[--box value#1 value#2 value#3]', '9: no stray blank')
call assert_contains(out, '[--fields F#1 [F#2...]]', '9: usage line, short form')
call assert_contains(out, nl//'  --fields F#1 [F#2...]', '9: the same in the help')

out = cli%usage(g=1)
! 4 and 11: the help of a command
call assert(out(1:len('usage: prog run [')) == 'usage: prog run [', '4: command, "'//out(1:20)//'"')
call assert(index(out, 'Examples:') == 0, '11: no examples of the program in the help of a command')
call assert(index(out, nl//nl//nl) == 0, '2: command, never two blank lines')
endprogram flap_test_help_layout

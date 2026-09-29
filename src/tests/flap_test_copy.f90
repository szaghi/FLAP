!< Copies are complete: intrinsic assignment of each type and the partial assign_object copy (issue #125, step 0.D.6, E1).
program flap_test_copy
!< Copies are complete: intrinsic assignment of each type and the partial assign_object copy (issue #125, step 0.D.6, E1).
!<
!< FLAP relies on intrinsic (deep) assignment for whole-object copies. The one explicit copy left is object%assign_object: a
!< component added to the base object must be added there too, or this test fails.
use flap, only : command_line_argument, command_line_arguments_group, command_line_interface
use flap_test_utils, only : assert, assert_equal
use penf, only : I4P

implicit none
type(command_line_argument)        :: a     !< Source argument, every component set.
type(command_line_argument)        :: b     !< Intrinsic copy.
type(command_line_argument)        :: c     !< Copy of the object part (assign_object).
type(command_line_arguments_group) :: g     !< Source group.
type(command_line_arguments_group) :: h     !< Intrinsic copy.
type(command_line_interface)       :: cli   !< Source CLI.
type(command_line_interface)       :: cli2  !< Intrinsic copy.
integer(I4P)                       :: error !< Error trapping flag.

! object components
a%progname = 'prog' ; a%version = 'v1' ; a%help = 'help' ; a%help_color = 'red' ; a%help_style = 'bold'
a%help_markdown = 'md' ; a%description = 'desc' ; a%license = 'MIT' ; a%authors = 'me' ; a%epilog = 'bye'
a%m_exclude = '--x' ; a%error_message = 'msg' ; a%error_color = 'blue' ; a%error_style = 'italics'
call a%set_examples(['prog -a', 'prog -b'])
a%error = 7 ; a%usage_lun = 11 ; a%version_lun = 12 ; a%error_lun = 13
! argument components
a%switch = '--sw' ; a%switch_ab = '-s' ; a%act = 'STORE' ; a%def = '1' ; a%nargs = '2' ; a%choices = '1,2' ; a%val = '2'
a%envvar = 'ENV' ; a%is_required = .true. ; a%is_positional = .true. ; a%position = 3 ; a%is_passed = .true.
a%is_hidden = .true. ; a%is_val_required = .false.

b = a
call check_object(b, 'intrinsic copy of an argument')
call assert_equal(b%switch, '--sw', 'argument copy: switch')
call assert_equal(b%switch_ab, '-s', 'argument copy: switch_ab')
call assert_equal(b%act, 'STORE', 'argument copy: act')
call assert_equal(b%def, '1', 'argument copy: def')
call assert_equal(b%nargs, '2', 'argument copy: nargs')
call assert_equal(b%choices, '1,2', 'argument copy: choices')
call assert_equal(b%val, '2', 'argument copy: val')
call assert_equal(b%envvar, 'ENV', 'argument copy: envvar')
call assert(b%is_required .and. b%is_positional .and. b%is_passed .and. b%is_hidden .and. (.not.b%is_val_required), &
            'argument copy: logical components')
call assert_equal(b%position, 3_I4P, 'argument copy: position')

call c%assign_object(a)
call check_object(c, 'assign_object')

g%group = 'cmd' ; g%cla = [a] ; g%Na = 1 ; g%is_called = .true. ; g%progname = 'prog' ; g%epilog = 'bye'
h = g
call assert_equal(h%group, 'cmd', 'group copy: group')
call assert_equal(h%Na, 1_I4P, 'group copy: Na')
call assert(h%is_called, 'group copy: is_called')
call assert_equal(int(size(h%cla), I4P), 1_I4P, 'group copy: cla')
call check_object(h%cla(1), 'group copy: its argument')
call assert_equal(h%epilog, 'bye', 'group copy: object part')

call cli%init(progname='prog', version='v1', description='desc', epilog='bye', examples=['prog -a'])
call cli%add(switch='--sw', switch_ab='-s', help='a switch', required=.false., act='store', def='1', error=error)
call cli%add_group(group='cmd', description='a command')
call cli%add(group='cmd', switch='--in', help='input', required=.true., act='store', error=error)
cli2 = cli
call assert_equal(cli2%usage(g=0), cli%usage(g=0), 'CLI copy: usage')
call assert_equal(cli2%usage(g=1), cli%usage(g=1), 'CLI copy: usage of the command')
call assert_equal(cli2%signature(), cli%signature(), 'CLI copy: signature')

contains
  subroutine check_object(x, what)
  !< Check every component of the object part against the source.
  class(command_line_argument), intent(in) :: x    !< Copy.
  character(*),                 intent(in) :: what !< Kind of copy.

  call assert_equal(x%progname, 'prog', what//': progname')
  call assert_equal(x%version, 'v1', what//': version')
  call assert_equal(x%help, 'help', what//': help')
  call assert_equal(x%help_color, 'red', what//': help_color')
  call assert_equal(x%help_style, 'bold', what//': help_style')
  call assert_equal(x%help_markdown, 'md', what//': help_markdown')
  call assert_equal(x%description, 'desc', what//': description')
  call assert_equal(x%license, 'MIT', what//': license')
  call assert_equal(x%authors, 'me', what//': authors')
  call assert_equal(x%epilog, 'bye', what//': epilog')
  call assert_equal(x%m_exclude, '--x', what//': m_exclude')
  call assert_equal(x%error_message, 'msg', what//': error_message')
  call assert_equal(x%error_color, 'blue', what//': error_color')
  call assert_equal(x%error_style, 'italics', what//': error_style')
  call assert_equal(int(size(x%examples), I4P), 2_I4P, what//': examples')
  call assert_equal(x%examples(2), 'prog -b', what//': examples(2)')
  call assert_equal(x%error, 7_I4P, what//': error')
  call assert_equal(x%usage_lun, 11_I4P, what//': usage_lun')
  call assert_equal(x%version_lun, 12_I4P, what//': version_lun')
  call assert_equal(x%error_lun, 13_I4P, what//': error_lun')
  endsubroutine check_object
endprogram flap_test_copy

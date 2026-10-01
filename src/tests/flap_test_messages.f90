!< The wording of the error messages (issue #126, output defects 1, 5, 6, 7, 10).
program flap_test_messages
!< The wording of the error messages (issue #126, output defects 1, 5, 6, 7, 10).
!<
!< 1: a value out of its choices is quoted as given (`"2"`, not `"+2"`); 5: the repeated-command error starts with the
!< message, as every error; 6: a list with too few values says so in plain words; 7: an unknown argument that is not a
!< switch is an argument, not a switch; 10: raise_error follows init(usage_on_error=).
use flap, only : command_line_interface, ERROR_COMMAND_REPEATED, ERROR_NARGS_INSUFFICIENT, ERROR_NOT_IN_CHOICES, &
                 ERROR_UNKNOWN
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P, R8P

implicit none
character(:), allocatable :: out !< Captured output.
integer(I4P)              :: lun !< Capture unit.

call capture_open(lun)

! 1: the value of an integer or real choice as given
call check_integer_choice
out = read_back(lun)
call assert_contains(out, 'but "2" has been passed!', '1: an integer value as given')
call check_real_choice
call assert_contains(read_back(lun), 'but "0.30" has been passed!', '1: a real value as given')

! 5: the repeated-command error starts with its message
call check_parse('run --n 1 run', ERROR_COMMAND_REPEATED, '5: a repeated command')
out = read_back(lun)
call assert(out(1:len('prog: error:')) == 'prog: error:', '5: no empty line before the message: "'//out(1:12)//'"')

! 6: too few values
call check_parse('--xyz 1 2', ERROR_NARGS_INSUFFICIENT, '6: too few values')
call assert_contains(read_back(lun), 'prog: error: option "--xyz" requires 3 values!', '6: plain words')

! 7: an argument that is not a switch is an argument
call check_parse('rnn', ERROR_UNKNOWN, '7: an unknown argument')
out = read_back(lun)
call assert_contains(out, 'prog: error: argument "rnn" is unknown! Did you mean "run"?', '7: an argument, not a switch')
call check_parse('--bogus', ERROR_UNKNOWN, '7: an unknown switch')
call assert_contains(read_back(lun), 'prog: error: switch "--bogus" is unknown!', '7: a switch is still a switch')

! 10: raise_error follows usage_on_error
call check_raise('full')
out = read_back(lun)
call assert_contains(out, 'Optional switches:', '10: full, the whole help')
call check_raise('usage')
out = read_back(lun)
call assert_contains(out, 'usage: prog', '10: usage, the usage line')
call assert(index(out, 'Optional switches:') == 0, '10: usage, not the whole help')
call check_raise('none')
out = read_back(lun)
call assert(index(out, 'usage:') == 0, '10: none, no usage')
call assert_contains(out, 'must be even', '10: none, the message')
call capture_close(lun)

contains
  subroutine define(cli, mode)
  !< A CLI with a list option, a command and a choice.
  type(command_line_interface), intent(inout)        :: cli   !< Command Line Interface (CLI).
  character(*),                 intent(in), optional :: mode  !< usage_on_error.
  integer(I4P)                                       :: error !< Error trapping flag.

  if (present(mode)) then
    call cli%init(progname='prog', usage_on_error=mode, error_lun=lun, usage_lun=lun, version_lun=lun, standalone=.false.)
  else
    call cli%init(progname='prog', error_lun=lun, usage_lun=lun, version_lun=lun, standalone=.false.)
  endif
  call cli%add(switch='--xyz', help='xyz', required=.false., act='store', nargs='3', def='1 2 3', error=error)
  call cli%add(switch='--level', help='level', required=.false., act='store', def='1', choices='1,3', error=error)
  call cli%add(switch='--cfl', help='cfl', required=.false., act='store', def='0.25', choices='0.25,0.5', error=error)
  call cli%add_group(group='run', description='run')
  call cli%add(group='run', switch='--n', help='n', required=.false., act='store', def='1', error=error)
  call assert_equal(error, 0_I4P, 'define')
  endsubroutine define

  subroutine check_parse(args, expected, message)
  !< Parse a command line, expecting an error.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  integer(I4P)                 :: error    !< Error trapping flag.

  call define(cli)
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected, message)
  endsubroutine check_parse

  subroutine check_integer_choice
  !< An integer value out of its choices.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: level !< Value.
  integer(I4P)                 :: error !< Error trapping flag.

  call define(cli)
  call cli%parse(args='--level 2', error=error)
  call cli%get(switch='--level', val=level, error=error)
  call assert_equal(error, ERROR_NOT_IN_CHOICES, '1: integer')
  endsubroutine check_integer_choice

  subroutine check_real_choice
  !< A real value out of its choices.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  real(R8P)                    :: cfl   !< Value.
  integer(I4P)                 :: error !< Error trapping flag.

  call define(cli)
  call cli%parse(args='--cfl 0.30', error=error)
  call cli%get(switch='--cfl', val=cfl, error=error)
  call assert_equal(error, ERROR_NOT_IN_CHOICES, '1: real')
  endsubroutine check_real_choice

  subroutine check_raise(mode)
  !< raise_error with a usage_on_error mode.
  character(*), intent(in)     :: mode  !< usage_on_error.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call define(cli, mode)
  call cli%parse(args='', error=error)
  error = cli%raise_error('must be even', switch='--xyz')
  endsubroutine check_raise
endprogram flap_test_messages

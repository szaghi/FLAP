!< The message of the CLI error, whichever object raised it (the CLI, a group or an argument).
program flap_test_error_message
!< The message of the CLI error, whichever object raised it (the CLI, a group or an argument).
!<
!< `cli%error_message` used to be set only by the errors raised by the CLI itself: after an unknown switch, a missing
!< required option or a failed `get` it was not allocated, the message staying on the group or on the argument.
use flap, only : command_line_interface, ERROR_CASTING_NUMBER, ERROR_MISSING_REQUIRED, ERROR_UNKNOWN, STATUS_PRINT_H
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
integer(I4P)                 :: lun   !< Capture unit of FLAP messages.
integer(I4P)                 :: error !< Error trapping flag.
character(:), allocatable    :: text  !< Captured messages.

call capture_open(lun)

! raised by the group, through a temporary argument: an unknown switch, with its hint
call define
call cli%parse(args='--nxx 4 --mesh m.grd', error=error)
call assert_equal(error, ERROR_UNKNOWN, 'unknown switch: the error')
call check_message('switch "--nxx" is unknown! Did you mean "--nx"?', 'unknown switch')
text = read_back(lun)
call assert_contains(text, cli%error_message, 'unknown switch: the message is the one printed')

! raised by an argument, while the group checks the required ones
call define
call cli%parse(args='--nx 4', error=error)
call assert_equal(error, ERROR_MISSING_REQUIRED, 'missing required: the error')
call check_message('"--mesh" is required', 'missing required')

! raised by the group: a mutually exclusive set
call define
call cli%parse(args='--mesh m.grd --left --right', error=error)
call assert(error /= 0, 'exclusive set: an error')
call check_message('mutually exclusive', 'exclusive set')

! raised by an argument in get: a value that is not a number, a value out of its choices
call define
call cli%parse(args='--mesh m.grd --nx many', error=error)
call assert_equal(error, 0_I4P, 'cast: parse is fine')
call get_nx(expected=ERROR_CASTING_NUMBER)
call check_message('cannot convert "many"', 'cast')
call define
call cli%parse(args='--mesh m.grd --scheme rk', error=error)
call get_scheme(fine=.false.)
call check_message('must be chosen in', 'choices')

! a get without error forgets the message of the previous one
call define
call cli%parse(args='--mesh m.grd --nx many --scheme cn', error=error)
call get_nx(expected=ERROR_CASTING_NUMBER)
call get_scheme(fine=.true.)
call assert_equal(cli%error, 0_I4P, 'get after a failed get: no error')
call assert(.not.allocated(cli%error_message), 'get after a failed get: no message')

! a status is not an error: no message
call define
call cli%parse(args='--help', error=error)
call assert_equal(error, STATUS_PRINT_H, 'help: the status')
call assert(.not.allocated(cli%error_message), 'help: no message')

! raised by an argument at its definition
call define
call cli%add(switch='--bad', help='no default', required=.false., act='store', error=error)
call assert(error /= 0, 'definition: an error')
call check_message('has not a default value', 'definition')

call capture_close(lun)

contains
  subroutine define()
  !< Define the CLI anew, its messages captured.
  integer(I4P) :: e !< Error trapping flag.

  call cli%free
  call cli%init(progname='prog', standalone=.false., usage_lun=lun, error_lun=lun)
  call cli%add(switch='--mesh', help='mesh', required=.true., act='store', error=e)
  call cli%add(switch='--nx', help='cells', required=.false., act='store', def='2', error=e)
  call cli%add(switch='--scheme', help='scheme', required=.false., act='store', def='fe', choices='fe,cn', error=e)
  call cli%add(switch='--left', help='left', required=.false., act='store_true', def='.false.', error=e)
  call cli%add(switch='--right', help='right', required=.false., act='store_true', def='.false.', error=e)
  call cli%set_mutually_exclusive_switches(switches='--left,--right', error=e)
  call assert_equal(e, 0_I4P, 'define: no error')
  text = read_back(lun) ! empties the capture
  endsubroutine define

  subroutine check_message(expected, what)
  !< Check that the CLI has the message of its error.
  character(*), intent(in) :: expected !< Part of the message expected.
  character(*), intent(in) :: what     !< Description of the case.

  call assert(cli%error /= 0, what//': the CLI error is set')
  call assert(allocated(cli%error_message), what//': the CLI has a message')
  if (allocated(cli%error_message)) then
    call assert_contains(cli%error_message, expected, what//': the message')
    call assert_contains(cli%error_message, 'prog: error: ', what//': the prefix')
  endif
  endsubroutine check_message

  subroutine get_nx(expected)
  !< Get --nx into an integer.
  integer(I4P), intent(in) :: expected !< Error expected.
  integer(I4P)             :: nx       !< Value.
  integer(I4P)             :: e        !< Error trapping flag.

  call cli%get(switch='--nx', val=nx, error=e)
  call assert_equal(e, expected, 'get --nx: the error')
  endsubroutine get_nx

  subroutine get_scheme(fine)
  !< Get --scheme into a string.
  logical, intent(in) :: fine   !< No error expected.
  character(8)        :: scheme !< Value.
  integer(I4P)        :: e      !< Error trapping flag.

  call cli%get(switch='--scheme', val=scheme, error=e)
  call assert_equal(e == 0, fine, 'get --scheme: the error')
  endsubroutine get_scheme
endprogram flap_test_error_message

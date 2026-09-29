!< Getting a value into a variable of an unsupported type is an error, never a silent no-op (issue #125, B07).
program flap_test_unsupported_type
!< Getting a value into a variable of an unsupported type is an error, never a silent no-op (issue #125, B07).
!<
!< Every scenario uses a fresh CLI: after a failed get, later gets on the same CLI return the old error (B22).
use flap, only : command_line_interface, ERROR_UNSUPPORTED_TYPE
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P, R4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
complex(R4P)                 :: z     !< Unsupported scalar.
complex(R4P)                 :: zl(2) !< Unsupported list.
integer(I4P)                 :: i     !< Integer, unsupported for a flag.
integer(I4P)                 :: il(2) !< Integers, unsupported for a list of flags.
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.

call capture_open(lun)

call define(cli)
z = (-9._R4P, -9._R4P)
call cli%get(switch='--x', val=z, error=error)
call assert_equal(error, ERROR_UNSUPPORTED_TYPE, 'complex scalar: error')
call assert(z == (-9._R4P, -9._R4P), 'complex scalar: variable untouched')
call assert_contains(read_back(lun), '"--x"', 'complex scalar: message names the switch')

call define(cli)
call cli%get(switch='--c', val=z, error=error)
call assert_equal(error, ERROR_UNSUPPORTED_TYPE, 'complex scalar with choices: error (not "not in choices")')

call define(cli)
call cli%get(switch='--l', val=zl, error=error)
call assert_equal(error, ERROR_UNSUPPORTED_TYPE, 'complex list: error')

call define(cli)
call cli%get(switch='--f', val=i, error=error)
call assert_equal(error, ERROR_UNSUPPORTED_TYPE, 'integer for a passed flag: error')

call define(cli)
call cli%get(switch='--g', val=i, error=error)
call assert_equal(error, ERROR_UNSUPPORTED_TYPE, 'integer for a flag left to its default: error')

call define(cli)
call cli%get(switch='--fl', val=il, error=error)
call assert_equal(error, ERROR_UNSUPPORTED_TYPE, 'integers for a list of flags: error')

call capture_close(lun)

contains
  subroutine define(cli)
  !< Define and parse a CLI with a value, a value with choices, a list, flags and a list of flags.
  type(command_line_interface), intent(out) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                              :: error !< Error trapping flag.

  call cli%init(progname='flap_test_unsupported_type', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--x', help='a value', required=.false., act='store', def='1', error=error)
  call assert_equal(error, 0_I4P, 'add --x')
  call cli%add(switch='--c', help='a value with choices', required=.false., act='store', def='1', choices='1,2', error=error)
  call assert_equal(error, 0_I4P, 'add --c')
  call cli%add(switch='--l', help='a list', required=.false., act='store', nargs='2', def='1 2', error=error)
  call assert_equal(error, 0_I4P, 'add --l')
  call cli%add(switch='--f', help='a flag', required=.false., act='store_true', def='.false.', error=error)
  call assert_equal(error, 0_I4P, 'add --f')
  call cli%add(switch='--g', help='another flag', required=.false., act='store_false', def='.true.', error=error)
  call assert_equal(error, 0_I4P, 'add --g')
  call cli%add(switch='--fl', help='a list of flags', required=.false., act='store_true', nargs='2', def='F F', error=error)
  call assert_equal(error, 0_I4P, 'add --fl')
  call cli%parse(args='--x 5 --f', error=error)
  call assert_equal(error, 0_I4P, 'parse')
  endsubroutine define
endprogram flap_test_unsupported_type

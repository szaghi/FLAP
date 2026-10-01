!< A value that is not a number is reported by FLAP, with a named error, on its error unit (issue #126, B40).
program flap_test_casting
!< A value that is not a number is reported by FLAP, with a named error, on its error unit (issue #126, B40).
!<
!< `get` of a value that is not a number into an integer or a real returned the I/O status of the read as its error and
!< left the message to PENF's `cton`, written on standard error without the program name: it is `ERROR_CASTING_NUMBER`,
!< with a message in FLAP's style on the error unit of the CLI, for every getter (scalar, fixed-size array, varying,
!< map value, positional).
use flap, only : command_line_interface, ERROR_CASTING_NUMBER
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, read_back, &
                            reinvoke
use penf, only : I4P, I8P, R4P, R8P

implicit none
integer(I4P)              :: lun      !< Capture unit.
character(:), allocatable :: out      !< Output of a child.
character(:), allocatable :: err      !< Errors of a child.
integer(I4P)              :: exitstat !< Exit status of a child.

if (child_case() == 1) then
  call child
  stop
endif
call capture_open(lun)

! scalar getters
call check_integer('--nx many', ERROR_CASTING_NUMBER, 0_I4P, 'integer, not a number')
call assert_contains(read_back(lun), 'flap_test_casting: error: cannot convert "many" of option "--nx" to an integer!', &
                     'integer: message')
call check_integer('--nx 42', 0_I4P, 42_I4P, 'integer, a number')
call check_integer('--nx=', ERROR_CASTING_NUMBER, 0_I4P, 'integer, an empty value')
out = read_back(lun)
call check_real('--cfl abc', ERROR_CASTING_NUMBER, 'real, not a number')
call assert_contains(read_back(lun), 'cannot convert "abc" of option "--cfl" to a real!', 'real: message')
call check_real('--cfl -3.5', 0_I4P, 'real, a negative number')
! lists, a map, a positional
call check_lists('--ijk 1 x 3', ERROR_CASTING_NUMBER, 'fixed-size integer list')
call assert_contains(read_back(lun), 'cannot convert "x" of option "--ijk" to an integer!', 'list: message')
call check_lists('--ijk 1 2 3 --w 0.5 y', ERROR_CASTING_NUMBER, 'varying real list')
call assert_contains(read_back(lun), 'cannot convert "y" of option "--w" to a real!', 'varying list: message')
call check_map('--set nx=lots', ERROR_CASTING_NUMBER, 'map value')
call assert_contains(read_back(lun), '"lots"', 'map value: message')
call check_positional('x1', ERROR_CASTING_NUMBER, 'positional')
call assert_contains(read_back(lun), 'cannot convert "x1" of positional argument 1 to a real!', 'positional: message')

! nothing on standard error but FLAP's own message (PENF's one was written there)
call reinvoke(1_I4P, exitstat, out, err, args='--nx many')
call assert_contains(err, 'cannot convert "many" of option "--nx" to an integer!', 'child: FLAP message on stderr')
call assert(index(err, 'Error: conversion') == 0, 'child: no PENF message')
call capture_close(lun)

contains
  subroutine child
  !< The default error unit (standard error).
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: nx    !< Value.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='flap_test_casting')
  call cli%add(switch='--nx', help='nx', required=.false., act='store', def='1', error=error)
  call cli%get(switch='--nx', val=nx, error=error)
  endsubroutine child

  subroutine check_integer(args, expected, expected_value, message)
  !< Integer option.
  character(*), intent(in)     :: args           !< Command line.
  integer(I4P), intent(in)     :: expected       !< Expected error.
  integer(I4P), intent(in)     :: expected_value !< Expected value, when valid.
  character(*), intent(in)     :: message        !< Description of the check.
  type(command_line_interface) :: cli            !< Command Line Interface (CLI).
  integer(I4P)                 :: nx             !< Value.
  integer(I8P)                 :: nx8            !< Value, another kind.
  integer(I4P)                 :: error          !< Error trapping flag.

  call define(cli)
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, message//': parse')
  call cli%get(switch='--nx', val=nx, error=error)
  call assert_equal(error, expected, message)
  if (expected == 0_I4P) call assert_equal(nx, expected_value, message//': value')
  call cli%get(switch='--nx', val=nx8, error=error)
  call assert_equal(error, expected, message//', I8P')
  endsubroutine check_integer

  subroutine check_real(args, expected, message)
  !< Real option.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  real(R8P)                    :: cfl      !< Value.
  real(R4P)                    :: cfl4     !< Value, another kind.
  integer(I4P)                 :: error    !< Error trapping flag.

  call define(cli)
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, message//': parse')
  call cli%get(switch='--cfl', val=cfl, error=error)
  call assert_equal(error, expected, message)
  if (expected == 0_I4P) call assert(abs(cfl + 3.5_R8P) < 1e-12_R8P, message//': value')
  call cli%get(switch='--cfl', val=cfl4, error=error)
  call assert_equal(error, expected, message//', R4P')
  endsubroutine check_real

  subroutine check_lists(args, expected, message)
  !< A fixed-size integer list (--ijk) and a varying real one (--w): the first failure is returned.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  integer(I4P)                 :: ijk(3)   !< Fixed-size values.
  real(R8P), allocatable       :: w(:)     !< Varying values.
  integer(I4P)                 :: error    !< Error trapping flag.

  call define(cli)
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, message//': parse')
  call cli%get(switch='--ijk', val=ijk, error=error)
  if (error == 0_I4P) call cli%get_varying(switch='--w', val=w, error=error)
  call assert_equal(error, expected, message)
  endsubroutine check_lists

  subroutine check_map(args, expected, message)
  !< A map value converted to an integer.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  integer(I4P)                 :: nx       !< Value.
  integer(I4P)                 :: error    !< Error trapping flag.

  call define(cli)
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, message//': parse')
  call cli%get_map_value(switch='--set', key='nx', val=nx, error=error)
  call assert_equal(error, expected, message)
  endsubroutine check_map

  subroutine check_positional(args, expected, message)
  !< A positional converted to a real.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  real(R8P)                    :: scale    !< Value.
  integer(I4P)                 :: error    !< Error trapping flag.

  call cli%init(progname='flap_test_casting', error_lun=lun, usage_lun=lun)
  call cli%add(positional=.true., position=1, help='scale', required=.true., act='store', error=error)
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, message//': parse')
  call cli%get(position=1, val=scale, error=error)
  call assert_equal(error, expected, message)
  endsubroutine check_positional

  subroutine define(cli)
  !< A CLI with numeric options.
  type(command_line_interface), intent(inout) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                                :: error !< Error trapping flag.

  call cli%init(progname='flap_test_casting', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--nx', help='nx', required=.false., act='store', def='1', error=error)
  call cli%add(switch='--cfl', help='cfl', required=.false., act='store', def='0.5', error=error)
  call cli%add(switch='--ijk', help='ijk', required=.false., act='store', nargs='3', def='1 1 1', error=error)
  call cli%add(switch='--w', help='w', required=.false., act='store', nargs='+', def='1.0', error=error)
  call cli%add(switch='--set', help='set', required=.false., act='store', nargs='+', map=.true., def='nx=1', error=error)
  call assert_equal(error, 0_I4P, 'define')
  endsubroutine define
endprogram flap_test_casting

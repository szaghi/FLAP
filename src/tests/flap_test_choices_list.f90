!< Choices are enforced on every value of a list, by both get and get_varying (issue #125, B08).
program flap_test_choices_list
!< Choices are enforced on every value of a list, by both get and get_varying (issue #125, B08).
!<
!< Every scenario uses a fresh CLI, so the scenarios are independent.
use flap, only : command_line_interface, ERROR_NOT_IN_CHOICES
use flap_test_utils, only : assert_equal, capture_close, capture_open
use penf, only : I4P, R8P

implicit none
integer(I4P) :: lun !< Capture unit.

call capture_open(lun)

call check_integer('--v 1 3', .true.,  0_I4P,                'varying integer, all in choices')
call check_integer('--v 1 2', .true.,  ERROR_NOT_IN_CHOICES, 'varying integer, 2 not in choices')
call check_integer('--v 1 2', .false., ERROR_NOT_IN_CHOICES, 'fixed integer, 2 not in choices')
call check_integer('',        .true.,  ERROR_NOT_IN_CHOICES, 'varying integer, default 5 not in choices')
call check_real('--r 2.0 1.0', 0_I4P,                        'varying real, all in choices')
call check_real('--r 2.0 3.0', ERROR_NOT_IN_CHOICES,         'varying real, 3.0 not in choices')
call check_character('--c a b', 0_I4P,                       'varying character, all in choices')
call check_character('--c a z', ERROR_NOT_IN_CHOICES,        'varying character, z not in choices')

call capture_close(lun)

contains
  subroutine check_integer(args, varying, expected, message)
  !< Integer list with choices 1,3 (default 1 5).
  character(*), intent(in)     :: args     !< Command line.
  logical,      intent(in)     :: varying  !< Use get_varying (otherwise get into a fixed-size array).
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  integer(I4P)                 :: fixed(2) !< Fixed-size values.
  integer(I4P), allocatable    :: vals(:)  !< Varying-size values.
  integer(I4P)                 :: error    !< Error trapping flag.

  call cli%init(progname='flap_test_choices_list', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--v', help='integers', required=.false., act='store', nargs='+', def='1 5', choices='1,3', error=error)
  call assert_equal(error, 0_I4P, message//': add')
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, message//': parse')
  if (varying) then
    call cli%get_varying(switch='--v', val=vals, error=error)
  else
    call cli%get(switch='--v', val=fixed, error=error)
  endif
  call assert_equal(error, expected, message)
  endsubroutine check_integer

  subroutine check_real(args, expected, message)
  !< Real list with choices 1.,2.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  real(R8P), allocatable       :: vals(:)  !< Values.
  integer(I4P)                 :: error    !< Error trapping flag.

  call cli%init(progname='flap_test_choices_list', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--r', help='reals', required=.false., act='store', nargs='*', def='1.0', choices='1.,2.', error=error)
  call assert_equal(error, 0_I4P, message//': add')
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, message//': parse')
  call cli%get_varying(switch='--r', val=vals, error=error)
  call assert_equal(error, expected, message)
  endsubroutine check_real

  subroutine check_character(args, expected, message)
  !< Character list with choices a,b.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  character(10), allocatable   :: vals(:)  !< Values.
  integer(I4P)                 :: error    !< Error trapping flag.

  call cli%init(progname='flap_test_choices_list', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--c', help='letters', required=.false., act='store', nargs='*', def='a', choices='a,b', error=error)
  call assert_equal(error, 0_I4P, message//': add')
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, message//': parse')
  call cli%get_varying(switch='--c', val=vals, error=error)
  call assert_equal(error, expected, message)
  endsubroutine check_character
endprogram flap_test_choices_list

!< Choices are checked on the whole value, not on the value truncated to the caller's variable (issue #126, B38).
program flap_test_choices_length
!< Choices are checked on the whole value, not on the value truncated to the caller's variable (issue #126, B38).
!<
!< A character variable shorter than the value receives it truncated: the choices must be checked before, on the value
!< as given, so that `--scheme fex` read into a `character(2)` is not accepted as `fe`, and the message names `fex`.
use flap, only : command_line_interface, ERROR_NOT_IN_CHOICES
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P

implicit none
integer(I4P)              :: lun !< Capture unit.
character(:), allocatable :: out !< Captured output.

call capture_open(lun)

! scalar get
call check_scalar('--scheme fex', .true., ERROR_NOT_IN_CHOICES, 'fe', 'scalar, longer value')
call assert_contains(read_back(lun), '"fex"', 'scalar, longer value: the message names the whole value')
call check_scalar('--scheme euler', .true., ERROR_NOT_IN_CHOICES, 'fe', 'scalar, much longer value')
call assert_contains(read_back(lun), '"euler"', 'scalar, much longer value: the message names the whole value')
call check_scalar('--scheme cn', .true., 0_I4P, 'cn', 'scalar, valid value')
call check_scalar('', .true., 0_I4P, 'fe', 'scalar, default')
call check_scalar('--scheme CN', .false., 0_I4P, 'cn', 'scalar, any case: the declared spelling')
call check_scalar('--scheme CNX', .false., ERROR_NOT_IN_CHOICES, 'fe', 'scalar, any case, longer value')
out = read_back(lun)

! a fixed-size array and a varying list
call check_fixed('--schemes fe fex', ERROR_NOT_IN_CHOICES, 'fixed array, a longer value')
call assert_contains(read_back(lun), '"fex"', 'fixed array: the message names the whole value')
call check_fixed('--schemes cn fe', 0_I4P, 'fixed array, valid values')
call check_varying('--schemes fe cnx', ERROR_NOT_IN_CHOICES, 'varying, a longer value')
call assert_contains(read_back(lun), '"cnx"', 'varying: the message names the whole value')
call check_varying('--schemes cn fe', 0_I4P, 'varying, valid values')

call capture_close(lun)

contains
  subroutine check_scalar(args, sensitive, expected, expected_value, message)
  !< Scalar option with choices fe,cn (default fe) read into a character(2).
  character(*), intent(in)     :: args           !< Command line.
  logical,      intent(in)     :: sensitive      !< Case-sensitive choices.
  integer(I4P), intent(in)     :: expected       !< Expected error.
  character(*), intent(in)     :: expected_value !< Expected value, when valid.
  character(*), intent(in)     :: message        !< Description of the check.
  type(command_line_interface) :: cli            !< Command Line Interface (CLI).
  character(2)                 :: scheme         !< Value.
  integer(I4P)                 :: error          !< Error trapping flag.

  call cli%init(progname='flap_test_choices_length', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--scheme', help='scheme', required=.false., act='store', def='fe', choices='fe,cn', &
               case_sensitive=sensitive, error=error)
  call assert_equal(error, 0_I4P, message//': add')
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, message//': parse')
  call cli%get(switch='--scheme', val=scheme, error=error)
  call assert_equal(error, expected, message)
  if (expected == 0_I4P) call assert(scheme == expected_value, message//': value "'//scheme//'"')
  endsubroutine check_scalar

  subroutine check_fixed(args, expected, message)
  !< List option (nargs=2) with choices fe,cn read into a character(2) array of 2 elements.
  character(*), intent(in)     :: args      !< Command line.
  integer(I4P), intent(in)     :: expected  !< Expected error.
  character(*), intent(in)     :: message   !< Description of the check.
  type(command_line_interface) :: cli       !< Command Line Interface (CLI).
  character(2)                 :: schemes(2) !< Values.
  integer(I4P)                 :: error     !< Error trapping flag.

  call cli%init(progname='flap_test_choices_length', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--schemes', help='schemes', required=.false., act='store', nargs='2', def='fe fe', &
               choices='fe,cn', error=error)
  call assert_equal(error, 0_I4P, message//': add')
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, message//': parse')
  call cli%get(switch='--schemes', val=schemes, error=error)
  call assert_equal(error, expected, message)
  endsubroutine check_fixed

  subroutine check_varying(args, expected, message)
  !< List option (nargs=+) with choices fe,cn read into an allocatable character(2) array.
  character(*), intent(in)     :: args       !< Command line.
  integer(I4P), intent(in)     :: expected   !< Expected error.
  character(*), intent(in)     :: message    !< Description of the check.
  type(command_line_interface) :: cli        !< Command Line Interface (CLI).
  character(2), allocatable    :: schemes(:) !< Values.
  integer(I4P)                 :: error      !< Error trapping flag.

  call cli%init(progname='flap_test_choices_length', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--schemes', help='schemes', required=.false., act='store', nargs='+', def='fe', &
               choices='fe,cn', error=error)
  call assert_equal(error, 0_I4P, message//': add')
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, message//': parse')
  call cli%get_varying(switch='--schemes', val=schemes, error=error)
  call assert_equal(error, expected, message)
  endsubroutine check_varying
endprogram flap_test_choices_length

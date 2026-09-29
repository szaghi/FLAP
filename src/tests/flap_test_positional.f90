!< Positional arguments (issue #125, B06): matched by their declared position, wherever they are on the command line.
program flap_test_positional
!< Positional arguments (issue #125, B06): matched by their declared position, wherever they are on the command line.
!<
!< The CLI declares the positionals out of order (position 2 first) and mixes them with a named option. Every scenario uses a
!< fresh CLI, so the scenarios are independent.
use flap, only : command_line_interface, ERROR_MISSING_CLA, ERROR_NO_LIST, ERROR_POSITION_DUPLICATE, ERROR_POSITION_GAP, &
                 ERROR_POSITIONAL_NARGS, ERROR_UNKNOWN, ERROR_UNKNOWN_CLAS_IGNORED
use flap_test_utils, only : assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI).
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: error    !< Error trapping flag.
integer(I4P)                 :: ilist(2) !< List value.
integer(I4P), allocatable    :: vlist(:) !< Varying list value.

call capture_open(lun)

call check('a b',        'a', 'b',  'd')
call check('-o z a b',   'a', 'b',  'z')
call check('a -o z b',   'a', 'b',  'z')
call check('a b -o z',   'a', 'b',  'z')
call check('a',          'a', 'D2', 'd')
call check('-3.5 -',     '-3.5', '-', 'd')

call define(cli)
call cli%parse(args='a b c', error=error)
call assert_equal(error, ERROR_UNKNOWN, 'a b c: excess argument is unknown')
call assert_contains(read_back(lun), '"c"', 'a b c: message names the excess argument')

call define(cli, ignore_unknown_clas=.true.)
call cli%parse(args='a b c', error=error)
call assert_equal(error, ERROR_UNKNOWN_CLAS_IGNORED, 'a b c with ignore_unknown_clas: parse')
call get_positional(cli, 2_I4P, 'b', 'a b c with ignore_unknown_clas: position 2')

call define(cli)
call cli%parse(args='--bogus a', error=error)
call assert_equal(error, ERROR_UNKNOWN, '--bogus a: an unknown switch is not a positional value')

call define(cli)
call cli%parse(args='a', error=error)
call assert_equal(cli%is_passed(position=1_I4P), .true., 'a: position 1 passed')
call assert_equal(cli%is_passed(position=2_I4P), .false., 'a: position 2 not passed')

call define(cli)
call cli%parse(args='a b', error=error)
call get_positional(cli, 3_I4P, '', 'position 3 is not defined', expected_error=ERROR_MISSING_CLA)

call define(cli)
call cli%parse(args='1 2', error=error)
call cli%get(position=1_I4P, val=ilist, error=error)
call assert_equal(error, ERROR_NO_LIST, 'list get of a scalar positional: error of the CLA is returned (B23)')

call define(cli)
call cli%parse(args='1 2', error=error)
call cli%get_varying(position=1_I4P, val=vlist, error=error)
call assert_equal(error, ERROR_NO_LIST, 'varying get of a scalar positional: error of the CLA is returned (B23)')

call cli%init(progname='flap_test_positional', error_lun=lun, usage_lun=lun)
call cli%add(positional=.true., position=1, help='a list', required=.false., nargs='+', def='1', error=error)
call assert_equal(error, ERROR_POSITIONAL_NARGS, 'nargs on a positional: definition error')

! B29 (#125, D20): positions are 1..N without duplicates
call cli%init(progname='flap_test_positional', error_lun=lun, usage_lun=lun)
call cli%add(positional=.true., position=1, help='first', required=.false., def='D1', error=error)
call cli%add(positional=.true., position=1, help='again', required=.false., def='D1', error=error)
call assert_equal(error, ERROR_POSITION_DUPLICATE, 'position declared twice: definition error')
call assert_contains(read_back(lun), 'position 1', 'position declared twice: message names the position')

call cli%init(progname='flap_test_positional', error_lun=lun, usage_lun=lun)
call cli%add(positional=.true., position=1, help='first', required=.false., def='D1', error=error)
call cli%add(positional=.true., position=3, help='third', required=.false., def='D3', error=error)
call assert_equal(error, 0_I4P, 'positions 1 and 3: accepted while defining (2 may follow)')
call cli%parse(args='a', error=error)
call assert_equal(error, ERROR_POSITION_GAP, 'positions 1 and 3: gap when parsing')
call assert_contains(read_back(lun), 'position 2', 'positions 1 and 3: message names the missing position')

call cli%init(progname='flap_test_positional', error_lun=lun, usage_lun=lun)
call cli%add_group(group='cmd', description='a command')
call cli%add(group='cmd', positional=.true., position=2, help='second', required=.false., def='D2', error=error)
call cli%parse(args='', error=error)
call assert_equal(error, ERROR_POSITION_GAP, 'gap in a command not called: still a definition error')

call capture_close(lun)

contains
  subroutine define(cli, ignore_unknown_clas)
  !< Define a CLI with a named option and two positionals declared out of order.
  type(command_line_interface), intent(out)          :: cli                 !< Command Line Interface (CLI).
  logical,                      intent(in), optional :: ignore_unknown_clas !< Ignore unknown arguments.
  integer(I4P)                                       :: error               !< Error trapping flag.

  call cli%init(progname='flap_test_positional', error_lun=lun, usage_lun=lun, ignore_unknown_clas=ignore_unknown_clas)
  call cli%add(switch='--opt', switch_ab='-o', help='an option', required=.false., act='store', def='d', error=error)
  call assert_equal(error, 0_I4P, 'add --opt')
  call cli%add(positional=.true., position=2, help='second', required=.false., def='D2', error=error)
  call assert_equal(error, 0_I4P, 'add position 2')
  call cli%add(positional=.true., position=1, help='first', required=.false., def='D1', error=error)
  call assert_equal(error, 0_I4P, 'add position 1')
  endsubroutine define

  subroutine check(args, p1, p2, opt)
  !< Parse a command line and check both positionals and the option.
  character(*), intent(in)     :: args  !< Command line.
  character(*), intent(in)     :: p1    !< Expected position 1.
  character(*), intent(in)     :: p2    !< Expected position 2.
  character(*), intent(in)     :: opt   !< Expected --opt.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  character(99)                :: val   !< Value.
  integer(I4P)                 :: error !< Error trapping flag.

  call define(cli)
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, args//': parse')
  call get_positional(cli, 1_I4P, p1, args//': position 1')
  call get_positional(cli, 2_I4P, p2, args//': position 2')
  call cli%get(switch='-o', val=val, error=error)
  call assert_equal(error, 0_I4P, args//': get --opt')
  call assert_equal(val, opt, args//': --opt')
  endsubroutine check

  subroutine get_positional(cli, position, expected, message, expected_error)
  !< Get a positional and check its value (or the expected error).
  type(command_line_interface), intent(inout)        :: cli            !< Command Line Interface (CLI).
  integer(I4P),                 intent(in)           :: position       !< Position.
  character(*),                 intent(in)           :: expected       !< Expected value.
  character(*),                 intent(in)           :: message        !< Description of the check.
  integer(I4P),                 intent(in), optional :: expected_error !< Expected error (default 0).
  character(99)                                      :: val            !< Value.
  integer(I4P)                                       :: error          !< Error trapping flag.
  integer(I4P)                                       :: err_expected   !< Expected error.

  err_expected = 0 ; if (present(expected_error)) err_expected = expected_error
  val = ''
  call cli%get(position=position, val=val, error=error)
  call assert_equal(error, err_expected, message//': error')
  if (err_expected == 0) call assert_equal(val, expected, message)
  endsubroutine get_positional
endprogram flap_test_positional

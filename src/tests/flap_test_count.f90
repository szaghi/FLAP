!< The count action: a repeatable flag counting its occurrences, also as -vvv (issue #125, step 1.6; #1 B.1-B.3, D1 rule 3).
program flap_test_count
!< The count action: a repeatable flag counting its occurrences, also as -vvv (issue #125, step 1.6; #1 B.1-B.3, D1 rule 3).
!<
!< Every scenario uses a fresh CLI (tests B-T1...B-T7 of #1).
use flap, only : command_line_interface, ERROR_COUNT_INCONSISTENT, ERROR_INLINE_VALUE_NOT_ALLOWED, ERROR_UNKNOWN, &
                 ERROR_VALUE_MISSING
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open
use penf, only : I1P, I4P, I8P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.
integer(I1P)                 :: v1    !< Count, 1-byte integer.
integer(I8P)                 :: v8    !< Count, 8-byte integer.
logical                      :: vv    !< The -vv switch.

call capture_open(lun)

call check('',                0_I4P, 'no occurrence: 0')           ! B-T1
call check('-v',              1_I4P, '-v: 1')                      ! B-T2
call check('-v --verbose -v', 3_I4P, '-v --verbose -v: 3')         ! B-T3
call check('-vvv',            3_I4P, '-vvv: 3')                    ! B-T4
call check('-v -vv',          3_I4P, '-v -vv: 3')
call check('-vvv --out x',    3_I4P, '-vvv --out x: 3')
call check('',                5_I4P, 'default 5, not passed: 5', def='5')
call check('-v -v',           2_I4P, 'default 5, passed twice: 2 (the default is not a starting count)', def='5')

! B-T5: an exact switch wins over the compact form
call define('-vv', with_vv=.true.)
call cli%get(switch='-v', val=v1, error=error)
call assert_equal(int(v1, I4P), 0_I4P, 'a defined -vv switch: -vv is that switch, the count stays 0')
call cli%get(switch='-vv', val=vv, error=error)
call assert(vv, 'a defined -vv switch: it is passed')

! any integer kind
call define('-vvvv')
call cli%get(switch='-v', val=v8, error=error)
call assert_equal(int(v8, I4P), 4_I4P, '-vvvv into integer(I8P)')

! B-T6: no inline value
call define('-v=2', expected=ERROR_INLINE_VALUE_NOT_ALLOWED)
! the compact form is a switch for the look-ahead of the previous option
call define('--out -vvv', expected=ERROR_VALUE_MISSING)
! only a repeated count abbreviation is compact
call define('-vx', expected=ERROR_UNKNOWN)
call define('-ww', expected=ERROR_UNKNOWN)

! B-T7: a count takes no positional, nargs, envvar or choices
call bad_definition('positional')
call bad_definition('nargs')
call bad_definition('envvar')
call bad_definition('choices')

! usage: repeatable, docopt-style
call define('')
call assert_contains(cli%usage(g=0), '[--verbose]...', 'usage: [--verbose]...')

call capture_close(lun)

contains
  subroutine define(args, expected, def, with_vv)
  !< Define a CLI with a count and parse a command line, checking the error (default 0).
  character(*), intent(in)           :: args      !< Command line.
  integer(I4P), intent(in), optional :: expected  !< Expected error.
  character(*), intent(in), optional :: def       !< Default of the count.
  logical,      intent(in), optional :: with_vv   !< Also define a -vv switch.
  integer(I4P)                       :: expected_ !< Expected error, local variable.

  expected_ = 0 ; if (present(expected)) expected_ = expected
  call cli%init(progname='flap_test_count', error_lun=lun, usage_lun=lun, error_hint=.false.)
  if (present(def)) then
    call cli%add(switch='--verbose', switch_ab='-v', help='verbosity', required=.false., act='count', def=def, error=error)
  else
    call cli%add(switch='--verbose', switch_ab='-v', help='verbosity', required=.false., act='count', error=error)
  endif
  call assert_equal(error, 0_I4P, 'add the count')
  call cli%add(switch='--out', help='output', required=.false., act='store', def='o', error=error)
  if (present(with_vv)) then
    if (with_vv) call cli%add(switch='-vv', help='very verbose', required=.false., act='store_true', def='.false.', &
                              error=error)
  endif
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected_, 'parse "'//args//'": error')
  endsubroutine define

  subroutine check(args, expected, message, def)
  !< Parse and check the count.
  character(*), intent(in)           :: args     !< Command line.
  integer(I4P), intent(in)           :: expected !< Expected count.
  character(*), intent(in)           :: message  !< Description of the check.
  character(*), intent(in), optional :: def      !< Default of the count.
  integer(I4P)                       :: v        !< Count.

  call define(args, def=def)
  v = -1
  call cli%get(switch='--verbose', val=v, error=error)
  call assert_equal(error, 0_I4P, message//': get error')
  call assert_equal(v, expected, message)
  endsubroutine check

  subroutine bad_definition(what)
  !< Define a count with an invalid attribute.
  character(*), intent(in) :: what !< Invalid attribute.

  call cli%init(progname='flap_test_count', error_lun=lun, usage_lun=lun)
  select case(what)
  case('positional')
    call cli%add(positional=.true., position=1, help='count', required=.false., act='count', error=error)
  case('nargs')
    call cli%add(switch='-v', help='count', required=.false., act='count', nargs='2', error=error)
  case('envvar')
    call cli%add(switch='-v', help='count', required=.false., act='count', envvar='FLAP_V', error=error)
  case('choices')
    call cli%add(switch='-v', help='count', required=.false., act='count', choices='1,2', error=error)
  endselect
  call assert_equal(error, ERROR_COUNT_INCONSISTENT, 'count with '//what//': definition error')
  endsubroutine bad_definition
endprogram flap_test_count

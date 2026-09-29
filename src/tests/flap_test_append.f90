!< The append action: a repeatable option collecting one value per occurrence (issue #125, step 1.6; #1 B.4-B.5, D9).
program flap_test_append
!< The append action: a repeatable option collecting one value per occurrence (issue #125, step 1.6; #1 B.4-B.5, D9).
!<
!< Passed values replace the default, never merge with it (D9). Every scenario uses a fresh CLI (tests B-T8...B-T18 of #1).
use flap, only : command_line_interface, ERROR_APPEND_INCONSISTENT, ERROR_APPEND_SCALAR_GET, ERROR_LIST_SIZE, &
                 ERROR_VALUE_MISSING
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open
use penf, only : I4P

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI).
character(10), allocatable   :: o(:)     !< Collected words.
integer(I4P),  allocatable   :: n(:)     !< Collected integers.
integer(I4P)                 :: n3(3)    !< Fixed-size list.
integer(I4P)                 :: n2(2)    !< Fixed-size list.
character(10)                :: scalar   !< Scalar value.
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: error    !< Error trapping flag.

call capture_open(lun)

call check('',                  ['x'],             'default x, not passed', def='x')                  ! B-T8
call check('',                  ['x', 'y'],        'default "x y", not passed', def='x y')            ! B-T9
call check('-o this',           ['this'],          '-o this: the default is replaced', def='x y')     ! B-T10
call check('-o this -o that',   ['this', 'that'],  '-o this -o that')                               ! B-T11
call check('--out=a -o b',      ['a', 'b'],        '--out=a -o b: inline and separate')               ! B-T12
call check('-o a --out b -o c', ['a', 'b', 'c'],   'switch and abbreviation collect together')
call check('-o init',           ['init'],          'a value equal to a command name stays a value')

! B-T13: the next token is a switch, so the value is missing
call define('-o -x', expected=ERROR_VALUE_MISSING)
call define('-o', expected=ERROR_VALUE_MISSING)
! B-T14: a scalar get is an error
call define('-o a')
call cli%get(switch='-o', val=scalar, error=error)
call assert_equal(error, ERROR_APPEND_SCALAR_GET, 'scalar get: error')
! B-T15: integers
call define('-n 1 -n 2')
call cli%get_varying(switch='-n', val=n, error=error)
call assert_equal(error, 0_I4P, 'integers: get_varying error')
call assert(size(n) == 2, 'integers: two values')
call assert(all(n == [1, 2]), 'integers: [1, 2]')
! B-T16: a fixed-size get must match the number of values
call cli%get(switch='-n', val=n3, error=error)
call assert_equal(error, ERROR_LIST_SIZE, 'fixed-size get of 3 for 2 values: size error')
call cli%get(switch='-n', val=n2, error=error)
call assert_equal(error, 0_I4P, 'fixed-size get of 2: error')
call assert(all(n2 == [1, 2]), 'fixed-size get of 2: values')

! B-T18: an append takes no positional, nargs or envvar
call bad_definition('positional')
call bad_definition('nargs')
call bad_definition('envvar')

! usage: repeatable, docopt-style
call define('')
call assert_contains(cli%usage(g=0), '[--out value]...', 'usage: [--out value]...')

call capture_close(lun)

contains
  subroutine define(args, expected, def)
  !< Define a CLI with appends and parse a command line, checking the error (default 0).
  character(*), intent(in)           :: args      !< Command line.
  integer(I4P), intent(in), optional :: expected  !< Expected error.
  character(*), intent(in), optional :: def       !< Default of -o.
  integer(I4P)                       :: expected_ !< Expected error, local variable.

  expected_ = 0 ; if (present(expected)) expected_ = expected
  call cli%init(progname='flap_test_append', error_lun=lun, usage_lun=lun, error_hint=.false.)
  if (present(def)) then
    call cli%add(switch='--out', switch_ab='-o', help='outputs', required=.false., act='append', def=def, error=error)
  else
    call cli%add(switch='--out', switch_ab='-o', help='outputs', required=.false., act='append', def='none', error=error)
  endif
  call assert_equal(error, 0_I4P, 'add the append')
  call cli%add(switch='--num', switch_ab='-n', help='numbers', required=.false., act='append', def='0', error=error)
  call cli%add(switch='-x', help='a flag', required=.false., act='store_true', def='.false.', error=error)
  call cli%add_group(group='init', description='a command')
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected_, 'parse "'//args//'": error')
  endsubroutine define

  subroutine check(args, expected, message, def)
  !< Parse and check the collected words.
  character(*), intent(in)           :: args        !< Command line.
  character(*), intent(in)           :: expected(:) !< Expected words.
  character(*), intent(in)           :: message     !< Description of the check.
  character(*), intent(in), optional :: def         !< Default of -o.
  integer(I4P)                       :: i           !< Counter.

  call define(args, def=def)
  call cli%get_varying(switch='-o', val=o, error=error)
  call assert_equal(error, 0_I4P, message//': get error')
  call assert_equal(int(size(o), I4P), int(size(expected), I4P), message//': number of values')
  do i=1, size(expected)
    call assert_equal(o(i), expected(i), message//': value')
  enddo
  endsubroutine check

  subroutine bad_definition(what)
  !< Define an append with an invalid attribute.
  character(*), intent(in) :: what !< Invalid attribute.

  call cli%init(progname='flap_test_append', error_lun=lun, usage_lun=lun)
  select case(what)
  case('positional')
    call cli%add(positional=.true., position=1, help='append', required=.false., act='append', def='a', error=error)
  case('nargs')
    call cli%add(switch='-o', help='append', required=.false., act='append', nargs='2', def='a b', error=error)
  case('envvar')
    call cli%add(switch='-o', help='append', required=.false., act='append', def='a', envvar='FLAP_O', error=error)
  endselect
  call assert_equal(error, ERROR_APPEND_INCONSISTENT, 'append with '//what//': definition error')
  endsubroutine bad_definition
endprogram flap_test_append

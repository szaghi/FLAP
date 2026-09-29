!< Inline values --option=value (issue #125, step 1.5, D1 rule 2; #1 feature A, tests A-T1...A-T14).
program flap_test_inline
!< Inline values --option=value (issue #125, step 1.5, D1 rule 2; #1 feature A, tests A-T1...A-T14).
!<
!< A token NAME=VALUE is split at the first '=' only when NAME is a switch of the group. Every scenario uses a fresh CLI.
!< The child (scenario 1) parses --env=1 with FLAP_TEST_INLINE set, and prints the value.
use flap, only : command_line_interface, ERROR_DUPLICATED_CLAS, ERROR_INLINE_VALUE_NARGS, ERROR_INLINE_VALUE_NOT_ALLOWED, &
                 ERROR_UNKNOWN, ERROR_VALUE_MISSING
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, reinvoke
use penf, only : I4P

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI).
character(99)                :: val      !< Value.
character(:), allocatable    :: out      !< Output of the child.
character(:), allocatable    :: err      !< Standard error of the child.
integer(I4P)                 :: ival     !< Integer value.
integer(I4P), allocatable    :: vals(:)  !< List value.
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: exitstat !< Exit status of the child.
integer(I4P)                 :: error    !< Error trapping flag.

if (child_case() == 1) then
  call cli%init(progname='flap_test_inline')
  call cli%add(switch='--env', help='from env', required=.false., act='store', def='0', envvar='FLAP_TEST_INLINE', error=error)
  call cli%parse(args='--env=1', error=error)
  call cli%get(switch='--env', val=val, error=error)
  print '(A)', 'error='//trim(adjustl(str_i(error)))//' val=['//trim(val)//']'
  stop
endif

call capture_open(lun)

! A-T1, A-T2: switch and abbreviation
call define('--speed=15') ; call get_int('--speed', 15_I4P, '--speed=15')
call define('-s=15')      ; call get_int('-s', 15_I4P, '-s=15')
! A-T3: split at the first '=' only
call define('--out=a=b') ; call get_str('--out', 'a=b', '--out=a=b')
! A-T5, A-T6: quoted inline values
call define('--out="a b"')   ; call get_str('--out', 'a b', '--out="a b"')
call define('--out="don''t"') ; call get_str('--out', "don't", '--out="don''t"')
! the next argument is not consumed: here it is a positional
call define('--out=x pos') ; call get_str('--out', 'x', '--out=x pos')
call cli%get(position=1_I4P, val=val, error=error)
call assert_equal(val, 'pos', '--out=x pos: the next argument is the positional')
! A-T4, D17 (#125 step 2.11 accepts it): an empty inline value is rejected as "--out ''" is, for a required value
call define('--out=', expected=ERROR_VALUE_MISSING)
! ... and is the empty string for an optional value, as "--opt ''" is
call define('--opt=') ; call get_str('--opt', '', '--opt=')
! A-T7: a flag does not take a value
call define('--flag=yes', expected=ERROR_INLINE_VALUE_NOT_ALLOWED)
! A-T8: a list does not take an inline value
call define('--v=1', expected=ERROR_INLINE_VALUE_NARGS)
! A-T9: the look-ahead of a list stops at an inline switch
call define('--v 1 2 --speed=3')
call cli%get_varying(switch='--v', val=vals, error=error)
call assert_equal(error, 0_I4P, '--v 1 2 --speed=3: list error')
call assert(size(vals) == 2, '--v 1 2 --speed=3: two values')
call get_int('--speed', 3_I4P, '--v 1 2 --speed=3')
! A-T10: an unknown switch stays unknown
call define('--unknown=3', expected=ERROR_UNKNOWN)
! A-T11: a positional value is never split
call define('a=b') ; call cli%get(position=1_I4P, val=val, error=error)
call assert_equal(val, 'a=b', 'a=b: positional not split')
! A-T12: an inline value equal to a command name
call define('commit --msg=tag')
call cli%get(group='commit', switch='--msg', val=val, error=error)
call assert_equal(val, 'tag', 'commit --msg=tag: the value')
call assert(.not.cli%run_command(group='tag'), 'commit --msg=tag: tag not called')
! A-T14: inline and separate forms of the same switch are a duplicate
call define('--speed=1 --speed=2', expected=ERROR_DUPLICATED_CLAS)
call define('--speed=1 -s 2', expected=ERROR_DUPLICATED_CLAS)

call capture_close(lun)

! A-T13: the inline value wins over the environment
call reinvoke(1_I4P, exitstat, out, err, env='FLAP_TEST_INLINE=5')
call assert_contains(out, 'error=0 val=[1]', '--env=1 with the variable set: the inline value')

contains
  subroutine define(args, expected)
  !< Define the CLI and parse a command line, checking the error (default 0).
  character(*), intent(in)           :: args      !< Command line.
  integer(I4P), intent(in), optional :: expected  !< Expected error.
  integer(I4P)                       :: expected_ !< Expected error, local variable.

  expected_ = 0 ; if (present(expected)) expected_ = expected
  call cli%init(progname='flap_test_inline', error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--speed', switch_ab='-s', help='speed', required=.false., act='store', def='10', error=error)
  call cli%add(switch='--out', help='output', required=.false., act='store', def='out.dat', error=error)
  call cli%add(switch='--opt', help='optional value', required=.false., act='store', def='d', val_required=.false., &
               error=error)
  call cli%add(switch='--flag', help='a flag', required=.false., act='store_true', def='.false.', error=error)
  call cli%add(switch='--v', help='a list', required=.false., act='store', nargs='+', def='0', error=error)
  call cli%add(positional=.true., position=1, help='a positional', required=.false., def='none', error=error)
  call cli%add_group(group='commit', description='commit')
  call cli%add(group='commit', switch='--msg', help='message', required=.false., act='store', def='m', error=error)
  call cli%add_group(group='tag', description='tag')
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected_, 'parse "'//args//'": error')
  endsubroutine define

  subroutine get_int(switch, expected, message)
  !< Get an integer and check it.
  character(*), intent(in) :: switch   !< Switch.
  integer(I4P), intent(in) :: expected !< Expected value.
  character(*), intent(in) :: message  !< Description of the check.

  call cli%get(switch=switch, val=ival, error=error)
  call assert_equal(error, 0_I4P, message//': get error')
  call assert_equal(ival, expected, message//': value')
  endsubroutine get_int

  subroutine get_str(switch, expected, message)
  !< Get a string and check it.
  character(*), intent(in) :: switch   !< Switch.
  character(*), intent(in) :: expected !< Expected value.
  character(*), intent(in) :: message  !< Description of the check.

  val = 'unset'
  call cli%get(switch=switch, val=val, error=error)
  call assert_equal(error, 0_I4P, message//': get error')
  call assert_equal(val, expected, message//': value')
  endsubroutine get_str

  function str_i(i) result(s)
  !< Integer to string.
  integer(I4P), intent(in) :: i !< Integer.
  character(12)            :: s !< String.

  write(s, '(I0)') i
  endfunction str_i
endprogram flap_test_inline

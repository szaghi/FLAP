!< Key=value options: add(map=, map_keys=), get_map, get_map_value (issue #125, step 3.6; #77 1.1-1.5, T1.1-T1.18).
program flap_test_map
!< Key=value options: add(map=, map_keys=), get_map, get_map_value (issue #125, step 3.6; #77 1.1-1.5, T1.1-T1.18).
!<
!< A map option takes KEY=VALUE tokens (split at the first '='), stored as a list; parse validates them, whatever the source
!< (format, repeated keys, the map_keys whitelist); passed pairs replace the default ones. get_map returns the keys and
!< values, get_map_value one value converted to the variable's type. Every get has its own variable (nvfortran, B33).
use flap, only : command_line_interface, ERROR_MAP_DUPLICATE_KEY, ERROR_MAP_FORMAT, ERROR_MAP_INCONSISTENT, &
                 ERROR_MAP_KEY_MISSING, ERROR_MAP_UNKNOWN_KEY
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, delete_file, &
                            read_back, reinvoke, scratch_file, write_file
use penf, only : I4P, R8P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
character(:), allocatable    :: out   !< Captured output.
character(:), allocatable    :: ini   !< Configuration file.
character(99)                :: s     !< Character value (every get before its check).
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.
integer(I4P)                 :: i4    !< Integer value.
real(R8P)                    :: r8    !< Real value.
logical                      :: found !< The key is in the map.
integer(I4P)                 :: exitstat !< Exit status of the child.
character(:), allocatable    :: err   !< Standard error of the child.

ini = scratch_file('ini')
if (child_case() == 1) then
  ! the environment variable of --set, a CSV record of pairs
  call capture_open(lun)
  call define
  call cli%parse(error=error)
  print '(A)', 'pairs=['//pairs_of('--set', error)//']'
  call capture_close(lun)
  stop
endif
call capture_open(lun)
! T1.1-T1.3: pairs, a value containing '=', an empty value
call run('--set a=1 b=2')
call assert_equal(pairs_of('--set', error), 'a=1 b=2', 'T1.1 pairs')
call assert_equal(error, 0_I4P, 'T1.1 no error')
call run('--set label=a=b')
call assert_equal(pairs_of('--set', error), 'label=a=b', 'T1.2 split at the first =')
s = text_of('label', found, error)
call assert(trim(s) == 'a=b' .and. found .and. error == 0, 'T1.2 value a=b')
call run('--set a=')
call assert_equal(pairs_of('--set', error), 'a=', 'T1.3 empty value')
s = text_of('a', found, error)
call assert(len_trim(s) == 0 .and. found .and. error == 0, 'T1.3 value empty')
! T1.4-T1.6: format and repeated keys, reported by parse
call parse_error('--set =1', ERROR_MAP_FORMAT, 'T1.4 empty key')
call parse_error('--set a', ERROR_MAP_FORMAT, 'T1.5 no =')
call assert_contains(out, '"--set" expects KEY=VALUE, got "a"', 'T1.5 message')
call parse_error('--set a=1 a=2', ERROR_MAP_DUPLICATE_KEY, 'T1.6 repeated key')
call assert_contains(out, 'key "a" of "--set" given twice', 'T1.6 message')
! T1.7: the whitelist, with a suggestion
call parse_error('--keys gamma=1', ERROR_MAP_UNKNOWN_KEY, 'T1.7 unknown key')
call assert_contains(out, 'unknown key "gamma" for "--keys" (allowed: alpha, beta)', 'T1.7 message')
call parse_error('--keys alpah=1', ERROR_MAP_UNKNOWN_KEY, 'T1.7 unknown key, close')
call assert_contains(out, 'Did you mean "alpha"?', 'T1.7 suggestion')
call run('--keys beta=2')
call assert_equal(pairs_of('--keys', error), 'beta=2', 'T1.7 an allowed key')
! T1.8, T1.9: default pairs, replaced (not merged) by the passed ones
call run('')
call assert_equal(pairs_of('--def', error), 'a=1 b=2', 'T1.8 default pairs')
call run('--def b=5')
call assert_equal(pairs_of('--def', error), 'b=5', 'T1.9 passed pairs replace the default')
! T1.10, T1.11: typed lookup
call run('--set cfl=0.5 nx=256')
r8 = real_of('cfl', found, error)
call assert(abs(r8 - 0.5_R8P) < 1e-12_R8P .and. found .and. error == 0, 'T1.10 real value')
i4 = int_of('nx', found, error)
call assert(i4 == 256 .and. found .and. error == 0, 'T1.10 integer value')
call run('--set nx=abc')
i4 = int_of('nx', found, error)
call assert(error /= 0, 'T1.11 conversion error')
out = read_back(lun)
call assert_contains(out, 'value "abc" of key "nx" of "--set"', 'T1.11 message names the key')
! T1.12, T1.13: a missing key
call run('--set a=1')
i4 = int_of('nx', found, error, initial=-7_I4P)
call assert(i4 == -7 .and. .not.found .and. error == 0, 'T1.12 missing key with found: untouched')
i4 = int_nofound('nx', error)
call assert_equal(error, ERROR_MAP_KEY_MISSING, 'T1.13 missing key without found')
! T1.14: the look-ahead stops at the next option
call run('--set a=1 b=2 --x 3')
call assert_equal(pairs_of('--set', error), 'a=1 b=2', 'T1.14 pairs')
s = x_of(error)
call assert(trim(s) == '3' .and. error == 0, 'T1.14 --x')
! T1.17: inline
call run('--set=a=1')
call assert_equal(pairs_of('--set', error), 'a=1', 'T1.17 inline pair')
! T1.18: append
call run('--app a=1 --app b=2')
call assert_equal(pairs_of('--app', error), 'a=1 b=2', 'T1.18 append pairs')
call parse_error('--app a=1 --app a=2', ERROR_MAP_DUPLICATE_KEY, 'T1.18 append, repeated key')
! configuration file (blank separated pairs), below the command line
call write_file(ini, 'set = u=1 v=2'//new_line('a'))
call run('', config=.true.)
call assert_equal(pairs_of('--set', error), 'u=1 v=2', 'configuration pairs')
call write_file(ini, 'set = u'//new_line('a'))
call parse_error('', ERROR_MAP_FORMAT, 'configuration pair without =', config=.true.)
call delete_file(ini)
! get_map on an option that is not a map
call run('')
call assert_equal(pairs_of('--x', error), '', 'get_map of a non-map')
call assert_equal(error, ERROR_MAP_INCONSISTENT, 'get_map of a non-map: error')
! usage
call define
out = cli%usage(g=0)
call assert_contains(out, ' [--keys KEY=VALUE [KEY=VALUE...]]', 'usage of a map, nargs=+')
call assert_contains(out, ' [--set [KEY=VALUE...]]', 'usage of a map, nargs=*')
call assert_contains(out, ' [--app KEY=VALUE]...', 'usage of an append map')
call assert_contains(out, 'keys: alpha, beta', 'help lists the allowed keys')
! T1.16: still a map after a later add
call define
call cli%add(switch='--later', help='later', required=.false., act='store', def='0', error=error)
call cli%parse(args='--set a=1', error=error)
call assert_equal(pairs_of('--set', error), 'a=1', 'T1.16 map after a later add')
! T1.15: definitions
call bad('positional', ERROR_MAP_INCONSISTENT)
call bad('flag', ERROR_MAP_INCONSISTENT)
call bad('scalar', ERROR_MAP_INCONSISTENT)
call bad('choices', ERROR_MAP_INCONSISTENT)
call bad('keys without map', ERROR_MAP_INCONSISTENT)
call bad('default without =', ERROR_MAP_FORMAT)
call bad('default outside the keys', ERROR_MAP_UNKNOWN_KEY)
out = read_back(lun)
call capture_close(lun)

! the environment: comma-separated pairs, a quoted comma kept in the value
call reinvoke(1_I4P, exitstat, out, err, args='', env="'FLAP_TEST_MAP_SET=u=1,""w=a,b""'")
call assert_contains(out, 'pairs=[u=1 w=a,b]', 'environment pairs')

contains
  subroutine define(config)
  !< Define the CLI.
  logical, intent(in), optional :: config !< Read the configuration file.

  call cli%init(progname='flap_test_map', error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--set', help='overrides', required=.false., act='store', nargs='*', map=.true., def='', &
               envvar='FLAP_TEST_MAP_SET', error=error)
  call assert_equal(error, 0_I4P, 'add --set')
  call cli%add(switch='--keys', help='whitelisted', required=.false., act='store', nargs='+', map=.true., &
               map_keys='alpha, beta', def='alpha=0', error=error)
  call cli%add(switch='--def', help='defaults', required=.false., act='store', nargs='+', map=.true., def='a=1 b=2', &
               error=error)
  call cli%add(switch='--app', help='appended', required=.false., act='append', map=.true., def='', error=error)
  call cli%add(switch='--x', help='x', required=.false., act='store', def='0', error=error)
  call assert_equal(error, 0_I4P, 'add the options')
  if (present(config)) then
    if (config) call cli%set_config(file=ini)
  endif
  endsubroutine define

  subroutine run(args, config)
  !< Define the CLI and parse a command line.
  character(*), intent(in)           :: args   !< Command line.
  logical,      intent(in), optional :: config !< Read the configuration file.

  call define(config=config)
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, 'parse "'//args//'"')
  endsubroutine run

  subroutine parse_error(args, expected, what, config)
  !< Define the CLI, parse a command line and check the error; the output goes to out.
  character(*), intent(in)           :: args     !< Command line.
  integer(I4P), intent(in)           :: expected !< Expected error.
  character(*), intent(in)           :: what     !< Description.
  logical,      intent(in), optional :: config   !< Read the configuration file.

  call define(config=config)
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected, what)
  out = read_back(lun)
  endsubroutine parse_error

  function pairs_of(switch, e) result(joined)
  !< The pairs of a map, KEY=VALUE blank separated.
  character(*), intent(in)      :: switch    !< Switch.
  integer(I4P), intent(out)     :: e         !< Error.
  character(len=:), allocatable :: joined    !< Pairs.
  character(32), allocatable    :: keys(:)   !< Keys.
  character(32), allocatable    :: values(:) !< Values.
  integer(I4P)                  :: i         !< Counter.

  joined = ''
  call cli%get_map(switch=switch, keys=keys, values=values, error=e)
  if (e /= 0) return
  do i=1, size(keys, dim=1)
    joined = joined//trim(keys(i))//'='//trim(values(i))
    if (i < size(keys, dim=1)) joined = joined//' '
  enddo
  endfunction pairs_of

  function text_of(key, f, e) result(val)
  !< A value of --set, as text.
  character(*), intent(in)  :: key !< Key.
  logical,      intent(out) :: f   !< Found.
  integer(I4P), intent(out) :: e   !< Error.
  character(99)             :: val !< Value.

  val = '?'
  call cli%get_map_value(switch='--set', key=key, val=val, found=f, error=e)
  endfunction text_of

  function real_of(key, f, e) result(val)
  !< A value of --set, as real.
  character(*), intent(in)  :: key !< Key.
  logical,      intent(out) :: f   !< Found.
  integer(I4P), intent(out) :: e   !< Error.
  real(R8P)                 :: val !< Value.

  val = -1._R8P
  call cli%get_map_value(switch='--set', key=key, val=val, found=f, error=e)
  endfunction real_of

  function int_of(key, f, e, initial) result(val)
  !< A value of --set, as integer.
  character(*), intent(in)           :: key     !< Key.
  logical,      intent(out)          :: f       !< Found.
  integer(I4P), intent(out)          :: e       !< Error.
  integer(I4P), intent(in), optional :: initial !< Initial value.
  integer(I4P)                       :: val     !< Value.

  val = -1 ; if (present(initial)) val = initial
  call cli%get_map_value(switch='--set', key=key, val=val, found=f, error=e)
  endfunction int_of

  function int_nofound(key, e) result(val)
  !< A value of --set, as integer, without found.
  character(*), intent(in)  :: key !< Key.
  integer(I4P), intent(out) :: e   !< Error.
  integer(I4P)              :: val !< Value.

  val = -1
  call cli%get_map_value(switch='--set', key=key, val=val, error=e)
  endfunction int_nofound

  function x_of(e) result(val)
  !< The value of --x.
  integer(I4P), intent(out) :: e   !< Error.
  character(99)             :: val !< Value.

  val = ''
  call cli%get(switch='--x', val=val, error=e)
  endfunction x_of

  subroutine bad(what, expected)
  !< A map option with an invalid definition.
  character(*), intent(in) :: what     !< Case.
  integer(I4P), intent(in) :: expected !< Expected error.

  call cli%init(progname='flap_test_map', error_lun=lun, usage_lun=lun)
  select case(what)
  case('positional')
    call cli%add(positional=.true., position=1, help='p', required=.false., act='store', def='a=1', map=.true., &
                 error=error)
  case('flag')
    call cli%add(switch='--m', help='m', required=.false., act='store_true', def='.false.', map=.true., error=error)
  case('scalar')
    call cli%add(switch='--m', help='m', required=.false., act='store', def='a=1', map=.true., error=error)
  case('choices')
    call cli%add(switch='--m', help='m', required=.false., act='store', nargs='+', def='a=1', choices='a=1,b=2', &
                 map=.true., error=error)
  case('keys without map')
    call cli%add(switch='--m', help='m', required=.false., act='store', nargs='+', def='a=1', map_keys='a', error=error)
  case('default without =')
    call cli%add(switch='--m', help='m', required=.false., act='store', nargs='+', def='a', map=.true., error=error)
  case('default outside the keys')
    call cli%add(switch='--m', help='m', required=.false., act='store', nargs='+', def='c=1', map=.true., map_keys='a,b', &
                 error=error)
  endselect
  call assert_equal(error, expected, 'map definition with '//what)
  endsubroutine bad
endprogram flap_test_map

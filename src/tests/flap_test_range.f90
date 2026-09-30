!< Numeric ranges: min, max, min_open, max_open, clamp (issue #125, step 3.1; #11 2.1-2.3, T2.1-T2.14).
program flap_test_range
!< Numeric ranges: min, max, min_open, max_open, clamp (issue #125, step 3.1; #11 2.1-2.3, T2.1-T2.14).
!<
!< The value is checked by get, after its conversion, in the target kind: an out-of-range value is ERROR_OUT_OF_RANGE, or
!< the bound with clamp (an open integer bound clamps to bound +/- 1; a real cannot clamp to an open bound, reported by get
!< since the type is known only there). Every element of a list is checked. Every get has its own variable (nvfortran, B33).
use flap, only : command_line_interface, ERROR_OUT_OF_RANGE, ERROR_RANGE_DEFINITION, ERROR_RANGE_TYPE
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I1P, I4P, R8P, R16P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
character(:), allocatable    :: out   !< Captured output.
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.
real(R8P)                    :: r8    !< Real value (every get before its check: no side effect inside an expression).
real(R16P)                   :: r16   !< Real value, quad precision.
integer(I4P)                 :: i4    !< Integer value.
integer(I1P)                 :: i1    !< Integer value, I1P.

call capture_open(lun)
! T2.1-T2.5: a real in (0, 1]
call run('--cfl 0.5')
r8 = real_of('--cfl', error)
call assert(abs(r8 - 0.5_R8P) < 1e-12_R8P .and. error == 0, 'in range')
call run('--cfl -1')
r8 = real_of('--cfl', error)
call assert(r8 < 0 .and. error == ERROR_OUT_OF_RANGE, 'below min: out of range')
out = read_back(lun)
call assert_contains(out, 'value "-1" of "--cfl" is out of range (0, 1]', 'out of range: message')
call run('--cfl 1.5')
r8 = real_of('--cfl', error)
call assert(r8 > 1 .and. error == ERROR_OUT_OF_RANGE, 'above max: out of range')
call run('--cfl 1')
r8 = real_of('--cfl', error)
call assert(abs(r8 - 1._R8P) < 1e-12_R8P .and. error == 0, 'at the closed bound: in range')
call run('--cfl 0')
r8 = real_of('--cfl', error)
call assert(r8 == 0 .and. error == ERROR_OUT_OF_RANGE, 'at the open bound: out of range')
! the R16P branch (real quad precision in the tests-gnu-r16p mode; R16P aliases R8P otherwise); no literal with the _R16P
! suffix: the preprocessor, run with -D_R16P, expands it (0.25_R16P becomes 0.251, B35 of #125)
call run('--cfl 0.25')
r16 = real16_of('--cfl', error)
call assert(abs(r16 - real(0.25_R8P, R16P)) < real(1.e-12_R8P, R16P) .and. error == 0, 'R16P in range')
! B35: the value is converted in the kind of the variable (it was converted in single precision under -D_R16P)
call run('--cfl 0.1')
r16 = real16_of('--cfl', error)
call assert(r16 == quad('0.1') .and. error == 0, 'R16P: converted in quad precision (B35)')
call run('--cfl 3')
r16 = real16_of('--cfl', error)
call assert(r16 > 1 .and. error == ERROR_OUT_OF_RANGE, 'R16P out of range')
! T2.6: integer clamp to closed bounds
call run('--threads 999')
i4 = int_of('--threads', error)
call assert(i4 == 256 .and. error == 0, 'clamp above max: max')
call run('--threads 0')
i4 = int_of('--threads', error)
call assert(i4 == 1 .and. error == 0, 'clamp below min: min')
! T2.7: integer clamp to open bounds: bound +/- 1
call run('--n 10')
i4 = int_of('--n', error)
call assert(i4 == 9 .and. error == 0, 'clamp to an open max: max - 1')
call run('--n -3')
i4 = int_of('--n', error)
call assert(i4 == 1 .and. error == 0, 'clamp to an open min: min + 1')
! T2.8: a real cannot clamp to an open bound (reported by get)
call run('--r -1')
r8 = real_of('--r', error)
call assert(r8 < 0 .and. error == ERROR_RANGE_DEFINITION, 'real clamp to an open bound: error')
call run('--r 0.3')
r8 = real_of('--r', error)
call assert(abs(r8 - 0.3_R8P) < 1e-12_R8P .and. error == 0, 'real in range, clamp unused')
! T2.11: every element of a list
call run('--list 1 20 3')
call assert(list_error('--list') == ERROR_OUT_OF_RANGE, 'list with an element out of range')
out = read_back(lun)
call assert_contains(out, 'value "20" of "--list"', 'list: the element is named')
call run('--list 1 2 3')
call assert(list_error('--list') == 0, 'list in range')
call run('--list 1 20')
call assert(fixed_list_error('--list') == ERROR_OUT_OF_RANGE, 'fixed-size list with an element out of range')
! T2.12: a range with a character get
call run('')
call assert(char_error('--name') == ERROR_RANGE_TYPE, 'range and character get: error')
! T2.13: I1P at its bounds
call run('--b -128')
i1 = i1_of('--b', error)
call assert(i1 == -127_I1P - 1_I1P .and. error == 0, 'I1P at -128')
call run('--b 127')
i1 = i1_of('--b', error)
call assert(i1 == 127_I1P .and. error == 0, 'I1P at 127')
! T2.14: the range survives a later add
call define
call cli%add(switch='--later', help='later', required=.false., act='store', def='0', error=error)
call cli%parse(args='--cfl 2', error=error)
r8 = real_of('--cfl', error)
call assert(r8 > 1 .and. error == ERROR_OUT_OF_RANGE, 'range after a later add')
! help
call define
call assert_contains(cli%usage(g=0), 'range (0, 1]', 'help: range of --cfl')
call assert_contains(cli%usage(g=0), 'range [1, 256]', 'help: range of --threads')
! T2.9, T2.10: definitions
call bad(min='5', max='1', what='min > max')
call bad(min='1', max='1', min_open=.true., what='empty open interval')
call bad(min='abc', what='non-numeric min')
call bad(max='1', flag=.true., what='range on a flag')
call cli%init(progname='flap_test_range', error_lun=lun, usage_lun=lun)
call cli%add(switch='--ok', help='ok', required=.false., act='store', def='1', min='1', max='1', error=error)
call assert_equal(error, 0_I4P, 'min = max, closed: allowed')
call capture_close(lun)

contains
  subroutine define()
  !< Define the CLI.
  call cli%init(progname='flap_test_range', error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--cfl', help='cfl', required=.false., act='store', def='0.8', min='0', min_open=.true., max='1', &
               error=error)
  call assert_equal(error, 0_I4P, 'add --cfl')
  call cli%add(switch='--threads', help='threads', required=.false., act='store', def='1', min='1', max='256', &
               clamp=.true., error=error)
  call cli%add(switch='--n', help='n', required=.false., act='store', def='5', min='0', max='10', min_open=.true., &
               max_open=.true., clamp=.true., error=error)
  call cli%add(switch='--r', help='r', required=.false., act='store', def='0.5', min='0', min_open=.true., clamp=.true., &
               error=error)
  call cli%add(switch='--list', help='list', required=.false., act='store', nargs='+', def='1 2', min='0', max='10', &
               error=error)
  call cli%add(switch='--b', help='byte', required=.false., act='store', def='0', min='-128', max='127', error=error)
  call cli%add(switch='--name', help='name', required=.false., act='store', def='x', min='0', error=error)
  call assert_equal(error, 0_I4P, 'add the options')
  endsubroutine define

  subroutine run(args)
  !< Define the CLI and parse a command line.
  character(*), intent(in) :: args !< Command line.

  call define
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, 'parse "'//args//'"')
  endsubroutine run

  function real_of(switch, e) result(val)
  !< Value of a real option.
  character(*), intent(in)  :: switch !< Switch.
  integer(I4P), intent(out) :: e      !< Error.
  real(R8P)                 :: val    !< Value.

  val = -999._R8P
  call cli%get(switch=switch, val=val, error=e)
  endfunction real_of

  function real16_of(switch, e) result(val)
  !< Value of a real(R16P) option.
  character(*), intent(in)  :: switch !< Switch.
  integer(I4P), intent(out) :: e      !< Error.
  real(R16P)                :: val    !< Value.

  val = real(-999, R16P)
  call cli%get(switch=switch, val=val, error=e)
  endfunction real16_of

  function quad(string) result(val)
  !< Value of a string read as real(R16P).
  character(*), intent(in) :: string !< String.
  real(R16P)               :: val    !< Value.

  read(string, *) val
  endfunction quad

  function int_of(switch, e) result(val)
  !< Value of an integer option.
  character(*), intent(in)  :: switch !< Switch.
  integer(I4P), intent(out) :: e      !< Error.
  integer(I4P)              :: val    !< Value.

  val = -999
  call cli%get(switch=switch, val=val, error=e)
  endfunction int_of

  function i1_of(switch, e) result(val)
  !< Value of an integer(I1P) option.
  character(*), intent(in)  :: switch !< Switch.
  integer(I4P), intent(out) :: e      !< Error.
  integer(I1P)              :: val    !< Value.

  val = 0_I1P
  call cli%get(switch=switch, val=val, error=e)
  endfunction i1_of

  function list_error(switch) result(e)
  !< Error of the get of a varying integer list.
  character(*), intent(in)  :: switch  !< Switch.
  integer(I4P)              :: e       !< Error.
  integer(I4P), allocatable :: vals(:) !< Values.

  call cli%get_varying(switch=switch, val=vals, error=e)
  endfunction list_error

  function fixed_list_error(switch) result(e)
  !< Error of the get of a fixed-size integer list of 2.
  character(*), intent(in) :: switch  !< Switch.
  integer(I4P)             :: e       !< Error.
  integer(I4P)             :: vals(2) !< Values.

  call cli%get(switch=switch, val=vals, error=e)
  endfunction fixed_list_error

  function char_error(switch) result(e)
  !< Error of the get of a character.
  character(*), intent(in) :: switch !< Switch.
  integer(I4P)             :: e      !< Error.
  character(20)            :: val    !< Value.

  call cli%get(switch=switch, val=val, error=e)
  endfunction char_error

  subroutine bad(what, min, max, min_open, flag)
  !< An invalid range definition.
  character(*), intent(in)           :: what     !< Description.
  character(*), intent(in), optional :: min      !< Minimum.
  character(*), intent(in), optional :: max      !< Maximum.
  logical,      intent(in), optional :: min_open !< Open minimum.
  logical,      intent(in), optional :: flag     !< On a flag.
  logical                            :: flag_    !< On a flag, local variable.

  flag_ = .false. ; if (present(flag)) flag_ = flag
  call cli%init(progname='flap_test_range', error_lun=lun, usage_lun=lun)
  if (flag_) then
    call cli%add(switch='--x', help='x', required=.false., act='store_true', def='.false.', min=min, max=max, error=error)
  else
    call cli%add(switch='--x', help='x', required=.false., act='store', def='1', min=min, max=max, min_open=min_open, &
                 error=error)
  endif
  call assert_equal(error, ERROR_RANGE_DEFINITION, what//': definition error')
  endsubroutine bad
endprogram flap_test_range

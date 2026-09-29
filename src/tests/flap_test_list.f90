!< List storage: one API over the stored list format, used by the parser and by every list getter (issue #125, step 0.D.3).
program flap_test_list
!< List storage: one API over the stored list format, used by the parser and by every list getter (issue #125, step 0.D.3).
!<
!< Every CLI scenario uses a fresh CLI, so the scenarios are independent.
use flap, only : command_line_interface, ERROR_CASTING_LOGICAL, ERROR_DEF_NARGS, ERROR_LIST_SIZE, &
                 ERROR_UNSUPPORTED_TYPE
use flap_test_utils, only : assert, assert_equal, capture_close, capture_open
use flap_utils_m, only : list_count, list_items, list_join, list_push
use penf, only : I4P

implicit none
character(:), allocatable :: list     !< List.
character(:), allocatable :: items(:) !< Items of a list.
integer(I4P)              :: n        !< Number of items.
integer(I4P)              :: lun      !< Capture unit.

! the API
call list_push(list, 'a')
call list_push(list, 'b c')
call list_push(list, '')
call assert_equal(list_count(list), 3_I4P, 'list_count: pushed items')
call list_items(list, items, n)
call assert_equal(n, 3_I4P, 'list_items: number of items')
call assert_equal(int(size(items), I4P), 3_I4P, 'list_items: size of the array')
call assert_equal(items(1), 'a', 'list_items: item 1')
call assert_equal(items(2), 'b c', 'list_items: item 2, blanks inside kept')
call assert_equal(items(3), '', 'list_items: item 3, empty')
call assert_equal(list_join(list, ' '), 'a b c ', 'list_join')
list = ''
call assert_equal(list_count(list), 0_I4P, 'list_count: empty list')
call list_items(list, items, n)
call assert_equal(n, 0_I4P, 'list_items: empty list has no item')
call assert_equal(list_join(list, ' '), '', 'list_join: empty list')

call capture_open(lun)
call check_flag_defaults
call check_bad_logical
call check_list_size
call check_flag_varying
call check_def_nargs
call capture_close(lun)

contains
  subroutine check_flag_defaults
  !< A list of flags left to its defaults gets every default value.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  logical                      :: t(2)  !< store_true list.
  logical                      :: f(3)  !< store_false list.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='flap_test_list', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--t', help='flags', required=.false., act='store_true', nargs='2', def='F T', error=error)
  call cli%add(switch='--f', help='flags', required=.false., act='store_false', nargs='3', def='F T F', error=error)
  call cli%add(switch='--x', help='flags', required=.false., act='store_true', nargs='2', def='F X', error=error)
  call cli%parse(args='', error=error)
  call assert_equal(error, 0_I4P, 'flag defaults: parse')
  t = .false.
  call cli%get(switch='--t', val=t, error=error)
  call assert_equal(error, 0_I4P, 'store_true list default: error')
  call assert(t(1) .eqv. .false., 'store_true list default: value 1')
  call assert(t(2) .eqv. .true., 'store_true list default: value 2')
  f = .true.
  call cli%get(switch='--f', val=f, error=error)
  call assert_equal(error, 0_I4P, 'store_false list default: error')
  call assert(all(f .eqv. [.false., .true., .false.]), 'store_false list default: every value')
  call cli%get(switch='--x', val=t, error=error)
  call assert_equal(error, ERROR_CASTING_LOGICAL, 'list default not a logical: casting error')
  endsubroutine check_flag_defaults

  subroutine check_bad_logical
  !< A passed value that is not a logical is a casting error for get_varying too.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  logical, allocatable         :: l(:)  !< Values.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='flap_test_list', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--l', help='logicals', required=.false., act='store', nargs='+', def='T', error=error)
  call cli%parse(args='--l T x', error=error)
  call assert_equal(error, 0_I4P, 'bad logical: parse')
  call cli%get_varying(switch='--l', val=l, error=error)
  call assert_equal(error, ERROR_CASTING_LOGICAL, 'bad logical, get_varying: casting error')
  endsubroutine check_bad_logical

  subroutine check_list_size
  !< B27 (#125): get into a fixed-size array needs exactly as many values as its size; otherwise the array is untouched.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: i2(2) !< Too few slots.
  integer(I4P)                 :: i3(3) !< Exact size.
  integer(I4P)                 :: i4(4) !< Too many slots.
  character(5)                 :: c1(1) !< Too few slots, character.
  logical                      :: l3(3) !< Too many slots, flags.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='flap_test_list', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--l', help='integers', required=.false., act='store', nargs='+', def='1', error=error)
  call cli%add(switch='--d', help='integers', required=.false., act='store', nargs='2', def='7 8', error=error)
  call cli%add(switch='--c', help='words', required=.false., act='store', nargs='*', def='a', error=error)
  call cli%add(switch='--t', help='flags', required=.false., act='store_true', nargs='2', def='F T', error=error)
  call cli%parse(args='--l 1 2 3 --c ab cd', error=error)
  call assert_equal(error, 0_I4P, 'list size: parse')
  i2 = -9
  call cli%get(switch='--l', val=i2, error=error)
  call assert_equal(error, ERROR_LIST_SIZE, '3 values into 2 slots: error')
  call assert(all(i2 == -9), '3 values into 2 slots: untouched')
  i4 = -9
  call cli%get(switch='--l', val=i4, error=error)
  call assert_equal(error, ERROR_LIST_SIZE, '3 values into 4 slots: error')
  call assert(all(i4 == -9), '3 values into 4 slots: untouched')
  call cli%get(switch='--l', val=i3, error=error)
  call assert_equal(error, 0_I4P, '3 values into 3 slots: error')
  call assert(all(i3 == [1, 2, 3]), '3 values into 3 slots: values')
  i3 = -9
  call cli%get(switch='--d', val=i3, error=error)
  call assert_equal(error, ERROR_LIST_SIZE, 'default of 2 values into 3 slots: error')
  call assert(all(i3 == -9), 'default of 2 values into 3 slots: untouched')
  c1 = 'zz'
  call cli%get(switch='--c', val=c1, error=error)
  call assert_equal(error, ERROR_LIST_SIZE, '2 words into 1 slot: error')
  call assert_equal(c1(1), 'zz', '2 words into 1 slot: untouched')
  l3 = .true.
  call cli%get(switch='--t', val=l3, error=error)
  call assert_equal(error, ERROR_LIST_SIZE, 'default of 2 flags into 3 slots: error')
  call assert(all(l3), 'default of 2 flags into 3 slots: untouched')
  endsubroutine check_list_size

  subroutine check_flag_varying
  !< B26 (#125): get_varying on a list of flags gives the defaults, or as many .true./.false. when passed.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  logical, allocatable         :: l(:)  !< Values.
  integer(I4P), allocatable    :: i(:)  !< Values of an unsupported type.
  integer(I4P)                 :: error !< Error trapping flag.

  call define_flags(cli, '')
  call cli%get_varying(switch='--t', val=l, error=error)
  call assert_equal(error, 0_I4P, 'store_true list not passed: error')
  call assert(allocated(l), 'store_true list not passed: allocated')
  call assert_equal(int(size(l), I4P), 2_I4P, 'store_true list not passed: size')
  call assert((.not.l(1)) .and. l(2), 'store_true list not passed: the defaults')
  call cli%get_varying(switch='--x', val=l, error=error)
  call assert_equal(error, ERROR_CASTING_LOGICAL, 'list default not a logical: casting error')
  call cli%get_varying(switch='--t', val=i, error=error)
  call assert_equal(error, ERROR_UNSUPPORTED_TYPE, 'integers for a list of flags: unsupported type')

  call define_flags(cli, '--t --f')
  call cli%get_varying(switch='--t', val=l, error=error)
  call assert_equal(error, 0_I4P, 'store_true list passed: error')
  call assert_equal(int(size(l), I4P), 2_I4P, 'store_true list passed: size')
  call assert(all(l), 'store_true list passed: all .true.')
  call cli%get_varying(switch='--f', val=l, error=error)
  call assert_equal(error, 0_I4P, 'store_false list passed: error')
  call assert_equal(int(size(l), I4P), 3_I4P, 'store_false list passed: size')
  call assert(all(.not.l), 'store_false list passed: all .false.')
  endsubroutine check_flag_varying

  subroutine define_flags(cli, args)
  !< Define lists of flags and parse a command line.
  type(command_line_interface), intent(inout) :: cli   !< Command Line Interface (CLI).
  character(*),                 intent(in)    :: args  !< Command line.
  integer(I4P)                                :: error !< Error trapping flag.

  call cli%free
  call cli%init(progname='flap_test_list', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--t', help='flags', required=.false., act='store_true', nargs='2', def='F T', error=error)
  call cli%add(switch='--f', help='flags', required=.false., act='store_false', nargs='3', def='T T F', error=error)
  call cli%add(switch='--x', help='flags', required=.false., act='store_true', nargs='2', def='F X', error=error)
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, 'flag lists: parse '//args)
  endsubroutine define_flags

  subroutine check_def_nargs
  !< B28 (#125): a list default whose count differs from an integer nargs is a definition error.
  call check_def('store',      '2', '1 2',      0_I4P,           'nargs=2, 2 values')
  call check_def('store',      '2', '  1   2 ', 0_I4P,           'nargs=2, 2 values among blanks')
  call check_def('store',      '2', '1 2 3',    ERROR_DEF_NARGS, 'nargs=2, 3 values')
  call check_def('store',      '2', '1',        ERROR_DEF_NARGS, 'nargs=2, 1 value')
  call check_def('store',      '+', '1 2 3',    0_I4P,           'nargs=+, any count')
  call check_def('store',      '*', '1',        0_I4P,           'nargs=*, any count')
  call check_def('store_true', '2', 'F',        ERROR_DEF_NARGS, 'list of flags, nargs=2, 1 value')
  endsubroutine check_def_nargs

  subroutine check_def(act, nargs, def, expected, message)
  !< Define a list option and check the definition error.
  character(*), intent(in)     :: act      !< Action.
  character(*), intent(in)     :: nargs    !< Number of values.
  character(*), intent(in)     :: def      !< Default.
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  integer(I4P)                 :: error    !< Error trapping flag.

  call cli%init(progname='flap_test_list', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--l', help='a list', required=.false., act=act, nargs=nargs, def=def, error=error)
  call assert_equal(error, expected, 'definition, '//message)
  endsubroutine check_def
endprogram flap_test_list

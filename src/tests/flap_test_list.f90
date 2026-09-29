!< List storage: one API over the stored list format, used by the parser and by every list getter (issue #125, step 0.D.3).
program flap_test_list
!< List storage: one API over the stored list format, used by the parser and by every list getter (issue #125, step 0.D.3).
!<
!< Every CLI scenario uses a fresh CLI, so the scenarios are independent.
use flap, only : command_line_interface, ERROR_CASTING_LOGICAL
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
endprogram flap_test_list

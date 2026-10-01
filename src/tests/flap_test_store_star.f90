!< An option with an optional value (act='store*') is rendered with its switch (issue #126, B39).
program flap_test_store_star
!< An option with an optional value (act='store*') is rendered with its switch (issue #126, B39).
!<
!< The usage line, the help, the man page and the Markdown showed a store* option as a bare `[value]`, as if it were a
!< positional: it is `[--save [value]]` in the usage (`--save [value]` when required, bare in a mutually exclusive set)
!< and `--save [value], -s [value]` in the help, with its choices as for any option.
use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, delete_file, read_file, &
                            scratch_file
use penf, only : I4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
character(:), allocatable    :: out   !< Output.
character(:), allocatable    :: file  !< Scratch file.
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.

file = scratch_file('out')
call capture_open(lun)

call cli%init(progname='flap_test_store_star', error_lun=lun, usage_lun=lun)
call cli%add(switch='--save', switch_ab='-s', help='save', required=.false., act='store*', def='vtk', choices='vtk,csv', &
             error=error)
call cli%add(switch='--log', help='log', required=.true., act='store*', def='-', metavar='FILE', error=error)
call cli%add(switch='--fast', help='fast', required=.false., act='store*', def='1', error=error)
call cli%add(switch='--slow', help='slow', required=.false., act='store*', def='1', error=error)
call cli%set_mutually_exclusive_switches(switches='--fast,--slow', error=error)
call assert_equal(error, 0_I4P, 'define')

! the usage line
out = cli%usage(g=0)
call assert_contains(out, ' [--save [value]]', 'usage: optional')
call assert_contains(out, ' --log [FILE]', 'usage: required, with its metavar')
call assert_contains(out, ' [--fast [value] | --slow [value]]', 'usage: in a mutually exclusive set')
! the help lines
call assert_contains(out, '   --save [value], -s [value], value in: `vtk,csv`', 'help: switch, abbreviation, choices')
call assert_contains(out, '   --log [FILE]'//new_line('a'), 'help: required, with its metavar')
call assert(index(out, new_line('a')//'  [value]') == 0, 'help: no bare placeholder')
! the man page and the Markdown
call cli%save_man_page(man_file=file, error=error)
call assert_equal(error, 0_I4P, 'man page saved')
call assert_contains(read_file(file), '--save [value]', 'man page')
call cli%save_usage_to_markdown(markdown_file=file, error=error)
call assert_equal(error, 0_I4P, 'markdown saved')
out = read_file(file)
call assert_contains(out, '* `--save [value]`, `-s [value]`', 'markdown')
call delete_file(file)

! the value is unchanged: the switch alone gives the default, a value the value
call cli%parse(args='--log --save csv', error=error)
call assert_equal(error, 0_I4P, 'parse')
call check_value('--save', 'csv', 'a value')
call check_value('--log', '-', 'the switch alone: the default')
call capture_close(lun)

contains
  subroutine check_value(switch, expected, message)
  !< Check the value of an option.
  character(*), intent(in) :: switch   !< Switch.
  character(*), intent(in) :: expected !< Expected value.
  character(*), intent(in) :: message  !< Description of the check.
  character(9)             :: val      !< Value.
  integer(I4P)             :: e        !< Error trapping flag.

  call cli%get(switch=switch, val=val, error=e)
  call assert_equal(e, 0_I4P, message//': get')
  call assert(trim(val) == expected, message//': "'//trim(val)//'"')
  endsubroutine check_value
endprogram flap_test_store_star

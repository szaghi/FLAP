!< What an error prints after its message: init(usage_on_error=) (issue #125, F27, step 6.4; issue #102).
program flap_test_usage_on_error
!< What an error prints after its message: init(usage_on_error=) (issue #125, F27, step 6.4; issue #102).
!<
!< A missing required option (and a required exclusive set with no member) prints the whole help of its group after the
!< error message: 'full', the default, unchanged. 'usage' prints the usage line only, 'none' nothing; the error message and
!< the hint line are always printed, and --help always prints the whole help.
use flap, only : command_line_interface, ERROR_MISSING_REQUIRED, ERROR_M_EXCLUDE_SET_REQUIRED, ERROR_USAGE_ON_ERROR, &
                 STATUS_PRINT_H
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P

implicit none
type(command_line_interface) :: cli        !< Command Line Interface (CLI).
character(:), allocatable    :: out        !< Captured output.
character(:), allocatable    :: usage_line !< Expected usage line.
integer(I4P)                 :: lun        !< Capture unit.
integer(I4P)                 :: error      !< Error trapping flag.

call capture_open(lun)

! the default and 'full': the whole help, as before
call define
call cli%parse(args='', error=error)
call assert_equal(error, ERROR_MISSING_REQUIRED, 'default: error')
out = read_back(lun)
call assert_contains(out, '--mesh', 'default: the error message')
call assert_contains(out, 'Required switches:', 'default: the whole help')
call assert_contains(out, "Try 'prog --help' for help.", 'default: the hint')
call define(mode='full')
call cli%parse(args='', error=error)
call assert_contains(read_back(lun), 'Required switches:', 'full: the whole help')

! 'usage': the usage line only
call define(mode='usage')
usage_line = first_line(cli%usage(g=0))
call assert_contains(usage_line, 'prog', 'the usage line')
call cli%parse(args='', error=error)
call assert_equal(error, ERROR_MISSING_REQUIRED, 'usage: error')
out = read_back(lun)
call assert_contains(out, '--mesh', 'usage: the error message')
call assert_contains(out, usage_line//new_line('a'), 'usage: the usage line')
call assert(index(out, 'Required switches:') == 0 .and. index(out, 'Optional switches:') == 0, 'usage: not the whole help')
call assert_contains(out, "Try 'prog --help' for help.", 'usage: the hint')
! a command: its own usage line
call define(mode='usage')
usage_line = first_line(cli%usage(g=1))
call assert_contains(usage_line, 'prog run', 'the usage line of the command')
call cli%parse(args='--mesh m run', error=error)
call assert_equal(error, ERROR_MISSING_REQUIRED, 'usage, command: error')
out = read_back(lun)
call assert_contains(out, '--steps', 'usage, command: the error message')
call assert_contains(out, usage_line//new_line('a'), 'usage, command: its usage line')
call assert(index(out, 'Required switches:') == 0, 'usage, command: not the whole help')
! any case
call define(mode='Usage')
call cli%parse(args='', error=error)
call assert_equal(error, ERROR_MISSING_REQUIRED, 'Usage: accepted')
call assert(index(read_back(lun), 'Required switches:') == 0, 'Usage: the usage line only')

! 'none': the message (and the hint) only
call define(mode='none')
call cli%parse(args='', error=error)
call assert_equal(error, ERROR_MISSING_REQUIRED, 'none: error')
out = read_back(lun)
call assert_contains(out, '--mesh', 'none: the error message')
call assert(index(out, 'usage:') == 0 .and. index(out, 'Required switches:') == 0, 'none: no usage')
call assert_contains(out, "Try 'prog --help' for help.", 'none: the hint')
! --help is not an error: always the whole help
call define(mode='none')
call cli%parse(args='--help', error=error)
call assert_equal(error, STATUS_PRINT_H, 'none: --help')
call assert_contains(read_back(lun), 'Required switches:', 'none: --help prints the whole help')

! a required exclusive set with no member: the same choice
call define_set(mode='usage')
call cli%parse(args='', error=error)
call assert_equal(error, ERROR_M_EXCLUDE_SET_REQUIRED, 'set, usage: error')
out = read_back(lun)
call assert(index(out, 'Optional switches:') == 0, 'set, usage: not the whole help')
call assert_contains(out, 'usage:', 'set, usage: the usage line')
call define_set(mode='none')
call cli%parse(args='', error=error)
call assert(index(read_back(lun), 'usage:') == 0, 'set, none: no usage')
call define_set
call cli%parse(args='', error=error)
call assert_contains(read_back(lun), 'Optional switches:', 'set, default: the whole help')

! an invalid value: a definition error, reported by parse
call define(mode='short')
call cli%parse(args='--mesh m', error=error)
call assert_equal(error, ERROR_USAGE_ON_ERROR, 'invalid value: error')
call assert_contains(read_back(lun), '"short"', 'invalid value: message')
call capture_close(lun)

contains
  subroutine define(mode)
  !< A CLI with a required option and a command with a required option.
  character(*), intent(in), optional :: mode !< usage_on_error.
  integer(I4P)                       :: e    !< Error trapping flag.

  if (present(mode)) then
    call cli%init(progname='prog', usage_on_error=mode, standalone=.false., error_lun=lun, usage_lun=lun, version_lun=lun)
  else
    call cli%init(progname='prog', standalone=.false., error_lun=lun, usage_lun=lun, version_lun=lun)
  endif
  call cli%add(switch='--mesh', help='mesh file', required=.true., act='store', error=e)
  call cli%add(switch='--cfl', help='cfl', required=.false., act='store', def='0.5', error=e)
  call cli%add_group(group='run', description='run')
  call cli%add(group='run', switch='--steps', help='steps', required=.true., act='store', error=e)
  call assert_equal(e, 0_I4P, 'define')
  endsubroutine define

  subroutine define_set(mode)
  !< A CLI with a required exclusive set.
  character(*), intent(in), optional :: mode !< usage_on_error.
  integer(I4P)                       :: e    !< Error trapping flag.

  if (present(mode)) then
    call cli%init(progname='prog', usage_on_error=mode, standalone=.false., error_lun=lun, usage_lun=lun, version_lun=lun)
  else
    call cli%init(progname='prog', standalone=.false., error_lun=lun, usage_lun=lun, version_lun=lun)
  endif
  call cli%add(switch='--a', help='a', required=.false., act='store_true', def='.false.', error=e)
  call cli%add(switch='--b', help='b', required=.false., act='store_true', def='.false.', error=e)
  call cli%set_mutually_exclusive_switches(switches='--a,--b', required=.true., error=e)
  call assert_equal(e, 0_I4P, 'define_set')
  endsubroutine define_set

  function first_line(text) result(line)
  !< The first line of a text.
  character(*), intent(in)  :: text !< Text.
  character(:), allocatable :: line !< First line.

  line = text
  if (index(text, new_line('a')) > 0) line = text(:index(text, new_line('a'))-1)
  endfunction first_line
endprogram flap_test_usage_on_error

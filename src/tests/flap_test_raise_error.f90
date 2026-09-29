!< Application errors reported in FLAP's style by raise_error (issue #125, step 1.3; #25-2).
program flap_test_raise_error
!< Application errors reported in FLAP's style by raise_error (issue #125, step 1.3; #25-2).
!<
!< Error and usage output go to two separate scratch units, so each can be checked alone.
use face, only : colorize
use flap, only : command_line_interface, ERROR_MISSING_GROUP, ERROR_USER
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
integer(I4P)                 :: elun  !< Capture unit of errors.
integer(I4P)                 :: ulun  !< Capture unit of the usage.
integer(I4P)                 :: error !< Error trapping flag.
character(:), allocatable    :: errs  !< Captured errors.
character(:), allocatable    :: usage !< Captured usage.

call capture_open(elun)
call capture_open(ulun)

! T2.1, T2.8 (before parse), T2.9
call define
error = cli%raise_error('boom')
call assert_equal(error, ERROR_USER, 'raise_error: returns ERROR_USER')
call assert_equal(cli%error, ERROR_USER, 'raise_error: sets the CLI error')
call read_both
call assert_equal(first_line(errs), 'prog: error: boom', 'raise_error: the message')
call assert_contains(usage, '--nx', 'raise_error before parse: the usage lists the defined options')
call assert(index(errs, achar(27)) == 0, 'no colour configured: no ANSI escape')
! T2.2 the switch prefixes the message
call define
call cli%parse(args='--nx 3', error=error)
error = cli%raise_error('must be even', switch='--nx')
call read_both
call assert_equal(first_line(errs), 'prog: error: switch "--nx": must be even', 'raise_error with switch: the message')
! T2.3 no usage
call define
error = cli%raise_error('boom', show_usage=.false.)
call read_both
call assert_equal(int(len(usage), I4P), 0_I4P, 'show_usage=.false.: no usage written')
! T2.4 the usage of a command
call define
error = cli%raise_error('bad step', group='post')
call read_both
call assert_contains(usage, '--step', 'group=post: the usage of the command')
call assert(index(usage, '--nx') == 0, 'group=post: not the top-level usage')
! T2.5 an undefined command
call define
error = cli%raise_error('boom', group='nope')
call read_both
call assert_equal(error, ERROR_MISSING_GROUP, 'group=nope: ERROR_MISSING_GROUP')
call assert(index(errs, 'boom') == 0, 'group=nope: the message is not printed')
call assert_equal(int(len(usage), I4P), 0_I4P, 'group=nope: no usage written')
! T2.7 the colour of the parser errors
call define(error_color='red')
error = cli%raise_error('boom', show_usage=.false.)
call read_both
call assert_equal(first_line(errs), 'prog: '//colorize('error', color_fg='red')//': boom', 'error_color: as the parser errors')

call capture_close(elun)
call capture_close(ulun)

contains
  subroutine define(error_color)
  !< Define a CLI with a command, errors and usage captured on separate units.
  character(*), intent(in), optional :: error_color !< ANSI color of error messages.

  call cli%init(progname='prog', usage_lun=ulun, error_lun=elun, error_color=error_color)
  call cli%add(switch='--nx', help='cells', required=.false., act='store', def='2', error=error)
  call cli%add_group(group='post', description='post-process')
  call cli%add(group='post', switch='--step', help='step', required=.false., act='store', def='1', error=error)
  call read_both ! drop the output of the definitions
  endsubroutine define

  subroutine read_both
  !< Read back both capture units.
  errs = read_back(elun)
  usage = read_back(ulun)
  endsubroutine read_both

  function first_line(text) result(line)
  !< Return the first non-empty line of a text.
  character(*), intent(in)  :: text !< Text.
  character(:), allocatable :: line !< First non-empty line.
  integer(I4P)              :: b    !< Start of the line.
  integer(I4P)              :: e    !< End of the line.

  b = 1
  do while (b <= len(text))
    if (text(b:b) /= new_line('a')) exit
    b = b + 1
  enddo
  e = index(text(b:), new_line('a'))
  if (e == 0) then
    line = text(b:)
  else
    line = text(b:b+e-2)
  endif
  endfunction first_line
endprogram flap_test_raise_error

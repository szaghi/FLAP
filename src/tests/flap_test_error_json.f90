!< Structured errors: JSON lines on the error unit (issue #128).
program flap_test_error_json
!< Structured errors: JSON lines on the error unit (issue #128).
use flap, only : command_line_interface, ERROR_CASTING_NUMBER, ERROR_FORMAT, ERROR_MISSING_REQUIRED, ERROR_NOT_IN_CHOICES, &
                 ERROR_OUT_OF_RANGE, ERROR_UNKNOWN
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, read_back, reinvoke
use penf, only : I4P

implicit none
character(1), parameter   :: BS = achar(92) !< Backslash.
integer(I4P)              :: lun      !< Capture unit.
character(:), allocatable :: out      !< Output of a child.
character(:), allocatable :: err      !< Errors of a child.
character(:), allocatable :: text     !< Captured text.
integer(I4P)              :: exitstat !< Exit status of a child.

select case(child_case())
case(1)
  call child('')
  stop
case(2)
  call child('json')
  stop
endselect

call capture_open(lun)
! T3.1 every error path, one line each
call line_of('--steps abc', ERROR_CASTING_NUMBER, 'a typed value')
call assert_line('"argument":"--steps"', 'T3.1 argument')
call line_of('', ERROR_MISSING_REQUIRED, 'missing required', omit_required=.true.)
call assert_line('"argument":"--steps"', 'T3.1 missing: argument')
call line_of('--steps 1 --choice z', ERROR_NOT_IN_CHOICES, 'not in choices')
call assert_line('"code":7,', 'T3.1 code')
call line_of('--steps 1 --range 9', ERROR_OUT_OF_RANGE, 'out of range')
call assert_line('"code":31,', 'T3.1 code of the range')
! T3.2 suggestions
call line_of('--steps 1 --chice z', ERROR_UNKNOWN, 'unknown')
call assert_line('"argument":"--chice"', 'T3.2 argument')
call assert_line('"suggestions":["--choice"]', 'T3.2 suggestions')
call line_of('--steps 1 --zzzzzzzz', ERROR_UNKNOWN, 'unknown, nothing near')
call assert(index(text, 'suggestions') == 0, 'T3.2 no suggestions')
! T3.3 no escape codes, whatever the colors asked
call line_of('--steps abc', ERROR_CASTING_NUMBER, 'colors', color='red')
call assert(index(text, achar(27)) == 0, 'T3.3 no escape code')
call assert(index(text, 'u001b') == 0, 'T3.3 no escaped escape code')
! T3.4 no usage and no hint, whatever usage_on_error
call line_of('', ERROR_MISSING_REQUIRED, 'full usage', omit_required=.true., usage='full')
call assert(index(text, 'usage:') == 0, 'T3.4 no usage')
call assert(index(text, 'Try ') == 0, 'T3.4 no hint')
! T3.5 a warning, then an error
call check_deprecated
! T3.6 an error of get
call check_get
! T3.8 an invalid format
call check_invalid
! T3.9 quotes and new lines in a value
call line_of("--steps 'a"//'"'//"b'", ERROR_CASTING_NUMBER, 'a quote')
call assert_line('a'//BS//'"b', 'T3.9 escaped')
! T3.10 the message of the program stays plain
call check_message
! T3.11 the text format is what it was
call check_text
! a command: the line comes from a CLA of the command
call check_command
call capture_close(lun)

! T3.7 the variable, per run
call reinvoke(1_I4P, exitstat, out, err, args='--bogus', env='FLAP_TEST_EJ=json')
call assert_contains(err, '{"schema_version":1,"level":"error","code":15,', 'T3.7 json')
call reinvoke(1_I4P, exitstat, out, err, args='--bogus', env='FLAP_TEST_EJ=JSON')
call assert_contains(err, '"level":"error"', 'T3.7 any case')
call reinvoke(1_I4P, exitstat, out, err, args='--bogus', env='FLAP_TEST_EJ=text')
call assert(index(err, '{') == 0, 'T3.7 text')
call assert_contains(err, 'error: switch "--bogus" is unknown', 'T3.7 text message')
call reinvoke(1_I4P, exitstat, out, err, args='--bogus', env='FLAP_TEST_EJ=junk')
call assert(index(err, '{') == 0, 'T3.7 junk is text')
call reinvoke(1_I4P, exitstat, out, err, args='--bogus', env='-u FLAP_TEST_EJ')
call assert(index(err, '{') == 0, 'T3.7 unset, the default')
call reinvoke(2_I4P, exitstat, out, err, args='--bogus', env='-u FLAP_TEST_EJ')
call assert_contains(err, '"level":"error"', 'T3.7 unset, error_format holds')
call reinvoke(2_I4P, exitstat, out, err, args='--bogus', env='FLAP_TEST_EJ=text')
call assert(index(err, '{') == 0, 'T3.7 the variable wins over error_format')

contains
  subroutine line_of(args, expected, message, omit_required, color, usage)
  !< Parse, and check that the capture is one JSON line.
  character(*), intent(in)           :: args          !< Command line.
  integer(I4P), intent(in)           :: expected      !< Expected error.
  character(*), intent(in)           :: message       !< Description of the check.
  logical,      intent(in), optional :: omit_required !< Passed only to name the case.
  character(*), intent(in), optional :: color         !< Color of the errors.
  character(*), intent(in), optional :: usage         !< init(usage_on_error=).
  type(command_line_interface)       :: cli           !< Command Line Interface (CLI).
  integer(I4P)                       :: error         !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun, error_format='json', error_color=color, usage_on_error=usage)
  call cli%add(switch='--steps', help='s', required=.true., val_type='I4P', error=error)
  call cli%add(switch='--choice', help='c', required=.false., def='a', choices='a,b', val_type='character', error=error)
  call cli%add(switch='--range', help='r', required=.false., def='1', min='0', max='5', val_type='I4P', error=error)
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected, message)
  text = read_back(lun)
  call one_line(message)
  endsubroutine line_of

  subroutine one_line(message)
  !< The capture is one JSON line of an error, with its code.
  character(*), intent(in) :: message !< Description of the check.

  call assert_contains(text, '{"schema_version":1,"level":"error","code":', message//': a JSON line')
  call assert_contains(text, ',"message":"prog: error', message//': the message')
  call assert(index(text, '}') > 0, message//': closed')
  call assert(index(trim(text(:len(text)-1)), new_line('a')) == 0, message//': one line, not '//text)
  endsubroutine one_line

  subroutine assert_line(piece, message)
  !< A piece of the last line.
  character(*), intent(in) :: piece   !< Expected piece.
  character(*), intent(in) :: message !< Description of the check.

  call assert_contains(text, piece, message)
  endsubroutine assert_line

  subroutine check_deprecated
  !< T3.5 a warning line, then an error line: each is JSON.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun, error_format='json')
  call cli%add(switch='--old', help='o', required=.false., def='1', deprecated='use new', error=error)
  call cli%add(switch='--need', help='n', required=.true., error=error)
  call cli%parse(args='--old 2', error=error)
  call assert_equal(error, ERROR_MISSING_REQUIRED, 'T3.5 error')
  text = read_back(lun)
  call assert_contains(text, '{"schema_version":1,"level":"warning","message":"prog: warning: option '//BS//'"--old'//BS//'" is '//&
                       'deprecated: use new"}'//new_line('a')//'{"schema_version":1,"level":"error"', 'T3.5 the two lines')
  endsubroutine check_deprecated

  subroutine check_get
  !< T3.6 an error raised in get.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: v     !< Value.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun, error_format='json')
  call cli%add(switch='--n', help='n', required=.false., def='1', error=error)
  call cli%parse(args='--n abc', error=error)
  call assert_equal(error, 0_I4P, 'T3.6 parse')
  call cli%get(switch='--n', val=v, error=error)
  call assert_equal(error, ERROR_CASTING_NUMBER, 'T3.6 get')
  text = read_back(lun)
  call one_line('T3.6')
  endsubroutine check_get

  subroutine check_invalid
  !< T3.8 an invalid format, reported in text.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun, error_format='yaml')
  call cli%parse(args='', error=error)
  call assert_equal(error, ERROR_FORMAT, 'T3.8 error')
  call assert_contains(read_back(lun), 'invalid error_format "yaml"', 'T3.8 message')
  endsubroutine check_invalid

  subroutine check_message
  !< T3.10 cli%error_message is the plain message.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun, error_format='json')
  call cli%add(switch='--need', help='n', required=.true., error=error)
  call cli%parse(args='', error=error)
  call assert(cli%error_message(1:1) /= '{', 'T3.10 not JSON')
  call assert_contains(cli%error_message, 'prog: error', 'T3.10 plain')
  text = read_back(lun)
  endsubroutine check_message

  subroutine check_text
  !< T3.11 the text format: message, blank line, hint.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--steps', help='s', required=.false., def='1', error=error)
  call cli%parse(args='--stepz 1', error=error)
  call assert_equal(error, ERROR_UNKNOWN, 'T3.11 error')
  text = read_back(lun)
  call assert_contains(text, 'prog: error: switch "--stepz" is unknown! Did you mean "--steps"?', 'T3.11 message')
  call assert_contains(text, "Try 'prog --help' for help.", 'T3.11 hint')
  call assert(index(text, '{') == 0, 'T3.11 no JSON')
  endsubroutine check_text

  subroutine check_command
  !< An error in a command.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun, error_format='json')
  call cli%add_group(group='run', help='r')
  call cli%add(group='run', switch='--np', help='n', required=.false., def='1', val_type='I4P', error=error)
  call cli%parse(args='run --np x', error=error)
  call assert_equal(error, ERROR_CASTING_NUMBER, 'a command')
  text = read_back(lun)
  call one_line('a command')
  call assert_line('"argument":"--np"', 'a command: argument')
  endsubroutine check_command

  subroutine child(fmt)
  !< The format chosen by the caller.
  character(*), intent(in)     :: fmt   !< init(error_format=), '' for none.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  if (fmt == '') then
    call cli%init(progname='prog', error_format_env='FLAP_TEST_EJ')
  else
    call cli%init(progname='prog', error_format=fmt, error_format_env='FLAP_TEST_EJ')
  endif
  call cli%add(switch='--x', help='x', required=.false., def='1', error=error)
  call cli%parse(error=error)
  endsubroutine child
endprogram flap_test_error_json

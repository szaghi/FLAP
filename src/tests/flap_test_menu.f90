!< Interactive menus: flap_menu_t, single choice on custom units, defaults, retries, multiple selection (issue #125, steps
!< 5.1-5.5; #78 1.1, 6.1, 2.1, 3.1, 5.1: T0.1, T1.1-T1.8, T6.1-T6.4, T2.1-T2.7, T3.1-T3.7, T5.1-T5.8).
program flap_test_menu
!< Interactive menus: flap_menu_t, single choice on custom units, defaults, retries, multiple selection (issue #125, steps
!< 5.1-5.5; #78 1.1, 6.1, 2.1, 3.1, 5.1: T0.1, T1.1-T1.8, T6.1-T6.4, T2.1-T2.7, T3.1-T3.7, T5.1-T5.8).
!<
!< The menu prints its numbered options and the question, reads one answer line and returns the chosen index. Every case
!< runs in-process on custom units (the answers in a scratch file, output and errors read back from capture units); the
!< default units (stdin, stdout, stderr) are checked in children re-invoked with a real standard input.
use flap, only : menu, ERROR_MENU_DEFINITION, ERROR_MENU_DUPLICATE, ERROR_MENU_EOF, ERROR_MENU_INVALID, &
                 ERROR_MENU_NO_RESPONSE, ERROR_MENU_TOO_MANY
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, read_back, &
                            reinvoke, run_command, scratch_file
use penf, only : I4P, str

implicit none
type(menu)                :: m        !< Menu.
character(:), allocatable :: out      !< Output of the menu, or of a child.
character(:), allocatable :: err      !< Errors of the menu, or of a child.
character(:), allocatable :: lib_dir  !< Directory of the library sources.
character(512)            :: buffer   !< Environment buffer.
integer(I4P)              :: in       !< Input unit (the answers).
integer(I4P)              :: lun      !< Output unit.
integer(I4P)              :: elun     !< Error unit.
integer(I4P)              :: choice   !< Chosen index.
integer(I4P), allocatable :: choices(:) !< Chosen indexes.
integer(I4P)              :: error    !< Error trapping flag.
integer(I4P)              :: exitstat !< Exit status of a child.
integer(I4P)              :: status   !< Retrieval status.
logical                   :: opened   !< Unit still connected.

if (child_case() == 1) then
  ! the default units: the answer from the real standard input, the menu on stdout, the errors on stderr
  call m%init(question='What is your favorite food?')
  call m%add_option(text='Pizza')
  call m%add_option(text='Ice Cream')
  call m%add_option(text='Tacos')
  call m%run(choice, error)
  print '(A)', new_line('a')//'choice='//trim(str(choice, .true.))//' error='//trim(str(error, .true.))
  stop
elseif (child_case() == 2) then
  ! a menu used without init
  call m%add_option(text='x', is_default=.true.)
  call m%add_option(text='y')
  call m%run(choice, error)
  print '(A)', new_line('a')//'choice='//trim(str(choice, .true.))//' error='//trim(str(error, .true.))
  stop
endif

call capture_open(lun)
call capture_open(elun)

! T1.5: the layout: the numbered options, then the question on the line the answer is typed on
call ask('2', choice, error)
out = read_back(lun)
call assert_equal(out, '1) Pizza'//new_line('a')//'2) Ice Cream'//new_line('a')//'3) Tacos'//new_line('a')// &
                  'What is your favorite food? '//new_line('a'), 'T1.5 layout')
! T1.1: the chosen index
call assert_equal(error, 0_I4P, 'T1.1 error')
call assert_equal(choice, 2_I4P, 'T1.1 choice')
call assert_equal(read_back(elun), '', 'T1.1 no error message')
! T1.2: blanks around the answer
call ask(' 3 ', choice, error)
call assert_equal(error, 0_I4P, 'T1.2 error')
call assert_equal(choice, 3_I4P, 'T1.2 choice')
call ask('02', choice, error)
call assert_equal(choice, 2_I4P, 'leading zeros')
out = read_back(lun)
! T1.3, T1.4: out of range, not a number
call check_invalid('0', 'T1.3 0')
call check_invalid('4', 'T1.3 4')
call check_invalid('2a', 'T1.4 2a')
call check_invalid('-1', 'T1.4 -1')
call check_invalid('1.0', 'T1.4 1.0')
! T5.5: several answers in single-choice mode: too many (checked before the numbers)
call ask('1 2', choice, error)
call assert_equal(error, ERROR_MENU_TOO_MANY, 'T5.5 1 2: too many')
call assert_equal(choice, 0_I4P, 'T5.5 choice 0')
call assert_contains(read_back(elun), 'too many responses: 1 2', 'T5.5 message')
call ask('x y', choice, error)
call assert_equal(error, ERROR_MENU_TOO_MANY, 'T5.5 x y: too many before invalid')
out = read_back(elun)
out = read_back(lun)
call check_invalid('99999999999999999999', 'too large for an integer')
! T1.8: a long answer is read whole (then rejected)
call check_invalid(repeat('1', 1999)//'x', 'T1.8 2000 characters')
! an empty answer, no default
call ask('', choice, error)
call assert_equal(error, ERROR_MENU_NO_RESPONSE, 'empty answer: no response')
call assert_equal(choice, 0_I4P, 'empty answer: choice 0')
call assert_contains(read_back(elun), 'no response', 'empty answer: message')
call ask('   ', choice, error)
call assert_equal(error, ERROR_MENU_NO_RESPONSE, 'blank answer: no response')
out = read_back(elun)
out = read_back(lun)
! end of input: never an answer (batch jobs, stdin from /dev/null)
call answers('', in, line_end=.false.)
call food(in)
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_EOF, 'end of input')
call assert_equal(choice, 0_I4P, 'end of input: choice 0')
call assert_contains(read_back(elun), 'end of input', 'end of input: message')
close(in, status='delete')
! a last answer without a line end is an answer
call answers('3', in, line_end=.false.)
call food(in)
call m%run(choice, error)
call assert_equal(error, 0_I4P, 'last line without a line end: error')
call assert_equal(choice, 3_I4P, 'last line without a line end')
close(in, status='delete')
! one menu, several runs: the options are kept, the next line is read
call answers('1'//new_line('a')//'3', in)
call food(in)
call m%run(choice, error)
call assert_equal(choice, 1_I4P, 'first run')
call m%run(choice, error)
call assert_equal(choice, 3_I4P, 'second run')
close(in, status='delete')
out = read_back(lun)
! T1.6: no options
call answers('1', in)
call m%init(question='Pick', input_unit=in, output_unit=lun, error_unit=elun)
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_DEFINITION, 'T1.6 no options')
call assert_equal(choice, 0_I4P, 'T1.6 choice 0')
call assert_contains(read_back(elun), 'no options', 'T1.6 message')
! T1.7: an empty option text
call m%add_option(text='', error=error)
call assert_equal(error, ERROR_MENU_DEFINITION, 'T1.7 empty text')
call m%add_option(text='  ', error=error)
call assert_equal(error, ERROR_MENU_DEFINITION, 'T1.7 blank text')
call assert_contains(read_back(elun), 'empty option', 'T1.7 message')
call m%add_option(text='only', error=error)
call assert_equal(error, 0_I4P, 'a valid option after an invalid one')
call m%run(choice, error)
call assert_equal(choice, 1_I4P, 'the invalid options were not added')
! init starts afresh: the options are dropped
call m%init(question='Pick', input_unit=in, output_unit=lun, error_unit=elun)
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_DEFINITION, 'init drops the options')
close(in, status='delete')
out = read_back(elun)
out = read_back(lun)
! T6.3: output and errors on different units, each with its own lines
call ask('7', choice, error)
out = read_back(lun)
err = read_back(elun)
call assert(index(out, 'invalid') == 0, 'T6.3 no error on the output unit')
call assert(index(err, 'Pizza') == 0, 'T6.3 no option on the error unit')
call assert_contains(err, 'invalid response: 7', 'T6.3 the error on the error unit')
! T6.4: the menu never closes the units
call answers('1', in)
call food(in)
call m%run(choice, error)
inquire(unit=in, opened=opened)
call assert(opened, 'T6.4 input unit still open')
inquire(unit=lun, opened=opened)
call assert(opened, 'T6.4 output unit still open')
call m%free
inquire(unit=in, opened=opened)
call assert(opened, 'T6.4 free keeps the input unit open')
close(in, status='delete')
out = read_back(lun)
! T6.1: the default units: the answer from the real standard input, the menu on standard output
call reinvoke(1_I4P, exitstat, out, err, stdin='2')
call assert_equal(exitstat, 0_I4P, 'T6.1 exit status')
call assert_contains(out, '1) Pizza'//new_line('a')//'2) Ice Cream', 'T6.1 menu on stdout')
call assert_contains(out, 'choice=2 error=0', 'T6.1 the answer read from stdin')
! no terminal (stdin from /dev/null): end of input at once, the message on stderr
call reinvoke(1_I4P, exitstat, out, err)
call assert_contains(out, 'choice=0 error='//trim(str(ERROR_MENU_EOF, .true.)), 'no stdin: end of input')
call assert_contains(err, 'end of input', 'no stdin: message on stderr')
! T2.x: default options (#78 2.1)
! T2.1, T2.6: an empty answer selects the default, marked by the icon ('*' by default)
call ask_default('', choice, error)
call assert_equal(error, 0_I4P, 'T2.1 error')
call assert_equal(choice, 2_I4P, 'T2.1 the default')
call assert_equal(read_back(elun), '', 'T2.1 no error message')
call assert_equal(read_back(lun), '1) Pizza'//new_line('a')//'2) *Ice Cream'//new_line('a')//'3) Tacos'//new_line('a')// &
                  'What is your favorite food? '//new_line('a'), 'T2.6 the default icon')
! T2.2: a blank answer too
call ask_default('   ', choice, error)
call assert_equal(choice, 2_I4P, 'T2.2 blank answer: the default')
! T2.7: an explicit answer wins
call ask_default('3', choice, error)
call assert_equal(choice, 3_I4P, 'T2.7 explicit answer')
call ask_default('9', choice, error)
call assert_equal(error, ERROR_MENU_INVALID, 'an invalid answer is not replaced by the default')
out = read_back(elun)
! T2.6: a custom icon, and no icon
call ask_default('', choice, error, icon='>')
call assert_contains(read_back(lun), '2) >Ice Cream', 'T2.6 custom icon')
call ask_default('', choice, error, icon='')
call assert_contains(read_back(lun), '2) Ice Cream', 'T2.6 empty icon')
call assert_equal(choice, 2_I4P, 'T2.6 empty icon: still the default')
! T2.4: a second default in single-choice mode is a definition error, and is not added
call answers('2', in)
call m%init(question='Pick', input_unit=in, output_unit=lun, error_unit=elun)
call m%add_option(text='a', is_default=.true., error=error)
call assert_equal(error, 0_I4P, 'T2.4 first default')
call m%add_option(text='b', is_default=.true., error=error)
call assert_equal(error, ERROR_MENU_DEFINITION, 'T2.4 second default')
call assert_contains(read_back(elun), 'default', 'T2.4 message')
call m%add_option(text='c', is_default=.false., error=error)
call assert_equal(error, 0_I4P, 'T2.4 a non-default option after it')
call m%run(choice, error)
call assert_equal(choice, 2_I4P, 'T2.4 the second default was not added: 2 is c')
call assert_contains(read_back(lun), '2) c', 'T2.4 c is the second option')
close(in, status='delete')
! a menu used without init: no question, the '*' icon, the default units
call reinvoke(2_I4P, exitstat, out, err, stdin='')
call assert_equal(exitstat, 0_I4P, 'without init: exit status')
call assert_contains(out, '1) *x'//new_line('a')//'2) y'//new_line('a')//' ', 'without init: the menu')
call assert_contains(out, 'choice=1 error=0', 'without init: the default')
! init drops the default (and the icon)
call answers('', in)
call m%init(question='Pick', input_unit=in, output_unit=lun, error_unit=elun)
call m%add_option(text='a', error=error)
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_NO_RESPONSE, 'init drops the default')
close(in, status='delete')
out = read_back(elun)
out = read_back(lun)

! T3.x: retries (#78 3.1)
! T3.1: by default the first invalid answer is returned, the next line is not read
call answers('7'//new_line('a')//'2', in)
call food(in)
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_INVALID, 'T3.1 no retry by default')
call assert_equal(read_back(elun), 'error: invalid response: 7'//new_line('a'), 'T3.1 message without tries')
call m%run(choice, error)
call assert_equal(choice, 2_I4P, 'T3.1 the next line is left for the next run')
close(in, status='delete')
out = read_back(lun)
! T3.2, T3.6, T3.7: loop_on_invalid, tries=3: two invalid answers, then a valid one; the menu shown at each attempt
call answers('7'//new_line('a')//'x'//new_line('a')//'2', in)
call retry_menu(in, tries=3_I4P)
call m%run(choice, error)
call assert_equal(error, 0_I4P, 'T3.2 error')
call assert_equal(choice, 2_I4P, 'T3.2 the valid answer')
call assert_equal(read_back(elun), 'error: invalid response: 7 (2 tries left)'//new_line('a')// &
                                   'error: invalid response: x (1 tries left)'//new_line('a'), 'T3.6 messages')
call assert_equal(count_of(read_back(lun), '1) Pizza'), 3_I4P, 'T3.7 the menu at each attempt')
close(in, status='delete')
! T3.3: tries=2, three invalid answers: the last error after two attempts, the third line left
call answers('7'//new_line('a')//'8'//new_line('a')//'3', in)
call retry_menu(in, tries=2_I4P)
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_INVALID, 'T3.3 the tries exhausted')
call assert_equal(choice, 0_I4P, 'T3.3 choice 0')
call assert_contains(read_back(elun), 'invalid response: 8 (0 tries left)', 'T3.3 the last message')
call m%run(choice, error)
call assert_equal(choice, 3_I4P, 'T3.3 the third line not read')
close(in, status='delete')
out = read_back(lun)
out = read_back(elun)
! an empty answer without a default is retried too; the last error is the last one
call answers(new_line('a')//'9', in)
call retry_menu(in, tries=2_I4P)
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_INVALID, 'the last error is returned')
call assert_contains(read_back(elun), 'no response (1 tries left)', 'no response retried')
close(in, status='delete')
call answers('9', in)
call retry_menu(in, tries=2_I4P)
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_EOF, 'T3.5 an invalid answer, then the end of input')
close(in, status='delete')
out = read_back(elun)
! T3.5: the end of input is never retried
call answers('9', in)
call retry_menu(in, tries=5_I4P)
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_EOF, 'T3.5 end of input, not a retry loop')
err = read_back(elun)
call assert_contains(err, 'invalid response: 9 (4 tries left)', 'T3.5 the invalid answer')
call assert_contains(err, 'end of input', 'T3.5 then the end of input')
call assert_equal(count_of(err, 'error:'), 2_I4P, 'T3.5 two messages only')
close(in, status='delete')
out = read_back(lun)
! T3.4: an empty input with retries: the end of input at once
call answers('', in, line_end=.false.)
call retry_menu(in, tries=3_I4P)
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_EOF, 'T3.4 empty input')
call assert_equal(count_of(read_back(lun), '1) Pizza'), 1_I4P, 'T3.4 the menu shown once')
close(in, status='delete')
out = read_back(elun)
! tries without loop_on_invalid: no retry; tries below 1: a definition error, the default (3) kept
call answers('7'//new_line('a')//'2', in)
call m%init(question='Pick', tries=5_I4P, input_unit=in, output_unit=lun, error_unit=elun)
call m%add_option(text='a')
call m%add_option(text='b')
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_INVALID, 'tries alone: no retry')
close(in, status='delete')
call answers('7'//new_line('a')//'8'//new_line('a')//'9'//new_line('a')//'2', in)
call m%init(question='Pick', loop_on_invalid=.true., tries=0_I4P, input_unit=in, output_unit=lun, error_unit=elun, &
            error=error)
call assert_equal(error, ERROR_MENU_DEFINITION, 'tries=0: definition error')
call assert_contains(read_back(elun), 'tries', 'tries=0: message')
call m%add_option(text='a')
call m%add_option(text='b')
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_INVALID, 'tries=0: the default 3 tries')
call m%run(choice, error)
call assert_equal(choice, 2_I4P, 'tries=0: three lines read')
close(in, status='delete')
out = read_back(lun)
out = read_back(elun)

! T5.x: multiple selection (#78 5.1)
! (each case checks its choices inside check_multiple, on a local: nvfortran 26.5 loses the reallocation of an array passed
! back through several call sites, as the class(*) caller bug of CLAUDE.md)
! T5.1, T5.2, T5.8: blank separated, runs of blanks as one, in the order typed
call check_multiple('1 3', 0_I4P, [1_I4P, 3_I4P], 'T5.1 1 3')
call check_multiple('  1   3  ', 0_I4P, [1_I4P, 3_I4P], 'T5.2 runs of blanks')
call check_multiple('3 1', 0_I4P, [3_I4P, 1_I4P], 'T5.8 order kept')
call check_multiple('2', 0_I4P, [2_I4P], 'one answer')
! T5.3: another separator splits exactly, fields trimmed; an empty field is invalid
call check_multiple('1,3', 0_I4P, [1_I4P, 3_I4P], 'T5.3 1,3', separator=',')
call check_multiple(' 1 , 3 ', 0_I4P, [1_I4P, 3_I4P], 'T5.3 1 , 3', separator=',')
call check_multiple('1,,3', ERROR_MENU_INVALID, what='T5.3 1,,3', separator=',')
call check_multiple('1,3,', ERROR_MENU_INVALID, what='T5.3 a trailing separator', separator=',')
call check_multiple('1 3', ERROR_MENU_INVALID, what='T5.3 blanks are not the separator', separator=',')
call check_multiple('1;;3', 0_I4P, [1_I4P, 3_I4P], 'a separator of two characters', separator=';;')
out = read_back(elun)
call check_multiple('1 4', ERROR_MENU_INVALID, what='an invalid field')
call assert_contains(read_back(elun), 'invalid response: 1 4', 'the whole answer in the message')
! T5.4: a repeated index
call check_multiple('2 2', ERROR_MENU_DUPLICATE, what='T5.4 duplicate')
call assert_contains(read_back(elun), 'duplicate response: 2 2', 'T5.4 message')
call check_multiple('2 02', ERROR_MENU_DUPLICATE, what='T5.4 the same number written twice')
out = read_back(lun)
! T2.5: several defaults in multiple mode, all returned by an empty answer
call check_multiple('', 0_I4P, [1_I4P, 3_I4P], 'T2.5 the defaults', defaults=.true.)
call assert_contains(read_back(lun), '1) *Pizza'//new_line('a')//'2) Ice Cream'//new_line('a')//'3) *Tacos', 'T2.5 icons')
call check_multiple('2', 0_I4P, [2_I4P], 'T2.5 an explicit answer wins', defaults=.true.)
call check_multiple('', ERROR_MENU_NO_RESPONSE, what='multiple, no default: no response')
out = read_back(elun)
! T5.6: the scalar run on a multiple menu
call answers('1', in)
call m%init(question='Pick', multiple=.true., input_unit=in, output_unit=lun, error_unit=elun)
call m%add_option(text='a')
call m%run(choice, error)
call assert_equal(error, ERROR_MENU_DEFINITION, 'T5.6 scalar run on a multiple menu')
call assert_contains(read_back(elun), 'run(choices)', 'T5.6 message')
call m%run(choices, error)
call assert_equal(choices, [1_I4P], 'T5.6 the line was not read')
close(in, status='delete')
! T5.7: the array run on a single-choice menu: one element; several are too many
call answers('2'//new_line('a')//'1 2', in)
call food(in)
call m%run(choices, error)
call assert_equal(error, 0_I4P, 'T5.7 error')
call assert_equal(choices, [2_I4P], 'T5.7 size 1')
call m%run(choices, error)
call assert_equal(error, ERROR_MENU_TOO_MANY, 'T5.7 too many')
close(in, status='delete')
! an empty separator is a definition error, the blank kept
call answers('1 2', in)
call m%init(question='Pick', multiple=.true., separator='', input_unit=in, output_unit=lun, error_unit=elun, error=error)
call assert_equal(error, ERROR_MENU_DEFINITION, 'empty separator')
call m%add_option(text='a')
call m%add_option(text='b')
call m%run(choices, error)
call assert_equal(choices, [1_I4P, 2_I4P], 'empty separator: the blank kept')
close(in, status='delete')
! retries cover the new errors
call answers('2 2'//new_line('a')//'1 3', in)
call m%init(question='Pick', multiple=.true., loop_on_invalid=.true., input_unit=in, output_unit=lun, error_unit=elun)
call m%add_option(text='a')
call m%add_option(text='b')
call m%add_option(text='c')
call m%run(choices, error)
call assert_equal(choices, [1_I4P, 3_I4P], 'a duplicate retried')
call assert_contains(read_back(elun), 'duplicate response: 2 2 (2 tries left)', 'a duplicate retried: message')
close(in, status='delete')
out = read_back(lun)
out = read_back(elun)

! T0.1: the parser never uses the menu module
lib_dir = 'src/lib'
call get_environment_variable('FLAP_TEST_LIB_DIR', value=buffer, status=status)
if (status == 0) lib_dir = trim(buffer)
call run_command("{ ls '"//lib_dir//"'/flap_menu_t.F90 && grep -li 'flap_menu_t' '"//lib_dir//"'/flap_command_line_* ; true ; }", &
                 exitstat, out)
call assert_contains(out, 'flap_menu_t.F90', 'T0.1 the library directory')
call assert(index(out, 'flap_command_line') == 0, 'T0.1 the parser does not use flap_menu_t: '//out)
call capture_close(lun)
call capture_close(elun)

contains
  subroutine food(input_unit)
  !< The menu of the examples, three options, on the capture units.
  integer(I4P), intent(in) :: input_unit !< Input unit.
  integer(I4P)             :: e          !< Error trapping flag.

  call m%init(question='What is your favorite food?', input_unit=input_unit, output_unit=lun, error_unit=elun)
  call m%add_option(text='Pizza', error=e)
  call assert_equal(e, 0_I4P, 'add Pizza')
  call m%add_option(text='Ice Cream', error=e)
  call m%add_option(text='Tacos', error=e)
  endsubroutine food

  subroutine check_multiple(answer, expected_error, expected, what, separator, defaults)
  !< Run the food menu with multiple selection on one answer and check the error and the choices (absent: none, as on
  !< error); with defaults, Pizza and Tacos are the defaults.
  character(*), intent(in)           :: answer         !< Answer line.
  integer(I4P), intent(in)           :: expected_error !< Expected error.
  integer(I4P), intent(in), optional :: expected(:)    !< Expected choices (default: none).
  character(*), intent(in)           :: what           !< Case.
  character(*), intent(in), optional :: separator      !< Separator.
  logical,      intent(in), optional :: defaults       !< Pizza and Tacos are defaults.
  integer(I4P), allocatable          :: got(:)         !< Chosen indexes.
  integer(I4P)                       :: u              !< Input unit.
  integer(I4P)                       :: e              !< Error trapping flag.
  logical                            :: d              !< Defaults, local variable.

  d = .false. ; if (present(defaults)) d = defaults
  call answers(answer, u)
  if (present(separator)) then
    call m%init(question='What do you like?', multiple=.true., separator=separator, input_unit=u, output_unit=lun, &
                error_unit=elun, error=e)
  else
    call m%init(question='What do you like?', multiple=.true., input_unit=u, output_unit=lun, error_unit=elun, error=e)
  endif
  call assert_equal(e, 0_I4P, what//': init')
  call m%add_option(text='Pizza', is_default=d, error=e)
  call m%add_option(text='Ice Cream', error=e)
  call m%add_option(text='Tacos', is_default=d, error=e)
  call assert_equal(e, 0_I4P, what//': a second default')
  call m%run(got, e)
  close(u, status='delete')
  call assert_equal(e, expected_error, what//': error')
  call assert(allocated(got), what//': choices allocated')
  if (present(expected)) then
    call assert_equal(got, expected, what//': choices')
  else
    call assert_equal(size(got, dim=1), 0_I4P, what//': no choices')
  endif
  endsubroutine check_multiple

  subroutine retry_menu(input_unit, tries)
  !< The food menu, retrying invalid answers.
  integer(I4P), intent(in) :: input_unit !< Input unit.
  integer(I4P), intent(in) :: tries      !< Attempts in total.
  integer(I4P)             :: e          !< Error trapping flag.

  call m%init(question='What is your favorite food?', loop_on_invalid=.true., tries=tries, input_unit=input_unit, &
              output_unit=lun, error_unit=elun, error=e)
  call assert_equal(e, 0_I4P, 'init with retries')
  call m%add_option(text='Pizza')
  call m%add_option(text='Ice Cream')
  call m%add_option(text='Tacos')
  endsubroutine retry_menu

  function count_of(text, what) result(n)
  !< Number of occurrences of a substring.
  character(*), intent(in) :: text !< Text.
  character(*), intent(in) :: what !< Substring.
  integer(I4P)             :: n    !< Occurrences.
  integer(I4P)             :: p    !< Position.
  integer(I4P)             :: i    !< Found position.

  n = 0
  p = 1
  do
    i = index(text(p:), what)
    if (i == 0) exit
    n = n + 1
    p = p + i + len(what) - 1
  enddo
  endfunction count_of

  subroutine ask_default(answer, choice, error, icon)
  !< Run the food menu, Ice Cream the default, on one answer.
  character(*), intent(in)           :: answer !< Answer line.
  integer(I4P), intent(out)          :: choice !< Chosen index.
  integer(I4P), intent(out)          :: error  !< Error trapping flag.
  character(*), intent(in), optional :: icon   !< Default icon.
  integer(I4P)                       :: u      !< Input unit.
  integer(I4P)                       :: e      !< Error trapping flag.

  call answers(answer, u)
  if (present(icon)) then
    call m%init(question='What is your favorite food?', default_icon=icon, input_unit=u, output_unit=lun, error_unit=elun)
  else
    call m%init(question='What is your favorite food?', input_unit=u, output_unit=lun, error_unit=elun)
  endif
  call m%add_option(text='Pizza', error=e)
  call m%add_option(text='Ice Cream', is_default=.true., error=e)
  call assert_equal(e, 0_I4P, 'add the default')
  call m%add_option(text='Tacos', error=e)
  call m%run(choice, error)
  close(u, status='delete')
  endsubroutine ask_default

  subroutine answers(text, in, line_end)
  !< Write the answers to a scratch file and open it for reading; without line_end, the last line has no line end.
  character(*), intent(in)           :: text     !< Answers, one per line.
  integer(I4P), intent(out)          :: in       !< Input unit.
  logical,      intent(in), optional :: line_end !< End the last line (default).
  character(:), allocatable          :: file     !< Scratch file.
  logical                            :: line_end_ !< End the last line, local variable.

  line_end_ = .true. ; if (present(line_end)) line_end_ = line_end
  file = scratch_file('answers')
  open(newunit=in, file=file, action='write', status='replace', access='stream', form='unformatted')
  if (line_end_) then
    write(in) text//new_line('a')
  else
    write(in) text
  endif
  close(in)
  open(newunit=in, file=file, action='read', status='old')
  endsubroutine answers

  subroutine ask(answer, choice, error)
  !< Run the food menu on one answer.
  character(*), intent(in)  :: answer !< Answer line.
  integer(I4P), intent(out) :: choice !< Chosen index.
  integer(I4P), intent(out) :: error  !< Error trapping flag.
  integer(I4P)              :: u      !< Input unit.

  call answers(answer, u)
  call food(u)
  call m%run(choice, error)
  close(u, status='delete')
  endsubroutine ask

  subroutine check_invalid(answer, what)
  !< An invalid answer: the error, choice 0, the whole answer in the message.
  character(*), intent(in) :: answer !< Answer line.
  character(*), intent(in) :: what   !< Case.
  integer(I4P)             :: c      !< Chosen index.
  integer(I4P)             :: e      !< Error trapping flag.

  call ask(answer, c, e)
  call assert_equal(e, ERROR_MENU_INVALID, what//': invalid')
  call assert_equal(c, 0_I4P, what//': choice 0')
  call assert_contains(read_back(elun), 'invalid response: '//trim(adjustl(answer)), what//': message')
  out = read_back(lun)
  endsubroutine check_invalid
endprogram flap_test_menu

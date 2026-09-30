!< Interactive menus: flap_menu_t, single choice on custom units (issue #125, step 5.1; #78 1.1 and 6.1, T0.1, T1.1-T1.8,
!< T6.1-T6.4).
program flap_test_menu
!< Interactive menus: flap_menu_t, single choice on custom units (issue #125, step 5.1; #78 1.1 and 6.1, T0.1, T1.1-T1.8,
!< T6.1-T6.4).
!<
!< The menu prints its numbered options and the question, reads one answer line and returns the chosen index. Every case
!< runs in-process on custom units (the answers in a scratch file, output and errors read back from capture units); the
!< default units (stdin, stdout, stderr) are checked in children re-invoked with a real standard input.
use flap, only : menu, ERROR_MENU_DEFINITION, ERROR_MENU_EOF, ERROR_MENU_INVALID, ERROR_MENU_NO_RESPONSE
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
call check_invalid('1 2', 'several answers')
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

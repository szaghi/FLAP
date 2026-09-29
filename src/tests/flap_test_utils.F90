!< Utilities for FLAP test programs: assertions, output capture and self re-invocation.
module flap_test_utils
!< Utilities for FLAP test programs: assertions, output capture and self re-invocation.
!<
!< Assertions end the program with `error stop 1` on failure, so a failed check always gives a non-zero exit status.
!<
!< Output capture: pass the unit returned by `capture_open` as `usage_lun`/`error_lun`/`version_lun` to `cli%init`, then
!< `read_back` the text written to it.
!<
!< Self re-invocation: `reinvoke` runs the calling program again in a child process with `FLAP_TEST_CASE` set, so the child
!< knows (via `child_case`) which scenario to run. This is how a test exercises environment variables, standard input, exit
!< statuses and the paths that end the program (`--help`, `--version`). It requires a POSIX `sh` and `env`.
use, intrinsic :: iso_fortran_env, only : error_unit
use penf, only : I4P, R8P

implicit none
private
public :: assert
public :: assert_contains
public :: assert_equal
public :: capture_close
public :: capture_open
public :: child_case
public :: read_back
public :: read_file
public :: reinvoke

character(*), parameter :: CASE_ENV = 'FLAP_TEST_CASE' !< Environment variable selecting the child scenario.

interface assert_equal
  !< Assert that an actual value equals the expected one.
  module procedure assert_equal_character, assert_equal_logical, assert_equal_I4P, assert_equal_R8P, &
                   assert_equal_I4P_1d, assert_equal_R8P_1d
endinterface assert_equal

contains
  ! assertions
  subroutine assert(condition, message)
  !< Assert that a condition holds.
  logical,      intent(in) :: condition !< Condition to check.
  character(*), intent(in) :: message   !< Description of the check.

  if (.not.condition) call fail(message)
  endsubroutine assert

  subroutine assert_contains(text, substring, message)
  !< Assert that a text contains a substring.
  character(*), intent(in) :: text      !< Text to search.
  character(*), intent(in) :: substring !< Substring expected in the text.
  character(*), intent(in) :: message   !< Description of the check.

  if (index(text, substring) == 0) call fail(message//': "'//substring//'" not found in:'//new_line('a')//text)
  endsubroutine assert_contains

  subroutine assert_equal_character(actual, expected, message)
  !< Assert that two strings are equal (Fortran comparison: trailing blanks are not significant).
  character(*), intent(in) :: actual   !< Actual value.
  character(*), intent(in) :: expected !< Expected value.
  character(*), intent(in) :: message  !< Description of the check.

  if (actual /= expected) call fail(message//': expected ['//expected//'], got ['//actual//']')
  endsubroutine assert_equal_character

  subroutine assert_equal_logical(actual, expected, message)
  !< Assert that two logicals are equal.
  logical,      intent(in) :: actual   !< Actual value.
  logical,      intent(in) :: expected !< Expected value.
  character(*), intent(in) :: message  !< Description of the check.

  if (actual .neqv. expected) call fail(message//': expected '//logical_to_string(expected)//', got '// &
                                        logical_to_string(actual))
  endsubroutine assert_equal_logical

  subroutine assert_equal_I4P(actual, expected, message)
  !< Assert that two integers are equal.
  integer(I4P), intent(in) :: actual   !< Actual value.
  integer(I4P), intent(in) :: expected !< Expected value.
  character(*), intent(in) :: message  !< Description of the check.

  if (actual /= expected) call fail(message//': expected '//integer_to_string(expected)//', got '//integer_to_string(actual))
  endsubroutine assert_equal_I4P

  subroutine assert_equal_R8P(actual, expected, message, tol)
  !< Assert that two reals are equal, exactly or within an absolute tolerance.
  real(R8P),           intent(in) :: actual   !< Actual value.
  real(R8P),           intent(in) :: expected !< Expected value.
  character(*),        intent(in) :: message  !< Description of the check.
  real(R8P), optional, intent(in) :: tol      !< Absolute tolerance (default: exact comparison).

  if (.not.reals_match(actual, expected, tol)) &
    call fail(message//': expected '//real_to_string(expected)//', got '//real_to_string(actual))
  endsubroutine assert_equal_R8P

  subroutine assert_equal_I4P_1d(actual, expected, message)
  !< Assert that two integer arrays are equal.
  integer(I4P), intent(in) :: actual(:)   !< Actual values.
  integer(I4P), intent(in) :: expected(:) !< Expected values.
  character(*), intent(in) :: message     !< Description of the check.
  integer(I4P)             :: i           !< Counter.

  call assert_equal_I4P(size(actual, kind=I4P), size(expected, kind=I4P), message//' (size)')
  do i = 1, size(expected, kind=I4P)
    call assert_equal_I4P(actual(i), expected(i), message//' (element '//integer_to_string(i)//')')
  enddo
  endsubroutine assert_equal_I4P_1d

  subroutine assert_equal_R8P_1d(actual, expected, message, tol)
  !< Assert that two real arrays are equal, exactly or within an absolute tolerance.
  real(R8P),           intent(in) :: actual(:)   !< Actual values.
  real(R8P),           intent(in) :: expected(:) !< Expected values.
  character(*),        intent(in) :: message     !< Description of the check.
  real(R8P), optional, intent(in) :: tol         !< Absolute tolerance (default: exact comparison).
  integer(I4P)                    :: i           !< Counter.

  call assert_equal_I4P(size(actual, kind=I4P), size(expected, kind=I4P), message//' (size)')
  do i = 1, size(expected, kind=I4P)
    call assert_equal_R8P(actual(i), expected(i), message//' (element '//integer_to_string(i)//')', tol)
  enddo
  endsubroutine assert_equal_R8P_1d

  ! output capture
  subroutine capture_open(lun)
  !< Open a scratch unit to capture output.
  integer(I4P), intent(out) :: lun    !< Capture unit.
  integer(I4P)              :: iostat !< I/O status.
  character(256)            :: iomsg  !< I/O message.

  iomsg = ''
  open(newunit=lun, status='scratch', action='readwrite', form='formatted', iostat=iostat, iomsg=iomsg)
  if (iostat /= 0) call fail('capture_open: '//trim(iomsg))
  endsubroutine capture_open

  function read_back(lun) result(text)
  !< Return the text written to a capture unit so far, then empty the unit: the next capture starts from scratch.
  integer(I4P), intent(in)  :: lun  !< Capture unit.
  character(:), allocatable :: text !< Captured text, one `new_line` after each line.

  rewind(lun)
  text = read_all(lun)
  rewind(lun)
  endfile(lun) ! truncate: the endfile record written at the beginning empties the file
  rewind(lun)
  endfunction read_back

  subroutine capture_close(lun)
  !< Close (and delete) a capture unit.
  integer(I4P), intent(in) :: lun !< Capture unit.

  close(lun)
  endsubroutine capture_close

  function read_file(path) result(text)
  !< Return the whole content of a text file.
  character(*), intent(in)  :: path   !< File path.
  character(:), allocatable :: text   !< File content, one `new_line` after each line.
  integer(I4P)              :: lun    !< File unit.
  integer(I4P)              :: iostat !< I/O status.
  character(256)            :: iomsg  !< I/O message.

  iomsg = ''
  open(newunit=lun, file=path, status='old', action='read', form='formatted', iostat=iostat, iomsg=iomsg)
  if (iostat /= 0) call fail('read_file: cannot open "'//path//'": '//trim(iomsg))
  text = read_all(lun)
  close(lun)
  endfunction read_file

  ! self re-invocation
  function child_case() result(case)
  !< Return the scenario requested by `reinvoke`, or 0 when the program was not re-invoked.
  integer(I4P)   :: case   !< Scenario number.
  character(32)  :: buffer !< Value of the environment variable.
  integer(I4P)   :: status !< Retrieval/conversion status.

  case = 0
  call get_environment_variable(CASE_ENV, value=buffer, status=status)
  if (status /= 0) return
  read(buffer, *, iostat=status) case
  if (status /= 0) call fail('child_case: invalid '//CASE_ENV//'="'//trim(buffer)//'"')
  endfunction child_case

  subroutine reinvoke(case, exitstat, out, err, args, env, stdin)
  !< Run the calling program again as a child process executing scenario `case` (read by the child with `child_case`).
  !<
  !< The command line is `env [env] FLAP_TEST_CASE=case 'self' [args] < stdin > out 2> err`, run by `sh`: `args` and `env` are
  !< passed verbatim, so shell quoting is the caller's responsibility. `env` takes `env` operands with options first, e.g.
  !< '-u OLD NEW=value' unsets OLD and sets NEW. Without `stdin` the child reads from `/dev/null`.
  integer(I4P),              intent(in)           :: case     !< Scenario run by the child.
  integer(I4P),              intent(out)          :: exitstat !< Exit status of the child.
  character(:), allocatable, intent(out)          :: out      !< Standard output of the child.
  character(:), allocatable, intent(out)          :: err      !< Standard error of the child.
  character(*),              intent(in), optional :: args     !< Command line arguments for the child.
  character(*),              intent(in), optional :: env      !< Extra `env` operands, options first: '-u OLD NEW=value'.
  character(*),              intent(in), optional :: stdin    !< Standard input for the child.
  character(:), allocatable                       :: self     !< Path of the running program.
  character(:), allocatable                       :: base     !< Base name of the temporary files.
  character(:), allocatable                       :: in_file  !< File used as standard input.
  character(:), allocatable                       :: cmd      !< Shell command.
  integer(I4P)                                    :: length   !< Length of the program path.
  integer(I4P)                                    :: cmdstat  !< Command execution status.
  character(256)                                  :: cmdmsg   !< Command execution message.

  call get_command_argument(0, length=length)
  allocate(character(length) :: self)
  call get_command_argument(0, value=self)
  base = self//'.case'//integer_to_string(case)
  in_file = '/dev/null'
  if (present(stdin)) then
    in_file = base//'.in'
    call write_file(in_file, stdin)
  endif
  cmd = 'env'
  if (present(env)) cmd = cmd//' '//env ! before the assignment below: `env` accepts options (-u) only first
  cmd = cmd//' '//CASE_ENV//'='//integer_to_string(case)//" '"//self//"'"
  if (present(args)) cmd = cmd//' '//args
  cmd = cmd//" < '"//in_file//"' > '"//base//".out' 2> '"//base//".err'"
  cmdmsg = ''
  call execute_command_line(cmd, wait=.true., exitstat=exitstat, cmdstat=cmdstat, cmdmsg=cmdmsg)
  if (cmdstat /= 0) call fail('reinvoke: cannot execute "'//cmd//'": '//trim(cmdmsg))
  out = read_file(base//'.out')
  err = read_file(base//'.err')
  call delete_file(base//'.out')
  call delete_file(base//'.err')
  if (present(stdin)) call delete_file(in_file)
  endsubroutine reinvoke

  ! private helpers
  subroutine fail(message)
  !< Report a failed check and end the program with a non-zero exit status.
  character(*), intent(in) :: message !< Failure description.

  write(error_unit, '(A)') 'FAIL: '//message
  error stop 1
  endsubroutine fail

  function read_all(lun) result(text)
  !< Read a formatted unit from its current position to the end; lines of any length are supported.
  integer(I4P), intent(in)  :: lun    !< Unit to read.
  character(:), allocatable :: text   !< Text read, one `new_line` after each line.
  character(:), allocatable :: line   !< Current line.
  character(256)            :: chunk  !< Chunk of the current line.
  integer(I4P)              :: nread  !< Characters read into the chunk.
  integer(I4P)              :: iostat !< I/O status.

  text = ''
  do
    line = ''
    do
      read(lun, '(A)', advance='no', size=nread, iostat=iostat) chunk
      line = line//chunk(1:nread)
      if (iostat /= 0) exit
    enddo
    if (is_iostat_end(iostat)) then
      if (len(line) > 0) text = text//line//new_line('a') ! last line without a trailing newline
      exit
    endif
    if (.not.is_iostat_eor(iostat)) call fail('read_all: read error, iostat='//integer_to_string(iostat))
    text = text//line//new_line('a')
  enddo
  endfunction read_all

  subroutine write_file(path, text)
  !< Write a text to a new file, replacing any existing one.
  character(*), intent(in) :: path   !< File path.
  character(*), intent(in) :: text   !< Text to write.
  integer(I4P)             :: lun    !< File unit.
  integer(I4P)             :: iostat !< I/O status.
  character(256)           :: iomsg  !< I/O message.

  iomsg = ''
  open(newunit=lun, file=path, status='replace', action='write', form='formatted', iostat=iostat, iomsg=iomsg)
  if (iostat /= 0) call fail('write_file: cannot open "'//path//'": '//trim(iomsg))
  write(lun, '(A)') text
  close(lun)
  endsubroutine write_file

  subroutine delete_file(path)
  !< Delete a file.
  character(*), intent(in) :: path   !< File path.
  integer(I4P)             :: lun    !< File unit.
  integer(I4P)             :: iostat !< I/O status.

  open(newunit=lun, file=path, status='old', iostat=iostat)
  if (iostat == 0) close(lun, status='delete')
  endsubroutine delete_file

  pure function integer_to_string(n) result(string)
  !< Convert an integer to a string without blanks.
  integer(I4P), intent(in)  :: n      !< Integer to convert.
  character(:), allocatable :: string !< Converted integer.
  character(11)             :: buffer !< Conversion buffer.

  write(buffer, '(I0)') n
  string = trim(buffer)
  endfunction integer_to_string

  pure function real_to_string(x) result(string)
  !< Convert a real to a string in scientific notation, with enough digits to tell neighbouring values apart.
  real(R8P),    intent(in)  :: x      !< Real to convert.
  character(:), allocatable :: string !< Converted real.
  character(32)             :: buffer !< Conversion buffer.

  write(buffer, '(ES24.16E3)') x
  string = trim(adjustl(buffer))
  endfunction real_to_string

  pure function logical_to_string(l) result(string)
  !< Convert a logical to '.true.' or '.false.'.
  logical, intent(in)       :: l      !< Logical to convert.
  character(:), allocatable :: string !< Converted logical.

  if (l) then
    string = '.true.'
  else
    string = '.false.'
  endif
  endfunction logical_to_string

  pure function reals_match(actual, expected, tol) result(match)
  !< Compare two reals, exactly or within an absolute tolerance.
  real(R8P),           intent(in) :: actual   !< Actual value.
  real(R8P),           intent(in) :: expected !< Expected value.
  real(R8P), optional, intent(in) :: tol      !< Absolute tolerance (default: exact comparison).
  logical                         :: match    !< Comparison result.

  if (present(tol)) then
    match = abs(actual - expected) <= tol
  else
    match = actual == expected
  endif
  endfunction reals_match
endmodule flap_test_utils

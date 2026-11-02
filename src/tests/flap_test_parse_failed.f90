!< A parse that did not complete is not repeated by a getter: same result, nothing printed again, real command line unread.
program flap_test_parse_failed
!< A parse that did not complete is not repeated by a getter: same result, nothing printed again, real command line unread.
!<
!< This program runs without arguments, so a new parse of the real command line would succeed, or fail in another way. Every
!< get has its own variable (nvfortran, B33).
use flap, only : command_line_interface, ERROR_MISSING_REQUIRED, ERROR_UNKNOWN, SOURCE_COMMANDLINE, STATUS_PRINT_H
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P

implicit none

call check_error
call check_required
call check_status
call check_explicit_parse
call check_get_args
call check_reset
call check_check_json

contains
  subroutine define(cli, lun, error_format, check)
  !< Define a CLI.
  type(command_line_interface), intent(out) :: cli          !< CLI.
  integer(I4P),                 intent(in)  :: lun          !< Capture unit.
  character(*), optional,       intent(in)  :: error_format !< Format of the errors.
  logical,      optional,       intent(in)  :: check        !< Add --check.
  integer(I4P)                              :: error        !< Error trapping flag.

  call cli%init(progname='prog', version='1', error_lun=lun, usage_lun=lun, version_lun=lun, standalone=.false., &
                error_format=error_format, check_option=check)
  call cli%add(switch='--n', help='n', required=.false., act='store', def='7', error=error)
  endsubroutine define

  integer function count_of(text, what) result(n)
  !< Count the occurrences of a text.
  character(*), intent(in) :: text !< Text.
  character(*), intent(in) :: what !< Text searched.
  integer                  :: i    !< Position.
  integer                  :: j    !< Next position.

  n = 0
  i = 1
  do
    j = index(text(i:), what)
    if (j == 0) exit
    n = n + 1
    i = i + j + len(what) - 1
  enddo
  endfunction count_of

  subroutine check_error
  !< The error of a failed parse comes back from every getter, with its message, once on the error unit.
  type(command_line_interface) :: cli     !< CLI.
  integer(I4P)                 :: lun     !< Capture unit.
  integer(I4P)                 :: error   !< Error trapping flag.
  integer(I4P)                 :: n1      !< Value of --n.
  integer(I4P)                 :: n2      !< Value of --n.
  integer(I4P), allocatable    :: list(:) !< Values of --n.
  character(:), allocatable    :: report  !< Provenance.
  character(:), allocatable    :: text    !< Captured text.
  character(:), allocatable    :: message !< Message of the parse.

  call capture_open(lun)
  call define(cli, lun)
  call cli%parse(args='--bogus', error=error)
  call assert_equal(error, ERROR_UNKNOWN, 'the parse fails')
  message = cli%error_message
  n1 = -1
  call cli%get(switch='--n', val=n1, error=error)
  call assert_equal(error, ERROR_UNKNOWN, 'get: the error of the parse')
  call assert_equal(cli%error, ERROR_UNKNOWN, 'get: cli%error')
  call assert_equal(cli%error_message, message, 'get: the message of the parse')
  call assert_equal(n1, -1_I4P, 'get: no value')
  n2 = -1
  call cli%get(switch='--n', val=n2, error=error)
  call assert_equal(error, ERROR_UNKNOWN, 'a second get: the same error')
  call cli%get_varying(switch='--n', val=list, error=error)
  call assert_equal(error, ERROR_UNKNOWN, 'get_varying: the same error')
  report = cli%provenance(format='json')
  call assert_contains(report, '"--bogus"', 'provenance: the command line of the parse')
  call assert_equal(cli%is_parsed(), .false., 'still not parsed')
  text = read_back(lun)
  call assert_equal(int(count_of(text, '--bogus'), I4P), 1_I4P, 'the message is printed once')
  call assert_equal(int(count_of(text, "Try '"), I4P), 1_I4P, 'the hint is printed once')
  call capture_close(lun)
  endsubroutine check_error

  subroutine check_required
  !< Another parse of the real command line would raise another error.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.
  integer(I4P)                 :: n     !< Value of --r.

  call capture_open(lun)
  call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--r', help='r', required=.true., act='store', error=error)
  call cli%parse(args='--r 1 --bogus', error=error)
  call assert_equal(error, ERROR_UNKNOWN, 'required: the parse fails')
  call cli%get(switch='--r', val=n, error=error)
  call assert_equal(error, ERROR_UNKNOWN, 'required: not the missing option of the real command line')
  call assert(error /= ERROR_MISSING_REQUIRED, 'required: not reparsed')
  call capture_close(lun)
  endsubroutine check_required

  subroutine check_status
  !< A status does not repeat its output either, and the values stay readable.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.
  integer(I4P)                 :: n1    !< Value of --n.
  integer(I4P)                 :: n2    !< Value of --n.
  character(:), allocatable    :: text  !< Captured text.

  call capture_open(lun)
  call define(cli, lun)
  call cli%parse(args='--n 3 --help', error=error)
  call assert_equal(error, STATUS_PRINT_H, 'the help is a status')
  call cli%get(switch='--n', val=n1, error=error)
  call assert_equal(error, 0_I4P, 'status: get succeeds')
  call assert_equal(n1, 3_I4P, 'status: the value of the parse')
  call cli%get(switch='--n', val=n2, error=error)
  call assert_equal(n2, 3_I4P, 'status: a second get')
  call assert_equal(cli%get_source(switch='--n'), SOURCE_COMMANDLINE, 'status: the source of the parse')
  text = read_back(lun)
  call assert_equal(int(count_of(text, 'usage:'), I4P), 1_I4P, 'status: the help is printed once')
  call capture_close(lun)
  endsubroutine check_status

  subroutine check_explicit_parse
  !< An explicit parse is obeyed, and its result replaces the kept one.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.
  integer(I4P)                 :: n     !< Value of --n.

  call capture_open(lun)
  call define(cli, lun)
  call cli%parse(args='--bogus', error=error)
  call cli%parse(args='--n 4', error=error)
  call assert_equal(error, 0_I4P, 'an explicit parse runs')
  call cli%get(switch='--n', val=n, error=error)
  call assert_equal(error, 0_I4P, 'explicit parse: get')
  call assert_equal(n, 4_I4P, 'explicit parse: value')
  call capture_close(lun)
  endsubroutine check_explicit_parse

  subroutine check_get_args
  !< A get passing args asks for a parse of that text.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.
  integer(I4P)                 :: n     !< Value of --n.

  call capture_open(lun)
  call define(cli, lun)
  call cli%parse(args='--bogus', error=error)
  call cli%get(switch='--n', val=n, args='--n 5', error=error)
  call assert_equal(error, 0_I4P, 'get(args=) parses')
  call assert_equal(n, 5_I4P, 'get(args=): value')
  call capture_close(lun)
  endsubroutine check_get_args

  subroutine check_reset
  !< reset_parse forgets the kept result: the next get parses the real command line, here empty.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.
  integer(I4P)                 :: n     !< Value of --n.

  call capture_open(lun)
  call define(cli, lun)
  call cli%parse(args='--bogus', error=error)
  call cli%reset_parse
  call cli%get(switch='--n', val=n, error=error)
  call assert_equal(error, 0_I4P, 'reset_parse: get parses again')
  call assert_equal(n, 7_I4P, 'reset_parse: the default')
  call capture_close(lun)
  endsubroutine check_reset

  subroutine check_check_json
  !< A failed --check gives one error line and no other result line after a get.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.
  integer(I4P)                 :: n     !< Value of --n.
  character(:), allocatable    :: text  !< Captured text.

  call capture_open(lun)
  call define(cli, lun, error_format='json', check=.true.)
  call cli%parse(args='--check --bogus', error=error)
  call assert_equal(error, ERROR_UNKNOWN, '--check: the parse fails')
  call cli%get(switch='--n', val=n, error=error)
  call assert_equal(error, ERROR_UNKNOWN, '--check: the error stays')
  text = read_back(lun)
  call assert_equal(int(count_of(text, '"level":"error"'), I4P), 1_I4P, '--check: one error line')
  call assert_equal(int(count_of(text, '"level":"result"'), I4P), 1_I4P, '--check: one result line')
  call capture_close(lun)
  endsubroutine check_check_json
endprogram flap_test_parse_failed

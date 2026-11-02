!< Error classes and exit statuses (issue #129).
program flap_test_exit_status
!< Error classes and exit statuses (issue #129).
use flap, only : command_line_interface, error_class, error_exit_status, ERROR_CASTING_NUMBER, ERROR_MISSING_REQUIRED, &
                 ERROR_PATH_NOT_FOUND, ERROR_UNKNOWN, ERROR_UNKNOWN_CLAS_IGNORED, ERROR_USER, EXIT_APPLICATION, EXIT_DEFINITION, &
                 EXIT_ENVIRONMENT, EXIT_USAGE, STATUS_NO_ARGS, STATUS_PRINT_H
use flap_test_utils, only : assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P

implicit none

call assert_equal(EXIT_APPLICATION, 1_I4P, 'application')
call assert_equal(EXIT_USAGE, 2_I4P, 'usage')
call assert_equal(EXIT_ENVIRONMENT, 3_I4P, 'environment')
call assert_equal(EXIT_DEFINITION, 4_I4P, 'definition')
call assert_equal(error_class(ERROR_UNKNOWN), 'usage', 'class of an unknown switch')
call assert_equal(error_class(ERROR_PATH_NOT_FOUND), 'environment', 'class of a missing path')
call assert_equal(error_class(1_I4P), 'definition', 'class of a definition')
call assert_equal(error_class(ERROR_USER), 'application', 'class of an application error')
call assert_equal(error_class(0_I4P), '', 'no error, no class')
call assert_equal(error_class(STATUS_PRINT_H), '', 'a status, no class')
call assert_equal(error_class(99999_I4P), '', 'an unknown code, no class')
call assert_equal(error_exit_status(0_I4P), 0_I4P, 'success')
call assert_equal(error_exit_status(STATUS_PRINT_H), 0_I4P, 'a status')
call assert_equal(error_exit_status(STATUS_NO_ARGS), 2_I4P, 'no arguments')
call assert_equal(error_exit_status(ERROR_UNKNOWN_CLAS_IGNORED), 0_I4P, 'ignored')
call assert_equal(error_exit_status(ERROR_CASTING_NUMBER), EXIT_USAGE, 'status of a bad value')
call assert_equal(error_exit_status(ERROR_MISSING_REQUIRED), EXIT_USAGE, 'status of a missing option')
call assert_equal(error_exit_status(ERROR_PATH_NOT_FOUND), EXIT_ENVIRONMENT, 'status of a missing path')
call assert_equal(error_exit_status(1_I4P), EXIT_DEFINITION, 'status of a definition')
call assert_equal(error_exit_status(ERROR_USER), EXIT_APPLICATION, 'status of an application error')
call assert_equal(error_exit_status(99999_I4P), EXIT_APPLICATION, 'an unknown code is not a success')
call check_cli

contains
  subroutine check_cli
  !< cli%exit_status follows the current error, and a JSON error carries the class.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call cli%init(progname='prog', error_lun=lun, usage_lun=lun, standalone=.false., error_format='json')
  call cli%add(switch='--n', help='n', required=.false., def='1', error=error)
  call assert_equal(cli%exit_status(), 0_I4P, 'nothing yet')
  call cli%parse(args='--bogus', error=error)
  call assert_equal(cli%exit_status(), EXIT_USAGE, 'after a failed parse')
  call assert_contains(read_back(lun), '"code":15,"class":"usage","message"', 'JSON class')
  call cli%reset_parse
  call cli%parse(args='--n 2', error=error)
  call assert_equal(cli%exit_status(), 0_I4P, 'after a good parse')
  call capture_close(lun)
  endsubroutine check_cli
endprogram flap_test_exit_status

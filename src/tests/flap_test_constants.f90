!< Pin the public codes registry exported by the flap module (issue #125, section 5): existing values never change.
program flap_test_constants
!< Pin the public codes registry exported by the flap module (issue #125, section 5): existing values never change.
use flap, only : command_line_interface,                                                                                          &
                 STATUS_PRINT_V, STATUS_PRINT_H, STATUS_PRINT_M,                                                                  &
                 ERROR_OPTIONAL_NO_DEF, ERROR_REQUIRED_M_EXCLUDE, ERROR_POSITIONAL_M_EXCLUDE, ERROR_NAMED_NO_NAME,                &
                 ERROR_POSITIONAL_NO_POSITION, ERROR_POSITIONAL_NO_STORE, ERROR_NOT_IN_CHOICES, ERROR_MISSING_REQUIRED,           &
                 ERROR_M_EXCLUDE, ERROR_CASTING_LOGICAL, ERROR_CHOICES_LOGICAL, ERROR_NO_LIST, ERROR_NARGS_INSUFFICIENT,          &
                 ERROR_VALUE_MISSING, ERROR_UNKNOWN, ERROR_ENVVAR_POSITIONAL, ERROR_ENVVAR_NOT_STORE, ERROR_ENVVAR_NARGS,         &
                 ERROR_STORE_STAR_POSITIONAL, ERROR_STORE_STAR_NARGS, ERROR_STORE_STAR_ENVVAR, ERROR_ACTION_UNKNOWN,              &
                 ERROR_DUPLICATED_CLAS, ERROR_MISSING_REQUIRED_VAL, ERROR_UNSUPPORTED_TYPE, ERROR_POSITIONAL_NARGS,               &
                 ERROR_LIST_SIZE, ERROR_DEF_NARGS,                                                                                &
                 ERROR_GROUP_CONSISTENCY, ERROR_GROUP_M_EXCLUDE, ERROR_POSITION_DUPLICATE, ERROR_POSITION_GAP,                    &
                 ERROR_MISSING_CLA, ERROR_MISSING_GROUP, ERROR_MISSING_SELECTION_CLA, ERROR_TOO_FEW_CLAS,                         &
                 ERROR_UNKNOWN_CLAS_IGNORED, ERROR_ARGUMENT_RETRIEVAL
use flap_test_utils, only : assert_equal, capture_close, capture_open
use penf, only : I4P

implicit none

call check_values
call check_returned_codes

contains
  subroutine check_values()
  !< Every exported constant keeps its registered value.

  call assert_equal(STATUS_PRINT_V,               -1_I4P,   'STATUS_PRINT_V')
  call assert_equal(STATUS_PRINT_H,               -2_I4P,   'STATUS_PRINT_H')
  call assert_equal(STATUS_PRINT_M,               -3_I4P,   'STATUS_PRINT_M')
  call assert_equal(ERROR_OPTIONAL_NO_DEF,         1_I4P,   'ERROR_OPTIONAL_NO_DEF')
  call assert_equal(ERROR_REQUIRED_M_EXCLUDE,      2_I4P,   'ERROR_REQUIRED_M_EXCLUDE')
  call assert_equal(ERROR_POSITIONAL_M_EXCLUDE,    3_I4P,   'ERROR_POSITIONAL_M_EXCLUDE')
  call assert_equal(ERROR_NAMED_NO_NAME,           4_I4P,   'ERROR_NAMED_NO_NAME')
  call assert_equal(ERROR_POSITIONAL_NO_POSITION,  5_I4P,   'ERROR_POSITIONAL_NO_POSITION')
  call assert_equal(ERROR_POSITIONAL_NO_STORE,     6_I4P,   'ERROR_POSITIONAL_NO_STORE')
  call assert_equal(ERROR_NOT_IN_CHOICES,          7_I4P,   'ERROR_NOT_IN_CHOICES')
  call assert_equal(ERROR_MISSING_REQUIRED,        8_I4P,   'ERROR_MISSING_REQUIRED')
  call assert_equal(ERROR_M_EXCLUDE,               9_I4P,   'ERROR_M_EXCLUDE')
  call assert_equal(ERROR_CASTING_LOGICAL,        10_I4P,   'ERROR_CASTING_LOGICAL')
  call assert_equal(ERROR_CHOICES_LOGICAL,        11_I4P,   'ERROR_CHOICES_LOGICAL')
  call assert_equal(ERROR_NO_LIST,                12_I4P,   'ERROR_NO_LIST')
  call assert_equal(ERROR_NARGS_INSUFFICIENT,     13_I4P,   'ERROR_NARGS_INSUFFICIENT')
  call assert_equal(ERROR_VALUE_MISSING,          14_I4P,   'ERROR_VALUE_MISSING')
  call assert_equal(ERROR_UNKNOWN,                15_I4P,   'ERROR_UNKNOWN')
  call assert_equal(ERROR_ENVVAR_POSITIONAL,      16_I4P,   'ERROR_ENVVAR_POSITIONAL')
  call assert_equal(ERROR_ENVVAR_NOT_STORE,       17_I4P,   'ERROR_ENVVAR_NOT_STORE')
  call assert_equal(ERROR_ENVVAR_NARGS,           18_I4P,   'ERROR_ENVVAR_NARGS')
  call assert_equal(ERROR_STORE_STAR_POSITIONAL,  19_I4P,   'ERROR_STORE_STAR_POSITIONAL')
  call assert_equal(ERROR_STORE_STAR_NARGS,       20_I4P,   'ERROR_STORE_STAR_NARGS')
  call assert_equal(ERROR_STORE_STAR_ENVVAR,      21_I4P,   'ERROR_STORE_STAR_ENVVAR')
  call assert_equal(ERROR_ACTION_UNKNOWN,         22_I4P,   'ERROR_ACTION_UNKNOWN')
  call assert_equal(ERROR_DUPLICATED_CLAS,        23_I4P,   'ERROR_DUPLICATED_CLAS')
  call assert_equal(ERROR_MISSING_REQUIRED_VAL,   24_I4P,   'ERROR_MISSING_REQUIRED_VAL')
  call assert_equal(ERROR_POSITIONAL_NARGS,       45_I4P,   'ERROR_POSITIONAL_NARGS')
  call assert_equal(ERROR_UNSUPPORTED_TYPE,       46_I4P,   'ERROR_UNSUPPORTED_TYPE')
  call assert_equal(ERROR_LIST_SIZE,              47_I4P,   'ERROR_LIST_SIZE')
  call assert_equal(ERROR_DEF_NARGS,              48_I4P,   'ERROR_DEF_NARGS')
  call assert_equal(ERROR_GROUP_CONSISTENCY,     100_I4P,   'ERROR_GROUP_CONSISTENCY')
  call assert_equal(ERROR_GROUP_M_EXCLUDE,       101_I4P,   'ERROR_GROUP_M_EXCLUDE')
  call assert_equal(ERROR_POSITION_DUPLICATE,    105_I4P,   'ERROR_POSITION_DUPLICATE')
  call assert_equal(ERROR_POSITION_GAP,          106_I4P,   'ERROR_POSITION_GAP')
  call assert_equal(ERROR_MISSING_CLA,          1000_I4P,   'ERROR_MISSING_CLA')
  call assert_equal(ERROR_MISSING_GROUP,        1001_I4P,   'ERROR_MISSING_GROUP')
  call assert_equal(ERROR_MISSING_SELECTION_CLA, 1002_I4P,  'ERROR_MISSING_SELECTION_CLA')
  call assert_equal(ERROR_TOO_FEW_CLAS,         1003_I4P,   'ERROR_TOO_FEW_CLAS')
  call assert_equal(ERROR_UNKNOWN_CLAS_IGNORED, 1004_I4P,   'ERROR_UNKNOWN_CLAS_IGNORED')
  call assert_equal(ERROR_ARGUMENT_RETRIEVAL,   1012_I4P,   'ERROR_ARGUMENT_RETRIEVAL')
  endsubroutine check_values

  subroutine check_returned_codes()
  !< The constants are the codes that FLAP actually returns.
  type(command_line_interface) :: cli   !< Command line interface.
  integer(I4P)                 :: lun   !< Capture unit (keeps the expected error messages off stderr).
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call cli%init(progname='flap_test_constants', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--x', help='a value', required=.false., act='store', def='0', error=error)
  call assert_equal(error, 0_I4P, 'add --x')
  call cli%parse(args='--bogus', error=error)
  call assert_equal(error, ERROR_UNKNOWN, 'unknown switch')
  call cli%free

  call cli%init(progname='flap_test_constants', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--x', help='a value', required=.true., act='store', error=error)
  call cli%parse(args='', error=error)
  call assert_equal(error, ERROR_MISSING_REQUIRED, 'missing required option')
  call cli%free

  call cli%init(progname='flap_test_constants', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--x', help='a value', required=.false., act='store', error=error)
  call assert_equal(error, ERROR_OPTIONAL_NO_DEF, 'optional option without default')
  call capture_close(lun)
  endsubroutine check_returned_codes
endprogram flap_test_constants

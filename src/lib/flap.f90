!< FLAP, Fortran command Line Arguments Parser for poor people
module flap
!< FLAP, Fortran command Line Arguments Parser for poor people
!<{!README-FLAP.md!}
use flap_command_line_argument_t, only : command_line_argument,        &
                                         SOURCE_COMMANDLINE,           &
                                         SOURCE_ENVIRONMENT,           &
                                         SOURCE_CONFIG,                &
                                         SOURCE_DEFAULT,               &
                                         SOURCE_NONE,                  &
                                         ERROR_OPTIONAL_NO_DEF,        &
                                         ERROR_REQUIRED_M_EXCLUDE,     &
                                         ERROR_POSITIONAL_M_EXCLUDE,   &
                                         ERROR_NAMED_NO_NAME,          &
                                         ERROR_POSITIONAL_NO_POSITION, &
                                         ERROR_POSITIONAL_NO_STORE,    &
                                         ERROR_NOT_IN_CHOICES,         &
                                         ERROR_MISSING_REQUIRED,       &
                                         ERROR_M_EXCLUDE,              &
                                         ERROR_CASTING_LOGICAL,        &
                                         ERROR_CHOICES_LOGICAL,        &
                                         ERROR_NO_LIST,                &
                                         ERROR_NARGS_INSUFFICIENT,     &
                                         ERROR_VALUE_MISSING,          &
                                         ERROR_UNKNOWN,                &
                                         ERROR_ENVVAR_POSITIONAL,      &
                                         ERROR_ENVVAR_NOT_STORE,       &
                                         ERROR_ENVVAR_NARGS,           &
                                         ERROR_STORE_STAR_POSITIONAL,  &
                                         ERROR_STORE_STAR_NARGS,       &
                                         ERROR_STORE_STAR_ENVVAR,      &
                                         ERROR_ACTION_UNKNOWN,         &
                                         ERROR_DUPLICATED_CLAS,        &
                                         ERROR_MISSING_REQUIRED_VAL,   &
                                         ERROR_UNSUPPORTED_TYPE,       &
                                         ERROR_POSITIONAL_NARGS,       &
                                         ERROR_LIST_SIZE,              &
                                         ERROR_DEF_NARGS,              &
                                         ERROR_INLINE_VALUE_NOT_ALLOWED, &
                                         ERROR_INLINE_VALUE_NARGS,     &
                                         ERROR_COUNT_INCONSISTENT,     &
                                         ERROR_APPEND_INCONSISTENT,    &
                                         ERROR_APPEND_SCALAR_GET
use flap_command_line_arguments_group_t, only : command_line_arguments_group,                 &
                                                STATUS_PRINT_V,                               &
                                                STATUS_PRINT_H,                               &
                                                STATUS_PRINT_M,                               &
                                                STATUS_NO_ARGS,                               &
                                                ERROR_GROUP_CONSISTENCY => ERROR_CONSISTENCY, &
                                                ERROR_GROUP_M_EXCLUDE => ERROR_M_EXCLUDE,     &
                                                ERROR_POSITION_DUPLICATE,                     &
                                                ERROR_POSITION_GAP,                           &
                                                ERROR_M_EXCLUDE_SET,                          &
                                                ERROR_M_EXCLUDE_SET_REQUIRED,                 &
                                                ERROR_M_EXCLUDE_SET_DEFINITION
use flap_command_line_interface_t, only : command_line_interface,      &
                                          ERROR_MISSING_CLA,           &
                                          ERROR_MISSING_GROUP,         &
                                          ERROR_MISSING_SELECTION_CLA, &
                                          ERROR_TOO_FEW_CLAS,          &
                                          ERROR_UNKNOWN_CLAS_IGNORED,  &
                                          ERROR_ARGUMENT_RETRIEVAL,    &
                                          ERROR_USER

implicit none
private
! types
public :: command_line_argument
public :: command_line_arguments_group
public :: command_line_interface
! constants: the single public surface of the codes registry (issue #125, section 5)
! statuses (negative): returned by parse, never errors
public :: STATUS_PRINT_V
public :: STATUS_PRINT_H
public :: STATUS_PRINT_M
public :: STATUS_NO_ARGS
! errors 1-99: command line argument
public :: SOURCE_COMMANDLINE
public :: SOURCE_ENVIRONMENT
public :: SOURCE_CONFIG
public :: SOURCE_DEFAULT
public :: SOURCE_NONE
public :: ERROR_OPTIONAL_NO_DEF
public :: ERROR_REQUIRED_M_EXCLUDE
public :: ERROR_POSITIONAL_M_EXCLUDE
public :: ERROR_NAMED_NO_NAME
public :: ERROR_POSITIONAL_NO_POSITION
public :: ERROR_POSITIONAL_NO_STORE
public :: ERROR_NOT_IN_CHOICES
public :: ERROR_MISSING_REQUIRED
public :: ERROR_M_EXCLUDE
public :: ERROR_CASTING_LOGICAL
public :: ERROR_CHOICES_LOGICAL
public :: ERROR_NO_LIST
public :: ERROR_NARGS_INSUFFICIENT
public :: ERROR_VALUE_MISSING
public :: ERROR_UNKNOWN
public :: ERROR_ENVVAR_POSITIONAL
public :: ERROR_ENVVAR_NOT_STORE
public :: ERROR_ENVVAR_NARGS
public :: ERROR_STORE_STAR_POSITIONAL
public :: ERROR_STORE_STAR_NARGS
public :: ERROR_STORE_STAR_ENVVAR
public :: ERROR_ACTION_UNKNOWN
public :: ERROR_DUPLICATED_CLAS
public :: ERROR_MISSING_REQUIRED_VAL
public :: ERROR_UNSUPPORTED_TYPE
public :: ERROR_POSITIONAL_NARGS
public :: ERROR_LIST_SIZE
public :: ERROR_DEF_NARGS
public :: ERROR_INLINE_VALUE_NOT_ALLOWED
public :: ERROR_INLINE_VALUE_NARGS
public :: ERROR_COUNT_INCONSISTENT
public :: ERROR_APPEND_INCONSISTENT
public :: ERROR_APPEND_SCALAR_GET
! errors 100-199: group (renamed here: the group module's own names clash with the argument ones)
public :: ERROR_GROUP_CONSISTENCY
public :: ERROR_GROUP_M_EXCLUDE
public :: ERROR_POSITION_DUPLICATE
public :: ERROR_POSITION_GAP
public :: ERROR_M_EXCLUDE_SET
public :: ERROR_M_EXCLUDE_SET_REQUIRED
public :: ERROR_M_EXCLUDE_SET_DEFINITION
! errors 1000-1999: command line interface
public :: ERROR_MISSING_CLA
public :: ERROR_MISSING_GROUP
public :: ERROR_MISSING_SELECTION_CLA
public :: ERROR_TOO_FEW_CLAS
public :: ERROR_UNKNOWN_CLAS_IGNORED
public :: ERROR_ARGUMENT_RETRIEVAL
public :: ERROR_USER
endmodule flap

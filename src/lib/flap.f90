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
                                         ERROR_ENVVAR_CSV,             &
                                         ERROR_PATH_NOT_FOUND,         &
                                         ERROR_PATH_NOT_READABLE,      &
                                         ERROR_PATH_NOT_WRITABLE,      &
                                         ERROR_PATH_INCONSISTENT,      &
                                         ERROR_CASTING_NUMBER,         &
                                         ERROR_DEPRECATED_REQUIRED,    &
                                         ERROR_ALTERNATE_INCONSISTENT, &
                                         ERROR_SWITCH_NEG_INCONSISTENT, &
                                         ERROR_MAP_FORMAT,             &
                                         ERROR_MAP_DUPLICATE_KEY,      &
                                         ERROR_MAP_UNKNOWN_KEY,        &
                                         ERROR_MAP_KEY_MISSING,        &
                                         ERROR_MAP_INCONSISTENT,       &
                                         ERROR_RANGE_DEFINITION,       &
                                         ERROR_OUT_OF_RANGE,           &
                                         ERROR_RANGE_TYPE,             &
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
                                                STATUS_ALTERNATE,                             &
                                                STATUS_SHOW_COMPLETION,                       &
                                                STATUS_INSTALL_COMPLETION,                    &
                                                STATUS_PRINT_MAN,                             &
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
                                          ERROR_USER,                  &
                                         ERROR_CONFIG_NOT_FOUND,      &
                                         ERROR_CONFIG_UNKNOWN_KEY,    &
                                         ERROR_GROUP_ALIAS,           &
                                         ERROR_COPY_POSITIONAL,       &
                                         ERROR_COMPLETION_SHELL,      &
                                         ERROR_COMPLETION_INSTALL,    &
                                         ERROR_COMMAND_REPEATED,      &
                                         ERROR_USAGE_ON_ERROR
use flap_menu_t, only : menu,                   &
                        ERROR_MENU_INVALID,     &
                        ERROR_MENU_TOO_MANY,    &
                        ERROR_MENU_DUPLICATE,   &
                        ERROR_MENU_NO_RESPONSE, &
                        ERROR_MENU_EOF,         &
                        ERROR_MENU_DEFINITION

implicit none
private
! types
public :: command_line_argument
public :: command_line_arguments_group
public :: command_line_interface
public :: menu
! constants: the single public surface of the codes registry (issue #125, section 5)
! statuses (negative): returned by parse, never errors
public :: STATUS_PRINT_V
public :: STATUS_PRINT_H
public :: STATUS_PRINT_M
public :: STATUS_NO_ARGS
public :: STATUS_ALTERNATE
public :: STATUS_SHOW_COMPLETION
public :: STATUS_INSTALL_COMPLETION
public :: STATUS_PRINT_MAN
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
public :: ERROR_ENVVAR_CSV
public :: ERROR_PATH_NOT_FOUND
public :: ERROR_PATH_NOT_READABLE
public :: ERROR_PATH_NOT_WRITABLE
public :: ERROR_PATH_INCONSISTENT
public :: ERROR_CASTING_NUMBER
public :: ERROR_DEPRECATED_REQUIRED
public :: ERROR_ALTERNATE_INCONSISTENT
public :: ERROR_SWITCH_NEG_INCONSISTENT
public :: ERROR_MAP_FORMAT
public :: ERROR_MAP_DUPLICATE_KEY
public :: ERROR_MAP_UNKNOWN_KEY
public :: ERROR_MAP_KEY_MISSING
public :: ERROR_MAP_INCONSISTENT
public :: ERROR_RANGE_DEFINITION
public :: ERROR_OUT_OF_RANGE
public :: ERROR_RANGE_TYPE
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
public :: ERROR_CONFIG_NOT_FOUND
public :: ERROR_CONFIG_UNKNOWN_KEY
public :: ERROR_GROUP_ALIAS
public :: ERROR_COPY_POSITIONAL
public :: ERROR_COMPLETION_SHELL
public :: ERROR_COMPLETION_INSTALL
public :: ERROR_COMMAND_REPEATED
public :: ERROR_USAGE_ON_ERROR
! errors 2000-2099: menu (flap_menu_t, never used by the parser)
public :: ERROR_MENU_INVALID
public :: ERROR_MENU_TOO_MANY
public :: ERROR_MENU_DUPLICATE
public :: ERROR_MENU_NO_RESPONSE
public :: ERROR_MENU_EOF
public :: ERROR_MENU_DEFINITION
endmodule flap

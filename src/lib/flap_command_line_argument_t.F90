!< Command Line Argument (CLA) class.
module flap_command_line_argument_t
!< Command Line Argument (CLA) class.

use face, only : colorize
use flap_object_t, only : object
use flap_utils_m
use penf

implicit none
private
save
public :: command_line_argument
public :: ACTION_STORE
public :: ACTION_STORE_STAR
public :: ACTION_STORE_TRUE
public :: ACTION_SHOW_COMPLETION
public :: ACTION_INSTALL_COMPLETION
public :: ACTION_STORE_FALSE
public :: ACTION_PRINT_HELP
public :: ACTION_PRINT_MARK
public :: ACTION_PRINT_MAN
public :: ACTION_PRINT_VERS
public :: ACTION_COUNT
public :: ACTION_APPEND
public :: ACTION_CONFIG
public :: ACTION_ALTERNATE
public :: ARGS_SEP
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

! value sources (F06 of #125), from the most to the least explicit: source < SOURCE_DEFAULT means "given by the user"
integer(I4P), parameter :: SOURCE_COMMANDLINE = 1 !< Value passed on the command line.
integer(I4P), parameter :: SOURCE_ENVIRONMENT = 2 !< Value read from the environment variable.
integer(I4P), parameter :: SOURCE_CONFIG      = 3 !< Value read from a configuration file.
integer(I4P), parameter :: SOURCE_DEFAULT     = 4 !< Default value.
integer(I4P), parameter :: SOURCE_NONE        = 5 !< No value.

type, extends(object) :: command_line_argument
  !< Command Line Argument (CLA) class.
  !<
  !< @note If not otherwise declared the action on CLA value is set to "store" a value.
  private
  character(len=:), allocatable, public :: switch                 !< Switch name.
  character(len=:), allocatable, public :: switch_ab              !< Abbreviated switch name.
  character(len=:), allocatable, public :: switch_neg             !< Negation of a flag, --no-x (F11); allocated if any.
  character(len=:), allocatable, public :: act                    !< CLA value action.
  character(len=:), allocatable, public :: def                    !< Default value.
  character(len=:), allocatable, public :: nargs                  !< Number of arguments consumed by CLA.
  character(len=:), allocatable, public :: choices                !< List (comma separated) of allowable values for the argument.
  character(len=:), allocatable, public :: val                    !< CLA value.
  character(len=:), allocatable, public :: envvar                 !< Environment variable from which take value.
  logical,                       public :: is_required=.false.    !< Flag for set required argument.
  logical,                       public :: is_positional=.false.  !< Flag for checking if CLA is a positional or a named CLA.
  integer(I4P),                  public :: position=0_I4P         !< Position of positional CLA.
  logical,                       public :: is_passed=.false.      !< Flag for checking if CLA has been passed to CLI.
  logical,                       public :: is_hidden=.false.      !< Flag for hiding CLA, thus it does not compare into help.
  logical,                       public :: is_val_required=.true. !< Flag for set required value for not required (optional) CLA.
  integer(I4P),                  public :: source=SOURCE_NONE     !< Source of the value (SOURCE_*).
  logical,                       public :: is_config=.false.      !< The CLA names the configuration file (act='config').
  logical,                       public :: must_exist=.false.     !< The value is a path that must exist.
  logical,                       public :: readable=.false.       !< The value is a path that must be readable (and exist).
  logical,                       public :: writable=.false.       !< The value is a path writable if it exists.
  logical,                       public :: allow_dash=.false.     !< '-' passes the path checks (standard input/output).
  character(len=:), allocatable, public :: deprecated             !< Deprecation message; allocated means deprecated (F13).
  character(len=:), allocatable, public :: range_min              !< Minimum of the value (F05), as given.
  character(len=:), allocatable, public :: range_max              !< Maximum of the value (F05), as given.
  logical,                       public :: min_open=.false.       !< The minimum is excluded.
  logical,                       public :: max_open=.false.       !< The maximum is excluded.
  logical,                       public :: clamp=.false.          !< An out-of-range value becomes the bound.
  logical,                       public :: case_sensitive=.true.  !< Character choices match only in their case (F14).
  logical,                       public :: is_map=.false.         !< The values are KEY=VALUE pairs (F18).
  logical,                       public :: is_auto_envvar=.false. !< The envvar is generated by auto_envvar_prefix (F07).
  character(len=:), allocatable, public :: metavar                !< Placeholder of the value in the help (F12).
  character(len=:), allocatable, public :: map_keys               !< Allowed keys of a map, comma separated (F18).
  logical,                       public :: is_negated=.false.     !< The last spelling of a flag pair passed is the negation.
  logical,                       public :: pair_passed=.false.    !< Both spellings of a flag pair passed (D5: once each).
  contains
    ! public methods
    procedure, public :: free                           !< Free dynamic memory.
    procedure, public :: check                          !< Check data consistency.
    procedure, public :: is_required_passed             !< Check if required CLA is passed.
    procedure, public :: has_value                      !< Check if the value is given by the user (explicit source).
    procedure, public :: set_source_value               !< Set a value read from the environment or a configuration file.
    procedure, public :: config_key                     !< Key of the CLA in a configuration file.
    procedure, public :: takes_config_value             !< Check if the CLA takes a value from a configuration file.
    procedure, public :: value_text                     !< Resolved value as text (provenance report).
    procedure, public :: has_path_checks                !< Check if the value is a path to check.
    procedure, public :: deprecation_note               !< Marker of a deprecated CLA in the help.
    procedure, public :: has_range                      !< Check if the value has a range.
    procedure, public :: range_text                     !< Range as text, e.g. (0, 1].
    procedure, public :: check_paths                    !< Check the path value(s): existence and permissions.
    procedure, public :: match_token                    !< Check if a command line token names this CLA.
    procedure, public :: match_negation                 !< Check if a command line token is the negation of this flag.
    procedure, public :: same_name                      !< Compare a switch name with a token (case rule of F14).
    procedure, public :: is_pair_override               !< Check if a flag passed may be passed again by its other spelling.
    procedure, public :: flag_value                     !< Value of a flag passed on the command line.
    procedure, public :: names                          !< Visible switch names, for suggestions.
    procedure, public :: placeholder                    !< Placeholder of the value in the help (metavar).
    procedure, public :: check_map                      !< Check the KEY=VALUE pairs of a map.
    procedure, public :: get_map                        !< Get the keys and values of a map.
    procedure, public :: get_map_value                  !< Get the value of a key of a map.
    procedure, public :: match_inline_token             !< Check a token also as NAME=VALUE.
    procedure, public :: set_inline_value               !< Set the value given inline (NAME=VALUE).
    procedure, public :: is_repeatable                  !< Check if the CLA may be passed more than once.
    procedure, public :: count_occurrences              !< Count occurrences of a count CLA.
    procedure, public :: append_value                   !< Collect a value of an append CLA.
    procedure, public :: is_list                        !< Check if the CLA holds a list (nargs or append).
    procedure, public :: is_builtin                     !< Check if the CLA is a builtin (help, version, man, ...).
    procedure, public :: raise_error_m_exclude          !< Raise error mutually exclusive CLAs passed.
    procedure, public :: raise_error_nargs_insufficient !< Raise error insufficient number of argument values passed.
    procedure, public :: raise_error_value_missing      !< Raise error missing value.
    procedure, public :: raise_error_switch_unknown     !< Raise error switch_unknown.
    procedure, public :: raise_error_duplicated_clas    !< Raise error duplicated CLAs passed.
    generic,   public :: get =>   &
                         get_cla, &
                         get_cla_list                    !< Get CLA value(s).
    generic,   public :: get_varying =>                &
#if defined PENF_R16P
                         get_cla_list_varying_R16P,    &
#endif
                         get_cla_list_varying_R8P,     &
                         get_cla_list_varying_R4P,     &
                         get_cla_list_varying_I8P,     &
                         get_cla_list_varying_I4P,     &
                         get_cla_list_varying_I2P,     &
                         get_cla_list_varying_I1P,     &
                         get_cla_list_varying_logical, &
                         get_cla_list_varying_char       !< Get CLA value(s) from varying size list.
    procedure, public :: has_choices                     !< Return true if CLA has defined choices.
    procedure, public :: sanitize_defaults               !< Sanitize default values.
    procedure, public :: signature                       !< Get signature.
    procedure, public :: signature_usage                 !< Get the signature for the usage text.
    procedure, public :: completion_words                !< Get the bash completion words (switches).
    procedure, public :: completion_offer                !< Get the bash lines offering the words not yet typed.
    procedure, public :: completion_values               !< Get the bash completion of the value.
    procedure, public :: completion_fish                 !< Get the fish completion lines.
    procedure, public :: completion_powershell           !< Get the PowerShell completion entries.
    procedure, public :: usage                           !< Get correct usage.
    ! private methods
    procedure, private :: errored                         !< Trig error occurence and print meaningful message.
    procedure, private :: check_count_consistency         !< Check data consistency for count CLA.
    procedure, private :: check_append_consistency        !< Check data consistency for append CLA.
    procedure, private :: check_envvar_consistency        !< Check data consistency for envvar CLA.
    procedure, private :: check_action_consistency        !< Check CLA action consistency.
    procedure, private :: check_optional_consistency      !< Check optional CLA consistency.
    procedure, private :: check_def_nargs_consistency     !< Check the count of a list default against nargs.
    procedure, private :: check_m_exclude_consistency     !< Check mutually exclusion consistency.
    procedure, private :: check_path_consistency          !< Check that the path checks are on an option taking a value.
    procedure, private :: check_alternate_consistency     !< Check that an alternate action has no attribute of a value.
    procedure, private :: check_switch_neg_consistency    !< Check that a negation belongs to a named scalar flag.
    procedure, private :: check_map_consistency           !< Check that a map is a named list, its default included.
    procedure, private :: check_map_list                  !< Check the KEY=VALUE pairs of a stored list.
    procedure, private :: check_range_consistency         !< Check the range definition.
    procedure, private :: check_range                     !< Check (or clamp) a value against the range.
    procedure, private :: check_named_consistency         !< Check named CLA consistency.
    procedure, private :: check_positional_consistency    !< Check positional CLA consistency.
    procedure, private :: check_choices                   !< Check if CLA value is in allowed choices.
    procedure, private :: check_choices_text              !< Check the choices of a whole character value, then store it.
    procedure, private :: cast_number                     !< Convert a value to a number, quietly (B40 of #126).
    procedure, private :: check_list_size                 !< Check CLA multiple values list size consistency.
    procedure, private :: stored_list                     !< Stored list of values (parsed or default).
    procedure, private :: get_cla                         !< Get CLA (single) value.
    procedure, private :: get_cla_from_buffer             !< Get CLA (single) value from a buffer.
    procedure, private :: get_cla_list                    !< Get CLA multiple values.
    procedure, private :: get_cla_list_from_buffer        !< Get CLA (single) value from a buffer.
    procedure, private :: get_cla_list_varying_R16P       !< Get CLA multiple values, varying size, R16P.
    procedure, private :: get_cla_list_varying_R8P        !< Get CLA multiple values, varying size, R8P.
    procedure, private :: get_cla_list_varying_R4P        !< Get CLA multiple values, varying size, R4P.
    procedure, private :: get_cla_list_varying_I8P        !< Get CLA multiple values, varying size, I8P.
    procedure, private :: get_cla_list_varying_I4P        !< Get CLA multiple values, varying size, I4P.
    procedure, private :: get_cla_list_varying_I2P        !< Get CLA multiple values, varying size, I2P.
    procedure, private :: get_cla_list_varying_I1P        !< Get CLA multiple values, varying size, I1P.
    procedure, private :: get_cla_list_varying_logical    !< Get CLA multiple values, varying size, bool.
    procedure, private :: get_cla_list_varying_char       !< Get CLA multiple values, varying size, char.
    final              :: finalize                        !< Free dynamic memory when finalizing.
endtype command_line_argument

! parameters
character(len=*), parameter :: ACTION_STORE       = 'STORE'         !< Store value (if invoked a value must be passed).
character(len=*), parameter :: ACTION_CONFIG      = 'CONFIG'        !< Name the configuration file (stored as a store CLA).
character(len=*), parameter :: ACTION_ALTERNATE   = 'ALTERNATE'     !< Alternate action: bypass the value validation (F16).
character(len=*), parameter :: ACTION_STORE_STAR  = 'STORE*'        !< Store value or revert on default if invoked alone.
character(len=*), parameter :: ACTION_STORE_TRUE  = 'STORE_TRUE'    !< Store .true. without the necessity of a value.
character(len=*), parameter :: ACTION_STORE_FALSE = 'STORE_FALSE'   !< Store .false. without the necessity of a value.
character(len=*), parameter :: ACTION_PRINT_HELP  = 'PRINT_HELP'    !< Print help message.
character(len=*), parameter :: ACTION_PRINT_MARK  = 'PRINT_MARKDOWN'!< Print help to Markdown file.
character(len=*), parameter :: ACTION_PRINT_MAN   = 'PRINT_MAN'     !< Save the man page (F29).
character(len=*), parameter :: ACTION_SHOW_COMPLETION    = 'SHOW_COMPLETION'    !< Print the completion script (F24).
character(len=*), parameter :: ACTION_INSTALL_COMPLETION = 'INSTALL_COMPLETION' !< Install the completion script (F24).
character(len=*), parameter :: ACTION_PRINT_VERS  = 'PRINT_VERSION' !< Print version.
character(len=*), parameter :: ACTION_COUNT       = 'COUNT'         !< Count the occurrences (repeatable, no value).
character(len=*), parameter :: ACTION_APPEND      = 'APPEND'        !< Collect one value per occurrence (repeatable).
character(len=*), parameter :: ARGS_SEP           = LIST_SEP        !< Arguments separator for multiple valued (list) CLA.

! errors codes
integer(I4P), parameter :: ERROR_OPTIONAL_NO_DEF        = 1  !< Optional CLA without default value.
integer(I4P), parameter :: ERROR_REQUIRED_M_EXCLUDE     = 2  !< Required CLA cannot exclude others.
integer(I4P), parameter :: ERROR_POSITIONAL_M_EXCLUDE   = 3  !< Positional CLA cannot exclude others.
integer(I4P), parameter :: ERROR_NAMED_NO_NAME          = 4  !< Named CLA without switch name.
integer(I4P), parameter :: ERROR_POSITIONAL_NO_POSITION = 5  !< Positional CLA without position.
integer(I4P), parameter :: ERROR_POSITIONAL_NO_STORE    = 6  !< Positional CLA without action_store.
integer(I4P), parameter :: ERROR_NOT_IN_CHOICES         = 7  !< CLA value out of a specified choices.
integer(I4P), parameter :: ERROR_MISSING_REQUIRED       = 8  !< Missing required CLA.
integer(I4P), parameter :: ERROR_M_EXCLUDE              = 9  !< Two mutually exclusive CLAs have been passed.
integer(I4P), parameter :: ERROR_CASTING_LOGICAL        = 10 !< Error casting CLA value to logical type.
integer(I4P), parameter :: ERROR_CHOICES_LOGICAL        = 11 !< Error adding choices check for CLA val of logical type.
integer(I4P), parameter :: ERROR_NO_LIST                = 12 !< Actual CLA is not list-values.
integer(I4P), parameter :: ERROR_NARGS_INSUFFICIENT     = 13 !< Multi-valued CLA with insufficient arguments.
integer(I4P), parameter :: ERROR_VALUE_MISSING          = 14 !< Missing value of CLA.
integer(I4P), parameter :: ERROR_UNKNOWN                = 15 !< Unknown CLA (switch name).
integer(I4P), parameter :: ERROR_ENVVAR_POSITIONAL      = 16 !< Envvar not allowed for positional CLA.
integer(I4P), parameter :: ERROR_ENVVAR_NOT_STORE       = 17 !< Envvar not allowed action different from store;
integer(I4P), parameter :: ERROR_ENVVAR_NARGS           = 18 !< Envvar not allowed for list-values CLA.
integer(I4P), parameter :: ERROR_STORE_STAR_POSITIONAL  = 19 !< Action store* not allowed for positional CLA.
integer(I4P), parameter :: ERROR_STORE_STAR_NARGS       = 20 !< Action store* not allowed for list-values CLA.
integer(I4P), parameter :: ERROR_STORE_STAR_ENVVAR      = 21 !< Action store* not allowed for environment variable CLA.
integer(I4P), parameter :: ERROR_ACTION_UNKNOWN         = 22 !< Unknown CLA (switch name).
integer(I4P), parameter :: ERROR_DUPLICATED_CLAS        = 23 !< Duplicated CLAs passed, passed multiple instance of the same CLA.
integer(I4P), parameter :: ERROR_MISSING_REQUIRED_VAL   = 24 !< Missing required value of CLA.
integer(I4P), parameter :: ERROR_INLINE_VALUE_NOT_ALLOWED = 25 !< Inline value (NAME=VALUE) for a CLA that takes no value.
integer(I4P), parameter :: ERROR_INLINE_VALUE_NARGS     = 26 !< Inline value (NAME=VALUE) for a list CLA.
integer(I4P), parameter :: ERROR_COUNT_INCONSISTENT     = 27 !< Count CLA with positional, nargs, envvar or choices.
integer(I4P), parameter :: ERROR_APPEND_INCONSISTENT    = 28 !< Append CLA with positional, nargs or envvar.
integer(I4P), parameter :: ERROR_APPEND_SCALAR_GET      = 29 !< Scalar get of an append CLA (a list).
integer(I4P), parameter :: ERROR_POSITIONAL_NARGS       = 45 !< Positional CLA with nargs (positionals are scalar).
integer(I4P), parameter :: ERROR_UNSUPPORTED_TYPE       = 46 !< Value requested into a variable of an unsupported type.
integer(I4P), parameter :: ERROR_LIST_SIZE              = 47 !< List requested into a fixed-size array of another size.
integer(I4P), parameter :: ERROR_DEF_NARGS              = 48 !< List default whose count differs from an integer nargs.
integer(I4P), parameter :: ERROR_ENVVAR_CSV             = 43 !< List value of an environment variable: unterminated quote.
integer(I4P), parameter :: ERROR_PATH_NOT_FOUND         = 33 !< Path value that does not exist (must_exist, readable).
integer(I4P), parameter :: ERROR_PATH_NOT_READABLE      = 34 !< Path value that cannot be opened for reading (readable).
integer(I4P), parameter :: ERROR_PATH_NOT_WRITABLE      = 35 !< Existing path value that cannot be opened for writing.
integer(I4P), parameter :: ERROR_PATH_INCONSISTENT      = 49 !< Path checks on an option taking no value.
integer(I4P), parameter :: ERROR_CASTING_NUMBER         = 50 !< A value that is not a number, got into one (B40 of #126).
integer(I4P), parameter :: ERROR_DEPRECATED_REQUIRED    = 44 !< A required option cannot be deprecated.
integer(I4P), parameter :: ERROR_ALTERNATE_INCONSISTENT = 37 !< An alternate action with an attribute of a value.
integer(I4P), parameter :: ERROR_SWITCH_NEG_INCONSISTENT = 36 !< A negation (switch_neg) of a CLA that is not a named flag.
integer(I4P), parameter :: ERROR_MAP_FORMAT             = 38 !< A map item that is not KEY=VALUE (empty KEY included).
integer(I4P), parameter :: ERROR_MAP_DUPLICATE_KEY      = 39 !< A map key given twice.
integer(I4P), parameter :: ERROR_MAP_UNKNOWN_KEY        = 40 !< A map key outside map_keys.
integer(I4P), parameter :: ERROR_MAP_KEY_MISSING        = 41 !< A map key not given, looked up without found.
integer(I4P), parameter :: ERROR_MAP_INCONSISTENT       = 42 !< A map on a CLA that is not a named list, or not a map.
integer(I4P), parameter :: ERROR_RANGE_DEFINITION       = 30 !< Invalid range (bounds, clamp to an open real bound).
integer(I4P), parameter :: ERROR_OUT_OF_RANGE           = 31 !< Value out of its range.
integer(I4P), parameter :: ERROR_RANGE_TYPE             = 32 !< Range with a character or logical get.

contains
  ! public methods
  elemental subroutine free(self)
  !< Free dynamic memory.
  class(command_line_argument), intent(inout) :: self  !< CLA data.

  ! object members
  call self%free_object
  ! other members
  if (allocated(self%switch   )) deallocate(self%switch   )
  if (allocated(self%switch_ab)) deallocate(self%switch_ab)
  if (allocated(self%switch_neg)) deallocate(self%switch_neg)
  if (allocated(self%act      )) deallocate(self%act      )
  if (allocated(self%def      )) deallocate(self%def      )
  if (allocated(self%nargs    )) deallocate(self%nargs    )
  if (allocated(self%choices  )) deallocate(self%choices  )
  if (allocated(self%val      )) deallocate(self%val      )
  if (allocated(self%envvar   )) deallocate(self%envvar   )
  self%is_required     = .false.
  self%is_positional   = .false.
  self%position        = 0_I4P
  self%is_passed       = .false.
  self%is_hidden       = .false.
  self%is_val_required = .true.
  self%source          = SOURCE_NONE
  self%is_config       = .false.
  self%must_exist      = .false.
  self%readable        = .false.
  self%writable        = .false.
  self%allow_dash      = .false.
  if (allocated(self%deprecated)) deallocate(self%deprecated)
  if (allocated(self%range_min)) deallocate(self%range_min)
  if (allocated(self%range_max)) deallocate(self%range_max)
  self%min_open        = .false.
  self%max_open        = .false.
  self%clamp           = .false.
  self%case_sensitive  = .true.
  self%is_map          = .false.
  self%is_auto_envvar  = .false.
  if (allocated(self%metavar)) deallocate(self%metavar)
  if (allocated(self%map_keys)) deallocate(self%map_keys)
  self%is_negated      = .false.
  self%pair_passed     = .false.
  endsubroutine free

  subroutine check(self, pref)
  !< Check data consistency.
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.

  call self%check_alternate_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_switch_neg_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_map_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_range_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_count_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_append_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_envvar_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_action_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_optional_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_def_nargs_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_m_exclude_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_path_consistency(pref=pref) ; if (self%error/=0) return
  if (allocated(self%deprecated).and.self%is_required) then
    call self%errored(pref=pref, error=ERROR_DEPRECATED_REQUIRED)
    return
  endif
  call self%check_named_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_positional_consistency(pref=pref)
  endsubroutine check

  function is_required_passed(self, pref) result(is_ok)
  !< Check if required CLA is passed: a required CLA, or one without default, needs a value from an explicit source (D2).
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  logical                                     :: is_ok !< Check result.

  is_ok = .true.
  if ((.not.self%has_value()).and.(self%is_required.or.(.not.allocated(self%def)))) then
    call self%errored(pref=pref, error=ERROR_MISSING_REQUIRED)
    is_ok = .false.
  endif
  endfunction is_required_passed

  elemental function has_value(self)
  !< Check if the value is given by the user, from an explicit source (command line, environment, config): not the default.
  !<
  !< The getters read `val` when this is true and `def` otherwise; `is_passed` keeps its meaning, "seen on the command line".
  class(command_line_argument), intent(in) :: self      !< CLA data.
  logical                                  :: has_value !< Check result.

  has_value = self%source < SOURCE_DEFAULT
  endfunction has_value

  subroutine set_source_value(self, value, source)
  !< Set a value read from the environment variable (F07 of #125) or from a configuration file (F08), with its source.
  !<
  !< A flag (store_true/store_false) takes it as its value: 1/0, true/false, t/f, yes/no, y/n, on/off, in any case (click's
  !< set); anything else is kept, so that get reports ERROR_CASTING_LOGICAL. A list (nargs) reads an environment variable
  !< as one CSV record (F22: an unterminated quote is ERROR_ENVVAR_CSV), a configuration value as blank separated values
  !< (as def).
  class(command_line_argument), intent(inout) :: self      !< CLA data.
  character(*),                 intent(in)    :: value     !< Value.
  integer(I4P),                 intent(in)    :: source    !< SOURCE_ENVIRONMENT or SOURCE_CONFIG.
  type(flap_string), allocatable              :: fields(:) !< Fields of a list.
  integer(I4P)                                :: nf        !< Number of fields.
  integer(I4P)                                :: f         !< Counter.
  integer(I4P)                                :: error     !< Split error.

  if (self%is_list().and.source == SOURCE_CONFIG) then
    self%val = replace_all(string=unique(string=wstrip(value), substring=' '), substring=' ', restring=LIST_SEP)
    self%source = source
    return
  endif
  if (self%is_list()) then
    call csv_split(record=value, fields=fields, nf=nf, error=error)
    if (error /= 0) then
      call self%errored(error=ERROR_ENVVAR_CSV, val_str=value)
      return
    endif
    self%val = ''
    do f=1, nf
      call list_push(self%val, fields(f)%s)
    enddo
    self%source = source
    return
  endif
  self%val = trim(adjustl(value))
  if (self%act == ACTION_STORE_TRUE .or. self%act == ACTION_STORE_FALSE) then
    select case(upper_case(self%val))
    case('1', 'TRUE', 'T', 'YES', 'Y', 'ON')
      self%val = '.true.'
    case('0', 'FALSE', 'F', 'NO', 'N', 'OFF')
      self%val = '.false.'
    endselect
  endif
  self%source = source
  endsubroutine set_source_value

  pure function config_key(self) result(key)
  !< Return the key of the CLA in a configuration file: its switch without the leading dashes ('' for a positional).
  class(command_line_argument), intent(in) :: self !< CLA data.
  character(len=:), allocatable            :: key  !< Key.
  integer(I4P)                             :: c    !< First character after the dashes.

  key = ''
  if (self%is_positional .or. .not.allocated(self%switch)) return
  key = trim(adjustl(self%switch))
  c = verify(key, '-')
  if (c > 0) then
    key = key(c:)
  else
    key = ''
  endif
  endfunction config_key

  function value_text(self) result(text)
  !< Return the resolved value as text, for the provenance report: a list blank separated, a flag passed on the command
  !< line as .true./.false., otherwise the value from its source (or the default).
  class(command_line_argument), intent(in) :: self !< CLA data.
  character(len=:), allocatable            :: text !< Value.

  if ((self%act == ACTION_STORE_TRUE .or. self%act == ACTION_STORE_FALSE .or. self%act == ACTION_ALTERNATE) .and. &
      self%source == SOURCE_COMMANDLINE) then
    text = merge('.true. ', '.false.', self%flag_value())
    text = trim(text)
  elseif (self%is_list()) then
    text = list_join(self%stored_list(), ' ')
  else
    text = self%stored_list()
  endif
  endfunction value_text

  pure function deprecation_note(self) result(note)
  !< Return the marker of a deprecated CLA in the help: ' (DEPRECATED: message)', ' (DEPRECATED)', or '' (F13 of #125).
  class(command_line_argument), intent(in) :: self !< CLA data.
  character(len=:), allocatable            :: note !< Marker.

  note = ''
  if (.not.allocated(self%deprecated)) return
  if (len_trim(self%deprecated) > 0) then
    note = ' (DEPRECATED: '//trim(adjustl(self%deprecated))//')'
  else
    note = ' (DEPRECATED)'
  endif
  endfunction deprecation_note

  elemental function has_range(self) result(ranged)
  !< Check if the value has a range (min or max).
  class(command_line_argument), intent(in) :: self   !< CLA data.
  logical                                  :: ranged !< Check result.

  ranged = allocated(self%range_min) .or. allocated(self%range_max)
  endfunction has_range

  pure function range_text(self) result(text)
  !< Return the range as text: (0, 1], [1, +inf), ...
  class(command_line_argument), intent(in) :: self !< CLA data.
  character(len=:), allocatable            :: text !< Range.

  text = merge('(', '[', self%min_open)
  if (allocated(self%range_min)) then
    text = text//trim(adjustl(self%range_min))
  else
    text = '(-inf'
  endif
  if (allocated(self%range_max)) then
    text = text//', '//trim(adjustl(self%range_max))//merge(')', ']', self%max_open)
  else
    text = text//', +inf)'
  endif
  endfunction range_text

  elemental function has_path_checks(self) result(checks)
  !< Check if the value is a path to check (must_exist, readable or writable).
  class(command_line_argument), intent(in) :: self   !< CLA data.
  logical                                  :: checks !< Check result.

  checks = self%must_exist .or. self%readable .or. self%writable
  endfunction has_path_checks

  subroutine check_paths(self, pref)
  !< Check the path value(s), whatever their source (F09 of #125): every item of a list; an empty value, and '-' with
  !< allow_dash, are not checked. Standard Fortran only: inquire for existence, an open for reading (readable) or for
  !< appending, writing nothing (writable, only if the file exists); the message carries the reason of the processor.
  !< Directories are not told apart: a directory exists and opens for reading.
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  character(len=:), allocatable               :: items(:) !< Values.
  character(len=:), allocatable               :: path     !< Value.
  character(256)                              :: iomsg    !< I/O message.
  logical                                     :: exists   !< The path exists.
  integer(I4P)                                :: n        !< Number of values.
  integer(I4P)                                :: i        !< Counter.
  integer(I4P)                                :: lun      !< Unit.
  integer(I4P)                                :: iostat   !< I/O status.

  if (.not.self%has_path_checks() .or. self%source == SOURCE_NONE) return
  if (self%is_list()) then
    call list_items(self%stored_list(), items, n)
  else
    n = 1
    items = [self%stored_list()]
  endif
  do i=1, n
    path = trim(adjustl(items(i)))
    if (path == '') cycle
    if (self%allow_dash .and. path == '-') cycle
    inquire(file=path, exist=exists)
    if ((self%must_exist .or. self%readable) .and. .not.exists) then
      call self%errored(pref=pref, error=ERROR_PATH_NOT_FOUND, val_str=path)
      return
    endif
    iomsg = ''
    if (self%readable) then
      open(newunit=lun, file=path, status='old', action='read', iostat=iostat, iomsg=iomsg)
      if (iostat /= 0) then
        call self%errored(pref=pref, error=ERROR_PATH_NOT_READABLE, val_str=path, log_value=trim(iomsg))
        return
      endif
      close(lun)
    endif
    if (self%writable .and. exists) then
      open(newunit=lun, file=path, status='old', action='write', position='append', iostat=iostat, iomsg=iomsg)
      if (iostat /= 0) then
        call self%errored(pref=pref, error=ERROR_PATH_NOT_WRITABLE, val_str=path, log_value=trim(iomsg))
        return
      endif
      close(lun)
    endif
  enddo
  endsubroutine check_paths

  pure function takes_config_value(self) result(takes)
  !< Check if the CLA takes a value from a configuration file: a named store (lists included), store_true or store_false.
  class(command_line_argument), intent(in) :: self  !< CLA data.
  logical                                  :: takes !< Check result.

  takes = .false.
  if (self%is_positional .or. self%is_config .or. .not.allocated(self%act)) return
  takes = self%act == ACTION_STORE .or. self%act == ACTION_STORE_TRUE .or. self%act == ACTION_STORE_FALSE
  endfunction takes_config_value

  pure function match_token(self, token) result(match)
  !< Check if a command line token names this CLA: the one matcher of switch names (decision D1 of #125).
  !<
  !< Rule 1: the token is the switch, its abbreviation or its negation (F11); blanks around both are not significant. A
  !< positional never matches. Rule 2 (NAME=VALUE) is match_inline_token, built on this one; match_negation tells which.
  !< With case_insensitive (F14, inherited from the CLI) the names match in any case.
  class(command_line_argument), intent(in) :: self  !< CLA data.
  character(*),                 intent(in) :: token !< Command line token.
  logical                                  :: match !< Check result.

  match = .false.
  if (self%is_positional .or. len_trim(token) == 0) return
  if (allocated(self%switch)) match = self%same_name(self%switch, token)
  if (match) return
  if (allocated(self%switch_ab)) match = self%same_name(self%switch_ab, token)
  if (match) return
  match = self%match_negation(token)
  endfunction match_token

  pure function match_negation(self, token) result(match)
  !< Check if a command line token is the negation of this flag (switch_neg, F11 of #125), by rule 1 of match_token.
  class(command_line_argument), intent(in) :: self  !< CLA data.
  character(*),                 intent(in) :: token !< Command line token.
  logical                                  :: match !< Check result.

  match = .false.
  if (self%is_positional .or. len_trim(token) == 0 .or. .not.allocated(self%switch_neg)) return
  match = self%same_name(self%switch_neg, token)
  endfunction match_negation

  pure function same_name(self, name, token) result(same)
  !< Compare a switch name with a token, blanks around them not significant; in any case with case_insensitive (F14).
  class(command_line_argument), intent(in) :: self  !< CLA data.
  character(*),                 intent(in) :: name  !< Switch name.
  character(*),                 intent(in) :: token !< Command line token.
  logical                                  :: same  !< Check result.

  if (self%case_insensitive) then
    same = upper_case(adjustl(name)) == upper_case(adjustl(token))
  else
    same = adjustl(name) == adjustl(token)
  endif
  endfunction same_name

  pure function is_pair_override(self, negated) result(override)
  !< Check if a flag already passed may be passed again: the other spelling of a flag pair, not yet passed (D5 of #125).
  class(command_line_argument), intent(in) :: self     !< CLA data.
  logical,                      intent(in) :: negated  !< The token is the negation.
  logical                                  :: override !< Check result.

  override = allocated(self%switch_neg) .and. self%is_passed .and. (.not.self%pair_passed) .and. &
             (negated .neqv. self%is_negated)
  endfunction is_pair_override

  pure function names(self) result(list)
  !< Return the switch names of a visible named CLA (switch, abbreviation, negation), for the suggestions of F10.
  class(command_line_argument), intent(in) :: self    !< CLA data.
  type(flap_string), allocatable           :: list(:) !< Names.
  integer(I4P)                             :: n       !< Number of names.

  ! sized first, filled by element: no array constructor growing an array of flap_string (gfortran 16 trunk crashes)
  n = 0
  if (.not.(self%is_positional .or. self%is_hidden)) then
    if (allocated(self%switch)) n = n + 1
    if (allocated(self%switch_ab)) n = n + 1
    if (allocated(self%switch_neg)) n = n + 1
  endif
  allocate(list(n))
  if (n == 0) return
  n = 0
  if (allocated(self%switch)) then
    n = n + 1
    list(n)%s = trim(adjustl(self%switch))
  endif
  if (allocated(self%switch_ab)) then
    n = n + 1
    list(n)%s = trim(adjustl(self%switch_ab))
  endif
  if (allocated(self%switch_neg)) then
    n = n + 1
    list(n)%s = trim(adjustl(self%switch_neg))
  endif
  endfunction names

  pure function placeholder(self) result(ph)
  !< Return the placeholder of the value in the usage and help (F12 of #125): the metavar if given (not blank), otherwise
  !< 'KEY=VALUE' for a map and 'value' for any other CLA.
  class(command_line_argument), intent(in) :: self !< CLA data.
  character(len=:), allocatable            :: ph   !< Placeholder.

  ph = 'value'
  if (self%is_map) ph = 'KEY=VALUE'
  if (allocated(self%metavar)) then
    if (len_trim(self%metavar) > 0) ph = trim(adjustl(self%metavar))
  endif
  endfunction placeholder

  pure function flag_value(self) result(val)
  !< Return the value of a flag passed on the command line: .true. for store_true (.false. for store_false), the opposite
  !< when the last spelling passed is the negation (F11 of #125).
  class(command_line_argument), intent(in) :: self !< CLA data.
  logical                                  :: val  !< Value.

  val = (self%act /= ACTION_STORE_FALSE) .neqv. self%is_negated
  endfunction flag_value

  pure subroutine match_inline_token(self, token, match, inline_val, has_inline)
  !< Check if a command line token names this CLA by rule 1 (match_token) or rule 2 of decision D1: NAME=VALUE, split at
  !< the first '=', with NAME matching by rule 1 (inline values, F01).
  class(command_line_argument),  intent(in)  :: self       !< CLA data.
  character(*),                  intent(in)  :: token      !< Command line token.
  logical,                       intent(out) :: match      !< Check result.
  character(len=:), allocatable, intent(out) :: inline_val !< VALUE of NAME=VALUE ('' otherwise).
  logical,                       intent(out) :: has_inline !< The token is NAME=VALUE.
  character(len=len(token))                  :: t          !< Token without leading blanks.
  integer(I4P)                               :: e          !< Position of the first '='.

  inline_val = ''
  has_inline = .false.
  match = self%match_token(token)
  if (match) return
  t = adjustl(token)
  e = index(t, '=')
  if (e > 1) then
    match = self%match_token(t(1:e-1))
    if (match) then
      has_inline = .true.
      inline_val = trim(t(e+1:))
    endif
  endif
  endsubroutine match_inline_token

  pure function is_repeatable(self) result(repeatable)
  !< Check if the CLA may be passed more than once (count).
  class(command_line_argument), intent(in) :: self       !< CLA data.
  logical                                  :: repeatable !< Check result.

  repeatable = .false.
  if (allocated(self%act)) repeatable = self%act==ACTION_COUNT.or.self%act==ACTION_APPEND
  endfunction is_repeatable

  pure function is_builtin(self) result(builtin)
  !< Check if the CLA is a builtin added by FLAP: --help, --version, --markdown, --man and the completion options (the
  !< hidden -- is recognised by its switch). Builtins are neither reported by provenance nor copied by copy_options.
  class(command_line_argument), intent(in) :: self    !< CLA data.
  logical                                  :: builtin !< Check result.

  builtin = .false.
  if (.not.allocated(self%act)) return
  builtin = self%act == ACTION_PRINT_HELP .or. self%act == ACTION_PRINT_VERS .or. self%act == ACTION_PRINT_MARK .or. &
            self%act == ACTION_PRINT_MAN .or. self%act == ACTION_SHOW_COMPLETION .or. self%act == ACTION_INSTALL_COMPLETION
  endfunction is_builtin

  pure function is_list(self) result(list)
  !< Check if the CLA holds a list: nargs, or the append action.
  class(command_line_argument), intent(in) :: self !< CLA data.
  logical                                  :: list !< Check result.

  list = allocated(self%nargs)
  if (.not.list.and.allocated(self%act)) list = self%act==ACTION_APPEND
  endfunction is_list

  subroutine append_value(self, value, first, pref)
  !< Collect one value of an append CLA; the first occurrence replaces the default (D9 of #125). An empty value is an
  !< empty item (D17, reversed in step 2.11).
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*),                 intent(in)    :: value !< Value.
  logical,                      intent(in)    :: first !< First occurrence on the command line.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.

  if (first.and.allocated(self%val)) deallocate(self%val)
  call list_push(self%val, trim(adjustl(value)))
  endsubroutine append_value

  subroutine count_occurrences(self, n, first)
  !< Add n occurrences to a count CLA; the first occurrence starts from 0 (the default applies only when not passed).
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  integer(I4P),                 intent(in)    :: n     !< Occurrences to add.
  logical,                      intent(in)    :: first !< First occurrence on the command line.
  integer(I4P)                                :: c     !< Current count.

  c = 0
  if (.not.first.and.allocated(self%val)) c = cton(str=trim(adjustl(self%val)), knd=1_I4P)
  self%val = trim(str(c + n, .true.))
  endsubroutine count_occurrences

  subroutine set_inline_value(self, value, pref, first)
  !< Set the value given inline (NAME=VALUE, F01): only a scalar store takes one; the next argument is not consumed.
  !<
  !< An empty value (NAME=) is the empty string, as a separate empty value (D17 of #125, reversed in step 2.11).
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*),                 intent(in)    :: value !< Inline value.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  logical,      optional,       intent(in)    :: first !< First occurrence on the command line (append, default .true.).
  logical                                     :: first_ !< First occurrence, local variable.

  first_ = .true. ; if (present(first)) first_ = first
  if (allocated(self%nargs).and.self%is_map) then
    ! --set=a=1: one KEY=VALUE pair (F18)
    if (allocated(self%val)) deallocate(self%val)
    call list_push(self%val, trim(adjustl(value)))
  elseif (allocated(self%nargs)) then
    call self%errored(pref=pref, error=ERROR_INLINE_VALUE_NARGS)
  elseif (self%act==action_append) then
    call self%append_value(value=value, first=first_, pref=pref)
  elseif (self%act==action_store.or.self%act==action_store_star) then
    self%val = trim(adjustl(value)) ! an empty value is the empty string (D17 of #125, reversed in 2.11)
  else
    call self%errored(pref=pref, error=ERROR_INLINE_VALUE_NOT_ALLOWED)
  endif
  endsubroutine set_inline_value

  function is_required_val_passed(self, pref) result(is_ok)
  !< Check if required value of CLA is passed.
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  logical                                     :: is_ok !< Check result.

  is_ok = .true.
  if (self%is_val_required.and.((.not.self%is_passed).or.(.not.allocated(self%val)))) then
    call self%errored(pref=pref, error=ERROR_MISSING_REQUIRED_VAL)
    is_ok = .false.
  endif
  endfunction is_required_val_passed

  subroutine raise_error_m_exclude(self, pref)
  !< Raise error mutually exclusive CLAs passed.
  class(command_line_argument), intent(inout) :: self !< CLA data.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.

  call self%errored(pref=pref, error=ERROR_M_EXCLUDE)
  endsubroutine raise_error_m_exclude

  subroutine raise_error_nargs_insufficient(self, pref)
  !< Raise error insufficient number of argument values passed.
  class(command_line_argument), intent(inout) :: self !< CLA data.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.

  call self%errored(pref=pref, error=ERROR_NARGS_INSUFFICIENT)
  endsubroutine raise_error_nargs_insufficient

  subroutine raise_error_value_missing(self, pref)
  !< Raise error missing value.
  class(command_line_argument), intent(inout) :: self !< CLA data.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.

  call self%errored(pref=pref, error=ERROR_VALUE_MISSING)
  endsubroutine raise_error_value_missing

  subroutine raise_error_switch_unknown(self, switch, pref, hint)
  !< Raise error switch_unknown.
  class(command_line_argument), intent(inout) :: self   !< CLA data.
  character(*), optional,       intent(in)    :: switch !< CLA switch name.
  character(*), optional,       intent(in)    :: pref   !< Prefixing string.
  character(*), optional,       intent(in)    :: hint   !< "Did you mean" hint, appended to the message (F10).

  call self%errored(pref=pref, error=ERROR_UNKNOWN, switch=switch, hint=hint)
  endsubroutine raise_error_switch_unknown

  subroutine raise_error_duplicated_clas(self, switch, pref)
  !< Raise error duplicated CLAs passed.
  class(command_line_argument), intent(inout) :: self   !< CLA data.
  character(*), optional,       intent(in)    :: switch !< CLA switch name.
  character(*), optional,       intent(in)    :: pref   !< Prefixing string.

  call self%errored(pref=pref, error=ERROR_DUPLICATED_CLAS, switch=switch)
  endsubroutine raise_error_duplicated_clas

  subroutine sanitize_defaults(self)
  !< Sanitize defaults values.
  !<
  !< It is necessary to *sanitize* the default values of non-passed, optional CLA.
  class(command_line_argument), intent(inout) :: self !< CLAsG data.

  ! if (.not.self%is_passed) then
    if (allocated(self%def)) then
      ! strip leading and trailing white spaces
      self%def = wstrip(self%def)
      if (self%is_list()) then
        ! store the white space separated values as a list (items joined by LIST_SEP: idempotent, as parse calls it again)
        self%def = unique(string=self%def, substring=' ')
        self%def = replace_all(string=self%def, substring=' ', restring=LIST_SEP)
      endif
    endif
  ! endif
  endsubroutine sanitize_defaults

  function usage(self, pref, markdown)
  !< Get correct usage.
  class(command_line_argument), intent(in) :: self       !< CLAs group data.
  character(*), optional,       intent(in) :: pref       !< Prefixing string.
  logical,      optional,       intent(in) :: markdown   !< Format for markdown
  character(len=:), allocatable            :: usage      !< Usage string.
  character(len=:), allocatable            :: prefd      !< Prefixing string.
  character(len=:), allocatable            :: switch_    !< Switch name, local variable.
  character(len=:), allocatable            :: switch_ab_ !< Abbreviated switch name, local variable.
  character(len=:), allocatable            :: neg_       !< Negation of a flag, '/--no-x' ('' for none).
  character(len=:), allocatable            :: ph         !< Placeholder of a value (metavar, F12).
  integer(I4P)                             :: a          !< Counter.
  logical                                  :: markdownd  !< Format for markdown
  integer                                  :: indent     !< how many spaces to indent

  markdownd = .false. ; if (present(markdown)) markdownd = markdown
  indent = 6 ; if (markdownd) indent = 4
  neg_ = '' ; if (allocated(self%switch_neg)) neg_ = '/'//trim(adjustl(self%switch_neg))
  ph = self%placeholder()
  switch_ = colorize(trim(adjustl(self%switch))//neg_, color_fg=self%help_color, style=self%help_style)
  switch_ab_ = colorize(trim(adjustl(self%switch_ab)), color_fg=self%help_color, style=self%help_style)
  if (.not.self%is_hidden) then
    if (self%act==action_store) then
      if (.not.self%is_positional) then
        if (allocated(self%nargs)) then
          usage = ''
          if (self%is_map) then
            ! KEY=VALUE pairs (F18)
            select case(self%nargs)
            case('+')
              usage = usage//' '//ph//' ['//ph//'...]'
            case('*')
              usage = usage//' ['//ph//'...]'
            case default
              do a=1, cton(str=trim(adjustl(self%nargs)),knd=1_I4P)
                usage = usage//' '//ph
              enddo
            endselect
          else
          select case(self%nargs)
          case('+')
            usage = usage//' '//ph//'#1 ['//ph//'#2...]'
          case('*')
            usage = usage//' ['//ph//'#1 '//ph//'#2...]'
          case default
            do a=1, cton(str=trim(adjustl(self%nargs)),knd=1_I4P)
              usage = usage//' '//ph//'#'//trim(str(a, .true.))
            enddo
          endselect
          endif
          if (trim(adjustl(self%switch))/=trim(adjustl(self%switch_ab))) then
            if (markdownd) then
              usage = new_line('a')//'* `'//trim(adjustl(self%switch))//usage//'`, `'//trim(adjustl(self%switch_ab))//usage//'`  '
            else
              usage = '  '//switch_//usage//', '//switch_ab_//usage
            endif
          else
            if (markdownd) then
              usage = new_line('a')//'* `'//trim(adjustl(self%switch))//usage//'`  '
            else
              usage = '  '//switch_//usage
            endif
          endif
        else
          if (trim(adjustl(self%switch))/=trim(adjustl(self%switch_ab))) then
            if (markdownd) then
              usage = new_line('a')//'* `'//trim(adjustl(self%switch))//' '//ph//'`, `'//trim(adjustl(self%switch_ab))//' '//ph//&
                      '`  '
            else
              usage = '  '//switch_//' '//ph//', '//switch_ab_//' '//ph
            endif
          else
            if (markdownd) then
              usage = new_line('a')//'* `'//trim(adjustl(self%switch))//' '//ph//'`  '
            else
              usage = '  '//switch_//' '//ph
            endif
          endif
        endif
      else
        if (markdownd) then
          usage = new_line('a')//'* '//ph
        else
          usage = '  '//ph
        endif
      endif
      if (allocated(self%choices).and.markdownd) usage = usage//', value in: `'//self%choices//'`'
    elseif (self%act==action_store_star) then
      ! an optional value, with its switch as any option (B39 of #126)
      if (trim(adjustl(self%switch))/=trim(adjustl(self%switch_ab))) then
        if (markdownd) then
          usage = new_line('a')//'* `'//trim(adjustl(self%switch))//' ['//ph//']`, `'//trim(adjustl(self%switch_ab))//&
                  ' ['//ph//']`  '
        else
          usage = '  '//switch_//' ['//ph//'], '//switch_ab_//' ['//ph//']'
        endif
      else
        if (markdownd) then
          usage = new_line('a')//'* `'//trim(adjustl(self%switch))//' ['//ph//']`  '
        else
          usage = '  '//switch_//' ['//ph//']'
        endif
      endif
      if (allocated(self%choices).and.markdownd) usage = usage//', value in: `'//self%choices//'`'
    elseif (self%act==ACTION_SHOW_COMPLETION .or. self%act==ACTION_INSTALL_COMPLETION) then
      ! an optional value, the shell (F24)
      if (markdownd) then
        usage = new_line('a')//'* `'//trim(adjustl(self%switch))//' ['//ph//']`  '
      else
        usage = '  '//switch_//' ['//ph//']'
      endif
      if (allocated(self%choices).and.markdownd) usage = usage//', value in: `'//self%choices//'`'
    else
      if (trim(adjustl(self%switch))/=trim(adjustl(self%switch_ab))) then
        if (markdownd) then
          usage = new_line('a')//'* `'//trim(adjustl(self%switch))//neg_//'`, `'//trim(adjustl(self%switch_ab))//'`  '
        else
          usage = '  '//switch_//', '//switch_ab_
        endif
      else
        if (markdownd) then
          usage = new_line('a')//'* `'//trim(adjustl(self%switch))//neg_//'`  '
        else
          usage = '  '//switch_
        endif
      endif
    endif
    prefd = '' ; if (present(pref)) prefd = pref
    usage = prefd//usage
    ! the choices on a detail line of the plain help, as the keys and the range (defect 12 of #126)
    if (allocated(self%choices).and..not.markdownd) usage = usage//new_line('a')//prefd//repeat(' ', indent)//'choices: '//&
                                                         replace_all(string=self%choices, substring=',', restring=', ')
    if (allocated(self%envvar)) then
      if (self%envvar /= '') then
        if (markdownd) usage = usage//'  '
        usage = usage//new_line('a')//prefd//repeat(' ', indent)//'environment variable name "'//trim(adjustl(self%envvar))//&
                '"'
      endif
    endif
    if (allocated(self%map_keys)) then
      if (markdownd) then
        usage = usage//'  '//new_line('a')//prefd//repeat(' ', 4)//'keys: '//replace_all(string=unique(string=&
                replace_all(string=self%map_keys, substring=' ', restring=''), substring=','), substring=',', restring=', ')
      else
        usage = usage//new_line('a')//prefd//repeat(' ', indent)//'keys: '//replace_all(string=unique(string=&
                replace_all(string=self%map_keys, substring=' ', restring=''), substring=','), substring=',', restring=', ')
      endif
    endif
    if (self%has_range()) then
      if (markdownd) then
        usage = usage//'  '//new_line('a')//prefd//repeat(' ', 4)//'range '//self%range_text()
      else
        usage = usage//new_line('a')//prefd//repeat(' ', indent)//'range '//self%range_text()
      endif
    endif
    if (.not.self%is_required) then
      if (self%def /= '') then
        if (markdownd) then
          ! two spaces make a line break in markdown.
          usage = usage//'  '//new_line('a')//prefd//repeat(' ', 4)//'default value '//trim(list_join(self%def, ' '))
        else
          usage = usage//new_line('a')//prefd//repeat(' ', indent)//'default value '//trim(list_join(self%def, ' '))
        endif
      endif
    endif
    if (self%m_exclude/='') usage = usage//new_line('a')//prefd//repeat(' ', indent)//'mutually exclude "'//self%m_exclude//'"'
    if (markdownd) then
      usage = usage//'  '//new_line('a')//prefd//repeat(' ',4)//trim(adjustl(self%help))//self%deprecation_note()//'  '
      if (self%help_markdown/='') then
        usage = usage//trim(adjustl(self%help_markdown))//'  '
      endif
    else
      usage = usage//new_line('a')//prefd//repeat(' ', indent)//trim(adjustl(self%help))//self%deprecation_note()
    endif
  else
    usage = ''
  endif
  endfunction usage

  function signature(self, bash_completion, plain)
  !< Get signature: dispatch to the renderer of the requested output.
  !<
  !< Usage text: signature_usage; bash completion: completion_words (plain) or completion_values.
  class(command_line_argument), intent(in) :: self            !< CLA data.
  logical, optional,            intent(in) :: bash_completion !< Return the signature for bash completion.
  logical, optional,            intent(in) :: plain           !< Return the signature as plain switches list.
  character(len=:), allocatable            :: signature       !< Signature.
  logical                                  :: bash_completion_ !< Return the signature for bash completion, local variable.
  logical                                  :: plain_           !< Return the signature as plain switches list, local var.

  bash_completion_ = .false. ; if (present(bash_completion)) bash_completion_ = bash_completion
  plain_ = .false. ; if (present(plain)) plain_ = plain
  if (.not.bash_completion_) then
    signature = self%signature_usage()
  elseif (plain_) then
    signature = self%completion_words()
  else
    signature = self%completion_values()
  endif
  endfunction signature

  function signature_usage(self, bare) result(signature)
  !< Get the signature for the usage text (human readable): the only place for rendering changes such as metavars.
  !<
  !< A bare signature has no optional brackets, as a member of a mutually exclusive set, where the set is bracketed.
  class(command_line_argument), intent(in) :: self      !< CLA data.
  logical, optional,            intent(in) :: bare      !< Render without optional brackets.
  character(len=:), allocatable            :: signature !< Signature.
  integer(I4P)                             :: nargs     !< Number of arguments consumed by CLA.
  integer(I4P)                             :: a         !< Counter.
  logical                                  :: required  !< Render as required (no brackets).
  character(len=:), allocatable            :: ph        !< Placeholder of a value (metavar, F12).

  signature = ''
  ph = self%placeholder()
  required = self%is_required ; if (present(bare)) required = required .or. bare
  if (self%is_hidden) return
  if (self%act==action_store) then
    if (.not.self%is_positional) then
      if (allocated(self%nargs).and.self%is_map) then
        ! KEY=VALUE pairs (F18)
        select case(self%nargs)
        case('+')
          signature = ph//' ['//ph//'...]'
        case('*')
          signature = '['//ph//'...]'
        case default
          nargs = cton(str=trim(adjustl(self%nargs)),knd=1_I4P)
          signature = ph
          do a=2, nargs
            signature = signature//' '//ph
          enddo
        endselect
      elseif (allocated(self%nargs)) then
        select case(self%nargs)
        ! the same placeholders as the help, single blanks (defect 9 of #126)
        case('+')
          signature = ph//'#1 ['//ph//'#2...]'
        case('*')
          signature = '['//ph//'#1 '//ph//'#2...]'
        case default
          nargs = cton(str=trim(adjustl(self%nargs)),knd=1_I4P)
          signature = ph//'#1'
          do a=2, nargs
            signature = signature//' '//ph//'#'//trim(str(a, .true.))
          enddo
        endselect
      else
        signature = ph
      endif
      if (.not.self%is_val_required) signature = '['//signature//']'
      if (required) then
        signature = ' '//trim(adjustl(self%switch))//' '//signature
      else
        signature = ' ['//trim(adjustl(self%switch))//' '//signature//']'
      endif
    else
      if (required) then
        signature = ' '//ph
      else
        signature = ' ['//ph//']'
      endif
    endif
  elseif (self%act==action_store_star) then
    ! an optional value, with its switch (B39 of #126)
    signature = trim(adjustl(self%switch))//' ['//ph//']'
    if (required) then
      signature = ' '//signature
    else
      signature = ' ['//signature//']'
    endif
  elseif (self%act==ACTION_SHOW_COMPLETION .or. self%act==ACTION_INSTALL_COMPLETION) then
    ! an optional value, the shell (F24)
    signature = ' ['//trim(adjustl(self%switch))//' ['//ph//']]'
  elseif (self%act==action_append) then
    ! repeatable, docopt-style
    if (required) then
      signature = ' '//trim(adjustl(self%switch))//' '//ph//'...'
    else
      signature = ' ['//trim(adjustl(self%switch))//' '//ph//']...'
    endif
  elseif (self%act==action_count) then
    ! repeatable, docopt-style
    if (required) then
      signature = ' '//trim(adjustl(self%switch))//'...'
    else
      signature = ' ['//trim(adjustl(self%switch))//']...'
    endif
  else
    signature = trim(adjustl(self%switch))
    if (allocated(self%switch_neg)) signature = signature//'/'//trim(adjustl(self%switch_neg)) ! a flag pair (F11)
    if (required) then
      signature = ' '//signature
    else
      signature = ' ['//signature//']'
    endif
  endif
  endfunction signature_usage

  function completion_words(self) result(words)
  !< Get the bash completion words of a named CLA: its switches, blank separated (none for positional or hidden CLAs).
  class(command_line_argument), intent(in) :: self  !< CLA data.
  character(len=:), allocatable            :: words !< Completion words.

  words = ''
  if (self%is_hidden.or.self%is_positional) return
  if (trim(adjustl(self%switch))/=trim(adjustl(self%switch_ab))) then
    words = ' '//trim(adjustl(self%switch))//' '//trim(adjustl(self%switch_ab))
  else
    words = ' '//trim(adjustl(self%switch))
  endif
  if (allocated(self%switch_neg)) words = words//' '//trim(adjustl(self%switch_neg))
  endfunction completion_words

  function completion_offer(self) result(lines)
  !< Get the bash lines adding the completion words of a named CLA to `words` (B37 of #125): unless repeatable (append,
  !< count), a spelling already typed (`used`: the words of its group so far, `--x` or `--x=value`) is not offered again;
  !< the switch and its abbreviation are one spelling, a negation is another (D5). None for positional or hidden CLAs.
  class(command_line_argument), intent(in) :: self  !< CLA data.
  character(len=:), allocatable            :: lines !< Bash lines.

  lines = ''
  if (self%is_hidden.or.self%is_positional) return
  if (self%is_repeatable()) then
    lines = new_line('a')//'    words="$words'//self%completion_words()//'"'
    return
  endif
  if (trim(adjustl(self%switch))/=trim(adjustl(self%switch_ab))) then
    lines = offer(trim(adjustl(self%switch)), trim(adjustl(self%switch_ab)))
  else
    lines = offer(trim(adjustl(self%switch)))
  endif
  if (allocated(self%switch_neg)) lines = lines//offer(trim(adjustl(self%switch_neg)))
  contains
    function offer(name, name_ab) result(line)
    !< The case line offering a spelling (a name, and its abbreviation) unless typed.
    character(*), intent(in)           :: name    !< Name.
    character(*), intent(in), optional :: name_ab !< Abbreviation.
    character(len=:), allocatable      :: line    !< Case line.

    line = new_line('a')//'    case " $used " in *" '//name//' "*|*" '//name//'="*'
    if (present(name_ab)) line = line//'|*" '//name_ab//' "*|*" '//name_ab//'="*'
    line = line//') ;; *) words="$words '//name
    if (present(name_ab)) line = line//' '//name_ab
    line = line//'" ;; esac'
    endfunction offer
  endfunction completion_offer

  function completion_fish(self, head) result(lines)
  !< Get the fish completion lines of a named CLA (F15 of #125): each starts with a new line and head (`complete -c prog`
  !< and its condition). Long switches are -l, one-letter ones -s, multi-letter single-dash ones old-style -o; choices are
  !< offered exclusively (-x -a), a free value completes file names (-r -F), a flag takes none; a negation has its own line.
  !< None for positional or hidden CLAs.
  class(command_line_argument), intent(in) :: self  !< CLA data.
  character(*),                 intent(in) :: head  !< Beginning of each line.
  character(len=:), allocatable            :: lines !< Completion lines.
  character(len=:), allocatable            :: names !< Switch names, as fish options.
  character(len=:), allocatable            :: value !< Value completion.
  character(len=:), allocatable            :: desc  !< Description.

  lines = ''
  if (self%is_hidden .or. self%is_positional .or. .not.allocated(self%switch)) return
  names = fish_name(self%switch)
  if (allocated(self%switch_ab)) then
    if (trim(adjustl(self%switch_ab)) /= trim(adjustl(self%switch))) names = names//fish_name(self%switch_ab)
  endif
  if (names == '') return
  value = ''
  if (self%act == ACTION_STORE .or. self%act == ACTION_APPEND .or. self%act == ACTION_STORE_STAR .or. &
      self%act == ACTION_SHOW_COMPLETION .or. self%act == ACTION_INSTALL_COMPLETION) then
    if (self%has_choices()) then
      value = " -x -a '"//fish_escape(replace_all(string=self%choices, substring=',', restring=' '))//"'"
    elseif (self%is_map) then
      value = ' -x'
    elseif (self%act == ACTION_STORE_STAR) then
      value = ' -F'
    else
      value = ' -r -F'
    endif
  endif
  desc = " -d '"//fish_escape(trim(adjustl(self%help)))//"'"
  lines = new_line('a')//head//names//desc//value
  if (allocated(self%switch_neg)) then
    if (fish_name(self%switch_neg) /= '') lines = lines//new_line('a')//head//fish_name(self%switch_neg)//desc
  endif
  contains
    pure function fish_name(switch) result(option)
    !< The fish option naming a switch: ' -l x' for --x, ' -s x' for -x, ' -o xy' for -xy ('' otherwise).
    character(*), intent(in)      :: switch !< Switch.
    character(len=:), allocatable :: option !< Fish option.
    character(len=:), allocatable :: s      !< Switch without blanks.

    s = trim(adjustl(switch))
    option = ''
    if (len(s) > 2) then
      if (s(1:2) == '--') then
        option = ' -l '//s(3:)
      elseif (s(1:1) == '-') then
        option = ' -o '//s(2:)
      endif
    elseif (len(s) == 2) then
      if (s(1:1) == '-' .and. s(2:2) /= '-') option = ' -s '//s(2:2)
    endif
    endfunction fish_name
  endfunction completion_fish

  function completion_powershell(self) result(entries)
  !< Get the PowerShell completion entries of a named CLA (F15 of #125), one per switch name, each on its own line:
  !< @{ n = name; d = help; c = choices or $null; v = takes a value }. A negation takes no value. None for positional or
  !< hidden CLAs.
  class(command_line_argument), intent(in) :: self    !< CLA data.
  character(len=:), allocatable            :: entries !< Completion entries.
  character(len=:), allocatable            :: rest    !< Choice, value and closing of an entry.
  character(len=:), allocatable            :: desc    !< Description.
  logical                                  :: value   !< The CLA takes a value.

  entries = ''
  if (self%is_hidden .or. self%is_positional .or. .not.allocated(self%switch)) return
  value = self%act == ACTION_STORE .or. self%act == ACTION_APPEND .or. self%act == ACTION_STORE_STAR .or. &
          self%act == ACTION_SHOW_COMPLETION .or. self%act == ACTION_INSTALL_COMPLETION
  if (value .and. self%has_choices()) then
    rest = "; c = @('"//replace_all(string=ps_escape(self%choices), substring=',', restring="', '")//"'); v = $true }"
  elseif (value) then
    rest = '; c = $null; v = $true }'
  else
    rest = '; c = $null; v = $false }'
  endif
  desc = "'; d = '"//ps_escape(trim(adjustl(self%help)))//"'"
  entries = entry(self%switch)//rest
  if (allocated(self%switch_ab)) then
    if (trim(adjustl(self%switch_ab)) /= trim(adjustl(self%switch))) entries = entries//entry(self%switch_ab)//rest
  endif
  if (allocated(self%switch_neg)) entries = entries//entry(self%switch_neg)//'; c = $null; v = $false }'
  contains
    function entry(switch) result(head)
    !< The beginning of the entry of a switch name.
    character(*), intent(in)      :: switch !< Switch.
    character(len=:), allocatable :: head   !< Beginning of the entry.

    head = new_line('a')//"      @{ n = '"//ps_escape(trim(adjustl(switch)))//desc
    endfunction entry
  endfunction completion_powershell

  function completion_values(self) result(values)
  !< Get the bash completion of the value following a named CLA: a `prev` test offering its choices, or nothing for a value.
  class(command_line_argument), intent(in) :: self   !< CLA data.
  character(len=:), allocatable            :: values !< Completion of the value.

  values = ''
  if (self%is_hidden.or.self%is_positional) return
  values = new_line('a')//'    if [ "$prev" == "'//self%switch//'" ] || [ "$prev" == "'//self%switch_ab//'" ] ; then'
  if (self%has_choices()) then
     values = values//new_line('a')//'       COMPREPLY=( $( compgen -W "'//choices(self%choices)//'" -- $cur ) )'
  elseif ((self%act==action_store).or.(self%act==action_store_star).or.(self%act==action_append)) then
     values = values//new_line('a')//'       COMPREPLY=( )'
  endif
  values = values//new_line('a')//'       return 0'
  values = values//new_line('a')//'    fi'
  contains
    pure function choices(choices_c)
    !< Return space-separated choices list from a comma-separated one.
    character(len=*), intent(in)  :: choices_c !< Comma-separated list of choices.
    character(len=len(choices_c)) :: choices   !< Space-separated list of choices.
    integer(I4P)                  :: c         !< Counter.

    choices = choices_c
    do c=1, len(choices)
      if (choices(c:c)==',') choices(c:c) = ' '
    enddo
    endfunction choices
  endfunction completion_values

  pure function has_choices(self)
  !< Return true if CLA has choices.
  class(command_line_argument), intent(in) :: self        !< CLA data.
  logical                                  :: has_choices !< Check result.

  has_choices = allocated(self%choices)
  endfunction has_choices

  ! private methods
  subroutine errored(self, error, pref, switch, val_str, log_value, hint, type_name)
  !< Trig error occurence and print meaningful message.
  class(command_line_argument), intent(inout) :: self      !< CLA data.
  integer(I4P),                 intent(in)    :: error     !< Error occurred.
  character(*), optional,       intent(in)    :: pref      !< Prefixing string.
  character(*), optional,       intent(in)    :: switch    !< CLA switch name.
  character(*), optional,       intent(in)    :: val_str   !< Value string.
  character(*), optional,       intent(in)    :: log_value !< Logical value to be casted.
  character(*), optional,       intent(in)    :: hint      !< Hint appended to the message (unknown switch, F10).
  character(*), optional,       intent(in)    :: type_name !< Type a value cannot be converted to ('an integer', 'a real').
  character(len=:), allocatable               :: prefd     !< Prefixing string.

  self%error = error
  if (self%error/=0) then
    prefd = self%error_prefix(pref=pref)
    select case(self%error)
    case(ERROR_OPTIONAL_NO_DEF)
      if (self%is_positional) then
        self%error_message = prefd//': "'//trim(str(n=self%position))//'-th" positional option has not a default value!'
      else
        self%error_message = prefd//': named option "'//self%switch//'" has not a default value!'
      endif
    case(ERROR_REQUIRED_M_EXCLUDE)
      self%error_message = prefd//': named option "'//self%switch//'" cannot exclude others'//&
                           ', it being required, only optional ones can!'
    case(ERROR_POSITIONAL_M_EXCLUDE)
      self%error_message = prefd//': "'//trim(str(n=self%position))//&
                           '-th" positional option cannot exclude others, only optional named options can!'
    case(ERROR_NAMED_NO_NAME)
      self%error_message = prefd//': a non positional optiona must have a switch name!'
    case(ERROR_POSITIONAL_NO_POSITION)
      self%error_message = prefd//': a positional option must have a position number different from 0!'
    case(ERROR_POSITIONAL_NO_STORE)
      self%error_message = prefd//': a positional option must have action set to "'//action_store//'"!'
    case(ERROR_M_EXCLUDE)
      self%error_message = prefd//': the options "'//self%switch//'" and "'//self%m_exclude//&
                           '" are mutually exclusive, but both have been passed!'
    case(ERROR_NOT_IN_CHOICES)
      if (self%is_positional) then
        self%error_message = prefd//': value of "'//trim(str(n=self%position))//&
                             '-th" positional option must be chosen in:'
      else
        self%error_message = prefd//': value of named option "'//self%switch//'" must be chosen in: '
      endif
      self%error_message = self%error_message//'('//self%choices//')'
      self%error_message = self%error_message//' but "'//trim(val_str)//'" has been passed!'
    case(ERROR_MISSING_REQUIRED)
      if (.not.self%is_positional) then
        self%error_message = prefd//': named option "'//trim(adjustl(self%switch))//'" is required!'
      else
        self%error_message = prefd//': "'//trim(str(self%position, .true.))//'-th" positional option is required!'
      endif
    case(ERROR_CASTING_LOGICAL)
      self%error_message = prefd//': cannot convert "'//log_value//'" of option "'//self%switch//'" to logical type!'
    case(ERROR_CHOICES_LOGICAL)
      self%error_message = prefd//': cannot use "choices" value check for option "'//self%switch//&
                           '" it being of logical type! The choices are limited to ".true." or ".false." by definition!'
    case(ERROR_NO_LIST)
      if (.not.self%is_positional) then
        self%error_message = prefd//': named option "'//trim(adjustl(self%switch))//&
                             '" has not "nargs" value but an array has been passed to "get" method!'
      else
        self%error_message = prefd//': "'//trim(str(self%position, .true.))//'-th" positional option '//&
                             'has not "nargs" value but an array has been passed to "get" method!'
      endif
    case(ERROR_NARGS_INSUFFICIENT)
      ! plain words (defect 6 of #126); a positional has no nargs (ERROR_POSITIONAL_NARGS)
      if (self%nargs=='+') then
        self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'" requires at least 1 value!'
      else
        self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'" requires '//trim(adjustl(self%nargs))//&
                             ' values!'
      endif
    case(ERROR_VALUE_MISSING)
      self%error_message = prefd//': named option "'//trim(adjustl(self%switch))//'" needs a value that is not passed!'
    case(ERROR_UNKNOWN)
      ! a switch is a switch; any other argument (an extra value, a misspelled command) is an argument (defect 7 of #126)
      if (index(adjustl(switch), '-') == 1) then
        self%error_message = prefd//': switch "'//trim(adjustl(switch))//'" is unknown!'
      else
        self%error_message = prefd//': argument "'//trim(adjustl(switch))//'" is unknown!'
      endif
      if (present(hint)) self%error_message = self%error_message//hint
    case(ERROR_ENVVAR_POSITIONAL)
      self%error_message = prefd//': "'//trim(str(self%position, .true.))//'-th" positional option '//&
                           'has "envvar" value that is not allowed for positional option!'
    case(ERROR_ENVVAR_NOT_STORE)
      self%error_message = prefd//': named option "'//trim(adjustl(self%switch))//&
                           '" is an envvar with action different from "'//action_store//'", "'//action_store_true//'" and "'//&
                           action_store_false//'" that is not allowed!'
    case(ERROR_ENVVAR_NARGS)
      self%error_message = prefd//': named option "'//trim(adjustl(self%switch))//&
                           '" is an envvar that is not allowed for list valued option!'
    case(ERROR_STORE_STAR_POSITIONAL)
      self%error_message = prefd//': "'//trim(str(self%position, .true.))//'-th" positional option '//&
                           'has "'//action_store_star//'" action that is not allowed for positional option!'
    case(ERROR_STORE_STAR_NARGS)
      self%error_message = prefd//': named option "'//trim(adjustl(self%switch))//&
                           '" has "'//action_store_star//'" action that is not allowed for list valued option!'
    case(ERROR_STORE_STAR_ENVVAR)
      self%error_message = prefd//': named option "'//trim(adjustl(self%switch))//&
                           '" has "'//action_store_star//'" action that is not allowed for environment variable option!'
    case(ERROR_ACTION_UNKNOWN)
      self%error_message = prefd//': named option "'//trim(adjustl(self%switch))//'" has unknown "'//self%act//'" action!'
    case(ERROR_DUPLICATED_CLAS)
      self%error_message = prefd//': switch "'//trim(adjustl(switch))//'" has been passed more than once!'
    case(ERROR_MISSING_REQUIRED_VAL)
      self%error_message = prefd//': named option "'//trim(adjustl(self%switch))//'" requires a value that is not passed!'
    case(ERROR_POSITIONAL_NARGS)
      self%error_message = prefd//': positional option "'//trim(str(self%position, .true.))//'-th" cannot have nargs: '//&
                           'positionals take one value each'
    case(ERROR_UNSUPPORTED_TYPE)
      self%error_message = prefd//': the value of "'//trim(adjustl(self%switch))//'" cannot be returned into a variable '//&
                           'of this type!'
    case(ERROR_INLINE_VALUE_NOT_ALLOWED)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'" does not take a value!'
    case(ERROR_INLINE_VALUE_NARGS)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'" takes a list of values: pass them '//&
                           'after the switch, not inline!'
    case(ERROR_COUNT_INCONSISTENT)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'" counts its occurrences: it cannot be '//&
                           'positional, nor have nargs, envvar or choices!'
    case(ERROR_APPEND_INCONSISTENT)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'" collects a value per occurrence: it '//&
                           'cannot be positional, nor have nargs or envvar!'
    case(ERROR_APPEND_SCALAR_GET)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'" collects a list of values: get it '//&
                           'into an array (get or get_varying), not a scalar!'
    case(ERROR_DEF_NARGS)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'" takes '//trim(adjustl(self%nargs))//&
                           ' values (nargs), but its default has '//trim(val_str)//'!'
    case(ERROR_LIST_SIZE)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'" has '//trim(val_str)//'!'
    case(ERROR_PATH_NOT_FOUND)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'": path "'//trim(val_str)//'" does not exist!'
    case(ERROR_PATH_NOT_READABLE)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'": path "'//trim(val_str)//&
                           '" is not readable: '//trim(log_value)//'!'
    case(ERROR_PATH_NOT_WRITABLE)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'": path "'//trim(val_str)//&
                           '" is not writable: '//trim(log_value)//'!'
    case(ERROR_RANGE_DEFINITION)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'": invalid range: '//trim(val_str)//'!'
    case(ERROR_CASTING_NUMBER)
      if (self%is_positional) then
        self%error_message = prefd//': cannot convert "'//val_str//'" of positional argument '//&
                             trim(str(self%position, .true.))//' to '//type_name//'!'
      else
        self%error_message = prefd//': cannot convert "'//val_str//'" of option "'//trim(adjustl(self%switch))//'" to '//&
                             type_name//'!'
      endif
    case(ERROR_OUT_OF_RANGE)
      self%error_message = prefd//': value "'//trim(val_str)//'" of "'//trim(adjustl(self%switch))//&
                           '" is out of range '//self%range_text()//'!'
    case(ERROR_RANGE_TYPE)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'" has a range: get it into a number, not a '//&
                           'character or a logical!'
    case(ERROR_MAP_FORMAT)
      self%error_message = prefd//': "'//trim(adjustl(self%switch))//'" expects KEY=VALUE, got "'//val_str//'"!'
    case(ERROR_MAP_DUPLICATE_KEY)
      self%error_message = prefd//': key "'//val_str//'" of "'//trim(adjustl(self%switch))//'" given twice!'
    case(ERROR_MAP_UNKNOWN_KEY)
      self%error_message = prefd//': unknown key "'//val_str//'" for "'//trim(adjustl(self%switch))//'"'
      if (present(hint)) self%error_message = self%error_message//hint
    case(ERROR_MAP_KEY_MISSING)
      self%error_message = prefd//': key "'//val_str//'" of "'//trim(adjustl(self%switch))//'" is not given!'
    case(ERROR_MAP_INCONSISTENT)
      self%error_message = prefd//': a map (KEY=VALUE pairs) is a named option with act="store" and nargs, or '//&
                           'act="append", without choices; map_keys needs map=.true.; get_map needs a map!'
    case(ERROR_SWITCH_NEG_INCONSISTENT)
      self%error_message = prefd//': negation "'//trim(adjustl(self%switch_neg))//'": only a named store_true/store_false '//&
                           'flag without nargs has one, different from its switch names!'
    case(ERROR_ALTERNATE_INCONSISTENT)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'" is an alternate action, a flag: it cannot '//&
                           'be positional, required, nor have nargs, envvar, choices or exclude!'
    case(ERROR_DEPRECATED_REQUIRED)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'" is required: it cannot be deprecated!'
    case(ERROR_PATH_INCONSISTENT)
      self%error_message = prefd//': option "'//trim(adjustl(self%switch))//'": must_exist, readable, writable and '//&
                           'allow_dash need an option taking a value (store, store*, append)!'
    case(ERROR_ENVVAR_CSV)
      self%error_message = prefd//': environment variable "'//trim(adjustl(self%envvar))//'" of option "'//&
                           trim(adjustl(self%switch))//'": unterminated quote in the list "'//trim(val_str)//'"!'
    endselect
    call self%print_error_message
  endif
  endsubroutine errored

  subroutine check_count_consistency(self, pref)
  !< Check count CLA consistency: a named flag without nargs, envvar or choices (F02 of #125).
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.

  if (.not.allocated(self%act)) return
  if (self%act/=ACTION_COUNT) return
  if (self%is_positional.or.allocated(self%nargs).or.allocated(self%envvar).or.allocated(self%choices)) &
    call self%errored(pref=pref, error=ERROR_COUNT_INCONSISTENT)
  endsubroutine check_count_consistency

  subroutine check_append_consistency(self, pref)
  !< Check append CLA consistency: a named option collecting one value per occurrence, without nargs or envvar (F02).
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.

  if (.not.allocated(self%act)) return
  if (self%act/=ACTION_APPEND) return
  if (self%is_positional.or.allocated(self%nargs).or.allocated(self%envvar)) &
    call self%errored(pref=pref, error=ERROR_APPEND_INCONSISTENT)
  endsubroutine check_append_consistency

  subroutine check_envvar_consistency(self, pref)
  !< Check data consistency for envvar CLA.
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.

  if (allocated(self%envvar)) then
    if (self%is_positional) then
      call self%errored(pref=pref, error=ERROR_ENVVAR_POSITIONAL)
      return
    endif
    if (.not.allocated(self%act)) then
      call self%errored(pref=pref, error=ERROR_ENVVAR_NOT_STORE)
      return
    else
      if (self%act/=action_store.and.self%act/=action_store_true.and.self%act/=action_store_false) then
        call self%errored(pref=pref, error=ERROR_ENVVAR_NOT_STORE)
        return
      endif
    endif
    ! lists accept an envvar (F22): ERROR_ENVVAR_NARGS is no longer raised
  endif
  endsubroutine check_envvar_consistency

  subroutine check_action_consistency(self, pref)
  !< Check CLA action consistency.
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.

  if (allocated(self%act)) then
    if (self%act==ACTION_STORE_STAR.and.(.not.allocated(self%def))) then
      call self%errored(pref=pref, error=ERROR_OPTIONAL_NO_DEF)
      return
    endif
    if (self%act==ACTION_STORE_STAR.and.self%is_positional) then
      call self%errored(pref=pref, error=ERROR_STORE_STAR_POSITIONAL)
      return
    endif
    if (self%act==ACTION_STORE_STAR.and.allocated(self%nargs)) then
      call self%errored(pref=pref, error=ERROR_STORE_STAR_NARGS)
      return
    endif
    if (self%act==ACTION_STORE_STAR.and.allocated(self%envvar)) then
      call self%errored(pref=pref, error=ERROR_STORE_STAR_ENVVAR)
      return
    endif
    if (self%act/=ACTION_STORE.and.      &
        self%act/=ACTION_STORE_STAR.and. &
        self%act/=ACTION_STORE_TRUE.and. &
        self%act/=ACTION_STORE_FALSE.and.&
        self%act/=ACTION_PRINT_HELP.and. &
        self%act/=ACTION_PRINT_MARK.and. &
        self%act/=ACTION_PRINT_MAN.and.  &
        self%act/=ACTION_PRINT_VERS.and. &
        self%act/=ACTION_COUNT.and.      &
        self%act/=ACTION_ALTERNATE.and.  &
        self%act/=ACTION_SHOW_COMPLETION.and.    &
        self%act/=ACTION_INSTALL_COMPLETION.and. &
        self%act/=ACTION_APPEND) then
      call self%errored(pref=pref, error=ERROR_ACTION_UNKNOWN)
      return
    endif
  endif
  endsubroutine check_action_consistency

  subroutine check_def_nargs_consistency(self, pref)
  !< Check that a list default has as many values as an integer nargs (B28 of #125); '+' and '*' take any count.
  class(command_line_argument), intent(inout) :: self   !< CLA data.
  character(*), optional,       intent(in)    :: pref   !< Prefixing string.
  integer(I4P)                                :: nargs  !< Number of values required.
  integer(I4P)                                :: n      !< Number of default values.
  integer(I4P)                                :: iostat !< Conversion status.
  integer(I4P)                                :: c      !< Counter.

  if (.not.(allocated(self%nargs).and.allocated(self%def))) return
  read(self%nargs, *, iostat=iostat) nargs
  if (iostat /= 0) return ! '+' or '*'
  if (index(self%def, LIST_SEP) > 0) then
    n = list_count(self%def) ! already stored as a list
  else
    n = 0 ! blank separated values
    do c=1, len(self%def)
      if (self%def(c:c) /= ' ') then
        if (c == 1) then
          n = n + 1
        elseif (self%def(c-1:c-1) == ' ') then
          n = n + 1
        endif
      endif
    enddo
  endif
  if (n /= nargs) call self%errored(pref=pref, error=ERROR_DEF_NARGS, val_str=trim(str(n, .true.)))
  endsubroutine check_def_nargs_consistency

  subroutine check_optional_consistency(self, pref)
  !< Check optional CLA consistency.
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  logical                                     :: is_inconsistent

                             is_inconsistent = ((.not.allocated(self%def)).and.(.not.self%is_required))
                             is_inconsistent = ((.not.allocated(self%def)).and.(.not.self%is_val_required)).or.is_inconsistent
  if (allocated(self%nargs)) is_inconsistent = ((.not.allocated(self%def)).and.(self%nargs=='*')).or.is_inconsistent
  if (is_inconsistent) call self%errored(pref=pref, error=ERROR_OPTIONAL_NO_DEF)
  endsubroutine check_optional_consistency

  subroutine check_range_consistency(self, pref)
  !< Check the range (F05 of #125): an option taking a value (store, store*, append, count), numeric bounds, min <= max
  !< (min < max when a bound is open).
  class(command_line_argument), intent(inout) :: self !< CLA data.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.
  real(R8P)                                   :: lo   !< Minimum.
  real(R8P)                                   :: hi   !< Maximum.
  logical                                     :: ok   !< Conversion status.

  if (.not.self%has_range()) return
  if (self%act /= ACTION_STORE .and. self%act /= ACTION_STORE_STAR .and. self%act /= ACTION_APPEND .and. &
      self%act /= ACTION_COUNT) then
    call self%errored(pref=pref, error=ERROR_RANGE_DEFINITION, val_str='a range needs an option taking a value')
    return
  endif
  if (allocated(self%range_min)) then
    call read_real(self%range_min, lo, ok)
    if (.not.ok) then
      call self%errored(pref=pref, error=ERROR_RANGE_DEFINITION, val_str='min "'//self%range_min//'" is not a number')
      return
    endif
  endif
  if (allocated(self%range_max)) then
    call read_real(self%range_max, hi, ok)
    if (.not.ok) then
      call self%errored(pref=pref, error=ERROR_RANGE_DEFINITION, val_str='max "'//self%range_max//'" is not a number')
      return
    endif
  endif
  if (allocated(self%range_min) .and. allocated(self%range_max)) then
    if (lo > hi .or. (lo == hi .and. (self%min_open .or. self%max_open))) &
      call self%errored(pref=pref, error=ERROR_RANGE_DEFINITION, val_str='the range '//self%range_text()//' is empty')
  endif
  endsubroutine check_range_consistency

  subroutine check_range(self, val, text, pref)
  !< Check a value against the range (F05 of #125), in its kind: out of range is ERROR_OUT_OF_RANGE, or, with clamp, the
  !< value becomes the bound (an open integer bound: bound +/- 1; a real cannot clamp to an open bound, ERROR_RANGE_DEFINITION).
  !< A character or logical get is ERROR_RANGE_TYPE.
  class(command_line_argument), intent(inout) :: self !< CLA data.
  class(*),                     intent(inout) :: val  !< Value.
  character(*),                 intent(in)    :: text !< Value as given, for the messages.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.
  integer(I8P)                                :: iv   !< Integer value.
  real(R8P)                                   :: rv   !< Real value.

  select type(val)
  type is(integer(I8P))
    iv = val ; call integer_range(iv) ; val = iv
  type is(integer(I4P))
    iv = int(val, I8P) ; call integer_range(iv) ; if (self%error == 0) val = int(iv, I4P)
  type is(integer(I2P))
    iv = int(val, I8P) ; call integer_range(iv) ; if (self%error == 0) val = int(iv, I2P)
  type is(integer(I1P))
    iv = int(val, I8P) ; call integer_range(iv) ; if (self%error == 0) val = int(iv, I1P)
  type is(real(R8P))
    rv = val ; call real_range(rv, single=.false.) ; val = rv
  type is(real(R4P))
    rv = real(val, R8P) ; call real_range(rv, single=.true.) ; if (self%error == 0) val = real(rv, R4P)
#if defined PENF_R16P
  type is(real(R16P))
    call real16_range(val)
#endif
  class default
    call self%errored(pref=pref, error=ERROR_RANGE_TYPE)
  endselect
  contains
    subroutine integer_range(v)
    !< Check (or clamp) an integer value.
    integer(I8P), intent(inout) :: v   !< Value.
    integer(I8P)                :: b   !< Bound.
    logical                     :: ok  !< Conversion status.

    if (allocated(self%range_min)) then
      call read_integer(self%range_min, b, ok)
      if (.not.ok) then
        call self%errored(pref=pref, error=ERROR_RANGE_DEFINITION, val_str='min "'//self%range_min//'" is not an integer')
        return
      endif
      if (v < b .or. (self%min_open .and. v == b)) then
        if (.not.self%clamp) then
          call out_of_range
          return
        endif
        v = b ; if (self%min_open) v = b + 1
      endif
    endif
    if (allocated(self%range_max)) then
      call read_integer(self%range_max, b, ok)
      if (.not.ok) then
        call self%errored(pref=pref, error=ERROR_RANGE_DEFINITION, val_str='max "'//self%range_max//'" is not an integer')
        return
      endif
      if (v > b .or. (self%max_open .and. v == b)) then
        if (.not.self%clamp) then
          call out_of_range
          return
        endif
        v = b ; if (self%max_open) v = b - 1
      endif
    endif
    endsubroutine integer_range

    subroutine real_range(v, single)
    !< Check (or clamp) a real value; the bounds are read in the kind of the value (single: R4P).
    real(R8P), intent(inout) :: v      !< Value.
    logical,   intent(in)    :: single !< The value is real(R4P).
    real(R8P)                :: b      !< Bound.

    if (allocated(self%range_min)) then
      b = bound(self%range_min, single)
      if (v < b .or. (self%min_open .and. v == b)) then
        if (.not.self%clamp) then
          call out_of_range
          return
        elseif (self%min_open) then
          call cannot_clamp
          return
        endif
        v = b
      endif
    endif
    if (allocated(self%range_max)) then
      b = bound(self%range_max, single)
      if (v > b .or. (self%max_open .and. v == b)) then
        if (.not.self%clamp) then
          call out_of_range
          return
        elseif (self%max_open) then
          call cannot_clamp
          return
        endif
        v = b
      endif
    endif
    endsubroutine real_range

    function bound(string, single) result(b)
    !< Bound read in the kind of the value (validated at definition).
    character(*), intent(in) :: string !< Bound as given.
    logical,      intent(in) :: single !< Read as real(R4P).
    real(R8P)                :: b      !< Bound.
    real(R4P)                :: b4     !< Bound, real(R4P).
    logical                  :: ok     !< Conversion status.

    if (single) then
      read(string, *, iostat=self%error) b4
      b = real(b4, R8P)
      self%error = 0
    else
      call read_real(string, b, ok)
    endif
    endfunction bound

#if defined PENF_R16P
    subroutine real16_range(v)
    !< Check (or clamp) a real(R16P) value.
    real(R16P), intent(inout) :: v   !< Value.
    real(R16P)                :: b   !< Bound.
    integer(I4P)              :: ios !< I/O status.

    if (allocated(self%range_min)) then
      read(self%range_min, *, iostat=ios) b
      if (v < b .or. (self%min_open .and. v == b)) then
        if (.not.self%clamp) then
          call out_of_range
          return
        elseif (self%min_open) then
          call cannot_clamp
          return
        endif
        v = b
      endif
    endif
    if (allocated(self%range_max)) then
      read(self%range_max, *, iostat=ios) b
      if (v > b .or. (self%max_open .and. v == b)) then
        if (.not.self%clamp) then
          call out_of_range
          return
        elseif (self%max_open) then
          call cannot_clamp
          return
        endif
        v = b
      endif
    endif
    endsubroutine real16_range
#endif

    subroutine out_of_range
    !< Report the value out of range.
    call self%errored(pref=pref, error=ERROR_OUT_OF_RANGE, val_str=trim(adjustl(text)))
    endsubroutine out_of_range

    subroutine cannot_clamp
    !< Report a real that cannot be clamped to an open bound.
    call self%errored(pref=pref, error=ERROR_RANGE_DEFINITION, &
                      val_str='a real value cannot be clamped to the open bound of '//self%range_text())
    endsubroutine cannot_clamp
  endsubroutine check_range

  subroutine check_alternate_consistency(self, pref)
  !< Check that an alternate action (F16 of #125) is a plain flag: no nargs, envvar, positional, choices, required, exclude.
  class(command_line_argument), intent(inout) :: self !< CLA data.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.

  if (.not.allocated(self%act)) return
  if (self%act /= ACTION_ALTERNATE) return
  if (allocated(self%nargs) .or. allocated(self%envvar) .or. self%is_positional .or. allocated(self%choices) .or. &
      self%is_required .or. self%m_exclude /= '') call self%errored(pref=pref, error=ERROR_ALTERNATE_INCONSISTENT)
  endsubroutine check_alternate_consistency

  subroutine check_switch_neg_consistency(self, pref)
  !< Check that a negation (switch_neg, F11 of #125) belongs to a named scalar flag and differs from its own names.
  class(command_line_argument), intent(inout) :: self !< CLA data.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.
  logical                                     :: ok   !< Consistency.

  if (.not.allocated(self%switch_neg)) return
  ok = .false.
  if (allocated(self%act)) ok = self%act == ACTION_STORE_TRUE .or. self%act == ACTION_STORE_FALSE
  ok = ok .and. (.not.self%is_positional) .and. (.not.allocated(self%nargs)) .and. len_trim(self%switch_neg) > 0
  if (ok .and. allocated(self%switch)) ok = adjustl(self%switch) /= adjustl(self%switch_neg)
  if (ok .and. allocated(self%switch_ab)) ok = adjustl(self%switch_ab) /= adjustl(self%switch_neg)
  if (.not.ok) call self%errored(pref=pref, error=ERROR_SWITCH_NEG_INCONSISTENT)
  endsubroutine check_switch_neg_consistency

  subroutine check_map_consistency(self, pref)
  !< Check a map (F18 of #125): a named store list (nargs) or append, without choices, not the configuration file; map_keys
  !< only on a map. The default pairs are checked as passed ones.
  class(command_line_argument), intent(inout) :: self !< CLA data.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.
  logical                                     :: ok   !< Consistency.

  if (.not.self%is_map) then
    if (allocated(self%map_keys)) call self%errored(pref=pref, error=ERROR_MAP_INCONSISTENT)
    return
  endif
  ok = allocated(self%act) .and. (.not.self%is_positional) .and. (.not.allocated(self%choices)) .and. (.not.self%is_config)
  if (ok) ok = (self%act == ACTION_STORE .and. allocated(self%nargs)) .or. self%act == ACTION_APPEND
  if (.not.ok) then
    call self%errored(pref=pref, error=ERROR_MAP_INCONSISTENT)
    return
  endif
  if (allocated(self%def)) call self%check_map_list(list=replace_all(string=unique(string=wstrip(self%def), substring=' '), &
                                                                     substring=' ', restring=LIST_SEP), pref=pref)
  endsubroutine check_map_consistency

  subroutine check_map(self, pref)
  !< Check the KEY=VALUE pairs of a map, whatever their source (F18 of #125): called by parse after the values are settled.
  class(command_line_argument), intent(inout) :: self !< CLA data.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.

  if (self%is_map) call self%check_map_list(list=self%stored_list(), pref=pref)
  endsubroutine check_map

  subroutine check_map_list(self, list, pref)
  !< Check the items of a stored list as KEY=VALUE pairs: format (a non-empty KEY before the first '='), repeated keys, and
  !< the map_keys whitelist (with a "Did you mean" hint).
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  character(*),                 intent(in)    :: list     !< Stored list.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  character(:), allocatable                   :: items(:) !< Items.
  type(flap_string), allocatable              :: keys(:)  !< Keys, as found.
  type(flap_string), allocatable              :: allowed(:) !< Allowed keys.
  character(len=:), allocatable               :: key      !< Current key.
  character(len=:), allocatable               :: names    !< Allowed keys, for the message.
  integer(I4P)                                :: n        !< Number of items.
  integer(I4P)                                :: i        !< Counter.
  integer(I4P)                                :: k        !< Counter.
  integer(I4P)                                :: e        !< Position of the first '='.

  call list_items(list, items, n)
  allowed = key_list()
  allocate(keys(n))
  do i=1, n
    e = index(items(i), '=')
    if (e <= 1) then
      call self%errored(pref=pref, error=ERROR_MAP_FORMAT, val_str=trim(items(i)))
      return
    endif
    key = items(i)(:e-1)
    do k=1, i-1
      if (keys(k)%s == key) then
        call self%errored(pref=pref, error=ERROR_MAP_DUPLICATE_KEY, val_str=key)
        return
      endif
    enddo
    keys(i)%s = key
    if (size(allowed, dim=1) > 0) then
      if (.not.any([(allowed(k)%s == key, k=1, size(allowed, dim=1))])) then
        names = allowed(1)%s
        do k=2, size(allowed, dim=1)
          names = names//', '//allowed(k)%s
        enddo
        call self%errored(pref=pref, error=ERROR_MAP_UNKNOWN_KEY, val_str=key, &
                          hint=' (allowed: '//names//')!'//suggestions(key, allowed, .false.))
        return
      endif
    endif
  enddo
  contains
    function key_list() result(list)
    !< The allowed keys (map_keys split at the commas, trimmed), sized first and filled by element.
    type(flap_string), allocatable :: list(:) !< Keys.
    character(len=:), allocatable  :: rest    !< Keys not yet split.
    integer(I4P)                   :: c       !< Position of the next comma.
    integer(I4P)                   :: m       !< Counter.

    if (.not.allocated(self%map_keys)) then
      allocate(list(0))
      return
    endif
    if (len_trim(self%map_keys) == 0) then
      allocate(list(0))
      return
    endif
    allocate(list(count(transfer(self%map_keys, 'a', len(self%map_keys)) == ',') + 1))
    rest = self%map_keys
    m = 0
    do
      c = index(rest, ',')
      m = m + 1
      if (c > 0) then
        list(m)%s = trim(adjustl(rest(:c-1)))
        rest = rest(c+1:)
      else
        list(m)%s = trim(adjustl(rest))
        exit
      endif
    enddo
    endfunction key_list
  endsubroutine check_map_list

  subroutine get_map(self, keys, values, pref)
  !< Get the keys and values of a map (F18 of #125), in the order given; ERROR_MAP_INCONSISTENT if the CLA is not a map.
  class(command_line_argument), intent(inout) :: self      !< CLA data.
  character(*), allocatable,    intent(out)   :: keys(:)   !< Keys.
  character(*), allocatable,    intent(out)   :: values(:) !< Values.
  character(*), optional,       intent(in)    :: pref      !< Prefixing string.
  character(:), allocatable                   :: items(:)  !< Items.
  integer(I4P)                                :: n         !< Number of items.
  integer(I4P)                                :: i         !< Counter.
  integer(I4P)                                :: e         !< Position of the first '='.

  self%error = 0
  if (.not.self%is_map) then
    call self%errored(pref=pref, error=ERROR_MAP_INCONSISTENT)
    return
  endif
  call list_items(self%stored_list(), items, n)
  allocate(keys(n), values(n))
  do i=1, n
    e = index(items(i), '=')
    keys(i) = items(i)(:e-1)
    values(i) = trim(items(i)(e+1:))
  enddo
  endsubroutine get_map

  subroutine get_map_value(self, key, val, found, pref)
  !< Get the value of a key of a map, converted to the type of val (F18 of #125). A missing key leaves val untouched:
  !< found=.false., or ERROR_MAP_KEY_MISSING without found. A conversion error keeps its code and names the key.
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  character(*),                 intent(in)    :: key      !< Key.
  class(*),                     intent(inout) :: val      !< Value.
  logical, optional,            intent(out)   :: found    !< The key is in the map.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  character(:), allocatable                   :: items(:) !< Items.
  integer(I4P)                                :: n        !< Number of items.
  integer(I4P)                                :: i        !< Counter.
  integer(I4P)                                :: e        !< Position of the first '='.

  self%error = 0
  if (present(found)) found = .false.
  if (.not.self%is_map) then
    call self%errored(pref=pref, error=ERROR_MAP_INCONSISTENT)
    return
  endif
  call list_items(self%stored_list(), items, n)
  do i=1, n
    e = index(items(i), '=')
    if (e <= 1) cycle
    if (items(i)(:e-1) /= trim(key)) cycle
    if (present(found)) found = .true.
    call self%get_cla_from_buffer(buffer=trim(items(i)(e+1:)), val=val, pref=pref)
    if (self%error /= 0) then
      self%error_message = self%error_prefix(pref=pref)//': value "'//trim(items(i)(e+1:))//'" of key "'//trim(key)//&
                           '" of "'//trim(adjustl(self%switch))//'" cannot be converted!'
      call self%print_error_message
    endif
    return
  enddo
  if (.not.present(found)) call self%errored(pref=pref, error=ERROR_MAP_KEY_MISSING, val_str=trim(key))
  endsubroutine get_map_value

  subroutine check_path_consistency(self, pref)
  !< Check that the path checks (must_exist, readable, writable, allow_dash) are on an option taking a value: store,
  !< store* or append (F09 of #125).
  class(command_line_argument), intent(inout) :: self !< CLA data.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.

  if (.not.(self%has_path_checks().or.self%allow_dash)) return
  if (self%act /= ACTION_STORE .and. self%act /= ACTION_STORE_STAR .and. self%act /= ACTION_APPEND) &
    call self%errored(pref=pref, error=ERROR_PATH_INCONSISTENT)
  endsubroutine check_path_consistency

  subroutine check_m_exclude_consistency(self, pref)
  !< Check mutually exclusion consistency.
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.

  if ((self%is_required).and.(self%m_exclude/='')) then
    call self%errored(pref=pref, error=ERROR_REQUIRED_M_EXCLUDE)
    return
  endif
  if ((self%is_positional).and.(self%m_exclude/='')) then
    call self%errored(pref=pref, error=ERROR_POSITIONAL_M_EXCLUDE)
    return
  endif
  endsubroutine check_m_exclude_consistency

  subroutine check_named_consistency(self, pref)
  !< Check named CLA consistency.
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.

  if ((.not.self%is_positional).and.(.not.allocated(self%switch))) call self%errored(pref=pref, error=ERROR_NAMED_NO_NAME)
  endsubroutine check_named_consistency

  subroutine check_positional_consistency(self, pref)
  !< Check positional CLA consistency.
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.

  if ((self%is_positional).and.(self%position==0_I4P)) then
    call self%errored(pref=pref, error=ERROR_POSITIONAL_NO_POSITION)
    return
  elseif ((self%is_positional).and.(self%act/=action_store)) then
    call self%errored(pref=pref, error=ERROR_POSITIONAL_NO_STORE)
  elseif ((self%is_positional).and.allocated(self%nargs)) then
    call self%errored(pref=pref, error=ERROR_POSITIONAL_NARGS)
  endif
  endsubroutine check_positional_consistency

  subroutine check_choices(self, val, pref, text)
  !< Check if CLA value is in allowed choices.
  !<
  !< @note This procedure can be called if and only if cla%choices has been allocated.
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  class(*),                     intent(inout) :: val     !< CLA value; a character one becomes the declared spelling.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  character(*), optional,       intent(in)    :: text    !< The value as given, for the message (not the number re-written).
  character(len(self%choices)), allocatable   :: toks(:) !< Tokens for parsing choices list.
  integer(I4P)                                :: Nc      !< Number of choices.
  logical                                     :: val_in  !< Flag for checking if val is in the choosen range.
  character(len=:), allocatable               :: val_str !< Value in string form.
  character(len=:), allocatable               :: tmp     !< Temporary string for avoiding GNU gfrotran bug.
  integer(I4P)                                :: c       !< Counter.

  val_in = .false.
  val_str = ''
  tmp = self%choices
  call tokenize(strin=tmp, delimiter=',', toks=toks, Nt=Nc)
  select type(val)
#if defined PENF_R16P
  type is(real(R16P))
    val_str = str(n=val)
    do c=1, Nc
      if (val==cton(str=trim(adjustl(toks(c))), knd=real(1, R16P))) val_in = .true.
    enddo
#endif
  type is(real(R8P))
    val_str = str(n=val)
    do c=1, Nc
      if (val==cton(str=trim(adjustl(toks(c))), knd=1._R8P)) val_in = .true.
    enddo
  type is(real(R4P))
    val_str = str(n=val)
    do c=1, Nc
      if (val==cton(str=trim(adjustl(toks(c))), knd=1._R4P)) val_in = .true.
    enddo
  type is(integer(I8P))
    val_str = str(n=val)
    do c=1, Nc
      if (val==cton(str=trim(adjustl(toks(c))), knd=1_I8P)) val_in = .true.
    enddo
  type is(integer(I4P))
    val_str = str(n=val)
    do c=1, Nc
      if (val==cton(str=trim(adjustl(toks(c))), knd=1_I4P)) val_in = .true.
    enddo
  type is(integer(I2P))
    val_str = str(n=val)
    do c=1, Nc
      if (val==cton(str=trim(adjustl(toks(c))), knd=1_I2P)) val_in = .true.
    enddo
  type is(integer(I1P))
    val_str = str(n=val)
    do c=1, Nc
      if (val==cton(str=trim(adjustl(toks(c))), knd=1_I1P)) val_in = .true.
    enddo
  type is(character(*))
    val_str = val
    if (self%case_sensitive) then
      do c=1, Nc
        if (val==toks(c)) val_in = .true.
      enddo
    else
      ! any case (F14): the value becomes the declared spelling of the choice
      do c=1, Nc
        if (upper_case(trim(adjustl(val)))==upper_case(trim(adjustl(toks(c))))) then
          val_in = .true.
          val = trim(adjustl(toks(c)))
          exit
        endif
      enddo
    endif
  type is(logical)
    call self%errored(pref=pref, error=ERROR_CHOICES_LOGICAL)
  class default
    call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
  endselect
  if (present(text)) val_str = trim(adjustl(text)) ! "2", not "+2" (defect 1 of #126)
  if (.not.val_in.and.(self%error==0)) then
    call self%errored(pref=pref, error=ERROR_NOT_IN_CHOICES, val_str=val_str)
  endif
  endsubroutine check_choices

  subroutine check_choices_text(self, text, val, pref)
  !< Check the choices of a character value on the whole value, then store it into the caller's variable (B38 of #126).
  !<
  !< A variable shorter than the value holds it truncated (`fex` in a `character(2)` is `fe`, a choice): the check must
  !< come first. With `case_sensitive=.false.` the variable receives the declared spelling of the choice.
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*),                 intent(in)    :: text  !< Whole value.
  character(*),                 intent(inout) :: val   !< Caller's variable.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  character(len=:), allocatable               :: whole !< Whole value (the declared spelling after the check).

  whole = text
  call self%check_choices(val=whole, pref=pref)
  if (self%error == 0) val = whole
  endsubroutine check_choices_text

  subroutine cast_number(self, text, val, pref)
  !< Convert a value to the number type of `val`, quietly: a failure is `ERROR_CASTING_NUMBER`, reported by FLAP (B40 of #126).
  !<
  !< PENF's `cton` writes its own message on standard error (not on the error unit of the CLI) and returns the I/O status
  !< as the error: values are never converted with it.
  class(command_line_argument), intent(inout) :: self      !< CLA data.
  character(*),                 intent(in)    :: text      !< Value.
  class(*),                     intent(inout) :: val       !< Number.
  character(*), optional,       intent(in)    :: pref      !< Prefixing string.
  character(len=:), allocatable               :: trimmed   !< Value without the blanks around it.
  character(len=:), allocatable               :: type_name !< Type of the number, for the message.
  integer(I4P)                                :: ios       !< I/O status.

  trimmed = trim(adjustl(text))
  ios = 0
  type_name = 'a real'
  select type(val)
#if defined PENF_R16P
  type is(real(R16P))
    read(trimmed, *, iostat=ios) val
#endif
  type is(real(R8P))
    read(trimmed, *, iostat=ios) val
  type is(real(R4P))
    read(trimmed, *, iostat=ios) val
  type is(integer(I8P))
    type_name = 'an integer'
    read(trimmed, *, iostat=ios) val
  type is(integer(I4P))
    type_name = 'an integer'
    read(trimmed, *, iostat=ios) val
  type is(integer(I2P))
    type_name = 'an integer'
    read(trimmed, *, iostat=ios) val
  type is(integer(I1P))
    type_name = 'an integer'
    read(trimmed, *, iostat=ios) val
  class default
    call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
    return
  endselect
  if (ios /= 0 .or. len(trimmed) == 0) then
    call self%errored(pref=pref, error=ERROR_CASTING_NUMBER, val_str=trimmed, type_name=type_name)
  else
    self%error = 0
  endif
  endsubroutine cast_number

  function check_list_size(self, vals, pref) result(is_ok)
  !< Check CLA multiple values list size consistency: a list without values (or with a single blank one) is empty.
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  character(*),                 intent(in)    :: vals(:) !< Stored values.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  logical                                     :: is_ok   !< Check result.

  is_ok = size(vals, dim=1) > 1
  if (size(vals, dim=1) == 1) is_ok = len_trim(vals(1)) > 0
  if (.not.is_ok) then
    ! there is no real value, but only for nargs=+ this is a real error
    if (allocated(self%nargs)) then ! nested: Fortran does not short-circuit .and.
      if (self%nargs=='+') call self%errored(pref=pref, error=ERROR_NARGS_INSUFFICIENT)
    endif
  endif
  endfunction check_list_size

  function stored_list(self) result(list)
  !< Return the stored list of values: the resolved one if given by the user (has_value), the default one otherwise.
  class(command_line_argument), intent(in) :: self !< CLA data.
  character(:), allocatable                :: list !< Stored list.

  list = ''
  if (self%has_value().and.allocated(self%val)) then
    list = self%val
  elseif (allocated(self%def)) then
    list = self%def
  endif
  endfunction stored_list

  subroutine get_cla(self, val, pref)
  !< Get CLA (single) value.
  implicit none
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  class(*),                     intent(inout) :: val   !< CLA value.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  character(len=:), allocatable               :: buffer !< Stored value of a flag.

  if (.not.self%is_required_passed(pref=pref)) return
  if (self%act==action_store.or.self%act==action_store_star) then
    if (self%has_value().and.allocated(self%val)) then
      call self%get_cla_from_buffer(buffer=self%val, val=val, pref=pref)
    elseif (allocated(self%def)) then ! using default value
      call self%get_cla_from_buffer(buffer=self%def, val=val, pref=pref)
    endif
    if (allocated(self%choices).and.self%error==0) then
      select type(val)
      type is(character(*))
        ! the whole value, not the one truncated to the variable (B38 of #126)
        call self%check_choices_text(text=self%stored_list(), val=val, pref=pref)
      class default
        call self%check_choices(val=val, pref=pref, text=self%stored_list())
      endselect
    endif
    if (self%has_range().and.self%error==0) call self%check_range(val=val, text=self%stored_list(), pref=pref)
  elseif (self%act==action_append) then
    call self%errored(pref=pref, error=ERROR_APPEND_SCALAR_GET)
  elseif (self%act==action_count) then
    ! the number of occurrences, or the default when not passed
    call self%get_cla_from_buffer(buffer=self%stored_list(), val=val, pref=pref)
    if (self%has_range().and.self%error==0) call self%check_range(val=val, text=self%stored_list(), pref=pref)
  elseif (self%act==action_store_true.or.self%act==ACTION_ALTERNATE) then
    if (self%source == SOURCE_COMMANDLINE) then ! a flag passed on the command line, or its negation
      select type(val)
      type is(logical)
        val = self%flag_value()
      class default
        call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
      endselect
    elseif (self%has_value().or.allocated(self%def)) then
      ! from the environment (normalized by set_env_value) or the default
      select type(val)
      type is(logical)
        buffer = self%stored_list()
        read(buffer, *, iostat=self%error)val
        if (self%error/=0) call self%errored(pref=pref, error=ERROR_CASTING_LOGICAL, log_value=buffer)
      class default
        call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
      endselect
    endif
  elseif (self%act==action_store_false) then
    if (self%source == SOURCE_COMMANDLINE) then ! a flag passed on the command line, or its negation
      select type(val)
      type is(logical)
        val = self%flag_value()
      class default
        call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
      endselect
    elseif (self%has_value().or.allocated(self%def)) then
      ! from the environment (normalized by set_env_value) or the default
      select type(val)
      type is(logical)
        buffer = self%stored_list()
        read(buffer, *, iostat=self%error)val
        if (self%error/=0) call self%errored(pref=pref, error=ERROR_CASTING_LOGICAL, log_value=buffer)
      class default
        call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
      endselect
    endif
  endif
  endsubroutine get_cla

  subroutine get_cla_from_buffer(self, buffer, val, pref)
  !< Get CLA (single) value from parsed value.
  implicit none
  class(command_line_argument), intent(inout) :: self   !< CLA data.
  character(*),                 intent(in)    :: buffer !< Buffer containing values (parsed or default CLA value).
  class(*),                     intent(inout) :: val    !< CLA value.
  character(*), optional,       intent(in)    :: pref   !< Prefixing string.

  select type(val)
#if defined PENF_R16P
  type is(real(R16P))
    call self%cast_number(text=buffer, val=val, pref=pref)
#endif
  type is(real(R8P))
    call self%cast_number(text=buffer, val=val, pref=pref)
  type is(real(R4P))
    call self%cast_number(text=buffer, val=val, pref=pref)
  type is(integer(I8P))
    call self%cast_number(text=buffer, val=val, pref=pref)
  type is(integer(I4P))
    call self%cast_number(text=buffer, val=val, pref=pref)
  type is(integer(I2P))
    call self%cast_number(text=buffer, val=val, pref=pref)
  type is(integer(I1P))
    call self%cast_number(text=buffer, val=val, pref=pref)
  type is(logical)
    read(buffer, *, iostat=self%error)val
    if (self%error/=0) call self%errored(pref=pref, error=ERROR_CASTING_LOGICAL, log_value=buffer)
  type is(character(*))
    val = buffer
  class default
    call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
  endselect
  endsubroutine get_cla_from_buffer

  subroutine get_cla_list(self, pref, val)
  !< Get CLA multiple values.
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  class(*),                     intent(inout) :: val(1:)  !< CLA values.

  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.self%is_list()) then
    call self%errored(pref=pref,error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store.or.self%act==action_append) then
    call self%get_cla_list_from_buffer(buffer=self%stored_list(), val=val, pref=pref)
  elseif (self%act==action_store_true) then
    if (self%source == SOURCE_COMMANDLINE) then ! a flag passed on the command line
      select type(val)
      type is(logical)
        val = .true.
      class default
        call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
      endselect
    else
      select type(val)
      type is(logical)
        call self%get_cla_list_from_buffer(buffer=self%stored_list(), val=val, pref=pref)
      class default
        call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
      endselect
    endif
  elseif (self%act==action_store_false) then
    if (self%source == SOURCE_COMMANDLINE) then ! a flag passed on the command line
      select type(val)
      type is(logical)
        val = .false.
      class default
        call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
      endselect
    else
      select type(val)
      type is(logical)
        call self%get_cla_list_from_buffer(buffer=self%stored_list(), val=val, pref=pref)
      class default
        call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
      endselect
    endif
  endif
  endsubroutine get_cla_list

  subroutine get_cla_list_from_buffer(self, buffer, val, pref)
  !< Get CLA multiple values from a buffer.
  implicit none
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  character(*),                 intent(in)    :: buffer  !< Buffer containing values (parsed or default CLA value).
  class(*),                     intent(inout) :: val(1:) !< CLA value.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  integer(I4P)                                :: Nv      !< Number of values.
  character(:), allocatable                   :: vals(:) !< Stored values.
  integer(I4P)                                :: v       !< Values counter.

  call list_items(buffer, vals, Nv)
  if (Nv /= size(val, dim=1)) then
    ! B27 (#125): never write past the end of the array, nor leave part of it silently unset
    call self%errored(pref=pref, error=ERROR_LIST_SIZE, val_str=trim(str(Nv, .true.))//' values, but the array has '//&
                      trim(str(int(size(val, dim=1), I4P), .true.))//' elements')
    return
  endif
  select type(val)
#if defined PENF_R16P
  type is(real(R16P))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref,text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
#endif
  type is(real(R8P))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref,text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  type is(real(R4P))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref,text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  type is(integer(I8P))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref,text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  type is(integer(I4P))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref,text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  type is(integer(I2P))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref,text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  type is(integer(I1P))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref,text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  type is(logical)
    do v=1, Nv
      read(vals(v),*,iostat=self%error)val(v)
      if (self%error/=0) then
        call self%errored(pref=pref,error=ERROR_CASTING_LOGICAL,log_value=vals(v))
        exit
      endif
    enddo
  type is(character(*))
    ! delegate to a character(*) dummy: gfortran 13.3 and 14.2 assign the elements of a class(*) character array with a
    ! wrong element length inside `type is(character(*))` (fixed in 13.4 and 14.3)
    call get_cla_list_character(self, val=val, vals=vals, pref=pref)
  class default
    call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
  endselect
  endsubroutine get_cla_list_from_buffer

  subroutine get_cla_list_character(self, val, vals, pref)
  !< Get CLA multiple values into a character array, checking the choices of each value.
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  character(*),                 intent(inout) :: val(1:) !< CLA values.
  character(*),                 intent(in)    :: vals(1:)!< Values to store.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  integer(I4P)                                :: v       !< Values counter.

  do v=1, size(vals, dim=1)
    if (allocated(self%choices)) then
      call self%check_choices_text(text=vals(v), val=val(v), pref=pref) ! the whole value (B38 of #126)
    else
      val(v) = vals(v)
    endif
    if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
    if (self%error/=0) exit
  enddo
  endsubroutine get_cla_list_character

  subroutine get_cla_list_varying_R16P(self, val, pref)
  !< Get CLA (multiple) value with varying size, real(R16P).
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  real(R16P), allocatable      , intent(out)   :: val(:)  !< CLA values.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  character(:), allocatable                   :: vals(:) !< Stored values (parsed or default).
  integer(I4P)                                :: Nv      !< Number of values.
  integer(I4P)                                :: v       !< Values counter.

  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.self%is_list()) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store.or.self%act==action_append) then
    call list_items(self%stored_list(), vals, Nv)
    if (.not.self%check_list_size(vals=vals, pref=pref)) then
      if (self%error /= 0) return
      Nv = 0 ! an empty list (nargs='*' passed without values, D21): a size-0 array
    endif
    allocate(real(R16P):: val(1:Nv))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v), pref=pref, text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  elseif (self%act==action_store_true.or.self%act==action_store_false) then
    call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
  endif
  endsubroutine get_cla_list_varying_R16P

  subroutine get_cla_list_varying_R8P(self, val, pref)
  !< Get CLA (multiple) value with varying size, real(R8P).
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  real(R8P), allocatable       , intent(out)   :: val(:)  !< CLA values.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  character(:), allocatable                   :: vals(:) !< Stored values (parsed or default).
  integer(I4P)                                :: Nv      !< Number of values.
  integer(I4P)                                :: v       !< Values counter.

  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.self%is_list()) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store.or.self%act==action_append) then
    call list_items(self%stored_list(), vals, Nv)
    if (.not.self%check_list_size(vals=vals, pref=pref)) then
      if (self%error /= 0) return
      Nv = 0 ! an empty list (nargs='*' passed without values, D21): a size-0 array
    endif
    allocate(real(R8P):: val(1:Nv))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v), pref=pref, text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  elseif (self%act==action_store_true.or.self%act==action_store_false) then
    call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
  endif
  endsubroutine get_cla_list_varying_R8P

  subroutine get_cla_list_varying_R4P(self, val, pref)
  !< Get CLA (multiple) value with varying size, real(R4P).
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  real(R4P), allocatable       , intent(out)   :: val(:)  !< CLA values.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  character(:), allocatable                   :: vals(:) !< Stored values (parsed or default).
  integer(I4P)                                :: Nv      !< Number of values.
  integer(I4P)                                :: v       !< Values counter.

  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.self%is_list()) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store.or.self%act==action_append) then
    call list_items(self%stored_list(), vals, Nv)
    if (.not.self%check_list_size(vals=vals, pref=pref)) then
      if (self%error /= 0) return
      Nv = 0 ! an empty list (nargs='*' passed without values, D21): a size-0 array
    endif
    allocate(real(R4P):: val(1:Nv))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v), pref=pref, text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  elseif (self%act==action_store_true.or.self%act==action_store_false) then
    call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
  endif
  endsubroutine get_cla_list_varying_R4P

  subroutine get_cla_list_varying_I8P(self, val, pref)
  !< Get CLA (multiple) value with varying size, integer(I8P).
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  integer(I8P), allocatable    , intent(out)   :: val(:)  !< CLA values.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  character(:), allocatable                   :: vals(:) !< Stored values (parsed or default).
  integer(I4P)                                :: Nv      !< Number of values.
  integer(I4P)                                :: v       !< Values counter.

  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.self%is_list()) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store.or.self%act==action_append) then
    call list_items(self%stored_list(), vals, Nv)
    if (.not.self%check_list_size(vals=vals, pref=pref)) then
      if (self%error /= 0) return
      Nv = 0 ! an empty list (nargs='*' passed without values, D21): a size-0 array
    endif
    allocate(integer(I8P):: val(1:Nv))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v), pref=pref, text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  elseif (self%act==action_store_true.or.self%act==action_store_false) then
    call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
  endif
  endsubroutine get_cla_list_varying_I8P

  subroutine get_cla_list_varying_I4P(self, val, pref)
  !< Get CLA (multiple) value with varying size, integer(I4P).
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  integer(I4P), allocatable    , intent(out)   :: val(:)  !< CLA values.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  character(:), allocatable                   :: vals(:) !< Stored values (parsed or default).
  integer(I4P)                                :: Nv      !< Number of values.
  integer(I4P)                                :: v       !< Values counter.

  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.self%is_list()) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store.or.self%act==action_append) then
    call list_items(self%stored_list(), vals, Nv)
    if (.not.self%check_list_size(vals=vals, pref=pref)) then
      if (self%error /= 0) return
      Nv = 0 ! an empty list (nargs='*' passed without values, D21): a size-0 array
    endif
    allocate(integer(I4P):: val(1:Nv))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v), pref=pref, text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  elseif (self%act==action_store_true.or.self%act==action_store_false) then
    call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
  endif
  endsubroutine get_cla_list_varying_I4P

  subroutine get_cla_list_varying_I2P(self, val, pref)
  !< Get CLA (multiple) value with varying size, integer(I2P).
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  integer(I2P), allocatable    , intent(out)   :: val(:)  !< CLA values.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  character(:), allocatable                   :: vals(:) !< Stored values (parsed or default).
  integer(I4P)                                :: Nv      !< Number of values.
  integer(I4P)                                :: v       !< Values counter.

  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.self%is_list()) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store.or.self%act==action_append) then
    call list_items(self%stored_list(), vals, Nv)
    if (.not.self%check_list_size(vals=vals, pref=pref)) then
      if (self%error /= 0) return
      Nv = 0 ! an empty list (nargs='*' passed without values, D21): a size-0 array
    endif
    allocate(integer(I2P):: val(1:Nv))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v), pref=pref, text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  elseif (self%act==action_store_true.or.self%act==action_store_false) then
    call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
  endif
  endsubroutine get_cla_list_varying_I2P

  subroutine get_cla_list_varying_I1P(self, val, pref)
  !< Get CLA (multiple) value with varying size, integer(I1P).
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  integer(I1P), allocatable    , intent(out)   :: val(:)  !< CLA values.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  character(:), allocatable                   :: vals(:) !< Stored values (parsed or default).
  integer(I4P)                                :: Nv      !< Number of values.
  integer(I4P)                                :: v       !< Values counter.

  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.self%is_list()) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store.or.self%act==action_append) then
    call list_items(self%stored_list(), vals, Nv)
    if (.not.self%check_list_size(vals=vals, pref=pref)) then
      if (self%error /= 0) return
      Nv = 0 ! an empty list (nargs='*' passed without values, D21): a size-0 array
    endif
    allocate(integer(I1P):: val(1:Nv))
    do v=1, Nv
      call self%cast_number(text=vals(v), val=val(v), pref=pref)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v), pref=pref, text=vals(v))
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  elseif (self%act==action_store_true.or.self%act==action_store_false) then
    call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
  endif
  endsubroutine get_cla_list_varying_I1P

  subroutine get_cla_list_varying_logical(self, val, pref)
  !< Get CLA (multiple) value with varying size, logical.
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  logical, allocatable         , intent(out)   :: val(:)  !< CLA values.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  character(:), allocatable                   :: vals(:) !< Stored values (parsed or default).
  integer(I4P)                                :: Nv      !< Number of values.
  integer(I4P)                                :: v       !< Values counter.

  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.self%is_list()) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store.or.self%act==action_append) then
    call list_items(self%stored_list(), vals, Nv)
    if (.not.self%check_list_size(vals=vals, pref=pref)) then
      if (self%error /= 0) return
      Nv = 0 ! an empty list (nargs='*' passed without values, D21): a size-0 array
    endif
    allocate(logical:: val(1:Nv))
    do v=1, Nv
      read(vals(v), *, iostat=self%error)val(v)
      if (self%error/=0) then
        call self%errored(pref=pref, error=ERROR_CASTING_LOGICAL, log_value=vals(v))
        exit
      endif
    enddo
  elseif (self%act==action_store_true.or.self%act==action_store_false) then
    ! a list of flags (B26 of #125): its defaults, or as many values as the defaults set by the flag when passed
    if (allocated(self%def)) then
      call list_items(self%def, vals, Nv)
    else
      call list_items('', vals, Nv)
    endif
    allocate(logical:: val(1:Nv))
    if (self%source == SOURCE_COMMANDLINE) then ! a flag passed on the command line
      val = self%act==action_store_true
    else
      do v=1, Nv
        read(vals(v), *, iostat=self%error)val(v)
        if (self%error/=0) then
          call self%errored(pref=pref, error=ERROR_CASTING_LOGICAL, log_value=vals(v))
          exit
        endif
      enddo
    endif
  endif
  endsubroutine get_cla_list_varying_logical

  subroutine get_cla_list_varying_char(self, val, pref)
  !< Get CLA (multiple) value with varying size, character.
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  character(*), allocatable    , intent(out)   :: val(:)  !< CLA values.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  character(:), allocatable                   :: vals(:) !< Stored values (parsed or default).
  integer(I4P)                                :: Nv      !< Number of values.
  integer(I4P)                                :: v       !< Values counter.

  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.self%is_list()) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store.or.self%act==action_append) then
    call list_items(self%stored_list(), vals, Nv)
    if (.not.self%check_list_size(vals=vals, pref=pref)) then
      if (self%error /= 0) return
      Nv = 0 ! an empty list (nargs='*' passed without values, D21): a size-0 array
    endif
    allocate(val(1:Nv))
    do v=1, Nv
      if (allocated(self%choices)) then
        call self%check_choices_text(text=trim(adjustl(vals(v))), val=val(v), pref=pref) ! the whole value (B38 of #126)
      else
        val(v) = trim(adjustl(vals(v)))
      endif
      if (self%has_range().and.self%error==0) call self%check_range(val=val(v), text=vals(v), pref=pref)
      if (self%error/=0) exit
    enddo
  elseif (self%act==action_store_true.or.self%act==action_store_false) then
    call self%errored(pref=pref, error=ERROR_UNSUPPORTED_TYPE)
  endif
  endsubroutine get_cla_list_varying_char


  elemental subroutine finalize(self)
  !< Free dynamic memory when finalizing.
  type(command_line_argument), intent(inout) :: self !< CLA data.

  call self%free
  endsubroutine finalize
  ! non type-bound procedures
  subroutine read_real(string, x, ok)
  !< Read a real from a string, quietly (cton prints an error message).
  character(*), intent(in)  :: string !< String.
  real(R8P),    intent(out) :: x      !< Value.
  logical,      intent(out) :: ok     !< The string is a number.
  integer(I4P)              :: ios    !< I/O status.

  x = 0._R8P
  read(string, *, iostat=ios) x
  ok = ios == 0 .and. len_trim(string) > 0
  endsubroutine read_real

  subroutine read_integer(string, i, ok)
  !< Read an integer from a string, quietly.
  character(*), intent(in)  :: string !< String.
  integer(I8P), intent(out) :: i      !< Value.
  logical,      intent(out) :: ok     !< The string is an integer.
  integer(I4P)              :: ios    !< I/O status.

  i = 0_I8P
  read(string, *, iostat=ios) i
  ok = ios == 0 .and. len_trim(string) > 0
  endsubroutine read_integer
endmodule flap_command_line_argument_t

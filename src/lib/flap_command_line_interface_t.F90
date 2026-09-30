!< Command Line Interface (CLI) class.
module flap_command_line_interface_t
!< Command Line Interface (CLI) class.

use face, only : colorize
use flap_command_line_argument_t, only : command_line_argument, ACTION_COUNT, ACTION_PRINT_HELP, ACTION_PRINT_MARK, &
                                         ACTION_PRINT_VERS, ACTION_STORE, ACTION_STORE_FALSE, ACTION_STORE_TRUE, ERROR_UNKNOWN
use flap_command_line_arguments_group_t, only : command_line_arguments_group, STATUS_NO_ARGS, STATUS_PRINT_H, STATUS_PRINT_M, &
                                                STATUS_PRINT_V
use flap_object_t, only : object
use flap_utils_m
use penf

implicit none
private
save

type, extends(object), public :: command_line_interface
  !< Command Line Interface (CLI) class.
  private
  type(command_line_arguments_group), allocatable :: clasg(:)                    !< CLA list [1:Na].
  type(flap_string), allocatable                  :: args(:)                     !< Actually passed command line arguments.
  logical                                         :: disable_hv=.false.          !< Disable automatic 'help' and 'version' CLAs.
  logical                                         :: is_parsed_=.false.          !< Parse status.
  logical                                         :: ignore_unknown_clas=.false. !< Disable errors-raising for passed unknown CLAs.
  logical                                         :: standalone=.true.           !< Stop after help/version/markdown.
  logical                                         :: error_hint=.true.           !< Print a hint after a failed parse.
  logical                                         :: no_args_is_help=.false.     !< Print the help when no arguments are passed.
  logical                                         :: ignore_env=.false.          !< Turn every environment lookup off.
  character(len=:), allocatable                   :: auto_envvar_prefix          !< Prefix of the generated envvar names.
  integer(I4P)                                    :: error_unknown_clas=0_I4P    !< Error trapping flag for unknown CLAs.
  contains
    ! public methods
    procedure, public :: free                            !< Free dynamic memory.
    procedure, public :: init                            !< Initialize CLI.
    procedure, public :: add_group                       !< Add CLAs group CLI.
    procedure, public :: add                             !< Add CLA to CLI.
    procedure, public :: is_passed                       !< Check if a CLA has been passed.
    procedure, public :: is_defined_group                !< Check if a CLAs group has been defined.
    procedure, public :: raise_error                     !< Report an application error in FLAP's style.
    procedure, public :: is_defined                      !< Check if a CLA has been defined.
    procedure, public :: is_parsed                       !< Check if CLI has been parsed.
    procedure, public :: set_mutually_exclusive_groups   !< Set two CLAs group as mutually exclusive.
    procedure, public :: set_mutually_exclusive_switches !< Set a mutually exclusive set of switches.
    procedure, public :: run_command => is_called_group  !< Check if a CLAs group has been run.
    procedure, public :: parse                           !< Parse Command Line Interfaces.
    procedure, public :: reset_parse                     !< Forget the result of a parse, keeping the definitions.
    generic,   public :: get =>   &
                         get_cla, &
                         get_cla_list                    !< Get CLA value(s) from CLAs list parsed.
    generic,   public :: get_varying =>                &
#if defined _R16P
                         get_cla_list_varying_R16P,    &
#endif
                         get_cla_list_varying_R8P,     &
                         get_cla_list_varying_R4P,     &
                         get_cla_list_varying_I8P,     &
                         get_cla_list_varying_I4P,     &
                         get_cla_list_varying_I2P,     &
                         get_cla_list_varying_I1P,     &
                         get_cla_list_varying_logical, &
                         get_cla_list_varying_char       !< Get CLA value(s) from CLAs list parsed, varying size list.
    procedure, public :: usage                           !< Get CLI usage.
    procedure, public :: signature                       !< Get CLI signature.
    procedure, public :: print_usage                     !< Print correct usage of CLI.
    procedure, public :: save_bash_completion            !< Save bash completion script (for named CLAs only).
    procedure, public :: save_man_page                   !< Save CLI usage as man page.
    procedure, public :: save_usage_to_markdown          !< Save CLI usage as markdown.
    ! private methods
    procedure, private :: ensure_builtins                 !< Add the builtin CLAs (help, markdown, version, --) if missing.
    procedure, private :: builtins_missing                !< Check if the builtin CLAs still have to be added.
    procedure, private :: usage_core                      !< Get CLI usage (builtins already present).
    procedure, private :: signature_core                  !< Get CLI signature (builtins already present).
    procedure, private :: save_bash_completion_core       !< Save bash completion script (builtins already present).
    procedure, private :: save_man_page_core              !< Save CLI usage as man page (builtins already present).
    procedure, private :: save_usage_to_markdown_core     !< Save CLI usage as markdown (builtins already present).
    procedure, private :: parse_core                      !< Parse the command line (body of parse).
    procedure, private :: group_index                     !< Index of the group with a name, -1 if none.
    procedure, private :: is_fatal                        !< Check if the current error stops parsing.
    procedure, private :: dispatch_status                 !< Print help/version/markdown in the D3 order.
    procedure, private :: no_args_help                    !< Print the help when no arguments are passed.
    procedure, private :: print_error_hint                !< Print the hint after a failed parse.
    procedure, private :: errored                         !< Trig error occurence and print meaningful message.
    procedure, private :: check                           !< Check data consistency.
    procedure, private :: check_m_exclusive               !< Check if two mutually exclusive CLAs group have been called.
    procedure, private :: get_clasg_indexes               !< Get CLAs groups indexes.
    generic,   private :: get_args =>           &
                          get_args_from_string, &
                          get_args_from_invocation        !< Get CLAs.
    procedure, private :: get_args_from_string            !< Get CLAs from string.
    procedure, private :: get_args_from_invocation        !< Get CLAs from CLI invocation.
    procedure, private :: get_cla                         !< Get CLA (single) value from CLAs list parsed.
    procedure, private :: get_cla_list                    !< Get CLA multiple values from CLAs list parsed.
    procedure, private :: get_cla_list_varying_R16P       !< Get CLA multiple values from CLAs list parsed, varying size, R16P.
    procedure, private :: get_cla_list_varying_R8P        !< Get CLA multiple values from CLAs list parsed, varying size, R8P.
    procedure, private :: get_cla_list_varying_R4P        !< Get CLA multiple values from CLAs list parsed, varying size, R4P.
    procedure, private :: get_cla_list_varying_I8P        !< Get CLA multiple values from CLAs list parsed, varying size, I8P.
    procedure, private :: get_cla_list_varying_I4P        !< Get CLA multiple values from CLAs list parsed, varying size, I4P.
    procedure, private :: get_cla_list_varying_I2P        !< Get CLA multiple values from CLAs list parsed, varying size, I2P.
    procedure, private :: get_cla_list_varying_I1P        !< Get CLA multiple values from CLAs list parsed, varying size, I1P.
    procedure, private :: get_cla_list_varying_logical    !< Get CLA multiple values from CLAs list parsed, varying size, bool.
    procedure, private :: get_cla_list_varying_char       !< Get CLA multiple values from CLAs list parsed, varying size, char.
    final              :: finalize                        !< Free dynamic memory when finalizing.
endtype command_line_interface

! errors codes
integer(I4P), parameter, public :: ERROR_MISSING_CLA           = 1000 !< CLA not found in CLI.
integer(I4P), parameter, public :: ERROR_MISSING_GROUP         = 1001 !< Group not found in CLI.
integer(I4P), parameter, public :: ERROR_MISSING_SELECTION_CLA = 1002 !< CLA selection in CLI failing.
integer(I4P), parameter, public :: ERROR_TOO_FEW_CLAS          = 1003 !< Insufficient arguments for CLI.
integer(I4P), parameter, public :: ERROR_UNKNOWN_CLAS_IGNORED  = 1004 !< Unknown CLAs passed, but ignored.
integer(I4P), parameter, public :: ERROR_USER                  = 1005 !< Application error reported by raise_error.
integer(I4P), parameter, public :: ERROR_ARGUMENT_RETRIEVAL    = 1012 !< A command line argument cannot be retrieved.

contains
  ! public methods
  elemental subroutine free(self)
  !< Free dynamic memory.
  class(command_line_interface), intent(inout) :: self !< CLI data.
  integer(I4P)                                 :: g    !< Counter.

  ! object members
  call self%free_object
  ! command_line_interface members
  if (allocated(self%clasg)) then
    do g=0, size(self%clasg,dim=1) - 1
      call self%clasg(g)%free
    enddo
    deallocate(self%clasg)
  endif
  if (allocated(self%args)) deallocate(self%args)
  if (allocated(self%examples)) deallocate(self%examples)
  self%disable_hv          = .false.
  self%is_parsed_          = .false.
  self%ignore_unknown_clas = .false.
  self%error_unknown_clas  = 0_I4P
  self%standalone          = .true.
  self%error_hint          = .true.
  self%no_args_is_help     = .false.
  self%ignore_env          = .false.
  if (allocated(self%auto_envvar_prefix)) deallocate(self%auto_envvar_prefix)
  endsubroutine free

  subroutine init(self, progname, version, help, description, license, authors, examples, epilog, disable_hv, &
                  usage_lun, error_lun, version_lun, error_color, error_style, ignore_unknown_clas, standalone, &
                  error_hint, no_args_is_help, ignore_env, auto_envvar_prefix)
  !< Initialize CLI.
  class(command_line_interface), intent(inout) :: self                !< CLI data.
  character(*), optional,        intent(in)    :: progname            !< Program name.
  character(*), optional,        intent(in)    :: version             !< Program version.
  character(*), optional,        intent(in)    :: help                !< Help message introducing the CLI usage.
  character(*), optional,        intent(in)    :: description         !< Detailed description message introducing the program.
  character(*), optional,        intent(in)    :: license             !< License description.
  character(*), optional,        intent(in)    :: authors             !< Authors list.
  character(*), optional,        intent(in)    :: examples(1:)        !< Examples of correct usage.
  character(*), optional,        intent(in)    :: epilog              !< Epilog message.
  logical,      optional,        intent(in)    :: disable_hv          !< Disable automatic insert of 'help' and 'version' CLAs.
  integer(I4P), optional,        intent(in)    :: usage_lun           !< Unit number to print usage/help.
  integer(I4P), optional,        intent(in)    :: version_lun         !< Unit number to print version/license info.
  integer(I4P), optional,        intent(in)    :: error_lun           !< Unit number to print error info.
  character(*), optional,        intent(in)    :: error_color         !< ANSI color of error messages.
  character(*), optional,        intent(in)    :: error_style         !< ANSI style of error messages.
  logical,      optional,        intent(in)    :: ignore_unknown_clas !< Disable errors-raising for passed unknown CLAs.
  logical,      optional,        intent(in)    :: standalone          !< Stop after help/version/markdown (default); if
                                                                      !< false, parse returns STATUS_PRINT_H/V/M instead.
  logical,      optional,        intent(in)    :: error_hint          !< Print "Try 'prog --help' for help." after a failed
                                                                      !< parse (default).
  logical,      optional,        intent(in)    :: no_args_is_help     !< Print the help (STATUS_NO_ARGS) when no arguments
                                                                      !< are passed.
  logical,      optional,        intent(in)    :: ignore_env          !< Turn every environment lookup off (F20): envvar
                                                                      !< names are still shown in the help.
  character(*), optional,        intent(in)    :: auto_envvar_prefix  !< Generate the envvar of the options without one:
                                                                      !< PREFIX[_GROUP]_NAME (F07).
  character(len=:), allocatable                :: prog_invocation     !< Complete program invocation.
  integer(I4P)                                 :: invocation_length   !< Length of invocation.
  integer(I4P)                                 :: retrieval_status    !< Retrieval status.

  call self%free
  if (present(progname)) then
    self%progname = progname
  else
    ! try to set the default progname to the 0th command line entry a-la unix $0
    call get_command_argument(0, length=invocation_length)
    allocate(character(len=invocation_length) :: prog_invocation)
    call get_command_argument(0, value=prog_invocation, status=retrieval_status)
    if (retrieval_status==0) then
      self%progname = prog_invocation
    else
      self%progname = 'program'
    endif
  endif
  self%version     = 'unknown' ; if (present(version    )) self%version     = version
  self%help        = 'usage: ' ; if (present(help       )) self%help        = help
  self%description = ''        ; if (present(description)) self%description = description
  self%license     = ''        ; if (present(license    )) self%license     = license
  self%authors     = ''        ; if (present(authors    )) self%authors     = authors
  call self%set_examples(examples)
  self%epilog      = '' ; if (present(epilog     ))         self%epilog              = epilog
                          if (present(disable_hv ))         self%disable_hv          = disable_hv         ! default set by self%free
                          if (present(usage_lun  ))         self%usage_lun           = usage_lun          ! default set by self%free
                          if (present(version_lun))         self%version_lun         = version_lun        ! default set by self%free
                          if (present(error_lun  ))         self%error_lun           = error_lun          ! default set by self%free
  self%error_color = '' ; if (present(error_color))         self%error_color         = error_color
  self%error_style = '' ; if (present(error_style))         self%error_style         = error_style
                          if (present(ignore_unknown_clas)) self%ignore_unknown_clas = ignore_unknown_clas! default set by self%free
                          if (present(standalone))          self%standalone          = standalone         ! default set by self%free
                          if (present(error_hint))          self%error_hint          = error_hint         ! default set by self%free
                          if (present(no_args_is_help))     self%no_args_is_help     = no_args_is_help    ! default set by self%free
                          if (present(ignore_env))          self%ignore_env          = ignore_env         ! default set by self%free
  self%auto_envvar_prefix = '' ; if (present(auto_envvar_prefix)) self%auto_envvar_prefix = trim(adjustl(auto_envvar_prefix))
  ! initialize only the first default group
  allocate(self%clasg(0:0))
  call self%clasg(0)%assign_object(self)
  self%clasg(0)%group = ''
  endsubroutine init

  subroutine add_group(self, help, description, exclude, examples, group, no_args_is_help)
  !< Add CLAs group to CLI.
  class(command_line_interface), intent(inout)    :: self              !< CLI data.
  character(*), optional,        intent(in)       :: help              !< Help message.
  character(*), optional,        intent(in)       :: description       !< Detailed description.
  character(*), optional,        intent(in)       :: exclude           !< Group name of the mutually exclusive group.
  character(*), optional,        intent(in)       :: examples(1:)      !< Examples of correct usage of the group.
  character(*),                  intent(in)       :: group             !< Name of the grouped CLAs.
  logical, optional,             intent(in)       :: no_args_is_help   !< Print the help of the group when invoked alone.
  type(command_line_arguments_group), allocatable :: clasg_list_new(:) !< New (extended) CLAs group list.
  character(len=:), allocatable                   :: helpd             !< Help message.
  character(len=:), allocatable                   :: descriptiond      !< Detailed description.
  character(len=:), allocatable                   :: excluded          !< Group name of the mutually exclusive group.
  integer(I4P)                                    :: Ng                !< Number of groups.
  integer(I4P)                                    :: gi                !< Group index

  if (.not.self%is_defined_group(group=group)) then
    helpd        = 'usage: ' ; if (present(help       )) helpd        = help
    descriptiond = ''        ; if (present(description)) descriptiond = description
    excluded     = ''        ; if (present(exclude    )) excluded     = exclude
    Ng = size(self%clasg,dim=1)
    allocate(clasg_list_new(0:Ng))
!    clasg_list_new(0:Ng-1) = self%clasg(0:Ng-1) ! Not working on Intel Fortran 15.0.2
    do gi = 0, Ng-1
      clasg_list_new(gi) = self%clasg(gi)
    enddo
    call clasg_list_new(Ng)%assign_object(self)
    clasg_list_new(Ng)%help        = helpd
    clasg_list_new(Ng)%description = descriptiond
    clasg_list_new(Ng)%group       = group
    clasg_list_new(Ng)%m_exclude   = excluded
    call clasg_list_new(Ng)%set_examples(examples)
    if (present(no_args_is_help)) clasg_list_new(Ng)%no_args_is_help = no_args_is_help
    if (allocated(self%clasg)) deallocate(self%clasg)
    allocate(self%clasg(lbound(clasg_list_new,1):ubound(clasg_list_new,1)), source=clasg_list_new)
    deallocate(clasg_list_new)
  endif
  endsubroutine add_group

  subroutine set_mutually_exclusive_groups(self, group1, group2)
  !< Set two CLAs group ad mutually exclusive.
  class(command_line_interface), intent(inout) :: self   !< CLI data.
  character(*),                  intent(in)    :: group1 !< Name of the first grouped CLAs.
  character(*),                  intent(in)    :: group2 !< Name of the second grouped CLAs.
  integer(I4P)                                 :: g1     !< Counter.
  integer(I4P)                                 :: g2     !< Counter.

  if (self%is_defined_group(group=group1, g=g1).and.self%is_defined_group(group=group2, g=g2)) then
    self%clasg(g1)%m_exclude = group2
    self%clasg(g2)%m_exclude = group1
  endif
  endsubroutine set_mutually_exclusive_groups

  subroutine set_mutually_exclusive_switches(self, switches, required, group, pref, error)
  !< Set a mutually exclusive set of switches (F03 of #125): at most one member may be passed, exactly one if required.
  !<
  !< The members (comma separated, by switch or abbreviation) must be already added to the group, not required, and in no
  !< other set; otherwise the set is not added and the error is ERROR_M_EXCLUDE_SET_DEFINITION. Only passed members count:
  !< a default neither satisfies nor violates a set.
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  character(*),                  intent(in)    :: switches !< Comma separated members, e.g. '--mesh,--restart'.
  logical,      optional,        intent(in)    :: required !< Exactly one member must be passed (default .false.).
  character(*), optional,        intent(in)    :: group    !< Group (command) of the members (default: the top level).
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  integer(I4P), optional,        intent(out)   :: error    !< Error trapping flag.
  integer(I4P)                                 :: g        !< Index of the group.

  g = 0
  if (present(group)) g = self%group_index(group)
  if (g < 0) then
    self%error = ERROR_MISSING_GROUP
  else
    call self%clasg(g)%add_exclusive_set(switches=switches, required=required, pref=pref)
    self%error = self%clasg(g)%error
  endif
  if (present(error)) error = self%error
  endsubroutine set_mutually_exclusive_switches

  subroutine add(self, pref, group, group_index, switch, switch_ab, help, help_markdown, help_color, help_style, &
                 required, val_required, positional, position, hidden, act, def, nargs, choices, exclude, envvar, error)
  !< Add CLA to CLI.
  !<
  !< @note If not otherwise declared the action on CLA value is set to "store" a value that must be passed after the switch name
  !< or directly passed in case of positional CLA.
  !<
  !< @note If not otherwise speficied the CLA belongs to the default group "zero" that is the group of non-grouped CLAs.
  !<
  !< @note If CLA belongs to a not yet present group it is created on the fly.
  class(command_line_interface), intent(inout) :: self          !< CLI data.
  character(*), optional,        intent(in)    :: pref          !< Prefixing string.
  character(*), optional,        intent(in)    :: group         !< Name of the grouped CLAs.
  integer(I4P), optional,        intent(in)    :: group_index   !< Index of the grouped CLAs.
  character(*), optional,        intent(in)    :: switch        !< Switch name.
  character(*), optional,        intent(in)    :: switch_ab     !< Abbreviated switch name.
  character(*), optional,        intent(in)    :: help          !< Help message describing the CLA.
  character(*), optional,        intent(in)    :: help_color    !< ANSI color of help messages.
  character(*), optional,        intent(in)    :: help_style    !< ANSI style of help messages.
  character(*), optional,        intent(in)    :: help_markdown !< Longer help message, markdown formatted.
  logical,      optional,        intent(in)    :: required      !< Flag for set required argument.
  logical,      optional,        intent(in)    :: val_required  !< Flag for set value required for optional argument.
  logical,      optional,        intent(in)    :: positional    !< Flag for checking if CLA is a positional or a named CLA.
  integer(I4P), optional,        intent(in)    :: position      !< Position of positional CLA.
  logical,      optional,        intent(in)    :: hidden        !< Flag for hiding CLA, thus it does not compare into help.
  character(*), optional,        intent(in)    :: act           !< CLA value action.
  character(*), optional,        intent(in)    :: def           !< Default value.
  character(*), optional,        intent(in)    :: nargs         !< Number of arguments consumed by CLA.
  character(*), optional,        intent(in)    :: choices       !< List of allowable values for the argument.
  character(*), optional,        intent(in)    :: exclude       !< Switch name of the mutually exclusive CLA.
  character(*), optional,        intent(in)    :: envvar        !< Environment variable from which take value.
  integer(I4P), optional,        intent(out)   :: error         !< Error trapping flag.
  type(command_line_argument)                  :: cla           !< CLA data.
  integer(I4P)                                 :: g             !< Counter.

  ! initialize CLA
  call cla%assign_object(self)
  if (present(switch)) then
    cla%switch    = switch
    cla%switch_ab = switch
  else
    if (present(switch_ab)) then
      cla%switch    = switch_ab
      cla%switch_ab = switch_ab
    endif
  endif
                                                  if (present(switch_ab    )) cla%switch_ab       = switch_ab
  cla%help            = 'Undocumented argument' ; if (present(help         )) cla%help            = help
  cla%help_color      = ''                      ; if (present(help_color   )) cla%help_color      = help_color
  cla%help_style      = ''                      ; if (present(help_style   )) cla%help_style      = help_style
  cla%help_markdown   = ''                      ; if (present(help_markdown)) cla%help_markdown   = help_markdown
  cla%is_required     = .false.                 ; if (present(required     )) cla%is_required     = required
  cla%is_val_required = .true.                  ; if (present(val_required )) cla%is_val_required = val_required
  cla%is_positional   = .false.                 ; if (present(positional   )) cla%is_positional   = positional
  cla%position        = 0_I4P                   ; if (present(position     )) cla%position        = position
  cla%is_hidden       = .false.                 ; if (present(hidden       )) cla%is_hidden       = hidden
  cla%act             = action_store            ; if (present(act          )) cla%act             = trim(adjustl(Upper_Case(act)))
                                                  if (present(def          )) cla%def             = def
                                                  if (present(def          )) cla%val             = def
  if (cla%act==ACTION_COUNT.and.(.not.present(def))) then
    cla%def = '0' ! a count starts from 0
    cla%val = '0'
  endif
                                                  if (present(nargs        )) cla%nargs           = nargs
                                                  if (present(choices      )) cla%choices         = choices
  cla%m_exclude     = ''                        ; if (present(exclude      )) cla%m_exclude       = exclude
                                                  if (present(envvar       )) cla%envvar          = envvar
  if (.not.present(envvar)) call set_auto_envvar
  call cla%check(pref=pref) ; self%error = cla%error
  if (self%error/=0) then
    if (present(error)) error = self%error
    return
  endif
  ! add CLA to CLI
  if ((.not.present(group)).and.(.not.present(group_index))) then
    call self%clasg(0)%add(pref=pref, cla=cla) ; self%error = self%clasg(0)%error
  elseif (present(group)) then
    if (self%is_defined_group(group=group, g=g)) then
      call self%clasg(g)%add(pref=pref, cla=cla) ; self%error = self%clasg(g)%error
    else
      call self%add_group(group=group)
      call self%clasg(size(self%clasg,dim=1)-1)%add(pref=pref, cla=cla) ; self%error = self%clasg(size(self%clasg,dim=1)-1)%error
    endif
  elseif (present(group_index)) then
    if (group_index<=size(self%clasg,dim=1)-1) then
      call self%clasg(group_index)%add(pref=pref, cla=cla) ; self%error = self%clasg(group_index)%error
    endif
  endif
  if (present(error)) error = self%error
  contains
    subroutine set_auto_envvar
    !< Generate the envvar of the CLA (auto_envvar_prefix, F07): named store/store_true/store_false options, not lists.
    character(len=:), allocatable :: gname !< Name of the group of the CLA.

    if (.not.allocated(self%auto_envvar_prefix)) return
    if (self%auto_envvar_prefix == '' .or. cla%is_positional .or. allocated(cla%nargs) .or. .not.allocated(cla%switch)) return
    if (cla%act /= ACTION_STORE .and. cla%act /= ACTION_STORE_TRUE .and. cla%act /= ACTION_STORE_FALSE) return
    gname = ''
    if (present(group)) then
      gname = group
    elseif (present(group_index)) then
      if (group_index >= 0 .and. group_index <= size(self%clasg, dim=1) - 1) gname = self%clasg(group_index)%group
    endif
    cla%envvar = envvar_name(prefix=self%auto_envvar_prefix, group=gname, switch=cla%switch)
    endsubroutine set_auto_envvar
  endsubroutine add

  pure function envvar_name(prefix, group, switch) result(name)
  !< Return the generated name of an environment variable: PREFIX[_GROUP]_NAME, upper case, NAME being the switch without its
  !< leading dashes, '-' becoming '_' (auto_envvar_prefix, F07 of #125; click's rule).
  character(*), intent(in)      :: prefix !< Prefix.
  character(*), intent(in)      :: group  !< Group (command), '' for the top level.
  character(*), intent(in)      :: switch !< Switch.
  character(len=:), allocatable :: name   !< Name of the variable.
  integer(I4P)                  :: c      !< First character after the dashes.

  name = trim(adjustl(switch))
  c = verify(name, '-')
  if (c > 0) name = name(c:)
  if (len_trim(group) > 0) name = trim(adjustl(group))//'_'//name
  name = upper_case(replace_all(string=trim(prefix)//'_'//name, substring='-', restring='_'))
  endfunction envvar_name

  subroutine check(self, pref, error)
  !< Check data consistency.
  class(command_line_interface), intent(INOUT) :: self  !< CLI data.
  character(*), optional,        intent(IN)    :: pref  !< Prefixing string.
  integer(I4P), optional,        intent(OUT)   :: error !< Error trapping flag.
  integer(I4P)                                 :: g     !< Counter.
  integer(I4P)                                 :: gg    !< Counter.

  do g=0,size(self%clasg,dim=1)-1
    ! check group consistency
    call self%clasg(g)%check(pref=pref)
    if (self%clasg(g)%error==0) call self%clasg(g)%check_position_gaps(pref=pref)
    self%error = self%clasg(g)%error
    if (present(error)) error = self%error
    if (self%error/=0) exit
    ! check mutually exclusive interaction
    if (g>0) then
      if (self%clasg(g)%m_exclude/='') then
        if (self%is_defined_group(group=self%clasg(g)%m_exclude, g=gg)) self%clasg(gg)%m_exclude = self%clasg(g)%group
      endif
    endif
  enddo
  endsubroutine check

  subroutine check_m_exclusive(self, pref)
  !< Check if two mutually exclusive CLAs group have been called.
  class(command_line_interface), intent(inout) :: self  !< CLI data.
  character(*), optional,        intent(in)    :: pref  !< Prefixing string.
  integer(I4P)                                 :: g     !< Counter.
  integer(I4P)                                 :: gg    !< Counter.

  do g=1,size(self%clasg,dim=1)-1
    if (self%clasg(g)%is_called.and.(self%clasg(g)%m_exclude/='')) then
      if (self%is_defined_group(group=self%clasg(g)%m_exclude, g=gg)) then
        if (self%clasg(gg)%is_called) then
          call self%clasg(g)%raise_error_m_exclude(pref=pref)
          self%error = self%clasg(g)%error
          exit
        endif
      endif
    endif
  enddo
  endsubroutine check_m_exclusive

  function is_passed(self, group, switch, position)
  !< Check if a CLA has been passed.
  class(command_line_interface), intent(in) :: self      !< CLI data.
  character(*), optional,        intent(in) :: group     !< Name of group (command) of CLA.
  character(*), optional,        intent(in) :: switch    !< Switch name.
  integer(I4P), optional,        intent(in) :: position  !< Position of positional CLA.
  logical                                   :: is_passed !< Check if a CLA has been passed.
  integer(I4P)                              :: g         !< Counter.

  is_passed = .false.
  if (.not.present(group)) then
    if (present(switch)) then
      is_passed = self%clasg(0)%is_passed(switch=switch)
    elseif (present(position)) then
      is_passed = self%clasg(0)%is_passed(position=position)
    endif
  else
    if (self%is_defined_group(group=group, g=g)) then
      if (present(switch)) then
        is_passed = self%clasg(g)%is_passed(switch=switch)
      elseif (present(position)) then
        is_passed = self%clasg(g)%is_passed(position=position)
      endif
    endif
  endif
  endfunction is_passed

  function is_defined_group(self, group, g) result(defined)
  !< Check if a CLAs group has been defined.
  class(command_line_interface), intent(in)  :: self    !< CLI data.
  character(*),                  intent(in)  :: group   !< Name of group (command) of CLAs.
  integer(I4P), optional,        intent(out) :: g       !< Index of group, -1 if not defined.
  logical                                    :: defined !< Check if a CLAs group has been defined.
  integer(I4P)                               :: gg      !< Index of group.

  gg = self%group_index(group)
  defined = gg >= 0
  if (present(g)) g = gg
  endfunction is_defined_group

  pure function group_index(self, name) result(g)
  !< Return the index of the group (command) with a name, -1 if there is none: the one resolver of group names.
  !<
  !< The top level is the group 0, named ''. Trailing blanks are not significant; the match is case sensitive.
  class(command_line_interface), intent(in) :: self !< CLI data.
  character(*),                  intent(in) :: name !< Name of group (command).
  integer(I4P)                              :: g    !< Index of group, -1 if not defined.

  if (allocated(self%clasg)) then
    do g=0, ubound(self%clasg, dim=1)
      if (allocated(self%clasg(g)%group)) then
        if (self%clasg(g)%group == name) return
      endif
    enddo
  endif
  g = -1
  endfunction group_index

  function raise_error(self, message, switch, group, show_usage) result(error)
  !< Report an application error in FLAP's style (prefix, colours, error unit) and return ERROR_USER; never stop (F17 of #125).
  !<
  !< For validation only the application can do (e.g. "--nx must be even"); by default the usage (of `group`) follows the
  !< message. An undefined `group` returns ERROR_MISSING_GROUP and prints nothing.
  class(command_line_interface), intent(inout) :: self        !< CLI data.
  character(*),                  intent(in)    :: message     !< Error message.
  character(*), optional,        intent(in)    :: switch      !< Offending switch, prefixing the message.
  character(*), optional,        intent(in)    :: group       !< Group (command) whose usage is printed (default: top level).
  logical,      optional,        intent(in)    :: show_usage  !< Print the usage after the message (default .true.).
  integer(I4P)                                 :: error       !< ERROR_USER, or ERROR_MISSING_GROUP.
  logical                                      :: show_usage_ !< Print the usage, local variable.
  integer(I4P)                                 :: g           !< Index of the group.

  show_usage_ = .true. ; if (present(show_usage)) show_usage_ = show_usage
  g = 0
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      self%error = ERROR_MISSING_GROUP
      error = self%error
      return
    endif
  endif
  self%error = ERROR_USER
  if (present(switch)) then
    self%error_message = self%error_prefix()//': switch "'//trim(adjustl(switch))//'": '//message
  else
    self%error_message = self%error_prefix()//': '//message
  endif
  call self%print_error_message
  if (show_usage_) write(self%usage_lun, '(A)') self%usage(g=g)
  error = self%error
  endfunction raise_error

  function is_called_group(self, group) result(called)
  !< Check if a CLAs group has been run.
  class(command_line_interface), intent(in) :: self   !< CLI data.
  character(*),                  intent(in) :: group  !< Name of group (command) of CLAs.
  logical                                   :: called !< Check if a CLAs group has been runned.
  integer(I4P)                              :: g      !< Counter.

  called = .false.
  if (self%is_defined_group(group=group, g=g)) called = self%clasg(g)%is_called
  endfunction is_called_group

  function is_defined(self, switch, group)
  !< Check if a CLA has been defined.
  class(command_line_interface), intent(in) :: self       !< CLI data.
  character(*),                  intent(in) :: switch     !< Switch name.
  character(*), optional,        intent(in) :: group      !< Name of group (command) of CLAs.
  logical                                   :: is_defined !< Check if a CLA has been defined.
  integer(I4P)                              :: g          !< Counter.

  is_defined = .false.
  if (.not.present(group)) then
    is_defined = self%clasg(0)%is_defined(switch=switch)
  else
    if (self%is_defined_group(group=group, g=g)) is_defined = self%clasg(g)%is_defined(switch=switch)
  endif
  endfunction is_defined

  elemental function is_parsed(self)
  !< Check if CLI has been parsed.
  class(command_line_interface), intent(in) :: self      !< CLI data.
  logical                                   :: is_parsed !< Parsed status.

  is_parsed = self%is_parsed_
  endfunction is_parsed

  subroutine reset_parse(self)
  !< Forget the result of a parse, keeping the definitions (options, commands, builtins): the next parse (or get) parses
  !< again. Without it, a second call of parse is ignored and the first result is kept.
  class(command_line_interface), intent(inout) :: self !< CLI data.
  integer(I4P)                                 :: g    !< Counter for CLAs group.

  self%is_parsed_ = .false.
  self%error = 0
  self%error_unknown_clas = 0
  if (allocated(self%args)) deallocate(self%args)
  do g=0, size(self%clasg, dim=1) - 1
    call self%clasg(g)%reset_parse
  enddo
  endsubroutine reset_parse

  subroutine parse(self, pref, args, error)
  !< Parse Command Line Interfaces by means of a previously initialized CLAs groups list.
  !<
  !< @note The leading and trailing white spaces are removed from CLA values.
  !<
  !< @note If the *args* argument is passed the command line arguments are taken from it and not from the actual program CLI
  !< invocations.
  class(command_line_interface), intent(inout) :: self    !< CLI data.
  character(*), optional,        intent(in)    :: pref    !< Prefixing string.
  character(*), optional,        intent(in)    :: args    !< String containing command line arguments.
  integer(I4P), optional,        intent(out)   :: error   !< Error trapping flag.

  if (present(error)) error = 0
  if (self%is_parsed_) return
  call self%parse_core(pref=pref, args=args)
  if (self%error > 0 .and. self%error /= ERROR_UNKNOWN_CLAS_IGNORED) call self%print_error_hint
  if (present(error)) error = self%error
  endsubroutine parse

  subroutine print_error_hint(self)
  !< Print the last line after a failed parse: "Try 'prog [command] --help' for help." (F26 of #125).
  !<
  !< Only when enabled (error_hint) and when there is a help option to suggest (not disable_hv); the command is the first
  !< called one with an error.
  class(command_line_interface), intent(in) :: self    !< CLI data.
  character(len=:), allocatable             :: command !< Command of the error, if any.
  integer(I4P)                              :: g       !< Counter for CLAs group.

  if (.not.self%error_hint .or. self%disable_hv) return
  command = ''
  do g=1, size(self%clasg, dim=1)-1
    if (self%clasg(g)%is_called .and. self%clasg(g)%error > 0) then
      command = ' '//self%clasg(g)%group
      exit
    endif
  enddo
  write(self%error_lun, '(A)') "Try '"//self%progname//command//" --help' for help."
  endsubroutine print_error_hint

  subroutine parse_core(self, pref, args)
  !< Parse the command line (the body of parse, which returns early once parsed and hands the error back).
  class(command_line_interface), intent(inout) :: self    !< CLI data.
  character(*), optional,        intent(in)    :: pref    !< Prefixing string.
  character(*), optional,        intent(in)    :: args    !< String containing command line arguments.
  integer(I4P)                                 :: g       !< Counter for CLAs group.
  integer(I4P), allocatable                    :: ai(:,:) !< Counter for CLAs grouped.
  character(len=:), allocatable                :: gargs(:)!< Arguments of a group.
  integer(I4P)                                 :: unknown !< Unknown argument error of a group.

  call self%ensure_builtins(pref=pref)

  ! parse passed CLAs grouping in indexes
  if (present(args)) then
    call self%get_args(args=args, ai=ai)
  else
    call self%get_args(ai=ai)
  endif
  if (self%error == ERROR_ARGUMENT_RETRIEVAL) return

  ! check CLI consistency
  call self%check(pref=pref)
  if (self%is_fatal()) return

  ! no arguments at all, or a command invoked alone: its help, if asked for (F25, first in the D3 order)
  if (self%no_args_help(ai=ai, pref=pref)) return

  ! parse CLI
  do g=0,size(ai,dim=1)-1
    if (ai(g,1)>0) then
      ! pass a copy: gfortran (13-16) hands a section of a deferred-length character array to a character(*) dummy
      ! starting at the first element of the whole array, not of the section
      gargs = to_characters(self%args(ai(g,1):ai(g,2)))
      call self%clasg(g)%parse(args=gargs, ignore_unknown_clas=self%ignore_unknown_clas, &
                               pref=pref, error_unknown_clas=unknown, ignore_env=self%ignore_env)
      ! keep the mark of an ignored unknown argument: a later group must not erase it (B30 of #125)
      if (unknown /= 0 .and. self%error_unknown_clas /= ERROR_UNKNOWN_CLAS_IGNORED) self%error_unknown_clas = unknown
    else
      call self%clasg(g)%sanitize_defaults
    endif
    self%error = self%clasg(g)%error
    if (self%is_fatal()) exit ! a status (help, version, markdown) does not stop parsing: syntax errors come first (D3)
  enddo
  if (self%is_fatal()) return

  ! dispatch the statuses (D3): help, then version, then markdown
  if (self%dispatch_status(pref=pref)) return

  ! settle the source of the values not given on the command line (R chain, F06)
  do g=0, size(self%clasg,dim=1)-1
    call self%clasg(g)%resolve_values(ignore_env=self%ignore_env)
  enddo

  ! check if all required CLAs have been passed
  do g=0, size(ai,dim=1)-1
    call self%clasg(g)%is_required_passed(pref=pref)
    self%error = self%clasg(g)%error
    if (self%is_fatal()) exit
  enddo
  if (self%is_fatal()) return

  ! check the mutually exclusive sets of switches: after the statuses and the values (E4 of #125)
  do g=0, size(ai,dim=1)-1
    call self%clasg(g)%check_exclusive_sets(pref=pref)
    self%error = self%clasg(g)%error
    if (self%is_fatal()) exit
  enddo
  if (self%is_fatal()) return

  ! check mutually exclusive interaction
  call self%check_m_exclusive(pref=pref)

  self%is_parsed_ = .true.

  ! check if the only error found is for unknown passed CLAs and if it is ignored by the user; a later group may have reset
  ! the error to 0 (B30 of #125)
  if ((self%error==0.or.self%error==ERROR_UNKNOWN).and.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) &
    self%error = ERROR_UNKNOWN_CLAS_IGNORED
  endsubroutine parse_core

  function no_args_help(self, ai, pref) result(printed)
  !< Print the help when no arguments are passed (no_args_is_help), or when a command with the flag is invoked alone.
  !<
  !< The status is STATUS_NO_ARGS; in standalone mode (default) the program ends with exit status 2 (a usage error, as in
  !< click), silently (quiet_stop).
  class(command_line_interface), intent(inout) :: self    !< CLI data.
  integer(I4P),                  intent(in)    :: ai(0:,1:) !< CLAs grouped indexes.
  character(*), optional,        intent(in)    :: pref    !< Prefixing string.
  logical                                      :: printed !< The help has been printed.
  integer(I4P)                                 :: g       !< Counter for CLAs group.
  integer(I4P)                                 :: gh      !< Group whose help is printed, -1 if none.

  gh = -1
  if (self%no_args_is_help) then
    if (.not.allocated(self%args)) then
      gh = 0
    elseif (size(self%args, dim=1) == 0) then
      gh = 0
    endif
  endif
  if (gh < 0) then
    do g=1, size(self%clasg, dim=1)-1
      if (self%clasg(g)%is_called .and. self%clasg(g)%no_args_is_help .and. ai(g,1) > ai(g,2)) then
        gh = g
        exit
      endif
    enddo
  endif
  printed = gh >= 0
  if (.not.printed) return
  self%error = STATUS_NO_ARGS
  write(self%usage_lun, '(A)') self%usage(pref=pref, g=gh)
  if (self%standalone) call quiet_stop(2_I4P)
  endfunction no_args_help

  function dispatch_status(self, pref) result(dispatched)
  !< Print the help (of the first group that asked for it), the version or the markdown, in this order (D3 of #125).
  !<
  !< In standalone mode (default) the program stops; otherwise the status is left in self%error for parse to return.
  class(command_line_interface), intent(inout) :: self       !< CLI data.
  character(*), optional,        intent(in)    :: pref       !< Prefixing string.
  logical                                      :: dispatched !< A status has been dispatched.
  integer(I4P)                                 :: g          !< Counter for CLAs group.

  dispatched = .true.
  do g=0, size(self%clasg, dim=1)-1
    if (self%clasg(g)%is_action_passed(ACTION_PRINT_HELP)) then
      self%error = STATUS_PRINT_H
      write(self%usage_lun,'(A)') self%usage(pref=pref, g=g)
      if (self%standalone) call quiet_stop(0_I4P)
      return
    endif
  enddo
  do g=0, size(self%clasg, dim=1)-1
    if (self%clasg(g)%is_action_passed(ACTION_PRINT_VERS)) then
      self%error = STATUS_PRINT_V
      call self%print_version(pref=pref)
      if (self%standalone) call quiet_stop(0_I4P)
      return
    endif
  enddo
  do g=0, size(self%clasg, dim=1)-1
    if (self%clasg(g)%is_action_passed(ACTION_PRINT_MARK)) then
      self%error = STATUS_PRINT_M
      call self%save_usage_to_markdown(trim(self%progname)//'.md')
      if (self%standalone) call quiet_stop(0_I4P)
      return
    endif
  enddo
  dispatched = .false.
  endfunction dispatch_status

  function is_fatal(self)
  !< Check if the current error stops parsing: any error but an unknown argument that is ignored (then recorded as such).
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  logical                                      :: is_fatal !< Check result.

  is_fatal = .false.
  if (self%error <= 0) return
  if (self%error == ERROR_UNKNOWN .and. self%ignore_unknown_clas) then
    self%error_unknown_clas = ERROR_UNKNOWN_CLAS_IGNORED
  else
    is_fatal = .true.
  endif
  endfunction is_fatal

  subroutine get_clasg_indexes(self, ai)
  !< Get the argument indexes of each CLAs group (command): ai(g,1:2) is the slice of self%args belonging to group g.
  !<
  !< Arguments before the first command name belong to group 0; the arguments after a command name belong to that command.
  !< The fixed value slots of a switch (`value_arity`) are skipped before testing for a command name, so a value equal to a
  !< command name stays a value (B04); a variadic list is ended by a command name.
  class(command_line_interface), intent(inout) :: self   !< CLI data.
  integer(I4P), allocatable,     intent(out)   :: ai(:,:)!< CLAs grouped indexes.
  integer(I4P)                                 :: Na     !< Number of command line arguments passed.
  integer(I4P)                                 :: a      !< Counter for CLAs.
  integer(I4P)                                 :: g      !< Counter for CLAs group.
  integer(I4P)                                 :: gc     !< Current group.
  integer(I4P)                                 :: n      !< Fixed value slots of a switch.

  allocate(ai(0:size(self%clasg,dim=1)-1,1:2))
  ai = 0
  if (allocated(self%args)) then
    Na = size(self%args,dim=1)
    gc = 0
    a = 0
    do while (a < Na)
      a = a + 1
      n = self%clasg(gc)%value_arity(switch=trim(adjustl(self%args(a)%s)))
      if (n > 0) then
        ! a switch of the current group and its values: never command names
        a = min(a + n, Na)
      elseif (self%is_defined_group(group=trim(self%args(a)%s), g=g)) then
        if (g > 0) then
          ! a command: its arguments start after its name
          gc = g
          self%clasg(g)%is_called = .true.
          ai(g,1) = a + 1
          ai(g,2) = a
          cycle
        endif
      endif
      ai(gc,2) = a
    enddo
    if (ai(0,2)>0) then
      ai(0,1) = 1
      self%clasg(0)%is_called = .true.
    elseif (all(ai==0)) then
      self%clasg(0)%is_called = .true.
    endif
  else
    self%clasg(0)%is_called = .true.
  endif
  endsubroutine get_clasg_indexes

  subroutine get_args_from_string(self, args, ai)
  !< Get CLAs from string.
  !<
  !< The string is split as a shell would split a command line: see `split_command_line`.
  class(command_line_interface), intent(inout) :: self   !< CLI data.
  character(*),                  intent(in)    :: args   !< String containing command line arguments.
  integer(I4P), allocatable,     intent(out)   :: ai(:,:)!< CLAs grouped indexes.
  character(len=len_trim(args)), allocatable   :: toks(:)!< Command line arguments.
  integer(I4P)                                 :: Na     !< Number of command line arguments passed.
  integer(I4P)                                 :: a      !< Counter for CLAs.

  ! prepare CLI arguments list
  if (allocated(self%args)) deallocate(self%args)

  call split_command_line(strin=trim(args), toks=toks, Nt=Na)

  if (Na > 0) then
    allocate(self%args(1:Na))
    get_args: do a=1,Na
      self%args(a)%s = trim(adjustl(toks(a)))
    enddo get_args
  endif

  call self%get_clasg_indexes(ai=ai)
  endsubroutine get_args_from_string

  subroutine get_args_from_invocation(self, ai)
  !< Get CLAs from CLI invocation.
  !<
  !< Every argument is read whole: its length is queried first, and a failed retrieval raises ERROR_ARGUMENT_RETRIEVAL.
  class(command_line_interface), intent(inout) :: self    !< CLI data.
  integer(I4P), allocatable,     intent(out)   :: ai(:,:) !< CLAs grouped indexes.
  character(len=:), allocatable                :: arg     !< Command line argument.
  integer(I4P)                                 :: Na      !< Number of command line arguments passed.
  integer(I4P)                                 :: l       !< Length of an argument.
  integer(I4P)                                 :: status  !< Retrieval status.
  integer(I4P)                                 :: a       !< Counter for CLAs.

  if (allocated(self%args)) deallocate(self%args)
  Na = command_argument_count()
  if (Na > 0) then
    allocate(self%args(1:Na))
    get_args: do a=1, Na
      call get_command_argument(a, length=l, status=status)
      if (status /= 0) then
        call self%errored(error=ERROR_ARGUMENT_RETRIEVAL, position=a)
        return
      endif
      allocate(character(l):: arg)
      call get_command_argument(a, value=arg, status=status)
      if (status /= 0) then
        call self%errored(error=ERROR_ARGUMENT_RETRIEVAL, position=a)
        return
      endif
      self%args(a)%s = trim(adjustl(arg))
      deallocate(arg)
    enddo get_args
  endif

  call self%get_clasg_indexes(ai=ai)
  endsubroutine get_args_from_invocation

  subroutine get_cla(self, val, pref, args, group, switch, position, error)
  !< Get CLA (single) value from CLAs list parsed.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  class(*),                      intent(inout) :: val      !< CLA value.
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  character(*), optional,        intent(in)    :: args     !< String containing command line arguments.
  character(*), optional,        intent(in)    :: group    !< Name of group (command) of CLA.
  character(*), optional,        intent(in)    :: switch   !< Switch name.
  integer(I4P), optional,        intent(in)    :: position !< Position of positional CLA.
  integer(I4P), optional,        intent(out)   :: error    !< Error trapping flag.
  logical                                      :: found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)                                 :: g        !< Group counter.
  integer(I4P)                                 :: a        !< Argument counter.

  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error>0.and.self%error_unknown_clas/=ERROR_UNKNOWN_CLAS_IGNORED) return
  endif
  self%error = 0 ! report only this get: the error of a previous get must not leak into it (B22)
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
      if (present(error)) error = self%error
      return ! g is not defined (B24)
    endif
  else
    g = 0
  endif
  if (self%error==0.or.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) then
    if (present(switch)) then
      ! search for the CLA corresponding to switch
      found = self%clasg(g)%is_defined(switch=switch, pos=a)
      if (.not.found) then
        call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
      else
        call self%clasg(g)%cla(a)%get(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
      endif
    elseif (present(position)) then
      a = self%clasg(g)%positional_index(position)
      if (a == 0) then
        call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch='position '//trim(str(position, .true.)))
      else
        call self%clasg(g)%cla(a)%get(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
      endif
    else
      call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
    endif
  endif
  ! check if the only error found is for unknown passed CLAs and if it is ignored by the user
  if (self%error==ERROR_UNKNOWN.and.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) self%error = ERROR_UNKNOWN_CLAS_IGNORED
  if (self%error==0.and.(.not.self%clasg(g)%is_called)) then
    ! TODO warn (if liked) for non invoked group querying
  endif
  if (present(error)) error = self%error
  endsubroutine get_cla

  subroutine get_cla_list(self, val, pref, args, group, switch, position, error)
  !< Get CLA multiple values from CLAs list parsed.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  class(*),                      intent(inout) :: val(1:)  !< CLA values.
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  character(*), optional,        intent(in)    :: args     !< String containing command line arguments.
  character(*), optional,        intent(in)    :: group    !< Name of group (command) of CLA.
  character(*), optional,        intent(in)    :: switch   !< Switch name.
  integer(I4P), optional,        intent(in)    :: position !< Position of positional CLA.
  integer(I4P), optional,        intent(out)   :: error    !< Error trapping flag.
  logical                                      :: found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)                                 :: g        !< Group counter.
  integer(I4P)                                 :: a        !< Argument counter.

  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error>0.and.self%error_unknown_clas/=ERROR_UNKNOWN_CLAS_IGNORED) return
  endif
  self%error = 0 ! report only this get: the error of a previous get must not leak into it (B22)
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
      if (present(error)) error = self%error
      return ! g is not defined (B24)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = self%clasg(g)%is_defined(switch=switch, pos=a)
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    a = self%clasg(g)%positional_index(position)
    if (a == 0) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch='position '//trim(str(position, .true.)))
    else
      call self%clasg(g)%cla(a)%get(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  ! check if the only error found is for unknown passed CLAs and if it is ignored by the user
  if (self%error==ERROR_UNKNOWN.and.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) self%error = ERROR_UNKNOWN_CLAS_IGNORED
  if (present(error)) error = self%error
  endsubroutine get_cla_list

  subroutine get_cla_list_varying_R16P(self, val, pref, args, group, switch, position, error)
  !< Get CLA multiple values from CLAs list parsed with varying size list, real(R16P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  real(R16P), allocatable,       intent(out)   :: val(:)   !< CLA values.
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  character(*), optional,        intent(in)    :: args     !< String containing command line arguments.
  character(*), optional,        intent(in)    :: group    !< Name of group (command) of CLA.
  character(*), optional,        intent(in)    :: switch   !< Switch name.
  integer(I4P), optional,        intent(in)    :: position !< Position of positional CLA.
  integer(I4P), optional,        intent(out)   :: error    !< Error trapping flag.
  logical                                      :: found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)                                 :: g        !< Group counter.
  integer(I4P)                                 :: a        !< Argument counter.

  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error>0.and.self%error_unknown_clas/=ERROR_UNKNOWN_CLAS_IGNORED) return
  endif
  self%error = 0 ! report only this get: the error of a previous get must not leak into it (B22)
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
      if (present(error)) error = self%error
      return ! g is not defined (B24)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = self%clasg(g)%is_defined(switch=switch, pos=a)
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    a = self%clasg(g)%positional_index(position)
    if (a == 0) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch='position '//trim(str(position, .true.)))
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  ! check if the only error found is for unknown passed CLAs and if it is ignored by the user
  if (self%error==ERROR_UNKNOWN.and.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) self%error = ERROR_UNKNOWN_CLAS_IGNORED
  if (present(error)) error = self%error
  endsubroutine get_cla_list_varying_R16P

  subroutine get_cla_list_varying_R8P(self, val, pref, args, group, switch, position, error)
  !< Get CLA multiple values from CLAs list parsed with varying size list, real(R8P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  real(R8P), allocatable,        intent(out)   :: val(:)   !< CLA values.
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  character(*), optional,        intent(in)    :: args     !< String containing command line arguments.
  character(*), optional,        intent(in)    :: group    !< Name of group (command) of CLA.
  character(*), optional,        intent(in)    :: switch   !< Switch name.
  integer(I4P), optional,        intent(in)    :: position !< Position of positional CLA.
  integer(I4P), optional,        intent(out)   :: error    !< Error trapping flag.
  logical                                      :: found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)                                 :: g        !< Group counter.
  integer(I4P)                                 :: a        !< Argument counter.

  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error>0.and.self%error_unknown_clas/=ERROR_UNKNOWN_CLAS_IGNORED) return
  endif
  self%error = 0 ! report only this get: the error of a previous get must not leak into it (B22)
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
      if (present(error)) error = self%error
      return ! g is not defined (B24)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = self%clasg(g)%is_defined(switch=switch, pos=a)
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    a = self%clasg(g)%positional_index(position)
    if (a == 0) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch='position '//trim(str(position, .true.)))
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  ! check if the only error found is for unknown passed CLAs and if it is ignored by the user
  if (self%error==ERROR_UNKNOWN.and.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) self%error = ERROR_UNKNOWN_CLAS_IGNORED
  if (present(error)) error = self%error
  endsubroutine get_cla_list_varying_R8P

  subroutine get_cla_list_varying_R4P(self, val, pref, args, group, switch, position, error)
  !< Get CLA multiple values from CLAs list parsed with varying size list, real(R4P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  real(R4P), allocatable,        intent(out)   :: val(:)   !< CLA values.
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  character(*), optional,        intent(in)    :: args     !< String containing command line arguments.
  character(*), optional,        intent(in)    :: group    !< Name of group (command) of CLA.
  character(*), optional,        intent(in)    :: switch   !< Switch name.
  integer(I4P), optional,        intent(in)    :: position !< Position of positional CLA.
  integer(I4P), optional,        intent(out)   :: error    !< Error trapping flag.
  logical                                      :: found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)                                 :: g        !< Group counter.
  integer(I4P)                                 :: a        !< Argument counter.

  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error>0.and.self%error_unknown_clas/=ERROR_UNKNOWN_CLAS_IGNORED) return
  endif
  self%error = 0 ! report only this get: the error of a previous get must not leak into it (B22)
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
      if (present(error)) error = self%error
      return ! g is not defined (B24)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = self%clasg(g)%is_defined(switch=switch, pos=a)
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    a = self%clasg(g)%positional_index(position)
    if (a == 0) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch='position '//trim(str(position, .true.)))
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  ! check if the only error found is for unknown passed CLAs and if it is ignored by the user
  if (self%error==ERROR_UNKNOWN.and.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) self%error = ERROR_UNKNOWN_CLAS_IGNORED
  if (present(error)) error = self%error
  endsubroutine get_cla_list_varying_R4P

  subroutine get_cla_list_varying_I8P(self, val, pref, args, group, switch, position, error)
  !< Get CLA multiple values from CLAs list parsed with varying size list, integer(I8P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  integer(I8P), allocatable,     intent(out)   :: val(:)   !< CLA values.
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  character(*), optional,        intent(in)    :: args     !< String containing command line arguments.
  character(*), optional,        intent(in)    :: group    !< Name of group (command) of CLA.
  character(*), optional,        intent(in)    :: switch   !< Switch name.
  integer(I4P), optional,        intent(in)    :: position !< Position of positional CLA.
  integer(I4P), optional,        intent(out)   :: error    !< Error trapping flag.
  logical                                      :: found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)                                 :: g        !< Group counter.
  integer(I4P)                                 :: a        !< Argument counter.

  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error>0.and.self%error_unknown_clas/=ERROR_UNKNOWN_CLAS_IGNORED) return
  endif
  self%error = 0 ! report only this get: the error of a previous get must not leak into it (B22)
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
      if (present(error)) error = self%error
      return ! g is not defined (B24)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = self%clasg(g)%is_defined(switch=switch, pos=a)
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    a = self%clasg(g)%positional_index(position)
    if (a == 0) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch='position '//trim(str(position, .true.)))
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  ! check if the only error found is for unknown passed CLAs and if it is ignored by the user
  if (self%error==ERROR_UNKNOWN.and.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) self%error = ERROR_UNKNOWN_CLAS_IGNORED
  if (present(error)) error = self%error
  endsubroutine get_cla_list_varying_I8P

  subroutine get_cla_list_varying_I4P(self, val, pref, args, group, switch, position, error)
  !< Get CLA multiple values from CLAs list parsed with varying size list, integer(I4P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  integer(I4P), allocatable,     intent(out)   :: val(:)   !< CLA values.
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  character(*), optional,        intent(in)    :: args     !< String containing command line arguments.
  character(*), optional,        intent(in)    :: group    !< Name of group (command) of CLA.
  character(*), optional,        intent(in)    :: switch   !< Switch name.
  integer(I4P), optional,        intent(in)    :: position !< Position of positional CLA.
  integer(I4P), optional,        intent(out)   :: error    !< Error trapping flag.
  logical                                      :: found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)                                 :: g        !< Group counter.
  integer(I4P)                                 :: a        !< Argument counter.

  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error>0.and.self%error_unknown_clas/=ERROR_UNKNOWN_CLAS_IGNORED) return
  endif
  self%error = 0 ! report only this get: the error of a previous get must not leak into it (B22)
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
      if (present(error)) error = self%error
      return ! g is not defined (B24)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = self%clasg(g)%is_defined(switch=switch, pos=a)
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    a = self%clasg(g)%positional_index(position)
    if (a == 0) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch='position '//trim(str(position, .true.)))
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  ! check if the only error found is for unknown passed CLAs and if it is ignored by the user
  if (self%error==ERROR_UNKNOWN.and.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) self%error = ERROR_UNKNOWN_CLAS_IGNORED
  if (present(error)) error = self%error
  endsubroutine get_cla_list_varying_I4P

  subroutine get_cla_list_varying_I2P(self, val, pref, args, group, switch, position, error)
  !< Get CLA multiple values from CLAs list parsed with varying size list, integer(I2P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  integer(I2P), allocatable,     intent(out)   :: val(:)   !< CLA values.
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  character(*), optional,        intent(in)    :: args     !< String containing command line arguments.
  character(*), optional,        intent(in)    :: group    !< Name of group (command) of CLA.
  character(*), optional,        intent(in)    :: switch   !< Switch name.
  integer(I4P), optional,        intent(in)    :: position !< Position of positional CLA.
  integer(I4P), optional,        intent(out)   :: error    !< Error trapping flag.
  logical                                      :: found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)                                 :: g        !< Group counter.
  integer(I4P)                                 :: a        !< Argument counter.

  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error>0.and.self%error_unknown_clas/=ERROR_UNKNOWN_CLAS_IGNORED) return
  endif
  self%error = 0 ! report only this get: the error of a previous get must not leak into it (B22)
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
      if (present(error)) error = self%error
      return ! g is not defined (B24)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = self%clasg(g)%is_defined(switch=switch, pos=a)
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    a = self%clasg(g)%positional_index(position)
    if (a == 0) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch='position '//trim(str(position, .true.)))
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  ! check if the only error found is for unknown passed CLAs and if it is ignored by the user
  if (self%error==ERROR_UNKNOWN.and.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) self%error = ERROR_UNKNOWN_CLAS_IGNORED
  if (present(error)) error = self%error
  endsubroutine get_cla_list_varying_I2P

  subroutine get_cla_list_varying_I1P(self, val, pref, args, group, switch, position, error)
  !< Get CLA multiple values from CLAs list parsed with varying size list, integer(I1P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  integer(I1P), allocatable,     intent(out)   :: val(:)   !< CLA values.
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  character(*), optional,        intent(in)    :: args     !< String containing command line arguments.
  character(*), optional,        intent(in)    :: group    !< Name of group (command) of CLA.
  character(*), optional,        intent(in)    :: switch   !< Switch name.
  integer(I4P), optional,        intent(in)    :: position !< Position of positional CLA.
  integer(I4P), optional,        intent(out)   :: error    !< Error trapping flag.
  logical                                      :: found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)                                 :: g        !< Group counter.
  integer(I4P)                                 :: a        !< Argument counter.

  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error>0.and.self%error_unknown_clas/=ERROR_UNKNOWN_CLAS_IGNORED) return
  endif
  self%error = 0 ! report only this get: the error of a previous get must not leak into it (B22)
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
      if (present(error)) error = self%error
      return ! g is not defined (B24)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = self%clasg(g)%is_defined(switch=switch, pos=a)
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    a = self%clasg(g)%positional_index(position)
    if (a == 0) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch='position '//trim(str(position, .true.)))
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  ! check if the only error found is for unknown passed CLAs and if it is ignored by the user
  if (self%error==ERROR_UNKNOWN.and.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) self%error = ERROR_UNKNOWN_CLAS_IGNORED
  if (present(error)) error = self%error
  endsubroutine get_cla_list_varying_I1P

  subroutine get_cla_list_varying_logical(self, val, pref, args, group, switch, position, error)
  !< Get CLA multiple values from CLAs list parsed with varying size list, logical.
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  logical, allocatable,          intent(out)   :: val(:)   !< CLA values.
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  character(*), optional,        intent(in)    :: args     !< String containing command line arguments.
  character(*), optional,        intent(in)    :: group    !< Name of group (command) of CLA.
  character(*), optional,        intent(in)    :: switch   !< Switch name.
  integer(I4P), optional,        intent(in)    :: position !< Position of positional CLA.
  integer(I4P), optional,        intent(out)   :: error    !< Error trapping flag.
  logical                                      :: found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)                                 :: g        !< Group counter.
  integer(I4P)                                 :: a        !< Argument counter.

  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error>0.and.self%error_unknown_clas/=ERROR_UNKNOWN_CLAS_IGNORED) return
  endif
  self%error = 0 ! report only this get: the error of a previous get must not leak into it (B22)
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
      if (present(error)) error = self%error
      return ! g is not defined (B24)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = self%clasg(g)%is_defined(switch=switch, pos=a)
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    a = self%clasg(g)%positional_index(position)
    if (a == 0) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch='position '//trim(str(position, .true.)))
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  ! check if the only error found is for unknown passed CLAs and if it is ignored by the user
  if (self%error==ERROR_UNKNOWN.and.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) self%error = ERROR_UNKNOWN_CLAS_IGNORED
  if (present(error)) error = self%error
  endsubroutine get_cla_list_varying_logical

  subroutine get_cla_list_varying_char(self, val, pref, args, group, switch, position, error)
  !< Get CLA multiple values from CLAs list parsed with varying size list, character.
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  class(command_line_interface), intent(inout) :: self     !< CLI data.
  character(*), allocatable,     intent(out)   :: val(:)   !< CLA values.
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  character(*), optional,        intent(in)    :: args     !< String containing command line arguments.
  character(*), optional,        intent(in)    :: group    !< Name of group (command) of CLA.
  character(*), optional,        intent(in)    :: switch   !< Switch name.
  integer(I4P), optional,        intent(in)    :: position !< Position of positional CLA.
  integer(I4P), optional,        intent(out)   :: error    !< Error trapping flag.
  logical                                      :: found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)                                 :: g        !< Group counter.
  integer(I4P)                                 :: a        !< Argument counter.

  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error>0.and.self%error_unknown_clas/=ERROR_UNKNOWN_CLAS_IGNORED) return
  endif
  self%error = 0 ! report only this get: the error of a previous get must not leak into it (B22)
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
      if (present(error)) error = self%error
      return ! g is not defined (B24)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = self%clasg(g)%is_defined(switch=switch, pos=a)
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    a = self%clasg(g)%positional_index(position)
    if (a == 0) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch='position '//trim(str(position, .true.)))
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  ! check if the only error found is for unknown passed CLAs and if it is ignored by the user
  if (self%error==ERROR_UNKNOWN.and.self%error_unknown_clas==ERROR_UNKNOWN_CLAS_IGNORED) self%error = ERROR_UNKNOWN_CLAS_IGNORED
  if (present(error)) error = self%error
  endsubroutine get_cla_list_varying_char

  subroutine ensure_builtins(self, pref)
  !< Add the builtin CLAs if not done by the user: --help, --markdown and --version (unless disabled) and the hidden "--"
  !< collecting trailing arguments, in every group. Idempotent.
  !<
  !< Called by parse and, on a copy, by every output method (usage, signature, save_*), so that their output is the same
  !< before and after parse (#125, B09).
  class(command_line_interface), intent(inout) :: self !< CLI data.
  character(*), optional,        intent(in)    :: pref !< Prefixing string.
  integer(I4P)                                 :: g    !< Counter for CLAs group.

  ! add help, markdown and version switches if not done by user
  if (.not.self%disable_hv) then
    do g=0,size(self%clasg,dim=1)-1
      call add_builtin(g, '--help',     '-h',  'Print this help message',                   'print_help')
      call add_builtin(g, '--markdown', '-md', 'Save this help message in a Markdown file', 'print_markdown')
      call add_builtin(g, '--version',  '-v',  'Print version',                             'print_version')
    enddo
  endif

  ! add hidden CLA '--' for getting the rid of eventual trailing CLAs garbage
  do g=0,size(self%clasg,dim=1)-1
    if (.not.self%is_defined(group=self%clasg(g)%group, switch='--')) &
      call self%add(pref        = pref,    &
                    group_index = g,       &
                    switch      = '--',    &
                    required    = .false., &
                    hidden      = .true.,  &
                    nargs       = '*',     &
                    def         = '',      &
                    act         = 'store')
  enddo
  contains
    subroutine add_builtin(g, switch, switch_ab, help, act)
    !< Add a builtin to a group, unless the user defined its switch; without its abbreviation if the user took that one
    !< (B32 of #125: the user's switches take precedence).
    integer(I4P), intent(in) :: g         !< Group index.
    character(*), intent(in) :: switch    !< Switch of the builtin.
    character(*), intent(in) :: switch_ab !< Abbreviation of the builtin.
    character(*), intent(in) :: help      !< Help message.
    character(*), intent(in) :: act       !< Action.

    if (self%is_defined(group=self%clasg(g)%group, switch=switch)) return
    if (self%is_defined(group=self%clasg(g)%group, switch=switch_ab)) then
      call self%add(pref=pref, group_index=g, switch=switch, help=help, required=.false., def='', act=act)
    else
      call self%add(pref=pref, group_index=g, switch=switch, switch_ab=switch_ab, help=help, required=.false., def='', &
                    act=act)
    endif
    endsubroutine add_builtin
  endsubroutine ensure_builtins

  function builtins_missing(self) result(missing)
  !< Check if the builtin CLAs still have to be added (the hidden "--" is added last, in every group).
  class(command_line_interface), intent(in) :: self    !< CLI data.
  logical                                   :: missing !< Check result.
  integer(I4P)                              :: g       !< Counter for CLAs group.

  missing = .false.
  do g=0, size(self%clasg, dim=1) - 1
    if (.not.self%clasg(g)%is_defined(switch='--')) then
      missing = .true.
      return
    endif
  enddo
  endfunction builtins_missing

  function usage(self, g, pref, no_header, no_examples, no_epilog, markdown) result(usaged)
  !< Get CLI usage, builtins included whether or not parse has been called.
  class(command_line_interface), intent(in) :: self        !< CLI data.
  integer(I4P),                  intent(in) :: g           !< Group index.
  character(*), optional,        intent(in) :: pref        !< Prefixing string.
  logical,      optional,        intent(in) :: no_header   !< Avoid insert header to usage.
  logical,      optional,        intent(in) :: no_examples !< Avoid insert examples to usage.
  logical,      optional,        intent(in) :: no_epilog   !< Avoid insert epilogue to usage.
  logical,      optional,        intent(in) :: markdown    !< Format things with markdown
  character(len=:), allocatable             :: usaged      !< Usage string.
  type(command_line_interface)              :: cli         !< Copy of the CLI with the builtins.

  if (self%builtins_missing()) then
    cli = self
    call cli%ensure_builtins(pref=pref)
    usaged = cli%usage_core(g=g, pref=pref, no_header=no_header, no_examples=no_examples, no_epilog=no_epilog, &
                            markdown=markdown)
  else
    usaged = self%usage_core(g=g, pref=pref, no_header=no_header, no_examples=no_examples, no_epilog=no_epilog, &
                             markdown=markdown)
  endif
  endfunction usage

  function signature(self, bash_completion)
  !< Get CLI signature, builtins included whether or not parse has been called.
  class(command_line_interface), intent(in) :: self            !< CLI data.
  logical, optional,             intent(in) :: bash_completion !< Return the signature for bash completion.
  character(len=:), allocatable             :: signature       !< Signature.
  type(command_line_interface)              :: cli             !< Copy of the CLI with the builtins.

  if (self%builtins_missing()) then
    cli = self
    call cli%ensure_builtins
    signature = cli%signature_core(bash_completion=bash_completion)
  else
    signature = self%signature_core(bash_completion=bash_completion)
  endif
  endfunction signature

  subroutine save_bash_completion(self, bash_file, error)
  !< Save bash completion script (for named CLAs only), builtins included whether or not parse has been called.
  class(command_line_interface), intent(in)  :: self      !< CLI data.
  character(*),                  intent(in)  :: bash_file !< Output file name of bash completion script.
  integer(I4P), optional,        intent(out) :: error     !< Error trapping flag.
  type(command_line_interface)               :: cli       !< Copy of the CLI with the builtins.

  if (self%builtins_missing()) then
    cli = self
    call cli%ensure_builtins
    call cli%save_bash_completion_core(bash_file=bash_file, error=error)
  else
    call self%save_bash_completion_core(bash_file=bash_file, error=error)
  endif
  endsubroutine save_bash_completion

  subroutine save_man_page(self, man_file, error)
  !< Save CLI usage as man page, builtins included whether or not parse has been called.
  class(command_line_interface), intent(in)  :: self     !< CLI data.
  character(*),                  intent(in)  :: man_file !< Output file name for saving man page.
  integer(I4P), optional,        intent(out) :: error    !< Error trapping flag.
  type(command_line_interface)               :: cli      !< Copy of the CLI with the builtins.

  if (self%builtins_missing()) then
    cli = self
    call cli%ensure_builtins
    call cli%save_man_page_core(man_file=man_file, error=error)
  else
    call self%save_man_page_core(man_file=man_file, error=error)
  endif
  endsubroutine save_man_page

  subroutine save_usage_to_markdown(self, markdown_file, error)
  !< Save CLI usage as markdown, builtins included whether or not parse has been called.
  class(command_line_interface), intent(in)  :: self          !< CLI data.
  character(*),                  intent(in)  :: markdown_file !< Output file name for saving markdown.
  integer(I4P), optional,        intent(out) :: error         !< Error trapping flag.
  type(command_line_interface)               :: cli           !< Copy of the CLI with the builtins.

  if (self%builtins_missing()) then
    cli = self
    call cli%ensure_builtins
    call cli%save_usage_to_markdown_core(markdown_file=markdown_file, error=error)
  else
    call self%save_usage_to_markdown_core(markdown_file=markdown_file, error=error)
  endif
  endsubroutine save_usage_to_markdown

  function usage_core(self, g, pref, no_header, no_examples, no_epilog, markdown) result(usaged)
  !< Print correct usage of CLI.
  class(command_line_interface), intent(in) :: self             !< CLI data.
  integer(I4P),                  intent(in) :: g                !< Group index.
  character(*), optional,        intent(in) :: pref             !< Prefixing string.
  logical,      optional,        intent(in) :: no_header        !< Avoid insert header to usage.
  logical,      optional,        intent(in) :: no_examples      !< Avoid insert examples to usage.
  logical,      optional,        intent(in) :: no_epilog        !< Avoid insert epilogue to usage.
  logical,      optional,        intent(in) :: markdown         !< Format things with markdown
  character(len=:), allocatable             :: prefd            !< Prefixing string.
  character(len=:), allocatable             :: usaged           !< Usage string.
  logical                                   :: no_headerd       !< Avoid insert header to usage.
  logical                                   :: no_examplesd     !< Avoid insert examples to usage.
  logical                                   :: no_epilogd       !< Avoid insert epilogue to usage.
  logical                                   :: markdownd        !< Format for markdown.
  logical                                   :: grouped_examples !< Will show examples of group usage.
  integer(I4P)                              :: gi               !< Counter.

  no_headerd = .false. ; if (present(no_header)) no_headerd = no_header
  no_examplesd = .false. ; if (present(no_examples)) no_examplesd = no_examples
  no_epilogd = .false. ; if (present(no_epilog)) no_epilogd = no_epilog
  markdownd = .false. ; if (present(markdown)) markdownd = markdown
  prefd = '' ; if (present(pref)) prefd = pref
  grouped_examples = .false.
  if (g>0) then ! usage of a specific command
    usaged = self%clasg(g)%usage(pref=prefd,no_header=no_headerd,markdown=markdownd)
    if(allocated(self%clasg(g)%examples).and.(.not.no_examplesd)) then
      usaged = usaged//print_examples(prefd, self%clasg(g)%examples)
      grouped_examples = .true.
    endif
  else ! usage of whole CLI
    if (no_headerd) then
      usaged = ''
    else
      usaged = prefd//self%help//self%progname//' '//self%signature()
      if (self%description/='') usaged = usaged//new_line('a')//new_line('a')//prefd//self%description
    endif
    if (self%clasg(0)%Na>0) usaged = usaged//new_line('a')//self%clasg(0)%usage(pref=prefd,no_header=.true.,markdown=markdownd)
    if (size(self%clasg,dim=1)>1) then
      usaged = usaged//new_line('a')//new_line('a')//prefd//'Commands:'
      do gi=1, size(self%clasg,dim=1)-1
        usaged = usaged//new_line('a')//prefd//'  '//self%clasg(gi)%group
        usaged = usaged//new_line('a')//prefd//repeat(' ',10)//self%clasg(gi)%description
      enddo
      usaged = usaged//new_line('a')//new_line('a')//prefd//'For more detailed commands help try:'
      do gi=1,size(self%clasg,dim=1)-1
        usaged = usaged//new_line('a')//prefd//'  '//self%progname//' '//self%clasg(gi)%group//' -h,--help'
      enddo
    endif
  endif
  if (allocated(self%examples).and.(.not.no_examplesd).and.(.not.grouped_examples)) then
    usaged = usaged//print_examples(prefd, self%examples)
  endif
  if (self%epilog/=''.and.(.not.no_epilogd)) usaged = usaged//new_line('a')//prefd//self%epilog

  contains
    function print_examples(prefd, examples) result(exampled)
    !< Print examples of the correct usage.
      character(*),     intent(in)  :: prefd          !< Prefixing string.
      type(flap_string), intent(in) :: examples(1:)   !< Examples to be printed.
      character(len=:), allocatable :: exampled       !< Examples string.
      integer(I4P)                  :: e              !< Counter.

      exampled = new_line('a')//new_line('a')//prefd//'Examples:'
      do e=1, size(examples,dim=1)
        exampled = exampled//new_line('a')//prefd//'   '//trim(examples(e)%s)
      enddo
    endfunction print_examples
  endfunction usage_core

  function signature_core(self, bash_completion) result(signature)
  !< Get signature.
  class(command_line_interface), intent(in) :: self             !< CLI data.
  logical, optional,             intent(in) :: bash_completion  !< Return the signature for bash completion.
  logical                                   :: bash_completion_ !< Return the signature for bash completion, local variable.
  character(len=:), allocatable             :: signature        !< Signature.
  character(len=:), allocatable             :: commands         !< Completion line of the command names.
  integer(I4P)                              :: g                !< Counter.
  integer(I4P)                              :: c                !< Character position.

  bash_completion_ = .false. ; if (present(bash_completion)) bash_completion_ = bash_completion

  signature = ''
  if (bash_completion_) then
    ! top-level words, the command names, then the value completions of the top-level switches (#125, B18: no nested
    ! COMPREPLY line); the command names come before the value completions, so that they are offered after a flag too
    signature = self%clasg(0)%signature(bash_completion=.true.)
    if (size(self%clasg,dim=1)>1) then
      commands = new_line('a')//'    COMPREPLY+=( $( compgen -W "'//self%clasg(1)%group
      do g=2,size(self%clasg,dim=1)-1
        commands = commands//' '//self%clasg(g)%group
      enddo
      commands = commands//'" -- $cur ) )'
      c = index(signature(2:), new_line('a')) ! end of the first line (the one setting COMPREPLY), 0 if it is the last
      if (c > 0) then
        signature = signature(1:c)//commands//signature(c+1:)
      else
        signature = signature//commands
      endif
    endif
  else
    signature = self%clasg(0)%signature()
    if (size(self%clasg,dim=1)>1) then
      signature = signature//' {'//self%clasg(1)%group
      do g=2,size(self%clasg,dim=1)-1
        signature = signature//','//self%clasg(g)%group
      enddo
      signature = signature//'} ...'
    endif
  endif
  endfunction signature_core

  subroutine print_usage(self, pref)
  !< Print correct usage.
  class(command_line_interface), intent(in) :: self  !< CLI data.
  character(*), optional,        intent(in) :: pref  !< Prefixing string.

  write(self%usage_lun, '(A)') self%usage(pref=pref, g=0)
  endsubroutine print_usage

  subroutine save_bash_completion_core(self, bash_file, error)
  !< Save bash completion script (for named CLAs only).
  class(command_line_interface), intent(in)  :: self      !< CLI data.
  character(*),                  intent(in)  :: bash_file !< Output file name of bash completion script.
  integer(I4P), optional,        intent(out) :: error     !< Error trapping flag.
  character(len=:), allocatable              :: script    !< Script text.
  integer(I4P)                               :: g         !< CLAs groups counter.
  integer(I4P)                               :: u         !< Unit file handler.

  script = '#!/usr/bin/env bash'
  script = script//new_line('a')//'_completion()'
  script = script//new_line('a')//'{'
  script = script//new_line('a')//'  local cur prev group w'
  script = script//new_line('a')//'  cur=${COMP_WORDS[COMP_CWORD]}'
  script = script//new_line('a')//'  prev=${COMP_WORDS[COMP_CWORD - 1]}'
  if (size(self%clasg,dim=1)>1) then
    ! the command is the first word typed so far that is a command name, found again at every call (#125, B21)
    script = script//new_line('a')//'  group=""'
    script = script//new_line('a')//'  for w in "${COMP_WORDS[@]:1:$((COMP_CWORD - 1))}"; do'
    script = script//new_line('a')//'    case "$w" in'
    script = script//new_line('a')//'      '//self%clasg(1)%group
    do g=2,size(self%clasg,dim=1)-1
      script = script//'|'//self%clasg(g)%group
    enddo
    script = script//') group="$w" ; break ;;'
    script = script//new_line('a')//'    esac'
    script = script//new_line('a')//'  done'
    script = script//new_line('a')//'  if [ "$group" == "'//self%clasg(1)%group//'" ] ; then'
    script = script//self%clasg(1)%signature(bash_completion=.true.)
    do g=2,size(self%clasg,dim=1)-1
      script = script//new_line('a')//'  elif [ "$group" == "'//self%clasg(g)%group//'" ] ; then'
      script = script//self%clasg(g)%signature(bash_completion=.true.)
    enddo
    script = script//new_line('a')//'  else'
    script = script//self%signature(bash_completion=.true.)
    script = script//new_line('a')//'  fi'
  else
    script = script//self%signature(bash_completion=.true.)
  endif
  script = script//new_line('a')//'  return 0'
  script = script//new_line('a')//'}'
  script = script//new_line('a')//'complete -F _completion '//basename(self%progname)
  if (present(error)) then
    ! failures are reported through error
    open(newunit=u, file=trim(adjustl(bash_file)), action='write', status='replace', iostat=error)
    if (error /= 0) return
    write(u, "(A)", iostat=error)script
  else
    ! without error, a failure stops the program as for any unchecked Fortran I/O
    open(newunit=u, file=trim(adjustl(bash_file)), action='write', status='replace')
    write(u, "(A)")script
  endif
  close(u)
  contains
    pure function basename(progname)
      character(len=*), intent(in)  :: progname !< Program name.
      character(len=:), allocatable :: basename !< Program name without full PATH.
      integer(I4P)                  :: pos      !< Counter.

      basename = progname
      pos = index(basename, '/', back=.true.)
      if (pos>0) then
        basename = basename(pos+1:)
      else
        pos = index(basename, '\', back=.true.)
        if (pos>0) basename = basename(pos+1:)
      endif
      endfunction basename
  endsubroutine save_bash_completion_core

  subroutine save_man_page_core(self, man_file, error)
  !< Save CLI usage as man page.
  class(command_line_interface), intent(in)  :: self               !< CLI data.
  character(*),                  intent(in)  :: man_file           !< Output file name for saving man page.
  integer(I4P), optional,        intent(out) :: error              !< Error trapping flag.
  character(len=:), allocatable              :: man                !< Man page.
  integer(I4P)                               :: idate(1:8)         !< Integer array for handling the date.
  integer(I4P)                               :: e                  !< Counter.
  integer(I4P)                               :: u                  !< Unit file handler.
  character(*), parameter                    :: month(12)=["Jan",&
                                                           "Feb",&
                                                           "Mar",&
                                                           "Apr",&
                                                           "May",&
                                                           "Jun",&
                                                           "Jul",&
                                                           "Aug",&
                                                           "Sep",&
                                                           "Oct",&
                                                           "Nov",&
                                                           "Dec"]  !< Months list.

  call date_and_time(values=idate)
  man = '.TH '//self%progname//' "1" "'//month(idate(2))//' '//trim(adjustl(strz(idate(1),4)))//'" "version '//self%version//&
    '" "'//self%progname//' Manual"'
  man = man//new_line('a')//'.SH NAME'
  man = man//new_line('a')//self%progname//' - manual page for '//self%progname//' version '//self%version
  man = man//new_line('a')//'.SH SYNOPSIS'
  man = man//new_line('a')//'.B '//self%progname//new_line('a')//trim(adjustl(self%signature()))
  if (self%description /= '') man = man//new_line('a')//'.SH DESCRIPTION'//new_line('a')//self%description
  if (self%clasg(0)%Na>0) then
    man = man//new_line('a')//'.SH OPTIONS'
    man = man//new_line('a')//self%usage(no_header=.true.,no_examples=.true.,no_epilog=.true.,g=0)
  endif
  if (allocated(self%examples)) then
    man = man//new_line('a')//'.SH EXAMPLES'
    man = man//new_line('a')//'.PP'
    man = man//new_line('a')//'.nf'
    man = man//new_line('a')//'.RS'
    do e=1, size(self%examples,dim=1)
      man = man//new_line('a')//trim(self%examples(e)%s)
    enddo
    man = man//new_line('a')//'.RE'
    man = man//new_line('a')//'.fi'
    man = man//new_line('a')//'.PP'
  endif
  if (self%authors /= '') man = man//new_line('a')//'.SH AUTHOR'//new_line('a')//self%authors
  if (self%license /= '') man = man//new_line('a')//'.SH COPYRIGHT'//new_line('a')//self%license
  if (present(error)) then
    ! failures are reported through error
    open(newunit=u, file=trim(adjustl(man_file)), action='write', status='replace', iostat=error)
    if (error /= 0) return
    write(u, "(A)", iostat=error)man
  else
    ! without error, a failure stops the program as for any unchecked Fortran I/O
    open(newunit=u, file=trim(adjustl(man_file)), action='write', status='replace')
    write(u, "(A)")man
  endif
  close(u)
  endsubroutine save_man_page_core

  subroutine save_usage_to_markdown_core(self, markdown_file, error)
  !< Save CLI usage as markdown.
  class(command_line_interface), intent(in)  :: self               !< CLI data.
  character(*),                  intent(in)  :: markdown_file      !< Output file name for saving man page.
  integer(I4P), optional,        intent(out) :: error              !< Error trapping flag.
  character(len=:), allocatable              :: man                !< Man page.
  integer(I4P)                               :: idate(1:8)         !< Integer array for handling the date.
  integer(I4P)                               :: e                  !< Counter.
  integer(I4P)                               :: u                  !< Unit file handler.
  character(*), parameter                    :: month(12)=["Jan",&
                                                           "Feb",&
                                                           "Mar",&
                                                           "Apr",&
                                                           "May",&
                                                           "Jun",&
                                                           "Jul",&
                                                           "Aug",&
                                                           "Sep",&
                                                           "Oct",&
                                                           "Nov",&
                                                           "Dec"]  !< Months list.

  call date_and_time(values=idate)
  man = '# '//self%progname//new_line('a')
  man = man//new_line('a')//'Manual page for `'//self%progname//'` version '//self%version//new_line('a')
  man = man//new_line('a')//'`'//self%progname//' '//trim(adjustl(self%signature()))//'`'//new_line('a')
  man = man//new_line('a')//month(idate(2))//' '//trim(adjustl(strz(idate(1),4)))//new_line('a')
  if (self%description /= '') man = man//new_line('a')//'### Short description'//new_line('a')//new_line('a')//self%description
  if (self%clasg(0)%Na>0) then
    man = man//new_line('a')//new_line('a')//'### Command line options:'
    man = man//self%usage(no_header=.true.,no_examples=.true.,no_epilog=.true.,g=0,markdown=.true.)
  endif
  if (allocated(self%examples)) then
    man = man//new_line('a')//new_line('a')//'### Examples'
    do e=1, size(self%examples,dim=1)
      man = man//new_line('a')
      man = man//new_line('a')//'`'//trim(self%examples(e)%s)//'` '
    enddo
  endif
  if (present(error)) then
    ! failures are reported through error
    open(newunit=u, file=trim(adjustl(markdown_file)), action='write', status='replace', iostat=error)
    if (error /= 0) return
    write(u, "(A)", iostat=error)man
  else
    ! without error, a failure stops the program as for any unchecked Fortran I/O
    open(newunit=u, file=trim(adjustl(markdown_file)), action='write', status='replace')
    write(u, "(A)")man
  endif
  close(u)
  endsubroutine save_usage_to_markdown_core

  ! private methods
  subroutine errored(self, error, pref, group, switch, position)
  !< Trig error occurrence and print meaningful message.
  class(command_line_interface), intent(inout) :: self     !< Object data.
  integer(I4P),                  intent(in)    :: error    !< Error occurred.
  character(*), optional,        intent(in)    :: pref     !< Prefixing string.
  character(*), optional,        intent(in)    :: group    !< Group name.
  character(*), optional,        intent(in)    :: switch   !< CLA switch name.
  integer(I4P), optional,        intent(in)    :: position !< Position of the command line argument.
  character(len=:), allocatable                :: prefd    !< Prefixing string.

  self%error = error
  if (self%error/=0) then
    prefd = self%error_prefix(pref=pref)
    select case(self%error)
    case(ERROR_MISSING_CLA)
      self%error_message = prefd//': there is no option "'//trim(adjustl(switch))//'"!'
    case(ERROR_MISSING_SELECTION_CLA)
      self%error_message = prefd//': to get an option value one of switch "name" or "position" must be provided!'
    case(ERROR_MISSING_GROUP)
      self%error_message = prefd//': ther is no group (command) named "'//trim(adjustl(group))//'"!'
    case(ERROR_ARGUMENT_RETRIEVAL)
      self%error_message = prefd//': the command line argument number '//trim(str(position, .true.))//' cannot be retrieved!'
    case(ERROR_TOO_FEW_CLAS)
      ! self%error_message = prefd//': too few arguments ('//trim(str(.true.,Na))//')'//&
                         ! ' respect the required ('//trim(str(.true.,self%Na_required))//')'
    endselect
    write(self%error_lun,'(A)')
    call self%print_error_message
  endif
  endsubroutine errored


  elemental subroutine finalize(self)
  !< Free dynamic memory when finalizing.
  type(command_line_interface), intent(inout) :: self !< CLI data.

  call self%free
  endsubroutine finalize

  subroutine quiet_stop(code)
  !< End the program with an exit status, printing nothing (help/version/markdown: 0; no arguments: 2).
  !<
  !< F2018 `stop code, quiet=.true.`; nvfortran 26.5 rejects `quiet=` and prints "FORTRAN STOP" on a plain `stop`, so it
  !< uses its `exit` extension (B33 of #125).
  integer(I4P), intent(in) :: code !< Exit status.

#if defined __NVCOMPILER
  call exit(code)
#else
  stop code, quiet=.true.
#endif
  endsubroutine quiet_stop
endmodule flap_command_line_interface_t

!< Command Line Interface (CLI) class.
module flap_command_line_interface_t
!-----------------------------------------------------------------------------------------------------------------------------------
!< Command Line Interface (CLI) class.
!-----------------------------------------------------------------------------------------------------------------------------------
use flap_command_line_argument_t, only : command_line_argument, action_store
use flap_command_line_arguments_group_t, only : command_line_arguments_group, STATUS_PRINT_H, STATUS_PRINT_V
use flap_object_t, only : object
use flap_utils_m
use penf
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
save
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
type, extends(object), public :: command_line_interface
  !< Command Line Interface (CLI) class.
  private
  type(command_line_arguments_group), allocatable :: clasg(:)           !< CLA list [1:Na].
#ifdef __GFORTRAN__
  character(512  ), allocatable                   :: args(:)            !< Actually passed command line arguments.
  character(512  ), allocatable                   :: examples(:)        !< Examples of correct usage.
#else
  character(len=:), allocatable                   :: args(:)            !< Actually passed command line arguments.
  character(len=:), allocatable                   :: examples(:)        !< Examples of correct usage (not work with gfortran).
#endif
  logical                                         :: disable_hv=.false. !< Disable automatic 'help' and 'version' CLAs.
  logical                                         :: is_parsed_=.false. !< Parse status.
  contains
    ! public methods
    procedure, public :: free                            !< Free dynamic memory.
    procedure, public :: init                            !< Initialize CLI.
    procedure, public :: add_group                       !< Add CLAs group CLI.
    procedure, public :: add                             !< Add CLA to CLI.
    procedure, public :: is_passed                       !< Check if a CLA has been passed.
    procedure, public :: is_defined_group                !< Check if a CLAs group has been defined.
    procedure, public :: is_defined                      !< Check if a CLA has been defined.
    procedure, public :: is_parsed                       !< Check if CLI has been parsed.
    procedure, public :: set_mutually_exclusive_groups   !< Set two CLAs group as mutually exclusive.
    procedure, public :: run_command => is_called_group  !< Check if a CLAs group has been run.
    procedure, public :: parse                           !< Parse Command Line Interfaces.
    generic,   public :: get =>   &
                         get_cla, &
                         get_cla_list                    !< Get CLA value(s) from CLAs list parsed.
    generic,   public :: get_varying =>                &
#ifdef r16p
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
    procedure, public :: save_man_page                   !< Save man page build on CLI.
    ! private methods
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
    procedure, private :: cli_assign_cli                  !< CLI assignment overloading.
    generic,   private :: assignment(=) => cli_assign_cli !< CLI assignment overloading.
    final              :: finalize                        !< Free dynamic memory when finalizing.
endtype command_line_interface
integer(I4P),     parameter, public :: MAX_VAL_LEN        = 1000            !< Maximum number of characters of CLA value.
! errors codes
integer(I4P), parameter, public :: ERROR_MISSING_CLA           = 25 !< CLA not found in CLI.
integer(I4P), parameter, public :: ERROR_MISSING_GROUP         = 26 !< Group not found in CLI.
integer(I4P), parameter, public :: ERROR_MISSING_SELECTION_CLA = 27 !< CLA selection in CLI failing.
integer(I4P), parameter, public :: ERROR_TOO_FEW_CLAS          = 28 !< Insufficient arguments for CLI.
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  ! public methods
  elemental subroutine free(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(inout) :: self !< CLI data.
  integer(I4P)                                 :: g    !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! object members
  call self%free_object
  ! command_line_interface members
  if (allocated(self%clasg)) then
    do g=0, size(self%clasg,dim=1) - 1
      call self%clasg(g)%free
    enddo
    deallocate(self%clasg)
  endif
  if (allocated(self%examples))  deallocate(self%examples)
  self%disable_hv = .false.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free

  subroutine init(self, progname, version, help, description, license, authors, examples, epilog, disable_hv, &
       usage_lun, error_lun, version_lun)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Initialize CLI.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(inout) :: self              !< CLI data.
  character(*), optional,        intent(in)    :: progname          !< Program name.
  character(*), optional,        intent(in)    :: version           !< Program version.
  character(*), optional,        intent(in)    :: help              !< Help message introducing the CLI usage.
  character(*), optional,        intent(in)    :: description       !< Detailed description message introducing the program.
  character(*), optional,        intent(in)    :: license           !< License description.
  character(*), optional,        intent(in)    :: authors           !< Authors list.
  character(*), optional,        intent(in)    :: examples(1:)      !< Examples of correct usage.
  character(*), optional,        intent(in)    :: epilog            !< Epilog message.
  logical,      optional,        intent(in)    :: disable_hv        !< Disable automatic insert of 'help' and 'version' CLAs.
  integer(I4P), optional,        intent(in)    :: usage_lun         !< Unit number to print usage/help
  integer(I4P), optional,        intent(in)    :: version_lun       !< Unit number to print version/license info
  integer(I4P), optional,        intent(in)    :: error_lun         !< Unit number to print error info
  character(len=:), allocatable                :: prog_invocation   !< Complete program invocation.
  integer(I4P)                                 :: invocation_length !< Length of invocation.
  integer(I4P)                                 :: retrieval_status  !< Retrieval status.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%free
  if (present(usage_lun))   self%usage_lun   = usage_lun
  if (present(version_lun)) self%version_lun = version_lun
  if (present(error_lun))   self%error_lun   = error_lun
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
  self%epilog      = ''        ; if (present(epilog     )) self%epilog      = epilog
  if (present(disable_hv)) self%disable_hv = disable_hv
  if (present(examples)) then
#ifdef __GFORTRAN__
    allocate(self%examples(1:size(examples)))
#else
    allocate(character(len=len(examples(1))):: self%examples(1:size(examples))) ! does not work with gfortran 4.9.2
#endif
    self%examples = examples
  endif
  ! initialize only the first default group
  allocate(self%clasg(0:0))
  call self%clasg(0)%assign_object(self)
  self%clasg(0)%group = ''
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine init

  subroutine add_group(self, help, description, exclude, group)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Add CLAs group to CLI.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(inout)    :: self              !< CLI data.
  character(*), optional,        intent(in)       :: help              !< Help message.
  character(*), optional,        intent(in)       :: description       !< Detailed description.
  character(*), optional,        intent(in)       :: exclude           !< Group name of the mutually exclusive group.
  character(*),                  intent(in)       :: group             !< Name of the grouped CLAs.
  type(command_line_arguments_group), allocatable :: clasg_list_new(:) !< New (extended) CLAs group list.
  character(len=:), allocatable                   :: helpd             !< Help message.
  character(len=:), allocatable                   :: descriptiond      !< Detailed description.
  character(len=:), allocatable                   :: excluded          !< Group name of the mutually exclusive group.
  integer(I4P)                                    :: Ng                !< Number of groups.
  integer(I4P)                                    :: gi                !< Group index
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
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
    deallocate(self%clasg)
    allocate(self%clasg(0:Ng))
    self%clasg = clasg_list_new
    deallocate(clasg_list_new)
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add_group

  subroutine set_mutually_exclusive_groups(self, group1, group2)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Set two CLAs group ad mutually exclusive.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(inout) :: self   !< CLI data.
  character(*),                  intent(in)    :: group1 !< Name of the first grouped CLAs.
  character(*),                  intent(in)    :: group2 !< Name of the second grouped CLAs.
  integer(I4P)                                 :: g1     !< Counter.
  integer(I4P)                                 :: g2     !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (self%is_defined_group(group=group1, g=g1).and.self%is_defined_group(group=group2, g=g2)) then
    self%clasg(g1)%m_exclude = group2
    self%clasg(g2)%m_exclude = group1
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine set_mutually_exclusive_groups

  subroutine add(self, pref, group, group_index, switch, switch_ab, help, required, &
                 positional, position, hidden, act, def, nargs, choices, exclude, envvar, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Add CLA to CLI.
  !<
  !< @note If not otherwise declared the action on CLA value is set to "store" a value that must be passed after the switch name
  !< or directly passed in case of positional CLA.
  !<
  !< @note If not otherwise speficied the CLA belongs to the default group "zero" that is the group of non-grouped CLAs.
  !<
  !< @note If CLA belongs to a not yet present group it is created on the fly.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(inout) :: self        !< CLI data.
  character(*), optional,        intent(in)    :: pref        !< Prefixing string.
  character(*), optional,        intent(in)    :: group       !< Name of the grouped CLAs.
  integer(I4P), optional,        intent(in)    :: group_index !< Index of the grouped CLAs.
  character(*), optional,        intent(in)    :: switch      !< Switch name.
  character(*), optional,        intent(in)    :: switch_ab   !< Abbreviated switch name.
  character(*), optional,        intent(in)    :: help        !< Help message describing the CLA.
  logical,      optional,        intent(in)    :: required    !< Flag for set required argument.
  logical,      optional,        intent(in)    :: positional  !< Flag for checking if CLA is a positional or a named CLA.
  integer(I4P), optional,        intent(in)    :: position    !< Position of positional CLA.
  logical,      optional,        intent(in)    :: hidden      !< Flag for hiding CLA, thus it does not compare into help.
  character(*), optional,        intent(in)    :: act         !< CLA value action.
  character(*), optional,        intent(in)    :: def         !< Default value.
  character(*), optional,        intent(in)    :: nargs       !< Number of arguments consumed by CLA.
  character(*), optional,        intent(in)    :: choices     !< List of allowable values for the argument.
  character(*), optional,        intent(in)    :: exclude     !< Switch name of the mutually exclusive CLA.
  character(*), optional,        intent(in)    :: envvar      !< Environment variable from which take value.
  integer(I4P), optional,        intent(out)   :: error       !< Error trapping flag.
  type(command_line_argument)                  :: cla         !< CLA data.
  integer(I4P)                                 :: g           !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
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
                                                if (present(switch_ab )) cla%switch_ab     = switch_ab
  cla%help          = 'Undocumented argument' ; if (present(help      )) cla%help          = help
  cla%is_required   = .false.                 ; if (present(required  )) cla%is_required   = required
  cla%is_positional = .false.                 ; if (present(positional)) cla%is_positional = positional
  cla%position      = 0_I4P                   ; if (present(position  )) cla%position      = position
  cla%is_hidden     = .false.                 ; if (present(hidden    )) cla%is_hidden     = hidden
  cla%act           = action_store            ; if (present(act       )) cla%act           = trim(adjustl(Upper_Case(act)))
                                                if (present(def       )) cla%def           = def
                                                if (present(def       )) cla%val           = def
                                                if (present(nargs     )) cla%nargs         = nargs
                                                if (present(choices   )) cla%choices       = choices
  cla%m_exclude     = ''                      ; if (present(exclude   )) cla%m_exclude     = exclude
                                                if (present(envvar    )) cla%envvar        = envvar
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add

  subroutine check(self, pref, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check data consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(INOUT) :: self  !< CLI data.
  character(*), optional,        intent(IN)    :: pref  !< Prefixing string.
  integer(I4P), optional,        intent(OUT)   :: error !< Error trapping flag.
  integer(I4P)                                 :: g     !< Counter.
  integer(I4P)                                 :: gg    !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  do g=0,size(self%clasg,dim=1)-1
    ! check group consistency
    call self%clasg(g)%check(pref=pref)
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check

  subroutine check_m_exclusive(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if two mutually exclusive CLAs group have been called.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(inout) :: self  !< CLI data.
  character(*), optional,        intent(in)    :: pref  !< Prefixing string.
  integer(I4P)                                 :: g     !< Counter.
  integer(I4P)                                 :: gg    !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_m_exclusive

  function is_passed(self, group, switch, position)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if a CLA has been passed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(in) :: self      !< CLI data.
  character(*), optional,        intent(in) :: group     !< Name of group (command) of CLA.
  character(*), optional,        intent(in) :: switch    !< Switch name.
  integer(I4P), optional,        intent(in) :: position  !< Position of positional CLA.
  logical                                   :: is_passed !< Check if a CLA has been passed.
  integer(I4P)                              :: g         !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction is_passed

  function is_defined_group(self, group, g) result(defined)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if a CLAs group has been defined.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(in)  :: self    !< CLI data.
  character(*),                  intent(in)  :: group   !< Name of group (command) of CLAs.
  integer(I4P), optional,        intent(out) :: g       !< Index of group.
  logical                                    :: defined !< Check if a CLAs group has been defined.
  integer(I4P)                               :: gg      !< Counter.
  integer(I4P)                               :: ggg     !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  defined = .false.
  do gg=0, size(self%clasg,dim=1)-1
    ggg = gg
    if (allocated(self%clasg(gg)%group)) defined = (self%clasg(gg)%group==group)
    if (defined) exit
  enddo
  if (present(g)) g = ggg
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction is_defined_group

  function is_called_group(self, group) result(called)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if a CLAs group has been run.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(in) :: self   !< CLI data.
  character(*),                  intent(in) :: group  !< Name of group (command) of CLAs.
  logical                                   :: called !< Check if a CLAs group has been runned.
  integer(I4P)                              :: g      !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  called = .false.
  if (self%is_defined_group(group=group, g=g)) called = self%clasg(g)%is_called
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction is_called_group

  function is_defined(self, switch, group)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if a CLA has been defined.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(in) :: self       !< CLI data.
  character(*),                  intent(in) :: switch     !< Switch name.
  character(*), optional,        intent(in) :: group      !< Name of group (command) of CLAs.
  logical                                   :: is_defined !< Check if a CLA has been defined.
  integer(I4P)                              :: g          !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  is_defined = .false.
  if (.not.present(group)) then
    is_defined = self%clasg(0)%is_defined(switch=switch)
  else
    if (self%is_defined_group(group=group, g=g)) is_defined = self%clasg(g)%is_defined(switch=switch)
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction is_defined

  elemental function is_parsed(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if CLI has been parsed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(in) :: self      !< CLI data.
  logical                                   :: is_parsed !< Parsed status.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  is_parsed = self%is_parsed_
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction is_parsed

  subroutine parse(self, pref, args, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Parse Command Line Interfaces by means of a previously initialized CLAs groups list.
  !<
  !< @note The leading and trailing white spaces are removed from CLA values.
  !<
  !< @note If the *args* argument is passed the command line arguments are taken from it and not from the actual program CLI
  !< invocations.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(inout) :: self    !< CLI data.
  character(*), optional,        intent(in)    :: pref    !< Prefixing string.
  character(*), optional,        intent(in)    :: args    !< String containing command line arguments.
  integer(I4P), optional,        intent(out)   :: error   !< Error trapping flag.
  integer(I4P)                                 :: g       !< Counter for CLAs group.
  integer(I4P), allocatable                    :: ai(:,:) !< Counter for CLAs grouped.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (self%is_parsed_) return

  ! add help and version switches if not done by user
  if (.not.self%disable_hv) then
    do g=0,size(self%clasg,dim=1)-1
      if (.not.(self%is_defined(group=self%clasg(g)%group, switch='--help').and.&
                self%is_defined(group=self%clasg(g)%group, switch='-h'))) &
        call self%add(pref        = pref,                      &
                      group_index = g,                         &
                      switch      = '--help',                  &
                      switch_ab   = '-h',                      &
                      help        = 'Print this help message', &
                      required    = .false.,                   &
                      def         = '',                        &
                      act         = 'print_help')
      if (.not.(self%is_defined(group=self%clasg(g)%group, switch='--version').and. &
                self%is_defined(group=self%clasg(g)%group, switch='-v'))) &
        call self%add(pref        = pref,            &
                      group_index = g,               &
                      switch      = '--version',     &
                      switch_ab   = '-v',            &
                      help        = 'Print version', &
                      required    = .false.,         &
                      def         = '',              &
                      act         = 'print_version')
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

  ! parse passed CLAs grouping in indexes
  if (present(args)) then
    call self%get_args(args=args, ai=ai)
  else
    call self%get_args(ai=ai)
  endif

  ! check CLI consistency
  call self%check(pref=pref)
  if (self%error>0) then
    if (present(error)) error = self%error
    return
  endif

  ! parse CLI
  do g=0,size(ai,dim=1)-1
    if (ai(g,1)>0) call self%clasg(g)%parse(args=self%args(ai(g,1):ai(g,2)), pref=pref)
    self%error = self%clasg(g)%error
    if (self%error /= 0) exit
  enddo
  if (self%error>0) then
    if (present(error)) error = self%error
    return
  endif

  ! trap the special cases of version/help printing
  if (self%error == STATUS_PRINT_V) then
    call self%print_version(pref=pref)
    stop
  elseif (self%error == STATUS_PRINT_H) then
    write(self%usage_lun,'(A)') self%usage(pref=pref, g=g)
    stop
  endif

  ! check if all required CLAs have been passed
  do g=0, size(ai,dim=1)-1
    call self%clasg(g)%is_required_passed(pref=pref)
    self%error = self%clasg(g)%error
    if (self%error>0) exit
  enddo
  if (self%error>0) then
    if (present(error)) error = self%error
    return
  endif

  ! check mutually exclusive interaction
  call self%check_m_exclusive(pref=pref)

  self%is_parsed_ = .true.

  if (present(error)) error = self%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine parse

  subroutine get_clasg_indexes(self, ai)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get the argument indexes of CLAs groups defined parsing the actual passed CLAs.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(inout) :: self   !< CLI data.
  integer(I4P), allocatable,     intent(out)   :: ai(:,:)!< CLAs grouped indexes.
  integer(I4P)                                 :: Na     !< Number of command line arguments passed.
  integer(I4P)                                 :: a      !< Counter for CLAs.
  integer(I4P)                                 :: aa     !< Counter for CLAs.
  integer(I4P)                                 :: g      !< Counter for CLAs group.
  logical                                      :: found  !< Flag for inquiring if a named group is found.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  allocate(ai(0:size(self%clasg,dim=1)-1,1:2))
  ai = 0
  if (allocated(self%args)) then
    Na = size(self%args,dim=1)
    a = 0
    found = .false.
    search_named: do while(a<Na)
      a = a + 1
      if (self%is_defined_group(group=trim(self%args(a)), g=g)) then
        found = .true.
        self%clasg(g)%is_called = .true.
        ai(g,1) = a + 1
        aa = a
        do while(aa<Na)
          aa = aa + 1
          if (self%is_defined_group(group=trim(self%args(aa)))) then
            a = aa - 1
            ai(g,2) = a
            exit
          else
            ai(g,2) = aa
          endif
        enddo
      elseif (.not.found) then
        ai(0,2) = a
      endif
    enddo search_named
    if (ai(0,2)>0) then
      ai(0,1) = 1
      self%clasg(0)%is_called = .true.
    elseif (all(ai==0)) then
      self%clasg(0)%is_called = .true.
    endif
  else
    self%clasg(0)%is_called = .true.
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_clasg_indexes

  subroutine get_args_from_string(self, args, ai)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLAs from string.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(inout) :: self   !< CLI data.
  character(*),                  intent(in)    :: args   !< String containing command line arguments.
  integer(I4P), allocatable,     intent(out)   :: ai(:,:)!< CLAs grouped indexes.
  character(len=len_trim(args))                :: argsd  !< Dummy string containing command line arguments.
  character(len=len_trim(args)), allocatable   :: toks(:)!< CLAs tokenized.
  integer(I4P)                                 :: Nt     !< Number of tokens.
  integer(I4P)                                 :: Na     !< Number of command line arguments passed.
  integer(I4P)                                 :: a      !< Counter for CLAs.
  integer(I4P)                                 :: t      !< Counter for tokens.
  integer(I4P)                                 :: c      !< Counter for characters inside tokens.
#ifndef __GFORTRAN__
  integer(I4P)                                 :: length !< Maxium lenght of arguments string.
#endif
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! prepare CLI arguments list
  if (allocated(self%args)) deallocate(self%args)

  ! sanitize arguments string
  argsd = trim(args)
  if (index(args,"'")>0) then
    argsd = sanitize_args(argsin=argsd,delimiter="'")
  elseif (index(args,'"')>0) then
    argsd = sanitize_args(argsin=argsd,delimiter='"')
  endif

  ! tokenize arguments string; the previously sanitized white spaces inside tokens are restored
  call tokenize(strin=argsd, delimiter=' ', toks=toks, Nt=Nt)
  Na = 0
  find_number_of_valid_arguments: do t=1,Nt
    if (trim(adjustl(toks(t)))/='') then
      Na = Na + 1
      do c=1,len(toks(t))
        if (toks(t)(c:c)=="'") toks(t)(c:c)=" "
      enddo
    endif
  enddo find_number_of_valid_arguments

  if (Na > 0) then
    ! allocate CLI arguments list
#ifdef __GFORTRAN__
    allocate(self%args(1:Na))
#else
    length = 0
    find_longest_arg: do t=1,Nt
      if (trim(adjustl(toks(t)))/='') length = max(length,len_trim(adjustl(toks(t))))
    enddo find_longest_arg
    allocate(character(length):: self%args(1:Na))
#endif

    ! construct arguments list
    a = 0
    get_args: do t=1,Nt
      if (trim(adjustl(toks(t)))/='') then
        a = a + 1
        self%args(a) = trim(adjustl(toks(t)))
      endif
    enddo get_args
  endif

  call self%get_clasg_indexes(ai=ai)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  contains
    function sanitize_args(argsin, delimiter) result(sanitized)
    !-------------------------------------------------------------------------------------------------------------------------------
    !< Sanitize arguments string.
    !<
    !< Substitute white spaces enclosed into string-arguments, i.e. 'string argument with spaces...' or
    !< "string argument with spaces..." with a safe equivalent for tokenization against white spaces, i.e. the finally tokenized
    !< string is string'argument'with'spaces...
    !<
    !< @note The white spaces are reintroduce later.
    !-------------------------------------------------------------------------------------------------------------------------------
    character(*), intent(in)                     :: argsin    !< Arguments string.
    character(*), intent(in)                     :: delimiter !< Delimiter enclosing string argument.
    character(len=len_trim(argsin))              :: sanitized !< Arguments string sanitized.
    character(len=len_trim(argsin)), allocatable :: tok(:)    !< Arguments string tokens.
    integer(I4P)                                 :: Nt        !< Number of command line arguments passed.
    integer(I4P)                                 :: t         !< Counter.
    integer(I4P)                                 :: tt        !< Counter.
    !-------------------------------------------------------------------------------------------------------------------------------

    !-------------------------------------------------------------------------------------------------------------------------------
    call tokenize(strin=trim(argsin), delimiter=delimiter, toks=tok, Nt=Nt)
    do t=2, Nt, 2
      do tt=1,len_trim(adjustl(tok(t)))
        if (tok(t)(tt:tt)==' ') tok(t)(tt:tt) = "'"
      enddo
    enddo
    sanitized = ''
    do t=1, Nt
      sanitized = trim(sanitized)//" "//trim(adjustl(tok(t)))
    enddo
    sanitized = trim(adjustl(sanitized))
    return
    !-------------------------------------------------------------------------------------------------------------------------------
    endfunction sanitize_args
  endsubroutine get_args_from_string

  subroutine get_args_from_invocation(self, ai)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLAs from CLI invocation.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(inout) :: self    !< CLI data.
  integer(I4P), allocatable,     intent(out)   :: ai(:,:) !< CLAs grouped indexes.
  integer(I4P)                                 :: Na      !< Number of command line arguments passed.
  character(max_val_len)                       :: switch  !< Switch name.
  integer(I4P)                                 :: a       !< Counter for CLAs.
  integer(I4P)                                 :: aa      !< Counter for CLAs.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self%args)) deallocate(self%args)
  Na = command_argument_count()
  if (Na > 0) then
#ifdef __GFORTRAN__
    allocate(self%args(1:Na))
#else
    aa = 0
    find_longest_arg: do a=1, Na
      call get_command_argument(a,switch)
      aa = max(aa,len_trim(switch))
    enddo find_longest_arg
    allocate(character(aa):: self%args(1:Na))
#endif
    get_args: do a=1, Na
      call get_command_argument(a,switch)
      self%args(a) = trim(adjustl(switch))
    enddo get_args
  endif

  call self%get_clasg_indexes(ai=ai)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_args_from_invocation

  subroutine get_cla(self, val, pref, args, group, switch, position, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (single) value from CLAs list parsed.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error/=0) return
  endif
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
    endif
  else
    g = 0
  endif
  if (self%error==0.and.self%clasg(g)%is_called) then
    if (present(switch)) then
      ! search for the CLA corresponding to switch
      found = .false.
      do a=1,self%clasg(g)%Na
        if (.not.self%clasg(g)%cla(a)%is_positional) then
          if ((self%clasg(g)%cla(a)%switch==switch).or.(self%clasg(g)%cla(a)%switch_ab==switch)) then
            found = .true.
            exit
          endif
        endif
      enddo
      if (.not.found) then
        call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
      else
        call self%clasg(g)%cla(a)%get(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
      endif
    elseif (present(position)) then
      call self%clasg(g)%cla(position)%get(pref=pref, val=val) ; self%error = self%clasg(g)%cla(position)%error
    else
      call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
    endif
  endif
  if (present(error)) error = self%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla

  subroutine get_cla_list(self, val, pref, args, group, switch, position, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA multiple values from CLAs list parsed.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error/=0) return
  endif
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = .false.
    do a=1, self%clasg(g)%Na
      if (.not.self%clasg(g)%cla(a)%is_positional) then
        if ((self%clasg(g)%cla(a)%switch==switch).or.(self%clasg(g)%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    call self%clasg(g)%cla(position)%get(pref=pref, val=val) ; self%error = error
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  if (present(error)) error = self%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list

  subroutine get_cla_list_varying_R16P(self, val, pref, args, group, switch, position, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA multiple values from CLAs list parsed with varying size list, real(R16P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error/=0) return
  endif
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = .false.
    do a=1, self%clasg(g)%Na
      if (.not.self%clasg(g)%cla(a)%is_positional) then
        if ((self%clasg(g)%cla(a)%switch==switch).or.(self%clasg(g)%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    call self%clasg(g)%cla(position)%get_varying(pref=pref, val=val) ; self%error = error
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  if (present(error)) error = self%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_R16P

  subroutine get_cla_list_varying_R8P(self, val, pref, args, group, switch, position, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA multiple values from CLAs list parsed with varying size list, real(R8P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error/=0) return
  endif
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = .false.
    do a=1, self%clasg(g)%Na
      if (.not.self%clasg(g)%cla(a)%is_positional) then
        if ((self%clasg(g)%cla(a)%switch==switch).or.(self%clasg(g)%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    call self%clasg(g)%cla(position)%get_varying(pref=pref, val=val) ; self%error = error
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  if (present(error)) error = self%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_R8P

  subroutine get_cla_list_varying_R4P(self, val, pref, args, group, switch, position, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA multiple values from CLAs list parsed with varying size list, real(R4P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error/=0) return
  endif
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = .false.
    do a=1, self%clasg(g)%Na
      if (.not.self%clasg(g)%cla(a)%is_positional) then
        if ((self%clasg(g)%cla(a)%switch==switch).or.(self%clasg(g)%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    call self%clasg(g)%cla(position)%get_varying(pref=pref, val=val) ; self%error = error
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  if (present(error)) error = self%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_R4P

  subroutine get_cla_list_varying_I8P(self, val, pref, args, group, switch, position, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA multiple values from CLAs list parsed with varying size list, integer(I8P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error/=0) return
  endif
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = .false.
    do a=1, self%clasg(g)%Na
      if (.not.self%clasg(g)%cla(a)%is_positional) then
        if ((self%clasg(g)%cla(a)%switch==switch).or.(self%clasg(g)%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    call self%clasg(g)%cla(position)%get_varying(pref=pref, val=val) ; self%error = error
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  if (present(error)) error = self%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_I8P

  subroutine get_cla_list_varying_I4P(self, val, pref, args, group, switch, position, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA multiple values from CLAs list parsed with varying size list, integer(I4P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error/=0) return
  endif
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = .false.
    do a=1, self%clasg(g)%Na
      if (.not.self%clasg(g)%cla(a)%is_positional) then
        if ((self%clasg(g)%cla(a)%switch==switch).or.(self%clasg(g)%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    call self%clasg(g)%cla(position)%get_varying(pref=pref, val=val) ; self%error = error
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  if (present(error)) error = self%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_I4P

  subroutine get_cla_list_varying_I2P(self, val, pref, args, group, switch, position, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA multiple values from CLAs list parsed with varying size list, integer(I2P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error/=0) return
  endif
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = .false.
    do a=1, self%clasg(g)%Na
      if (.not.self%clasg(g)%cla(a)%is_positional) then
        if ((self%clasg(g)%cla(a)%switch==switch).or.(self%clasg(g)%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    call self%clasg(g)%cla(position)%get_varying(pref=pref, val=val) ; self%error = error
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  if (present(error)) error = self%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_I2P

  subroutine get_cla_list_varying_I1P(self, val, pref, args, group, switch, position, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA multiple values from CLAs list parsed with varying size list, integer(I1P).
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error/=0) return
  endif
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = .false.
    do a=1, self%clasg(g)%Na
      if (.not.self%clasg(g)%cla(a)%is_positional) then
        if ((self%clasg(g)%cla(a)%switch==switch).or.(self%clasg(g)%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    call self%clasg(g)%cla(position)%get_varying(pref=pref, val=val) ; self%error = error
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  if (present(error)) error = self%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_I1P

  subroutine get_cla_list_varying_logical(self, val, pref, args, group, switch, position, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA multiple values from CLAs list parsed with varying size list, logical.
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error/=0) return
  endif
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = .false.
    do a=1, self%clasg(g)%Na
      if (.not.self%clasg(g)%cla(a)%is_positional) then
        if ((self%clasg(g)%cla(a)%switch==switch).or.(self%clasg(g)%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    call self%clasg(g)%cla(position)%get_varying(pref=pref, val=val) ; self%error = error
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  if (present(error)) error = self%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_logical

  subroutine get_cla_list_varying_char(self, val, pref, args, group, switch, position, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA multiple values from CLAs list parsed with varying size list, character.
  !<
  !< @note The CLA list is returned deallocated if values are not correctly gotten.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_parsed_) then
    call self%parse(pref=pref, args=args, error=error)
    if (self%error/=0) return
  endif
  if (present(group)) then
    if (.not.self%is_defined_group(group=group, g=g)) then
      call self%errored(pref=pref, error=ERROR_MISSING_GROUP, group=group)
    endif
  else
    g = 0
  endif
  if (present(switch)) then
    ! search for the CLA corresponding to switch
    found = .false.
    do a=1, self%clasg(g)%Na
      if (.not.self%clasg(g)%cla(a)%is_positional) then
        if ((self%clasg(g)%cla(a)%switch==switch).or.(self%clasg(g)%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      call self%errored(pref=pref, error=ERROR_MISSING_CLA, switch=switch)
    else
      call self%clasg(g)%cla(a)%get_varying(pref=pref, val=val) ; self%error = self%clasg(g)%cla(a)%error
    endif
  elseif (present(position)) then
    call self%clasg(g)%cla(position)%get_varying(pref=pref, val=val) ; self%error = error
  else
    call self%errored(pref=pref, error=ERROR_MISSING_SELECTION_CLA)
  endif
  if (present(error)) error = self%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_char

  function usage(self, g, pref, no_header, no_examples, no_epilog) result(usaged)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Print correct usage of CLI.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(in) :: self         !< CLI data.
  integer(I4P),                  intent(in) :: g            !< Group index.
  character(*), optional,        intent(in) :: pref         !< Prefixing string.
  logical,      optional,        intent(in) :: no_header    !< Avoid insert header to usage.
  logical,      optional,        intent(in) :: no_examples  !< Avoid insert examples to usage.
  logical,      optional,        intent(in) :: no_epilog    !< Avoid insert epilogue to usage.
  character(len=:), allocatable             :: prefd        !< Prefixing string.
  character(len=:), allocatable             :: usaged       !< Usage string.
  logical                                   :: no_headerd   !< Avoid insert header to usage.
  logical                                   :: no_examplesd !< Avoid insert examples to usage.
  logical                                   :: no_epilogd   !< Avoid insert epilogue to usage.
  integer(I4P)                              :: gi           !< Counter.
  integer(I4P)                              :: e            !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  no_headerd = .false. ; if (present(no_header)) no_headerd = no_header
  no_examplesd = .false. ; if (present(no_examples)) no_examplesd = no_examples
  no_epilogd = .false. ; if (present(no_epilog)) no_epilogd = no_epilog
  prefd = '' ; if (present(pref)) prefd = pref
  if (g>0) then ! usage of a specific command
    usaged = self%clasg(g)%usage(pref=prefd,no_header=no_headerd)
  else ! usage of whole CLI
    if (no_headerd) then
      usaged = ''
    else
      usaged = prefd//self%help//self%progname//' '//self%signature()
      if (self%description/='') usaged = usaged//new_line('a')//new_line('a')//prefd//self%description
    endif
    if (self%clasg(0)%Na>0) usaged = usaged//new_line('a')//self%clasg(0)%usage(pref=prefd,no_header=.true.)
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
  if (allocated(self%examples).and.(.not.no_examplesd)) then
    usaged = usaged//new_line('a')//new_line('a')//prefd//'Examples:'
    do e=1, size(self%examples,dim=1)
      usaged = usaged//new_line('a')//prefd//'   '//trim(self%examples(e))
    enddo
  endif
  if (self%epilog/=''.and.(.not.no_epilogd)) usaged = usaged//new_line('a')//prefd//self%epilog
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction usage

  function signature(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get signature.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(in) :: self      !< CLI data.
  character(len=:), allocatable             :: signature !< Signature.
  integer(I4P)                              :: g         !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  signature = self%clasg(0)%signature()
  if (size(self%clasg,dim=1)>1) then
    signature = signature//' {'//self%clasg(1)%group
    do g=2,size(self%clasg,dim=1)-1
      signature = signature//','//self%clasg(g)%group
    enddo
    signature = signature//'} ...'
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction signature

  subroutine print_usage(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Print correct usage.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(in) :: self  !< CLI data.
  character(*), optional,        intent(in) :: pref  !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(self%usage_lun, '(A)') self%usage(pref=pref, g=0)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine print_usage

  subroutine save_man_page(self, man_file, error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Save man page build on the CLI.
  !---------------------------------------------------------------------------------------------------------------------------------
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call date_and_time(values=idate)
  man = '.TH '//self%progname//' "1" "'//month(idate(2))//' '//trim(adjustl(strz(4,idate(1))))//'" "version '//self%version//&
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
      man = man//new_line('a')//trim(self%examples(e))
    enddo
    man = man//new_line('a')//'.RE'
    man = man//new_line('a')//'.fi'
    man = man//new_line('a')//'.PP'
  endif
  if (self%authors /= '') man = man//new_line('a')//'.SH AUTHOR'//new_line('a')//self%authors
  if (self%license /= '') man = man//new_line('a')//'.SH COPYRIGHT'//new_line('a')//self%license
  open(newunit=u,file=trim(adjustl(man_file)))
  if (present(error)) then
    write(u, "(A)", iostat=error)man
  else
    write(u, "(A)")man
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine save_man_page

  ! private methods
  subroutine errored(self, error, pref, group, switch)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Trig error occurrence and print meaningful message.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(inout) :: self   !< Object data.
  integer(I4P),                  intent(in)    :: error  !< Error occurred.
  character(*), optional,        intent(in)    :: pref   !< Prefixing string.
  character(*), optional,        intent(in)    :: group  !< Group name.
  character(*), optional,        intent(in)    :: switch !< CLA switch name.
  character(len=:), allocatable                :: prefd  !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  self%error = error
  if (self%error/=0) then
    prefd = '' ; if (present(pref)) prefd = pref
    select case(self%error)
    case(ERROR_MISSING_CLA)
      self%error_message = prefd//self%progname//': error: there is no option "'//trim(adjustl(switch))//'"!'
    case(ERROR_MISSING_SELECTION_CLA)
      self%error_message = prefd//self%progname//&
        ': error: to get an option value one of switch "name" or "position" must be provided!'
    case(ERROR_MISSING_GROUP)
      self%error_message = prefd//self%progname//': error: ther is no group (command) named "'//trim(adjustl(group))//'"!'
    case(ERROR_TOO_FEW_CLAS)
      ! self%error_message = prefd//self%progname//': error: too few arguments ('//trim(str(.true.,Na))//')'//&
                         ! ' respect the required ('//trim(str(.true.,self%Na_required))//')'
    endselect
    write(self%error_lun,'(A)')
    call self%print_error_message
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine errored

  elemental subroutine cli_assign_cli(lhs, rhs)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Assignment operator.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_interface), intent(inout) :: lhs !< Left hand side.
  type(command_line_interface),  intent(in)    :: rhs !< Right hand side.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! object members
  call lhs%assign_object(rhs)
  ! command_line_interface members
  if (allocated(rhs%clasg   )) lhs%clasg      = rhs%clasg
  if (allocated(rhs%examples)) lhs%examples   = rhs%examples
                               lhs%disable_hv = rhs%disable_hv
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine cli_assign_cli

  elemental subroutine finalize(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory when finalizing.
  !---------------------------------------------------------------------------------------------------------------------------------
  type(command_line_interface), intent(inout) :: self !< CLI data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize
endmodule flap_command_line_interface_t

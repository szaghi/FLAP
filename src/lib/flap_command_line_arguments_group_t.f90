!< Command Line Arguments Group (CLAsG) class.
module flap_command_line_arguments_group_t
!< Command Line Arguments Group (CLAsG) class.

use face, only : colorize
use flap_command_line_argument_t, only : command_line_argument, &
                                         ACTION_PRINT_HELP,     &
                                         ACTION_SHOW_COMPLETION, ACTION_INSTALL_COMPLETION, &
                                         ACTION_PRINT_MARK,     &
                                         ACTION_PRINT_VERS,     &
                                         ACTION_APPEND,         &
                                         ACTION_COUNT,          &
                                         ACTION_STORE,          &
                                         ACTION_STORE_STAR,     &
                                         SOURCE_COMMANDLINE,    &
                                         SOURCE_CONFIG,         &
                                         SOURCE_DEFAULT,        &
                                         SOURCE_ENVIRONMENT,    &
                                         SOURCE_NONE
use flap_config_m, only : config_file
use flap_object_t, only : object
use flap_utils_m, only : fish_escape, flap_string, list_count, list_items, list_push, ps_escape, read_env, suggestions, &
                         tokenize, upper_case, write_text
use penf

implicit none
private
save
public :: command_line_arguments_group
public :: STATUS_PRINT_V
public :: STATUS_PRINT_H
public :: STATUS_PRINT_M
public :: STATUS_NO_ARGS
public :: STATUS_ALTERNATE
public :: STATUS_SHOW_COMPLETION
public :: STATUS_INSTALL_COMPLETION
public :: ERROR_CONSISTENCY
public :: ERROR_M_EXCLUDE
public :: ERROR_M_EXCLUDE_SET
public :: ERROR_M_EXCLUDE_SET_REQUIRED
public :: ERROR_M_EXCLUDE_SET_DEFINITION
public :: ERROR_POSITION_DUPLICATE
public :: ERROR_POSITION_GAP

type :: exclusive_set
  !< Mutually exclusive set of switches: at most one member may be passed, exactly one if required (F03 of #125).
  character(len=:), allocatable :: switches            !< Members, by their switch, as a stored list (LIST_SEP).
  logical                       :: is_required=.false. !< Exactly one member must be passed.
endtype exclusive_set

type, extends(object) :: command_line_arguments_group
  !< Command Line Arguments Group (CLAsG) class.
  !<
  !< CLAsG are useful for building nested commands.
  private
  character(len=:), allocatable,            public :: group             !< Group name (command).
  integer(I4P),                             public :: Na=0_I4P          !< Number of CLA.
  integer(I4P)                                     :: Na_required=0_I4P !< Number of required command line arguments.
  integer(I4P)                                     :: Na_optional=0_I4P !< Number of optional command line arguments.
  type(command_line_argument), allocatable, public :: cla(:)            !< CLA list [1:Na].
  logical,                                  public :: is_called=.false. !< Flag for checking if CLAs group has been passed to CLI.
  logical,                                  public :: no_args_is_help=.false. !< Print the help when invoked with no arguments.
  type(exclusive_set), allocatable                 :: m_sets(:)         !< Mutually exclusive sets of switches.
  character(len=:), allocatable,            public :: deprecated        !< Deprecation message of the command (F13).
  type(flap_string), allocatable,           public :: aliases(:)        !< Aliases of the command (F19), aliases(i)%s.
  contains
    ! public methods
    procedure, public :: free                  !< Free dynamic memory.
    procedure, public :: is_named              !< Check if a name is the name of the group (command) or an alias.
    procedure, public :: has_alias             !< Check if a name is an alias of the group (command).
    procedure, public :: names                 !< Name and aliases of the group (command), separated.
    procedure, public :: name_count            !< Number of names of the group (command): 1 + aliases.
    procedure, public :: has_examples          !< Check if the group (command) has examples.
    procedure, public :: completion_fish       !< Fish completion lines of the group (command) and its CLAs.
    procedure, public :: completion_powershell !< PowerShell completion tables of the group (command).
    procedure, public :: examples_text         !< Examples of the group (command), for its help.
    procedure, public :: name_of               !< Name (1) or alias (2, ...) of the group (command).
    procedure, public :: check                 !< Check data consistency.
    procedure, public :: check_position_gaps   !< Check that the declared positions have no gap.
    procedure, public :: is_required_passed    !< Check if required CLAs are passed.
    procedure, public :: add_exclusive_set     !< Add a mutually exclusive set of switches.
    procedure, public :: check_exclusive_sets  !< Check the mutually exclusive sets of switches.
    procedure, public :: check_maps            !< Check the KEY=VALUE pairs of the map CLAs.
    procedure, public :: is_passed             !< Check if a CLA has been passed.
    procedure, public :: is_defined            !< Check if a CLA has been defined.
    procedure, public :: is_switch_token       !< Check if a command line token names a CLA of the group.
    procedure, public :: is_action_passed      !< Check if a CLA with an action has been passed.
    procedure, public :: match_compact_count   !< Match the compact form -vvv of a count CLA.
    procedure, public :: positional_index      !< Index of the positional CLA declared at a position.
    procedure, public :: value_arity           !< Number of fixed value slots following a switch.
    procedure, public :: reset_parse           !< Forget the result of a parse, keeping the definitions.
    procedure, public :: resolve_values        !< Settle the source of the values not given on the command line.
    procedure, public :: config_key_index      !< Index of the CLA named by a configuration file key.
    procedure, public :: raise_error_m_exclude !< Raise error mutually exclusive CLAs passed.
    procedure, public :: add                   !< Add CLA to CLAsG.
    procedure, public :: parse                 !< Parse CLAsG arguments.
    procedure, public :: usage                 !< Get correct CLAsG usage.
    procedure, public :: signature             !< Get CLAsG signature.
    procedure, public :: sanitize_defaults     !< Sanitize default values.
    ! private methods
    procedure, private :: errored                             !< Trig error occurrence and print meaningful message.
    procedure, public  :: check_m_exclusive                   !< Check if two mutually exclusive CLAs have been passed.
    procedure, private :: exclusive_set_of                    !< Index of the mutually exclusive set of a CLA.
    procedure, private :: exclusive_set_signature             !< Usage signature of a mutually exclusive set.
    final              :: finalize                            !< Free dynamic memory when finalizing.
endtype command_line_arguments_group

! status codes
integer(I4P), parameter :: STATUS_PRINT_V = -1 !< Print version status.
integer(I4P), parameter :: STATUS_PRINT_H = -2 !< Print help status.
integer(I4P), parameter :: STATUS_PRINT_M = -3 !< Print help status to Markdown file.
integer(I4P), parameter :: STATUS_NO_ARGS = -5 !< No arguments passed, help printed (no_args_is_help).
integer(I4P), parameter :: STATUS_ALTERNATE = -4 !< An alternate action passed: value validation bypassed (F16).
integer(I4P), parameter :: STATUS_SHOW_COMPLETION = -6    !< --show-completion passed (F24).
integer(I4P), parameter :: STATUS_INSTALL_COMPLETION = -7 !< --install-completion passed (F24).

! errors codes
integer(I4P), parameter :: ERROR_CONSISTENCY = 100 !< CLAs group consistency error.
integer(I4P), parameter :: ERROR_M_EXCLUDE   = 101 !< Two mutually exclusive CLAs group have been called.
integer(I4P), parameter :: ERROR_M_EXCLUDE_SET            = 102 !< Two members of a mutually exclusive set have been passed.
integer(I4P), parameter :: ERROR_M_EXCLUDE_SET_REQUIRED   = 103 !< No member of a required mutually exclusive set passed.
integer(I4P), parameter :: ERROR_M_EXCLUDE_SET_DEFINITION = 104 !< Invalid definition of a mutually exclusive set.
integer(I4P), parameter :: ERROR_POSITION_DUPLICATE = 105 !< Two positional CLAs declared at the same position.
integer(I4P), parameter :: ERROR_POSITION_GAP       = 106 !< Declared positions are not 1..N: one is missing.

contains
  ! public methods
  elemental subroutine free(self)
  !< Free dynamic memory.
  class(command_line_arguments_group), intent(inout) :: self !< CLAsG data.

  ! object members
  call self%free_object
  ! command_line_arguments_group members
  if (allocated(self%group)) deallocate(self%group)
  if (allocated(self%cla)) then
    call self%cla%free
    deallocate(self%cla)
  endif
  self%Na          = 0_I4P
  self%Na_required = 0_I4P
  self%Na_optional = 0_I4P
  self%is_called   = .false.
  self%no_args_is_help = .false.
  if (allocated(self%m_sets)) deallocate(self%m_sets)
  if (allocated(self%deprecated)) deallocate(self%deprecated)
  if (allocated(self%aliases)) deallocate(self%aliases)
  endsubroutine free

  pure function is_named(self, name) result(named)
  !< Check if a name is the name of the group (command) or one of its aliases (F19 of #125). Trailing blanks are not
  !< significant; the case is, unless case_insensitive (F14).
  class(command_line_arguments_group), intent(in) :: self  !< CLAsG data.
  character(*),                        intent(in) :: name  !< Name.
  logical                                         :: named !< Check result.

  named = .false.
  if (.not.allocated(self%group)) return
  named = same(self%group, name, self%case_insensitive)
  if (.not.named) named = self%has_alias(name)
  endfunction is_named

  pure function has_alias(self, name) result(alias)
  !< Check if a name is an alias of the group (command) (F19 of #125), with the case rule of is_named.
  class(command_line_arguments_group), intent(in) :: self  !< CLAsG data.
  character(*),                        intent(in) :: name  !< Name.
  logical                                         :: alias !< Check result.
  integer(I4P)                                    :: i     !< Counter.

  alias = .false.
  if (.not.allocated(self%aliases)) return
  do i=1, size(self%aliases, dim=1)
    alias = same(self%aliases(i)%s, name, self%case_insensitive)
    if (alias) return
  enddo
  endfunction has_alias

  subroutine check_maps(self, pref)
  !< Check the KEY=VALUE pairs of the map CLAs (F18 of #125), whatever their source; the first error stops.
  class(command_line_arguments_group), intent(inout) :: self !< CLAsG data.
  character(*), optional,              intent(in)    :: pref !< Prefixing string.
  integer(I4P)                                       :: a    !< Counter.

  do a=1, self%Na
    if (.not.self%cla(a)%is_map) cycle
    call self%cla(a)%check_map(pref=pref)
    if (self%cla(a)%error /= 0) then
      self%error = self%cla(a)%error
      return
    endif
  enddo
  endsubroutine check_maps

  function completion_fish(self, prog, commands) result(lines)
  !< Get the fish completion lines of the group (F15 of #125): for a command, the line completing its names (while no
  !< command is typed) and its CLAs (once it is); for the top level, its CLAs (while no command is typed, if any).
  class(command_line_arguments_group), intent(in) :: self     !< CLAsG data.
  character(*),                        intent(in) :: prog     !< Program name.
  logical,                             intent(in) :: commands !< The CLI has commands.
  character(len=:), allocatable                   :: lines    !< Completion lines.
  character(len=:), allocatable                   :: head     !< Beginning of the lines of the CLAs.
  integer(I4P)                                    :: a        !< Counter.

  lines = ''
  if (self%group /= '') then
    lines = new_line('a')//"complete -c "//prog//" -n '__fish_use_subcommand' -f -a '"//fish_escape(self%names(' '))//&
            "' -d '"//fish_escape(trim(adjustl(self%description)))//"'"
    head = "complete -c "//prog//" -n '__fish_seen_subcommand_from "//fish_escape(self%names(' '))//"'"
  elseif (commands) then
    head = "complete -c "//prog//" -n '__fish_use_subcommand'"
  else
    head = "complete -c "//prog
  endif
  do a=1, self%Na
    lines = lines//self%cla(a)%completion_fish(head)
  enddo
  endfunction completion_fish

  function completion_powershell(self, commands) result(text)
  !< Get the PowerShell completion table rows of the group (F15 of #125): with commands, its names and aliases mapped to
  !< its name ('co' = 'compile'); otherwise its options, as the entry of the options table ('compile' = @(...)).
  class(command_line_arguments_group), intent(in) :: self     !< CLAsG data.
  logical,                             intent(in) :: commands !< Return the command rows instead of the options.
  character(len=:), allocatable                   :: text     !< Rows.
  integer(I4P)                                    :: a        !< Counter.
  integer(I4P)                                    :: i        !< Counter.

  text = ''
  if (commands) then
    do i=1, self%name_count()
      text = text//new_line('a')//"    '"//ps_escape(self%name_of(i))//"' = '"//ps_escape(self%group)//"'"
    enddo
  else
    text = new_line('a')//"    '"//ps_escape(self%group)//"' = @("
    do a=1, self%Na
      text = text//self%cla(a)%completion_powershell()
    enddo
    text = text//new_line('a')//'    )'
  endif
  endfunction completion_powershell

  pure function has_examples(self) result(has)
  !< Check if the group (command) has examples.
  class(command_line_arguments_group), intent(in) :: self !< CLAsG data.
  logical                                         :: has  !< Check result.

  has = allocated(self%examples)
  endfunction has_examples

  pure function examples_text(self, prefd) result(text)
  !< Return the examples of the group (command) for its help: a blank line, 'Examples:', one example per line.
  class(command_line_arguments_group), intent(in) :: self  !< CLAsG data.
  character(*),                        intent(in) :: prefd !< Prefixing string.
  character(len=:), allocatable                   :: text  !< Examples.
  integer(I4P)                                    :: e     !< Counter.

  text = new_line('a')//new_line('a')//prefd//'Examples:'
  if (.not.allocated(self%examples)) return
  do e=1, size(self%examples, dim=1)
    text = text//new_line('a')//prefd//'   '//trim(self%examples(e)%s)
  enddo
  endfunction examples_text

  pure function name_count(self) result(n)
  !< Return the number of names of the group (command): its name and its aliases (F19).
  class(command_line_arguments_group), intent(in) :: self !< CLAsG data.
  integer(I4P)                                    :: n    !< Number of names.

  n = 1
  if (allocated(self%aliases)) n = n + size(self%aliases, dim=1)
  endfunction name_count

  pure function name_of(self, i) result(name)
  !< Return the i-th name of the group (command): 1 its name, 2... its aliases (F19).
  class(command_line_arguments_group), intent(in) :: self !< CLAsG data.
  integer(I4P),                        intent(in) :: i    !< Index of the name.
  character(len=:), allocatable                   :: name !< Name.

  if (i == 1) then
    name = self%group
  else
    name = self%aliases(i-1)%s
  endif
  endfunction name_of

  pure function names(self, sep) result(list)
  !< Return the name of the group (command) followed by its aliases, separated by sep (help listing, completion).
  class(command_line_arguments_group), intent(in) :: self !< CLAsG data.
  character(*),                        intent(in) :: sep  !< Separator.
  character(len=:), allocatable                   :: list !< Name and aliases.
  integer(I4P)                                    :: i    !< Counter.

  list = self%group
  if (.not.allocated(self%aliases)) return
  do i=1, size(self%aliases, dim=1)
    list = list//sep//self%aliases(i)%s
  enddo
  endfunction names

  subroutine check(self, pref)
  !< Check data consistency.
  class(command_line_arguments_group), intent(inout) :: self  !< CLAsG data.
  character(*), optional,              intent(in)    :: pref  !< Prefixing string.
  integer(I4P)                                       :: a     !< Counter.
  integer(I4P)                                       :: aa    !< Counter.
  logical                                            :: clash !< Two CLAs have the same switch.

  ! verify if CLAs switches are unique
  clash = .false.
  CLA_unique: do a=1, self%Na
    if (.not.self%cla(a)%is_positional) then
      do aa=1, self%Na
        if ((a/=aa).and.(.not.self%cla(aa)%is_positional)) then
          clash = self%cla(aa)%match_token(self%cla(a)%switch).or.self%cla(aa)%match_token(self%cla(a)%switch_ab)
          if (allocated(self%cla(a)%switch_neg)) clash = clash.or.self%cla(aa)%match_token(self%cla(a)%switch_neg)
          if (clash) then
            call self%errored(pref=pref, error=ERROR_CONSISTENCY, a1=a, a2=aa)
            exit CLA_unique
          endif
        endif
      enddo
    endif
  enddo CLA_unique
  ! verify that positions are unique (B29 of #125, D20)
  POS_unique: do a=1, self%Na
    if (clash) exit POS_unique
    if (.not.self%cla(a)%is_positional) cycle
    do aa=a + 1, self%Na
      if (.not.self%cla(aa)%is_positional) cycle
      if (self%cla(aa)%position == self%cla(a)%position) then
        call self%errored(pref=pref, error=ERROR_POSITION_DUPLICATE, position=self%cla(a)%position)
        exit POS_unique
      endif
    enddo
  enddo POS_unique
  ! update mutually exclusive relations
  CLA_exclude: do a=1, self%Na
    if (.not.self%cla(a)%is_positional) then
      if (self%cla(a)%m_exclude/='') then
        if (self%is_defined(switch=self%cla(a)%m_exclude, pos=aa)) then
          self%cla(aa)%m_exclude = self%cla(a)%switch
        endif
      endif
    endif
  enddo CLA_exclude
  endsubroutine check

  subroutine check_position_gaps(self, pref)
  !< Check that the declared positions are 1..N without gaps (B29 of #125, D20).
  !<
  !< Checked when parsing starts, not in add: positionals may be declared in any order.
  class(command_line_arguments_group), intent(inout) :: self  !< CLAsG data.
  character(*), optional,              intent(in)    :: pref  !< Prefixing string.
  integer(I4P)                                       :: p     !< Position.
  integer(I4P)                                       :: pmax  !< Highest declared position.
  integer(I4P)                                       :: a     !< Counter.

  pmax = 0
  do a=1, self%Na
    if (self%cla(a)%is_positional) pmax = max(pmax, self%cla(a)%position)
  enddo
  do p=1, pmax
    if (self%positional_index(p) == 0) then
      call self%errored(pref=pref, error=ERROR_POSITION_GAP, position=p)
      return
    endif
  enddo
  endsubroutine check_position_gaps

  subroutine is_required_passed(self, pref)
  !< Check if required CLAs are passed.
  class(command_line_arguments_group), intent(inout) :: self  !< CLAsG data.
  character(*), optional,              intent(in)    :: pref  !< Prefixing string.
  integer(I4P)                                       :: a     !< Counter.

  if (self%is_called) then
    do a=1, self%Na
      if (.not.self%cla(a)%is_required_passed(pref=pref)) then
        self%error = self%cla(a)%error
        call write_text(self%usage_lun, self%usage(pref=pref))
        return
      endif
    enddo
  endif
  endsubroutine is_required_passed

  subroutine add_exclusive_set(self, switches, required, pref)
  !< Add a mutually exclusive set of switches (F03 of #125): at most one member may be passed, exactly one if required.
  !<
  !< The members are comma separated and must be already defined, named switches (by switch or abbreviation, stored by their
  !< switch), not individually required, distinct and in no other set. An invalid set is not added: the error is
  !< ERROR_M_EXCLUDE_SET_DEFINITION.
  class(command_line_arguments_group), intent(inout) :: self        !< CLAsG data.
  character(*),                        intent(in)    :: switches    !< Comma separated members.
  logical, optional,                   intent(in)    :: required    !< Exactly one member must be passed (default .false.).
  character(*), optional,              intent(in)    :: pref        !< Prefixing string.
  character(len=len_trim(switches)+1), allocatable   :: toks(:)     !< Members as given.
  type(exclusive_set)                                :: new_set     !< New set.
  type(exclusive_set), allocatable                   :: new_sets(:) !< New (extended) sets list.
  character(len=:), allocatable                      :: reason      !< Why the set is invalid.
  integer(I4P)                                       :: n           !< Number of members.
  integer(I4P)                                       :: t           !< Counter.
  integer(I4P)                                       :: tt          !< Counter.
  integer(I4P)                                       :: a           !< Index of the CLA of a member.
  integer(I4P)                                       :: aa          !< Index of the CLA of another member.

  ! tokenize ignores a delimiter in the last position: the added comma keeps a last empty member ('--a,--b,')
  call tokenize(strin=trim(switches)//',', delimiter=',', toks=toks, Nt=n)
  reason = ''
  new_set%switches = ''
  do t=1, n
    if (len_trim(toks(t)) == 0) then
      reason = 'a member is empty'
    elseif (.not.self%is_defined(switch=trim(adjustl(toks(t))), pos=a)) then
      reason = '"'//trim(adjustl(toks(t)))//'" is not defined'
    elseif (self%cla(a)%is_required) then
      reason = '"'//trim(adjustl(toks(t)))//'" is required'
    elseif (self%exclusive_set_of(a) > 0) then
      reason = '"'//trim(adjustl(toks(t)))//'" is already in a set'
    else
      do tt=1, t - 1
        if (self%is_defined(switch=trim(adjustl(toks(tt))), pos=aa)) then
          if (aa == a) reason = '"'//trim(adjustl(toks(t)))//'" is repeated'
        endif
      enddo
    endif
    if (reason /= '') exit
    call list_push(new_set%switches, trim(adjustl(self%cla(a)%switch)))
  enddo
  if (reason == '' .and. n < 2) reason = 'it needs at least two switches'
  if (reason /= '') then
    call self%errored(pref=pref, error=ERROR_M_EXCLUDE_SET_DEFINITION, members=trim(switches), reason=reason)
    return
  endif
  new_set%is_required = .false. ; if (present(required)) new_set%is_required = required
  if (allocated(self%m_sets)) then
    allocate(new_sets(1:size(self%m_sets, dim=1)+1))
    new_sets(1:size(self%m_sets, dim=1)) = self%m_sets
    new_sets(size(new_sets, dim=1)) = new_set
    call move_alloc(from=new_sets, to=self%m_sets)
  else
    self%m_sets = [new_set]
  endif
  endsubroutine add_exclusive_set

  subroutine check_exclusive_sets(self, pref)
  !< Check the mutually exclusive sets of a called group: at most one member given, exactly one for a required set.
  !<
  !< Explicit sources count (command line, environment, configuration file; D2, E3 of #125), a default does not. When a
  !< member is on the command line, the environment and configuration values of the other members fall back to their
  !< defaults first, so that a value set for a batch job never makes a command line alternative a violation. Called after
  !< the statuses (help, version, markdown) and the value resolution, like the required check (E4 of #125).
  class(command_line_arguments_group), intent(inout) :: self     !< CLAsG data.
  character(*), optional,              intent(in)    :: pref     !< Prefixing string.
  character(len=:), allocatable                      :: items(:) !< Members.
  character(len=:), allocatable                      :: given    !< Given members, quoted.
  integer(I4P)                                       :: n        !< Number of members.
  integer(I4P)                                       :: ng       !< Number of given members.
  integer(I4P)                                       :: s        !< Counter.
  integer(I4P)                                       :: i        !< Counter.
  integer(I4P)                                       :: a        !< CLA of a member.
  logical                                            :: cl       !< A member is on the command line.

  if (.not.self%is_called .or. .not.allocated(self%m_sets)) return
  do s=1, size(self%m_sets, dim=1)
    call list_items(self%m_sets(s)%switches, items, n)
    cl = .false.
    do i=1, n
      if (self%is_defined(switch=trim(items(i)), pos=a)) cl = cl .or. self%cla(a)%source == SOURCE_COMMANDLINE
    enddo
    given = ''
    ng = 0
    do i=1, n
      if (.not.self%is_defined(switch=trim(items(i)), pos=a)) cycle
      if (.not.self%cla(a)%has_value()) cycle
      if (cl .and. self%cla(a)%source /= SOURCE_COMMANDLINE) then
        ! the command line takes precedence: back to the default
        if (allocated(self%cla(a)%def)) then
          self%cla(a)%source = SOURCE_DEFAULT
        else
          self%cla(a)%source = SOURCE_NONE
        endif
        cycle
      endif
      ng = ng + 1
      given = given//', "'//trim(items(i))//'"'
    enddo
    if (ng > 1) then
      call self%errored(pref=pref, error=ERROR_M_EXCLUDE_SET, members=given(3:))
      return
    elseif (ng == 0 .and. self%m_sets(s)%is_required) then
      given = ''
      do i=1, n
        given = given//', "'//trim(items(i))//'"'
      enddo
      call self%errored(pref=pref, error=ERROR_M_EXCLUDE_SET_REQUIRED, members=given(3:))
      call write_text(self%usage_lun, self%usage(pref=pref))
      return
    endif
  enddo
  endsubroutine check_exclusive_sets

  pure function is_passed(self, switch, position)
  !< Check if a CLA has been passed.
  class(command_line_arguments_group), intent(in) :: self      !< CLAsG data.
  character(*), optional,              intent(in) :: switch    !< Switch name.
  integer(I4P), optional,              intent(in) :: position  !< Position of positional CLA.
  logical                                         :: is_passed !< Check if a CLA has been passed.
  integer(I4P)                                    :: a         !< CLA counter.

  is_passed = .false.
  if (self%Na>0) then
    if (present(switch)) then
      do a=1, self%Na
        if (self%cla(a)%match_token(switch)) then
          is_passed = self%cla(a)%is_passed
          exit
        endif
      enddo
    elseif (present(position)) then
      a = self%positional_index(position)
      if (a > 0) is_passed = self%cla(a)%is_passed
    endif
  endif
  endfunction is_passed

  pure function positional_index(self, position) result(a)
  !< Return the index of the positional CLA declared at a position, 0 if there is none.
  !<
  !< Positionals are looked up by their declared position, never by their index in the CLA list.
  class(command_line_arguments_group), intent(in) :: self     !< CLAsG data.
  integer(I4P),                        intent(in) :: position !< Position of the positional CLA.
  integer(I4P)                                    :: a        !< Index of the positional CLA, 0 if not defined.

  do a=1, self%Na
    if (self%cla(a)%is_positional) then
      if (self%cla(a)%position == position) return
    endif
  enddo
  a = 0
  endfunction positional_index

  subroutine reset_parse(self)
  !< Forget the result of a parse (called status, passed values, errors), keeping the definitions.
  class(command_line_arguments_group), intent(inout) :: self !< CLAsG data.
  integer(I4P)                                       :: a    !< Counter.

  self%is_called = .false.
  self%error = 0
  do a=1, self%Na
    self%cla(a)%is_passed = .false.
    if (allocated(self%cla(a)%val)) deallocate(self%cla(a)%val)
    self%cla(a)%error = 0
    self%cla(a)%source = SOURCE_NONE
    self%cla(a)%is_negated = .false.
    self%cla(a)%pair_passed = .false.
  enddo
  endsubroutine reset_parse

  subroutine resolve_values(self, ignore_env, config, check_paths, lenient)
  !< Settle the source of the values not given on the command line (the value-resolution chain R, F06 of #125).
  !<
  !< Called after all groups are parsed, before the required check. The source of a parsed value (command line, or the
  !< environment for a bare switch with envvar) is recorded while parsing, so that it survives a parse stopped by an error.
  !< The others take, in order, the environment variable if set and not blank (F07), the configuration file (section =
  !< group name, key = switch without dashes; F08) if the value is not blank, the default, or nothing.
  class(command_line_arguments_group), intent(inout) :: self       !< CLAsG data.
  logical, optional,                   intent(in)    :: ignore_env !< Turn every environment lookup off.
  type(config_file), optional,         intent(in)    :: config     !< Configuration file.
  logical, optional,                   intent(in)    :: check_paths !< Check the path values (F09).
  logical, optional,                   intent(in)    :: lenient    !< Ignore invalid environment lists (alternate, F16).
  character(len=:), allocatable                      :: envvar     !< Value of an environment variable.
  character(len=:), allocatable                      :: cvalue     !< Value from the configuration file.
  logical                                            :: found      !< The variable is set.
  integer(I4P)                                       :: a          !< Counter.

  do a=1, self%Na
    if (self%cla(a)%has_value()) cycle
    if (allocated(self%cla(a)%envvar).and.(.not.self%cla(a)%is_positional)) then
      call read_env(name=self%cla(a)%envvar, value=envvar, found=found, ignore=ignore_env)
      if (found.and.len_trim(envvar) > 0) then
        call self%cla(a)%set_source_value(value=envvar, source=SOURCE_ENVIRONMENT)
        if (self%cla(a)%error == 0) cycle
        if (.not.present(lenient)) then
          self%error = self%cla(a)%error
          return
        elseif (.not.lenient) then
          self%error = self%cla(a)%error
          return
        endif
        self%cla(a)%error = 0 ! lenient: the next sources
      endif
    endif
    if (present(config).and.self%cla(a)%takes_config_value()) then
      call config%lookup(section=self%group, key=self%cla(a)%config_key(), value=cvalue, found=found)
      if (found.and.len_trim(cvalue) > 0) then
        call self%cla(a)%set_source_value(value=cvalue, source=SOURCE_CONFIG)
        cycle
      endif
    endif
    if (allocated(self%cla(a)%def)) then
      self%cla(a)%source = SOURCE_DEFAULT
    else
      self%cla(a)%source = SOURCE_NONE
    endif
  enddo
  if (present(check_paths)) then
    if (check_paths) then
      do a=1, self%Na
        call self%cla(a)%check_paths
        if (self%cla(a)%error /= 0) then
          self%error = self%cla(a)%error
          return
        endif
      enddo
    endif
  endif
  endsubroutine resolve_values

  function config_key_index(self, key) result(a)
  !< Return the index of the CLA named by a configuration file key (its switch without dashes), 0 if none.
  class(command_line_arguments_group), intent(in) :: self !< CLAsG data.
  character(*),                        intent(in) :: key  !< Key.
  integer(I4P)                                    :: a    !< Index of the CLA.

  do a=1, self%Na
    if (self%cla(a)%is_positional) cycle
    if (self%cla(a)%config_key() == key) return
  enddo
  a = 0
  endfunction config_key_index

  function value_arity(self, switch) result(n)
  !< Return the number of values that always follow a switch of this group, 0 if not fixed or not a switch.
  !<
  !< Fixed: `store` with a required value (1) or with an integer `nargs` (N). Not fixed: flags, optional values, environment
  !< variables and variadic lists (`nargs='+'/'*'`), whose extent is decided while parsing.
  class(command_line_arguments_group), intent(in) :: self   !< CLAsG data.
  character(*),                        intent(in) :: switch !< Command line argument, maybe a switch.
  integer(I4P)                                    :: n      !< Number of fixed value slots.
  integer(I4P)                                    :: a      !< Counter.
  integer(I4P)                                    :: iostat !< Conversion status.

  n = 0
  do a=1, self%Na
    if (.not.self%cla(a)%match_token(switch)) cycle
    if (self%cla(a)%act == action_append) then
      n = 1 ! one value per occurrence
      return
    endif
    if (self%cla(a)%act /= action_store) return
    if (allocated(self%cla(a)%nargs)) then
      read(self%cla(a)%nargs, *, iostat=iostat) n
      if (iostat /= 0) n = 0 ! '+' or '*'
    elseif (self%cla(a)%is_val_required.and.(.not.allocated(self%cla(a)%envvar))) then
      n = 1
    endif
    return
  enddo
  endfunction value_arity

  function is_defined(self, switch, pos)
  !< Check if a CLA has been defined.
  class(command_line_arguments_group), intent(in)  :: self       !< CLAsG data.
  character(*),                        intent(in)  :: switch     !< Switch name.
  integer(I4P), optional,              intent(out) :: pos        !< CLA position.
  logical                                          :: is_defined !< Check if a CLA has been defined.
  integer(I4P)                                     :: a          !< CLA counter.

  is_defined = .false.
  if (present(pos)) pos = 0
  if (self%Na>0) then
    do a=1, self%Na
      if (self%cla(a)%match_token(switch)) then
        is_defined = .true.
        if (present(pos)) pos = a
        exit
      endif
    enddo
  endif
  endfunction is_defined

  pure subroutine match_compact_count(self, token, a, n)
  !< Match the compact form of a count, -vvv (D1 rule 3): a dash and one letter repeated, the letter forming the switch_ab
  !< -v of a count CLA. The caller uses it only when no switch matches the whole token (an exact switch wins).
  class(command_line_arguments_group), intent(in)  :: self  !< CLAsG data.
  character(*),                        intent(in)  :: token !< Command line token.
  integer(I4P),                        intent(out) :: a     !< Index of the count CLA, 0 if no match.
  integer(I4P),                        intent(out) :: n     !< Occurrences (repetitions of the letter).
  integer(I4P)                                     :: c     !< Counter.
  integer(I4P)                                     :: l     !< Length of the token.
  character(len=:), allocatable                    :: t     !< Token without blanks around.

  a = 0
  n = 0
  t = trim(adjustl(token))
  l = len(t)
  if (l < 3) return
  if (t(1:1) /= '-' .or. t(2:2) == '-') return
  do c=3, l
    if (t(c:c) /= t(2:2)) return
  enddo
  do c=1, self%Na
    if (.not.allocated(self%cla(c)%act)) cycle
    if (self%cla(c)%act /= ACTION_COUNT) cycle
    if (.not.allocated(self%cla(c)%switch_ab)) cycle
    if (trim(adjustl(self%cla(c)%switch_ab)) == t(1:2)) then
      a = c
      n = l - 1
      return
    endif
  enddo
  endsubroutine match_compact_count

  pure function is_action_passed(self, act) result(passed)
  !< Check if a CLA with an action (e.g. print help) has been passed.
  class(command_line_arguments_group), intent(in) :: self   !< CLAsG data.
  character(*),                        intent(in) :: act    !< Action.
  logical                                         :: passed !< Check result.
  integer(I4P)                                    :: a      !< CLA counter.

  passed = .false.
  do a=1, self%Na
    if (self%cla(a)%is_passed .and. allocated(self%cla(a)%act)) then
      if (self%cla(a)%act == act) then
        passed = .true.
        return
      endif
    endif
  enddo
  endfunction is_action_passed

  pure function is_switch_token(self, token)
  !< Check if a command line token names a CLA of the group, also as NAME=VALUE: the look-ahead test of the parser.
  class(command_line_arguments_group), intent(in) :: self            !< CLAsG data.
  character(*),                        intent(in) :: token           !< Command line token.
  logical                                         :: is_switch_token !< Check result.
  integer(I4P)                                    :: a               !< CLA counter.
  character(len=:), allocatable                   :: inline_val      !< Inline value, if any.
  logical                                         :: has_inline      !< The token is NAME=VALUE.
  logical                                         :: match           !< The token names the CLA.
  integer(I4P)                                    :: n               !< Occurrences of a compact count.

  is_switch_token = .false.
  call self%match_compact_count(token, a, n)
  if (a > 0) then
    is_switch_token = .true.
    return
  endif
  do a=1, self%Na
    call self%cla(a)%match_inline_token(token, match, inline_val, has_inline)
    if (match) then
      is_switch_token = .true.
      return
    endif
  enddo
  endfunction is_switch_token

  subroutine raise_error_m_exclude(self, pref)
  !< Raise error mutually exclusive CLAs passed.
  class(command_line_arguments_group), intent(inout) :: self !< CLA data.
  character(*), optional,              intent(in)    :: pref !< Prefixing string.

  call self%errored(pref=pref, error=ERROR_M_EXCLUDE)
  endsubroutine raise_error_m_exclude

  subroutine add(self, pref, cla)
  !< Add CLA to CLAs list.
  !<
  !< @note If not otherwise declared the action on CLA value is set to "store" a value that must be passed after the switch name
  !< or directly passed in case of positional CLA.
  class(command_line_arguments_group), intent(inout) :: self            !< CLAsG data.
  character(*), optional,              intent(in)    :: pref            !< Prefixing string.
  type(command_line_argument),         intent(in)    :: cla             !< CLA data.
  type(command_line_argument), allocatable           :: cla_list_new(:) !< New (extended) CLA list.
  integer(I4P)                                       :: c               !< Counter.
  integer(I4P)                                       :: p               !< Insertion index of a positional CLA.

  if (self%Na>0_I4P) then
    if (.not.cla%is_positional) then
      allocate(cla_list_new(1:self%Na+1))
      do c=1, self%Na
        cla_list_new(c) = self%cla(c)
      enddo
      cla_list_new(self%Na+1) = cla
    else
      ! keep positionals near their position in the list (it orders the usage), without overrunning it: lookups use the
      ! declared position (positional_index), not the list index
      p = max(1_I4P, min(cla%position, self%Na + 1))
      allocate(cla_list_new(1:self%Na+1))
      do c=1, p - 1
        cla_list_new(c) = self%cla(c)
      enddo
      cla_list_new(p) = cla
      do c=p + 1, self%Na + 1
        cla_list_new(c) = self%cla(c-1)
      enddo
    endif
  else
    allocate(cla_list_new(1:1))
    cla_list_new(1)=cla
  endif
  call move_alloc(from=cla_list_new, to=self%cla)
  self%Na = self%Na + 1
  if (cla%is_required) then
    self%Na_required = self%Na_required + 1
  else
    self%Na_optional = self%Na_optional + 1
  endif
  if (allocated(cla_list_new)) deallocate(cla_list_new)
  call self%check(pref=pref)
  endsubroutine add

  subroutine parse(self, args, ignore_unknown_clas, pref, error_unknown_clas, ignore_env, commands)
  !< Parse CLAsG arguments.
  class(command_line_arguments_group), intent(inout) :: self                !< CLAsG data.
  character(*),                        intent(in)    :: args(:)             !< Command line arguments.
  logical,                             intent(in)    :: ignore_unknown_clas !< Disable errors-raising for passed unknown CLAs.
  character(*), optional,              intent(in)    :: pref                !< Prefixing string.
  integer(I4P),                        intent(out)   :: error_unknown_clas  !< Error flag for passed unknown CLAs.
  logical,      optional,              intent(in)    :: ignore_env          !< Turn every environment lookup off.
  type(flap_string), optional,         intent(in)    :: commands(:)         !< Command names and aliases (top level), for the
                                                                            !< suggestions of an unknown argument (F10).
  type(command_line_argument)                        :: cla                 !< CLA data.
  character(:), allocatable                          :: envvar              !< Value of an environment variable.
  integer(I4P)                                       :: arg                 !< Argument counter.
  integer(I4P)                                       :: a                   !< Counter.
  integer(I4P)                                       :: aa                  !< Counter.
  integer(I4P)                                       :: aaa                 !< Counter.
  integer(I4P)                                       :: nargs               !< Number of arguments consumed by a CLA.
  logical                                            :: found               !< Flag for checking if switch is a defined CLA.
  logical                                            :: found_val           !< Flag for checking if switch value is found.
  integer(I4P)                                       :: ipos                !< Positional cursor: positionals consumed so far.
  character(len=:), allocatable                      :: inline_val          !< Inline value of NAME=VALUE.
  logical                                            :: has_inline          !< The argument is NAME=VALUE.
  logical                                            :: match               !< The argument names the CLA.
  logical                                            :: first               !< First occurrence of the CLA.
  logical                                            :: negated             !< The argument is the negation of a flag.
  integer(I4P)                                       :: n                   !< Occurrences of a compact count.

  error_unknown_clas = 0
  if (self%is_called) then
     call self%sanitize_defaults
     ipos = 0
     arg = 0
     do while (arg < size(args, dim=1)) ! loop over CLAs group arguments passed
        arg = arg + 1
        found = .false.
        do a=1, self%Na ! loop over CLAs group clas named options
           if (.not.self%cla(a)%is_positional) then
              call self%cla(a)%match_inline_token(args(arg), match, inline_val, has_inline)
              if (match) then
                 first = .not.self%cla(a)%is_passed
                 negated = self%cla(a)%match_negation(args(arg))
                 if (self%cla(a)%is_passed.and.(.not.self%cla(a)%is_repeatable()).and. &
                     (.not.self%cla(a)%is_pair_override(negated))) then
                    ! current CLA has been already passed: raise the error on it and stop parsing
                    call self%cla(a)%raise_error_duplicated_clas(pref=pref, switch=trim(adjustl(args(arg))))
                    self%error = self%cla(a)%error
                    return
                 else
                    ! a flag pair (F11): the last spelling wins (D5), each spelling once
                    if (self%cla(a)%is_passed.and.allocated(self%cla(a)%switch_neg)) self%cla(a)%pair_passed = .true.
                    self%cla(a)%is_negated = negated
                    self%cla(a)%is_passed = .true.
                    self%cla(a)%source = SOURCE_COMMANDLINE
                    found = .true.
                 endif
                 found_val = .false.

                 ! check action
                 if (has_inline) then
                    ! NAME=VALUE (D1 rule 2): the value is inline, the next argument is not consumed
                    call self%cla(a)%set_inline_value(value=inline_val, pref=pref, first=first)
                    if (self%cla(a)%error/=0) then
                       self%error = self%cla(a)%error
                       return
                    endif
                 elseif (self%cla(a)%act==action_store) then
                    ! flush default (if any) to value as starting point
                    if (allocated(self%cla(a)%def)) self%cla(a)%val = self%cla(a)%def

                    ! search for actual passed value if passed/required

                    ! check for envvar: the bare switch reads it, lists excepted (their values follow nargs)
                    if (allocated(self%cla(a)%envvar).and.(.not.allocated(self%cla(a)%nargs))) then
                       ! verify if the value has been passed directly to cli
                       if (arg + 1 <= size(args,dim=1)) then
                          ! there are still other arguments to check
                          if (.not.self%is_switch_token(args(arg+1))) then
                             ! argument seems good...
                             arg = arg + 1
                             self%cla(a)%val = trim(adjustl(args(arg)))
                             found_val = .true.
                          endif
                       endif
                       if (.not.found_val) then
                          ! value not found, try to take val from environment
                          call read_env(name=self%cla(a)%envvar, value=envvar, found=found_val, ignore=ignore_env)
                          if (found_val) then
                             self%cla(a)%val = trim(adjustl(envvar))
                             self%cla(a)%source = SOURCE_ENVIRONMENT
                          else
                             ! no found, raise value missing error
                             call self%cla(a)%raise_error_value_missing(pref=pref)
                             self%error = self%cla(a)%error
                             return
                          endif
                       endif

                    ! check for multiple argument values
                    elseif (allocated(self%cla(a)%nargs)) then
                       select case(self%cla(a)%nargs)
                       case('+')
                          aaa = n_next_undef_args(args=args, arg=arg)
                          if (aaa>=arg+1) then
                             self%cla(a)%val = ''
                             do aa=arg + 1, aaa
                                call list_push(self%cla(a)%val, trim(adjustl(args(aa))))
                                found_val = .true.
                             enddo
                             arg = aaa
                          elseif (self%cla(a)%is_val_required) then
                             call self%cla(a)%raise_error_nargs_insufficient(pref=pref)
                             self%error = self%cla(a)%error
                             return
                          endif
                       case('*')
                          ! the values that follow; none is an empty list, the default applies only when absent (D21)
                          aaa = n_next_undef_args(args=args, arg=arg)
                          self%cla(a)%val = ''
                          if (aaa>=arg+1) then
                             do aa=arg + 1, aaa
                                call list_push(self%cla(a)%val, trim(adjustl(args(aa))))
                                found_val = .true.
                             enddo
                             arg = aaa
                          endif
                       case default
                          nargs = cton(str=trim(adjustl(self%cla(a)%nargs)), knd=1_I4P)
                          ! take nargs values when at least nargs follow: further values are the next arguments (B19)
                          if (n_next_undef_args(args=args, arg=arg) >= arg + nargs) then
                             self%cla(a)%val = ''
                             do aa=arg + 1, arg + nargs
                                call list_push(self%cla(a)%val, trim(adjustl(args(aa))))
                             enddo
                             found_val = .true.
                             arg = arg + nargs
                          elseif (self%cla(a)%is_val_required) then
                             call self%cla(a)%raise_error_nargs_insufficient(pref=pref)
                             self%error = self%cla(a)%error
                             return
                          endif
                       endselect

                    ! check for single argument value
                    else
                       if (self%cla(a)%is_val_required) then
                          ! value is required
                          if (arg+1>size(args)) then
                             ! no more arguments remaining, raise value missing error
                             call self%cla(a)%raise_error_value_missing(pref=pref)
                             self%error = self%cla(a)%error
                             return
                          elseif (self%is_switch_token(args(arg+1))) then
                             ! the next argument is a CLA switch, raise value missing error
                             call self%cla(a)%raise_error_value_missing(pref=pref)
                             self%error = self%cla(a)%error
                             return
                          else
                             ! value found: an explicitly empty argument is the empty string (D17 of #125, reversed in 2.11)
                             arg = arg + 1
                             self%cla(a)%val = trim(adjustl(args(arg)))
                             found_val = .true.
                          endif
                       else
                          ! value is not required, check if it is passed
                          if (arg + 1 <= size(args, dim=1)) then
                             ! there are arguments to check
                             if (.not.self%is_switch_token(args(arg+1))) then
                                ! value found
                                arg = arg + 1
                                self%cla(a)%val = trim(adjustl(args(arg)))
                                found_val = .true.
                             endif
                          endif
                       endif
                    endif

                 elseif (self%cla(a)%act==action_store_star.or.self%cla(a)%act==ACTION_SHOW_COMPLETION.or. &
                         self%cla(a)%act==ACTION_INSTALL_COMPLETION) then
                    ! an optional value (the shell of the completion builtins, F24)
                    if (arg + 1 <= size(args, dim=1)) then ! verify if the value has been passed directly to cli
                       ! there are still other arguments to check
                       if (.not.self%is_switch_token(args(arg+1))) then
                          ! arguments seem good...
                          arg = arg + 1
                          self%cla(a)%val = trim(adjustl(args(arg)))
                          found = .true.
                          found_val = .true.
                       endif
                    endif
                    if (.not.found) then
                       ! flush default to val if default is set
                       if (allocated(self%cla(a)%def)) self%cla(a)%val = self%cla(a)%def
                    endif
                 elseif (self%cla(a)%act==action_count) then
                    call self%cla(a)%count_occurrences(n=1_I4P, first=first)
                 elseif (self%cla(a)%act==action_append) then
                    ! one value per occurrence, as for a store with a required value
                    if (arg+1>size(args)) then
                       call self%cla(a)%raise_error_value_missing(pref=pref)
                    elseif (self%is_switch_token(args(arg+1))) then
                       call self%cla(a)%raise_error_value_missing(pref=pref)
                    else
                       arg = arg + 1
                       call self%cla(a)%append_value(value=args(arg), first=first, pref=pref)
                    endif
                    if (self%cla(a)%error/=0) then
                       self%error = self%cla(a)%error
                       return
                    endif
                 elseif (self%cla(a)%act==action_print_help) then
                    self%error = STATUS_PRINT_H
                 elseif (self%cla(a)%act==action_print_mark) then
                    self%error = STATUS_PRINT_M
                 elseif (self%cla(a)%act==action_print_vers) then
                    self%error = STATUS_PRINT_V
                 endif

                 self%cla(a)%is_passed = .true.
                 found = .true.
                 exit
              endif
           endif
        enddo
        if (.not.found) then ! current argument (arg-th) does not correspond to a named option
           ! the compact form of a count, -vvv (D1 rule 3): only when no switch matches the whole argument
           call self%match_compact_count(args(arg), a, n)
           if (a > 0) then
              first = .not.self%cla(a)%is_passed
              self%cla(a)%is_passed = .true.
              self%cla(a)%source = SOURCE_COMMANDLINE
              call self%cla(a)%count_occurrences(n=n, first=first)
              cycle
           endif
           ! the n-th such argument is the value of the positional CLA declared at position n (positional cursor)
           a = 0
           if (.not.is_switch_like(trim(adjustl(args(arg))))) then
              ipos = ipos + 1
              a = self%positional_index(ipos)
           endif
           if (a > 0) then
              ! positional CLA always stores a value
              self%cla(a)%val = trim(adjustl(args(arg)))
              self%cla(a)%is_passed = .true.
              self%cla(a)%source = SOURCE_COMMANDLINE
           else
              ! neither a named option nor a further positional: unknown argument, reported on a scratch CLA
              call cla%assign_object(self)
              call cla%raise_error_switch_unknown(pref=pref, switch=trim(adjustl(args(arg))), hint=hint(args(arg)))
              self%error = cla%error
              error_unknown_clas = self%error
              if (.not.ignore_unknown_clas) return
           endif
        endif
     enddo
  endif
  contains
     pure function hint(token)
     !< "Did you mean" hint of an unknown argument (F10): the switch names of the group for a switch (the name before an
     !< inline '='), the command names for another argument.
     character(*), intent(in)       :: token !< Unknown argument.
     character(len=:), allocatable  :: hint  !< Hint.
     type(flap_string), allocatable :: names(:) !< Candidates.
     type(flap_string), allocatable :: cnames(:) !< Names of a CLA.
     character(len=:), allocatable  :: name  !< Name of the argument.
     integer(I4P)                   :: c     !< Counter.
     integer(I4P)                   :: i     !< Counter.
     integer(I4P)                   :: n     !< Number of candidates.

     name = trim(adjustl(token))
     if (is_switch_like(name)) then
       c = index(name, '=')
       if (c > 1) name = name(:c-1)
       ! sized first, filled by element: no array constructor growing an array of flap_string (gfortran 16 trunk crashes)
       n = 0
       do c=1, self%Na
         cnames = self%cla(c)%names()
         n = n + size(cnames, dim=1)
       enddo
       allocate(names(n))
       n = 0
       do c=1, self%Na
         cnames = self%cla(c)%names()
         do i=1, size(cnames, dim=1)
           n = n + 1
           names(n)%s = cnames(i)%s
         enddo
       enddo
     elseif (present(commands)) then
       names = commands
     else
       allocate(names(0))
     endif
     hint = suggestions(name, names, self%case_insensitive)
     endfunction hint

     pure function is_switch_like(token)
     !< Return true if an argument looks like a switch: a dash followed by anything but a digit or a dot.
     !<
     !< Such an argument is never taken as a positional value (so "-3.5" and "-" are values, "--bogus" is not).
     character(*), intent(in) :: token          !< Argument.
     logical                  :: is_switch_like !< Check result.

     is_switch_like = .false.
     if (len(token) >= 2) is_switch_like = token(1:1) == '-' .and. index('0123456789.', token(2:2)) == 0
     endfunction is_switch_like

     function n_next_undef_args(args, arg)
     !< Return the number of the next undefined (not named switch) arguments.
     character(*), intent(in) :: args(:)           !< Command line arguments.
     integer(I4P), intent(in) :: arg               !< Current argument number.
     integer(I4P)             :: n_next_undef_args !< Number of the next undefined (not named switch) arguments.
     integer(I4P)             :: i                 !< Counter.

     n_next_undef_args = 0
     do i=arg + 1, size(args,dim=1)
        if (.not.self%is_switch_token(args(i))) then
           n_next_undef_args = i
        else
           exit
        endif
     enddo
     endfunction n_next_undef_args
  endsubroutine parse

  function usage(self, pref, no_header, markdown)
  !< Get correct CLAsG usage.
  class(command_line_arguments_group), intent(in) :: self      !< CLAsG data.
  character(*), optional,              intent(in) :: pref      !< Prefixing string.
  logical,      optional,              intent(in) :: no_header !< Avoid insert header to usage.
  logical,      optional,              intent(in) :: markdown  !< Format things form markdown.
  character(len=:), allocatable                   :: usage     !< Usage string.
  integer(I4P)                                    :: a         !< Counters.
  character(len=:), allocatable                   :: prefd     !< Prefixing string.
  logical                                         :: markdownd !< Markdonw format, local variable.

  markdownd = .false. ; if (present(markdown)) markdownd = markdown
  prefd = '' ; if (present(pref)) prefd = pref
  usage = self%progname ; if (self%group/='') usage = self%progname//' '//self%group
  usage = prefd//self%help//' '//usage//self%signature()
  if (self%description/='') usage = usage//new_line('a')//new_line('a')//prefd//self%description
  if (present(no_header)) then
    if (no_header) usage = ''
  endif
  if (self%Na_required>0) then
    usage = usage//new_line('a')//new_line('a')//prefd//'Required switches:'
    if(markdownd)usage = usage//'  '
    do a=1, self%Na
      if (self%cla(a)%is_required.and.(.not.self%cla(a)%is_hidden)) usage = usage//new_line('a')//&
        self%cla(a)%usage(pref=prefd,markdown=markdownd)
    enddo
  endif
  if (self%Na_optional>0) then
    usage = usage//new_line('a')//new_line('a')//prefd//'Optional switches:'
    if(markdownd)usage = usage//'  '
    do a=1, self%Na
      if (.not.self%cla(a)%is_required.and.(.not.self%cla(a)%is_hidden)) usage = usage//new_line('a')//&
        self%cla(a)%usage(pref=prefd,markdown=markdownd)
    enddo
  endif
  endfunction usage

  function signature(self, bash_completion, plain)
  !< Get CLAsG signature: the usage text, or the bash completion (a COMPREPLY line with the switches, then the value tests).
  class(command_line_arguments_group), intent(in) :: self             !< CLAsG data.
  logical, optional,                   intent(in) :: bash_completion  !< Return the signature for bash completion.
  logical, optional,                   intent(in) :: plain            !< Return the value tests as plain switches lists.
  logical                                         :: bash_completion_ !< Return the signature for bash completion, local variable.
  logical                                         :: plain_           !< Return the signature as plain switches list, local var.
  character(len=:), allocatable                   :: signature        !< Signature.
  integer(I4P)                                    :: a                !< Counter.
  integer(I4P)                                    :: s                !< Index of a mutually exclusive set.

  signature = ''
  bash_completion_ = .false. ; if (present(bash_completion)) bash_completion_ = bash_completion
  plain_ = .false. ; if (present(plain)) plain_ = plain
  if (bash_completion_) then
    do a=1, self%Na
      signature = signature//self%cla(a)%completion_words()
    enddo
    signature = new_line('a')//'    COMPREPLY=( $( compgen -W "'//signature//'" -- $cur ) )'
    do a=1, self%Na
      if (plain_) then
        signature = signature//self%cla(a)%completion_words()
      else
        signature = signature//self%cla(a)%completion_values()
      endif
    enddo
  else
    do a=1, self%Na
      s = self%exclusive_set_of(a)
      if (s == 0) then
        signature = signature//self%cla(a)%signature_usage()
      elseif (a == first_member(s)) then
        ! a set is rendered once, where its first member is
        signature = signature//self%exclusive_set_signature(s)
      endif
    enddo
  endif
  contains
    function first_member(s) result(first)
    !< Return the index of the first CLA (in the list) of a set.
    integer(I4P), intent(in) :: s     !< Index of the set.
    integer(I4P)             :: first !< Index of its first CLA.

    do first=1, self%Na
      if (self%exclusive_set_of(first) == s) return
    enddo
    endfunction first_member
  endfunction signature

  ! private methods
  subroutine errored(self, error, pref, a1, a2, position, members, reason)
  !< Trig error occurrence and print meaningful message.
  class(command_line_arguments_group), intent(inout) :: self     !< CLAsG data.
  integer(I4P),                        intent(in)    :: error    !< Error occurred.
  character(*), optional,              intent(in)    :: pref     !< Prefixing string.
  integer(I4P), optional,              intent(in)    :: a1       !< First index CLAs group inconsistent.
  integer(I4P), optional,              intent(in)    :: a2       !< Second index CLAs group inconsistent.
  integer(I4P), optional,              intent(in)    :: position !< Position of positional CLAs.
  character(*), optional,              intent(in)    :: members  !< Members of a mutually exclusive set.
  character(*), optional,              intent(in)    :: reason   !< Why a mutually exclusive set is invalid.
  character(len=:), allocatable                      :: prefd    !< Prefixing string.
  character(len=:), allocatable                      :: where    !< Group (command) of the error, if any.

  self%error = error
  if (self%error/=0) then
    prefd = self%error_prefix(pref=pref)
    select case(self%error)
    case(ERROR_CONSISTENCY)
      if (self%group /= '') then
        self%error_message = prefd//': group (command) name: "'//self%group//'" consistency error:'
      else
        self%error_message = prefd//': consistency error:'
      endif
      self%error_message = self%error_message//' "'//trim(str(a1, .true.))//             &
                           '-th" option has the same switch or abbreviated switch of "'//&
                           trim(str(a2, .true.))//'-th" option:'//new_line('a')
      self%error_message = self%error_message//prefd//' CLA('//trim(str(a1, .true.)) //') switches = '//self%cla(a1)%switch //' '//&
                           self%cla(a1)%switch_ab//new_line('a')
      self%error_message = self%error_message//prefd//' CLA('//trim(str(a2, .true.))//') switches = '//self%cla(a2)%switch//' '//&
                           self%cla(a2)%switch_ab
    case(ERROR_M_EXCLUDE)
      self%error_message = prefd//': the group "'//self%group//'" and "'//self%m_exclude//'" are mutually'//&
                           ' exclusive, but both have been called!'
    case(ERROR_POSITION_DUPLICATE)
      where = '' ; if (self%group /= '') where = ' of group (command) "'//self%group//'"'
      self%error_message = prefd//': position '//trim(str(position, .true.))//' is declared by two positional options'//&
                           where//'!'
    case(ERROR_POSITION_GAP)
      where = '' ; if (self%group /= '') where = ' of group (command) "'//self%group//'"'
      self%error_message = prefd//': no positional option'//where//' is declared at position '//&
                           trim(str(position, .true.))//', but higher positions are!'
    case(ERROR_M_EXCLUDE_SET)
      where = '' ; if (self%group /= '') where = ' in group (command) "'//self%group//'"'
      self%error_message = prefd//': switches '//members//' are mutually exclusive'//where//'!'
    case(ERROR_M_EXCLUDE_SET_REQUIRED)
      where = '' ; if (self%group /= '') where = ' in group (command) "'//self%group//'"'
      self%error_message = prefd//': one of '//members//' is required'//where//'!'
    case(ERROR_M_EXCLUDE_SET_DEFINITION)
      where = '' ; if (self%group /= '') where = ' of group (command) "'//self%group//'"'
      self%error_message = prefd//': invalid mutually exclusive set "'//members//'"'//where//': '//reason//'!'
    endselect
    call self%print_error_message
  endif
  endsubroutine errored

  subroutine check_m_exclusive(self, pref)
  !< Check if two mutually exclusive CLAs have been passed.
  class(command_line_arguments_group), intent(inout) :: self !< CLAsG data.
  character(*), optional,              intent(in)    :: pref !< Prefixing string.
  integer(I4P)                                       :: a    !< Counter.

  if (self%is_called) then
    do a=1, self%Na
      if (self%cla(a)%is_passed) then
        if (self%cla(a)%m_exclude/='') then
          if (self%is_passed(switch=self%cla(a)%m_exclude)) then
            call self%cla(a)%raise_error_m_exclude(pref=pref)
            self%error = self%cla(a)%error
            return
          endif
        endif
      endif
    enddo
  endif
  endsubroutine check_m_exclusive

  pure function exclusive_set_of(self, a) result(s)
  !< Return the index of the mutually exclusive set of a CLA, 0 if it is in none.
  class(command_line_arguments_group), intent(in) :: self     !< CLAsG data.
  integer(I4P),                        intent(in) :: a        !< Index of the CLA.
  integer(I4P)                                    :: s        !< Index of the set.
  character(len=:), allocatable                   :: items(:) !< Members.
  integer(I4P)                                    :: n        !< Number of members.
  integer(I4P)                                    :: i        !< Counter.

  if (allocated(self%m_sets)) then
    do s=1, size(self%m_sets, dim=1)
      call list_items(self%m_sets(s)%switches, items, n)
      do i=1, n
        if (self%cla(a)%match_token(trim(items(i)))) return
      enddo
    enddo
  endif
  s = 0
  endfunction exclusive_set_of

  function exclusive_set_signature(self, s) result(signature)
  !< Return the usage signature of a mutually exclusive set, docopt style: (a | b) if required, [a | b] otherwise.
  class(command_line_arguments_group), intent(in) :: self      !< CLAsG data.
  integer(I4P),                        intent(in) :: s         !< Index of the set.
  character(len=:), allocatable                   :: signature !< Signature.
  character(len=:), allocatable                   :: items(:)  !< Members.
  character(len=:), allocatable                   :: member    !< Signature of a member.
  integer(I4P)                                    :: n         !< Number of members.
  integer(I4P)                                    :: i         !< Counter.
  integer(I4P)                                    :: a         !< Index of the CLA of a member.

  signature = ''
  call list_items(self%m_sets(s)%switches, items, n)
  do i=1, n
    if (.not.self%is_defined(switch=trim(items(i)), pos=a)) cycle
    member = trim(adjustl(self%cla(a)%signature_usage(bare=.true.)))
    if (member == '') cycle ! hidden
    if (signature /= '') signature = signature//' | '
    signature = signature//member
  enddo
  if (signature == '') return
  if (self%m_sets(s)%is_required) then
    signature = ' ('//signature//')'
  else
    signature = ' ['//signature//']'
  endif
  endfunction exclusive_set_signature

  subroutine sanitize_defaults(self)
  !< Sanitize defaults values.
  !<
  !< It is necessary to *sanitize* the default values of non-passed, optional CLAs.
  class(command_line_arguments_group), intent(inout) :: self !< CLAsG data.
  integer(I4P)                                       :: a    !< Counter.

  if (self%is_called) then
    do a=1, self%Na
      call self%cla(a)%sanitize_defaults
    enddo
  endif
  endsubroutine sanitize_defaults


  elemental subroutine finalize(self)
  !< Free dynamic memory when finalizing.
  type(command_line_arguments_group), intent(inout) :: self !< CLAsG data.

  call self%free
  endsubroutine finalize
  ! non type-bound procedures
  pure function same(a, b, case_insensitive) result(equal)
  !< Compare two names, trailing blanks not significant, in any case with case_insensitive (F14).
  character(*), intent(in) :: a                !< First name.
  character(*), intent(in) :: b                !< Second name.
  logical,      intent(in) :: case_insensitive !< Compare in any case.
  logical                  :: equal            !< Check result.

  if (case_insensitive) then
    equal = upper_case(a) == upper_case(b)
  else
    equal = a == b
  endif
  endfunction same
endmodule flap_command_line_arguments_group_t

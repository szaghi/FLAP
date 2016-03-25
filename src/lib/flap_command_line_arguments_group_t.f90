!< Command Line Arguments Group (CLAsG) class.
module flap_command_line_arguments_group_t
!-----------------------------------------------------------------------------------------------------------------------------------
!< Command Line Arguments Group (CLAsG) class.
!-----------------------------------------------------------------------------------------------------------------------------------
use, intrinsic:: ISO_FORTRAN_ENV, only: stdout=>OUTPUT_UNIT, stderr=>ERROR_UNIT
use flap_command_line_argument_t, only : command_line_argument, &
                                         ACTION_PRINT_HELP,     &
                                         ACTION_PRINT_VERS,     &
                                         ACTION_STORE,          &
                                         ACTION_STORE_STAR,     &
                                         ARGS_SEP
use flap_object_t, only : object
use penf
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
save
public :: command_line_arguments_group
public :: STATUS_PRINT_V
public :: STATUS_PRINT_H
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
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
  contains
    ! public methods
    procedure, public :: free                  !< Free dynamic memory.
    procedure, public :: check                 !< Check data consistency.
    procedure, public :: is_required_passed    !< Check if required CLAs are passed.
    procedure, public :: is_passed             !< Check if a CLA has been passed.
    procedure, public :: is_defined            !< Check if a CLA has been defined.
    procedure, public :: raise_error_m_exclude !< Raise error mutually exclusive CLAs passed.
    procedure, public :: add                   !< Add CLA to CLAsG.
    procedure, public :: parse                 !< Parse CLAsG arguments.
    procedure, public :: usage                 !< Get correct CLAsG usage.
    procedure, public :: signature             !< Get CLAsG signature.
    ! private methods
    procedure, private :: errored                             !< Trig error occurrence and print meaningful message.
    procedure, private :: check_m_exclusive                   !< Check if two mutually exclusive CLAs have been passed.
    procedure, private :: sanitize_defaults                   !< Sanitize default values.
    procedure, private :: clasg_assign_clasg                  !< Assignment operator.
    generic,   private :: assignment(=) => clasg_assign_clasg !< Assignment operator overloading.
    final              :: finalize                            !< Free dynamic memory when finalizing.
endtype command_line_arguments_group
! status codes
integer(I4P), parameter :: STATUS_PRINT_V = -1 !< Print version status.
integer(I4P), parameter :: STATUS_PRINT_H = -2 !< Print help status.
! errors codes
integer(I4P), parameter :: ERROR_CONSISTENCY = 23 !< CLAs group consistency error.
integer(I4P), parameter :: ERROR_M_EXCLUDE   = 24 !< Two mutually exclusive CLAs group have been called.
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  ! public methods
  elemental subroutine free(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(inout) :: self !< CLAsG data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free

  subroutine check(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check data consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(inout) :: self  !< CLAsG data.
  character(*), optional,              intent(in)    :: pref  !< Prefixing string.
  integer(I4P)                                       :: a     !< Counter.
  integer(I4P)                                       :: aa    !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! verify if CLAs switches are unique
  CLA_unique: do a=1, self%Na
    if (.not.self%cla(a)%is_positional) then
      do aa=1, self%Na
        if ((a/=aa).and.(.not.self%cla(aa)%is_positional)) then
          if ((self%cla(a)%switch==self%cla(aa)%switch   ).or.(self%cla(a)%switch_ab==self%cla(aa)%switch   ).or.&
              (self%cla(a)%switch==self%cla(aa)%switch_ab).or.(self%cla(a)%switch_ab==self%cla(aa)%switch_ab)) then
            call self%errored(pref=pref, error=ERROR_CONSISTENCY, a1=a, a2=aa)
            exit CLA_unique
          endif
        endif
      enddo
    endif
  enddo CLA_unique
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check

  subroutine is_required_passed(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if required CLAs are passed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(inout) :: self  !< CLAsG data.
  character(*), optional,              intent(in)    :: pref  !< Prefixing string.
  integer(I4P)                                       :: a     !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (self%is_called) then
    do a=1, self%Na
      if (.not.self%cla(a)%is_required_passed(pref=pref)) then
        self%error = self%cla(a)%error
        write(stdout, '(A)') self%usage(pref=pref)
        return
      endif
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine is_required_passed

  pure function is_passed(self, switch, position)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if a CLA has been passed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(in) :: self      !< CLAsG data.
  character(*), optional,              intent(in) :: switch    !< Switch name.
  integer(I4P), optional,              intent(in) :: position  !< Position of positional CLA.
  logical                                         :: is_passed !< Check if a CLA has been passed.
  integer(I4P)                                    :: a         !< CLA counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  is_passed = .false.
  if (self%Na>0) then
    if (present(switch)) then
      do a=1, self%Na
        if (.not.self%cla(a)%is_positional) then
          if ((self%cla(a)%switch==switch).or.(self%cla(a)%switch_ab==switch)) then
            is_passed = self%cla(a)%is_passed
            exit
          endif
        endif
      enddo
    elseif (present(position)) then
      is_passed = self%cla(position)%is_passed
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction is_passed

  function is_defined(self, switch, pos)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if a CLA has been defined.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(in)  :: self       !< CLAsG data.
  character(*),                        intent(in)  :: switch     !< Switch name.
  integer(I4P), optional,              intent(out) :: pos        !< CLA position.
  logical                                          :: is_defined !< Check if a CLA has been defined.
  integer(I4P)                                     :: a          !< CLA counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  is_defined = .false.
  if (present(pos)) pos = 0
  if (self%Na>0) then
    do a=1, self%Na
      if (.not.self%cla(a)%is_positional) then
        if ((self%cla(a)%switch==switch).or.(self%cla(a)%switch_ab==switch)) then
          is_defined = .true.
          if (present(pos)) pos = a
          exit
        endif
      endif
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction is_defined

  subroutine raise_error_m_exclude(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Raise error mutually exclusive CLAs passed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(inout) :: self !< CLA data.
  character(*), optional,              intent(in)    :: pref !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%errored(pref=pref, error=ERROR_M_EXCLUDE)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine raise_error_m_exclude

  subroutine add(self, pref, cla)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Add CLA to CLAs list.
  !<
  !< @note If not otherwise declared the action on CLA value is set to "store" a value that must be passed after the switch name
  !< or directly passed in case of positional CLA.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(inout) :: self            !< CLAsG data.
  character(*), optional,              intent(in)    :: pref            !< Prefixing string.
  type(command_line_argument),         intent(in)    :: cla             !< CLA data.
  type(command_line_argument), allocatable           :: cla_list_new(:) !< New (extended) CLA list.
  integer(I4P)                                       :: c               !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (self%Na>0_I4P) then
    if (.not.cla%is_positional) then
      allocate(cla_list_new(1:self%Na+1))
      do c=1, self%Na
        cla_list_new(c) = self%cla(c)
      enddo
      cla_list_new(self%Na+1) = cla
    else
      allocate(cla_list_new(1:self%Na+1))
      do c=1, cla%position - 1
        cla_list_new(c) = self%cla(c)
      enddo
      cla_list_new(cla%position) = cla
      do c=cla%position + 1, self%Na + 1
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add

  subroutine parse(self, args, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Parse CLAsG arguments.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(inout) :: self      !< CLAsG data.
  character(*), optional,              intent(in)    :: pref      !< Prefixing string.
  character(*),                        intent(in)    :: args(:)   !< Command line arguments.
  character(500)                                     :: envvar    !< Environment variables buffer.
  integer(I4P)                                       :: arg       !< Argument counter.
  integer(I4P)                                       :: a         !< Counter.
  integer(I4P)                                       :: aa        !< Counter.
  integer(I4P)                                       :: aaa       !< Counter.
  integer(I4P)                                       :: nargs     !< Number of arguments consumed by a CLA.
  logical                                            :: found     !< Flag for checking if switch is a defined CLA.
  logical                                            :: found_val !< Flag for checking if switch value is found.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (self%is_called) then
    arg = 0
    do while (arg < size(args, dim=1)) ! loop over CLAs group arguments passed
      arg = arg + 1
      found = .false.
      do a=1, self%Na ! loop over CLAs group clas named options
        if (.not.self%cla(a)%is_positional) then
          if (trim(adjustl(self%cla(a)%switch   ))==trim(adjustl(args(arg))).or.&
              trim(adjustl(self%cla(a)%switch_ab))==trim(adjustl(args(arg)))) then
            found_val = .false.
            if (self%cla(a)%act==action_store) then
              if (allocated(self%cla(a)%envvar)) then
                if (arg + 1 <= size(args,dim=1)) then ! verify if the value has been passed directly to cli
                  ! there are still other arguments to check
                  if (.not.self%is_defined(switch=trim(adjustl(args(arg+1))))) then
                    ! argument seem good...
                    arg = arg + 1
                    self%cla(a)%val = trim(adjustl(args(arg)))
                    found = .true.
                    found_val = .true.
                  endif
                endif
                if (.not.found) then
                  ! not found, try to take val from environment
                  call get_environment_variable(name=self%cla(a)%envvar, value=envvar, status=aa)
                  if (aa==0) then
                    self%cla(a)%val = trim(adjustl(envvar))
                    found_val = .true.
                  else
                    ! flush default to val if environment is not set and default is set
                    if (allocated(self%cla(a)%def)) then
                      self%cla(a)%val = self%cla(a)%def
                      found_val = .true.
                    endif
                  endif
                endif
              elseif (allocated(self%cla(a)%nargs)) then
                self%cla(a)%val = ''
                select case(self%cla(a)%nargs)
                case('+')
                  aaa = 0
                  do aa=arg + 1, size(args,dim=1)
                    if (.not.self%is_defined(switch=trim(adjustl(args(aa))))) then
                      aaa = aa
                    else
                      exit
                    endif
                  enddo
                  if (aaa>=arg+1) then
                    do aa=aaa, arg + 1, -1 ! decreasing loop due to gfortran bug
                      self%cla(a)%val = trim(adjustl(args(aa)))//args_sep//trim(self%cla(a)%val)
                      found_val = .true.
                    enddo
                    arg = aaa
                  elseif (aaa==0) then
                    call self%cla(a)%raise_error_nargs_insufficient(pref=pref)
                    self%error = self%cla(a)%error
                    return
                  endif
                case('*')
                  aaa = 0
                  do aa=arg + 1, size(args,dim=1)
                    if (.not.self%is_defined(switch=trim(adjustl(args(aa))))) then
                      aaa = aa
                    else
                      exit
                    endif
                  enddo
                  if (aaa>=arg+1) then
                    do aa=aaa, arg + 1, -1 ! decreasing loop due to gfortran bug
                      self%cla(a)%val = trim(adjustl(args(aa)))//args_sep//trim(self%cla(a)%val)
                      found_val = .true.
                    enddo
                    arg = aaa
                  endif
                case default
                  nargs = cton(str=trim(adjustl(self%cla(a)%nargs)), knd=1_I4P)
                  if (arg + nargs > size(args,dim=1)) then
                    call self%cla(a)%raise_error_nargs_insufficient(pref=pref)
                    self%error = self%cla(a)%error
                    return
                  endif
                  do aa=arg + nargs, arg + 1, -1 ! decreasing loop due to gfortran bug
                    self%cla(a)%val = trim(adjustl(args(aa)))//args_sep//trim(self%cla(a)%val)
                  enddo
                  found_val = .true.
                  arg = arg + nargs
                endselect
              else
                if (arg+1>size(args)) then
                  call self%cla(a)%raise_error_value_missing(pref=pref)
                  self%error = self%cla(a)%error
                  return
                endif
                arg = arg + 1
                self%cla(a)%val = trim(adjustl(args(arg)))
                found_val = .true.
              endif
            elseif (self%cla(a)%act==action_store_star) then
              if (arg + 1 <= size(args, dim=1)) then ! verify if the value has been passed directly to cli
                ! there are still other arguments to check
                if (.not.self%is_defined(switch=trim(adjustl(args(arg+1))))) then
                  ! argument seem good...
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
            elseif (self%cla(a)%act==action_print_help) then
              self%error = STATUS_PRINT_H
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
        if (.not.self%cla(arg)%is_positional) then ! current argument (arg-th) is not positional... there is a problem!
          call self%cla(arg)%raise_error_switch_unknown(pref=pref, switch=trim(adjustl(args(arg))))
          self%error = self%cla(arg)%error
          return
        else
          ! positional CLA always stores a value
          self%cla(arg)%val = trim(adjustl(args(arg)))
          self%cla(arg)%is_passed = .true.
        endif
      endif
    enddo
    call self%check_m_exclusive(pref=pref)
    call self%sanitize_defaults
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine parse

  function usage(self, pref, no_header)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get correct CLAsG usage.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(in) :: self      !< CLAsG data.
  character(*), optional,              intent(in) :: pref      !< Prefixing string.
  logical,      optional,              intent(in) :: no_header !< Avoid insert header to usage.
  character(len=:), allocatable                   :: usage     !< Usage string.
  integer(I4P)                                    :: a         !< Counters.
  character(len=:), allocatable                   :: prefd     !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  usage = self%progname ; if (self%group/='') usage = self%progname//' '//self%group
  usage = prefd//self%help//' '//usage//self%signature()
  if (self%description/='') usage = usage//new_line('a')//new_line('a')//prefd//self%description
  if (present(no_header)) then
    if (no_header) usage = ''
  endif
  if (self%Na_required>0) then
    usage = usage//new_line('a')//new_line('a')//prefd//'Required switches:'
    do a=1, self%Na
      if (self%cla(a)%is_required.and.(.not.self%cla(a)%is_hidden)) usage = usage//new_line('a')//self%cla(a)%usage(pref=prefd)
    enddo
  endif
  if (self%Na_optional>0) then
    usage = usage//new_line('a')//new_line('a')//prefd//'Optional switches:'
    do a=1, self%Na
      if (.not.self%cla(a)%is_required.and.(.not.self%cla(a)%is_hidden)) usage = usage//new_line('a')//self%cla(a)%usage(pref=prefd)
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction usage

  function signature(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLAsG signature.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(in) :: self      !< CLAsG data.
  character(len=:), allocatable                   :: signature !< Signature.
  integer(I4P)                                    :: a         !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  signature = ''
  do a=1, self%Na
    signature = signature//self%cla(a)%signature()
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction signature

  ! private methods
  subroutine errored(self, error, pref, a1, a2)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Trig error occurrence and print meaningful message.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(inout) :: self  !< CLAsG data.
  integer(I4P),                        intent(in)    :: error !< Error occurred.
  character(*), optional,              intent(in)    :: pref  !< Prefixing string.
  integer(I4P), optional,              intent(in)    :: a1    !< First index CLAs group inconsistent.
  integer(I4P), optional,              intent(in)    :: a2    !< Second index CLAs group inconsistent.
  character(len=:), allocatable                      :: prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  self%error = error
  if (self%error/=0) then
    prefd = '' ; if (present(pref)) prefd = pref
    select case(self%error)
    case(ERROR_CONSISTENCY)
      if (self%group /= '') then
        self%error_message = prefd//self%progname//': error: group (command) name: "'//self%group//'" consistency error:'
      else
        self%error_message = prefd//self%progname//': error: consistency error:'
      endif
      self%error_message = self%error_message//' "'//trim(str(a1, .true.))//&
        '-th" option has the same switch or abbreviated switch of "'//trim(str(a2, .true.))//'-th" option:'//new_line('a')
      self%error_message = self%error_message//prefd//' CLA('//trim(str(a1, .true.)) //') switches = '//self%cla(a1)%switch //' '//&
        self%cla(a1)%switch_ab//new_line('a')
      self%error_message = self%error_message//prefd//' CLA('//trim(str(a2, .true.))//') switches = '//self%cla(a2)%switch//' '//&
                         self%cla(a2)%switch_ab
    case(ERROR_M_EXCLUDE)
      self%error_message = prefd//self%progname//': error: the group "'//self%group//'" and "'//self%m_exclude//'" are mutually'//&
       ' exclusive, but both have been called!'
    endselect
    call self%print_error_message
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine errored

  subroutine check_m_exclusive(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if two mutually exclusive CLAs have been passed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(inout) :: self !< CLAsG data.
  character(*), optional,              intent(in)    :: pref !< Prefixing string.
  integer(I4P)                                       :: a    !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_m_exclusive

  subroutine sanitize_defaults(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Sanitize defaults values.
  !<
  !< It is necessary to *sanitize* the default values of non-passed, optional CLAs.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(inout) :: self !< CLAsG data.
  integer(I4P)                                       :: a    !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (self%is_called) then
    do a=1, self%Na
      call self%cla(a)%sanitize_defaults
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine sanitize_defaults

  elemental subroutine clasg_assign_clasg(lhs, rhs)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Assignment operator.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_arguments_group), intent(INOUT) :: lhs !< Left hand side.
  type(command_line_arguments_group),  intent(IN)    :: rhs !< Right hand side.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! object members
  call lhs%assign_object(rhs)
  ! command_line_arguments_group members
  if (allocated(rhs%group)) lhs%group = rhs%group
  if (allocated(rhs%cla  )) then
    if (allocated(lhs%cla)) deallocate(lhs%cla) ; allocate(lhs%cla(1:size(rhs%cla,dim=1)),source=rhs%cla)
  endif
  lhs%Na          = rhs%Na
  lhs%Na_required = rhs%Na_required
  lhs%Na_optional = rhs%Na_optional
  lhs%is_called   = rhs%is_called
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine clasg_assign_clasg

  elemental subroutine finalize(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory when finalizing.
  !---------------------------------------------------------------------------------------------------------------------------------
  type(command_line_arguments_group), intent(inout) :: self !< CLAsG data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize
endmodule flap_command_line_arguments_group_t

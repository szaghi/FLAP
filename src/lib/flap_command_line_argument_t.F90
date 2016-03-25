!< Command Line Argument (CLA) class.
module flap_command_line_argument_t
!-----------------------------------------------------------------------------------------------------------------------------------
!< Command Line Argument (CLA) class.
!-----------------------------------------------------------------------------------------------------------------------------------
use, intrinsic:: ISO_FORTRAN_ENV, only : stderr=>ERROR_UNIT
use flap_object_t, only : object
use flap_utils_m
use penf
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
save
public :: command_line_argument
public :: ACTION_STORE
public :: ACTION_STORE_STAR
public :: ACTION_STORE_TRUE
public :: ACTION_STORE_FALSE
public :: ACTION_PRINT_HELP
public :: ACTION_PRINT_VERS
public :: ARGS_SEP
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
type, extends(object) :: command_line_argument
  !< Command Line Argument (CLA) class.
  !<
  !< @note If not otherwise declared the action on CLA value is set to "store" a value.
  private
  character(len=:), allocatable, public :: switch                !< Switch name.
  character(len=:), allocatable, public :: switch_ab             !< Abbreviated switch name.
  logical,                       public :: is_required=.false.   !< Flag for set required argument.
  logical,                       public :: is_positional=.false. !< Flag for checking if CLA is a positional or a named CLA.
  integer(I4P),                  public :: position= 0_I4P       !< Position of positional CLA.
  logical,                       public :: is_passed=.false.     !< Flag for checking if CLA has been passed to CLI.
  logical,                       public :: is_hidden=.false.     !< Flag for hiding CLA, thus it does not compare into help.
  character(len=:), allocatable, public :: act                   !< CLA value action.
  character(len=:), allocatable, public :: def                   !< Default value.
  character(len=:), allocatable, public :: nargs                 !< Number of arguments consumed by CLA.
  character(len=:), allocatable, public :: choices               !< List (comma separated) of allowable values for the argument.
  character(len=:), allocatable, public :: val                   !< CLA value.
  character(len=:), allocatable, public :: envvar                !< Environment variable from which take value.
  contains
    ! public methods
    procedure, public :: free                            !< Free dynamic memory.
    procedure, public :: check                           !< Check data consistency.
    procedure, public :: is_required_passed              !< Check if required CLA is passed.
    procedure, public :: raise_error_m_exclude           !< Raise error mutually exclusive CLAs passed.
    procedure, public :: raise_error_nargs_insufficient  !< Raise error insufficient number of argument values passed.
    procedure, public :: raise_error_value_missing       !< Raise error missing value.
    procedure, public :: raise_error_switch_unknown      !< Raise error switch_unknown.
    generic,   public :: get =>   &
                         get_cla, &
                         get_cla_list                    !< Get CLA value(s).
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
                         get_cla_list_varying_char       !< Get CLA value(s) from varying size list.
    procedure, public :: sanitize_defaults               !< Sanitize default values.
    procedure, public :: usage                           !< Get correct usage.
    procedure, public :: signature                       !< Get signature.
    ! private methods
    procedure, private :: errored                         !< Trig error occurence and print meaningful message.
    procedure, private :: check_envvar_consistency        !< Check data consistency for envvar CLA.
    procedure, private :: check_action_consistency        !< Check CLA action consistency.
    procedure, private :: check_optional_consistency      !< Check optional CLA consistency.
    procedure, private :: check_m_exclude_consistency     !< Check mutually exclusion consistency.
    procedure, private :: check_named_consistency         !< Check named CLA consistency.
    procedure, private :: check_positional_consistency    !< Check positional CLA consistency.
    procedure, private :: check_choices                   !< Check if CLA value is in allowed choices.
    procedure, private :: check_list_size                 !< Check CLA multiple values list size consistency.
    procedure, private :: get_cla                         !< Get CLA (single) value.
    procedure, private :: get_cla_from_buffer             !< Get CLA (single) value from a buffer.
    procedure, private :: get_cla_list                    !< Get CLA multiple values.
    procedure, private :: get_cla_list_from_buffer        !< Get CLA (single) value from a buffer.
    procedure, private :: get_cla_list_varying_R8P        !< Get CLA multiple values, varying size, R8P.
    procedure, private :: get_cla_list_varying_R4P        !< Get CLA multiple values, varying size, R4P.
    procedure, private :: get_cla_list_varying_I8P        !< Get CLA multiple values, varying size, I8P.
    procedure, private :: get_cla_list_varying_I4P        !< Get CLA multiple values, varying size, I4P.
    procedure, private :: get_cla_list_varying_I2P        !< Get CLA multiple values, varying size, I2P.
    procedure, private :: get_cla_list_varying_I1P        !< Get CLA multiple values, varying size, I1P.
    procedure, private :: get_cla_list_varying_logical    !< Get CLA multiple values, varying size, bool.
    procedure, private :: get_cla_list_varying_char       !< Get CLA multiple values, varying size, char.
    procedure, private :: cla_assign_cla                  !< Assignment operator.
    generic,   private :: assignment(=) => cla_assign_cla !< Assignment operator overloading.
    final              :: finalize                        !< Free dynamic memory when finalizing.
endtype command_line_argument
! parameters
character(len=*), parameter :: ACTION_STORE       = 'STORE'         !< Store value (if invoked a value must be passed).
character(len=*), parameter :: ACTION_STORE_STAR  = 'STORE*'        !< Store value or revert on default is invoked alone.
character(len=*), parameter :: ACTION_STORE_TRUE  = 'STORE_TRUE'    !< Store .true. without the necessity of a value.
character(len=*), parameter :: ACTION_STORE_FALSE = 'STORE_FALSE'   !< Store .false. without the necessity of a value.
character(len=*), parameter :: ACTION_PRINT_HELP  = 'PRINT_HELP'    !< Print help message.
character(len=*), parameter :: ACTION_PRINT_VERS  = 'PRINT_VERSION' !< Print version.
character(len=*), parameter :: ARGS_SEP           = '||!||'         !< Arguments separator for multiple valued (list) CLA.
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
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  ! public methods
  elemental subroutine free(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self !< CLA data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! object members
  call self%free_object
  ! command_line_argument members
  if (allocated(self%switch   )) deallocate(self%switch   )
  if (allocated(self%switch_ab)) deallocate(self%switch_ab)
  if (allocated(self%act      )) deallocate(self%act      )
  if (allocated(self%def      )) deallocate(self%def      )
  if (allocated(self%nargs    )) deallocate(self%nargs    )
  if (allocated(self%choices  )) deallocate(self%choices  )
  if (allocated(self%val      )) deallocate(self%val      )
  if (allocated(self%envvar   )) deallocate(self%envvar   )
  self%is_required   = .false.
  self%is_positional = .false.
  self%position      =  0_I4P
  self%is_passed     = .false.
  self%is_hidden     = .false.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free

  subroutine check(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check data consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%check_envvar_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_action_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_optional_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_m_exclude_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_named_consistency(pref=pref) ; if (self%error/=0) return
  call self%check_positional_consistency(pref=pref)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check

  function is_required_passed(self, pref) result(is_ok)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if required CLA is passed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  logical                                     :: is_ok !< Check result.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  is_ok = .true.
  if (((.not.self%is_passed).and.self%is_required).or.((.not.self%is_passed).and.(.not.allocated(self%def)))) then
    call self%errored(pref=pref, error=ERROR_MISSING_REQUIRED)
    is_ok = .false.
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction is_required_passed

  subroutine raise_error_m_exclude(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Raise error mutually exclusive CLAs passed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self !< CLA data.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%errored(pref=pref, error=ERROR_M_EXCLUDE)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine raise_error_m_exclude

  subroutine raise_error_nargs_insufficient(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Raise error insufficient number of argument values passed.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self !< CLA data.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%errored(pref=pref, error=ERROR_NARGS_INSUFFICIENT)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine raise_error_nargs_insufficient

  subroutine raise_error_value_missing(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Raise error missing value.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self !< CLA data.
  character(*), optional,       intent(in)    :: pref !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%errored(pref=pref, error=ERROR_VALUE_MISSING)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine raise_error_value_missing

  subroutine raise_error_switch_unknown(self, switch, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Raise error switch_unknown.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self   !< CLA data.
  character(*), optional,       intent(in)    :: switch !< CLA switch name.
  character(*), optional,       intent(in)    :: pref   !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%errored(pref=pref, error=ERROR_UNKNOWN, switch=switch)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine raise_error_switch_unknown

  subroutine sanitize_defaults(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Sanitize defaults values.
  !<
  !< It is necessary to *sanitize* the default values of non-passed, optional CLA.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self !< CLAsG data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_passed) then
    if (allocated(self%def)) then
      ! strip leading and trailing white spaces
      self%def = wstrip(self%def)
      if (allocated(self%nargs)) then
        ! replace white space separator with FLAP ARGS_SEP
        self%def = unique(string=self%def, substring=' ')
        self%def = replace_all(string=self%def, substring=' ', restring=ARGS_SEP)
      endif
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine sanitize_defaults

  function usage(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get correct usage.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(in) :: self  !< CLAs group data.
  character(*), optional,       intent(in) :: pref  !< Prefixing string.
  character(len=:), allocatable            :: usage !< Usage string.
  character(len=:), allocatable            :: prefd !< Prefixing string.
  integer(I4P)                             :: a     !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_hidden) then
    if (self%act==action_store) then
      if (.not.self%is_positional) then
        if (allocated(self%nargs)) then
          usage = ''
          select case(self%nargs)
          case('+')
            usage = usage//' value#1 [value#2...]'
          case('*')
            usage = usage//' [value#1 value#2...]'
          case default
            do a=1, cton(str=trim(adjustl(self%nargs)),knd=1_I4P)
              usage = usage//' value#'//trim(str(a, .true.))
            enddo
          endselect
          if (trim(adjustl(self%switch))/=trim(adjustl(self%switch_ab))) then
            usage = '   '//trim(adjustl(self%switch))//usage//', '//trim(adjustl(self%switch_ab))//usage
          else
            usage = '   '//trim(adjustl(self%switch))//usage
          endif
        else
          if (trim(adjustl(self%switch))/=trim(adjustl(self%switch_ab))) then
            usage = '   '//trim(adjustl(self%switch))//' value, '//trim(adjustl(self%switch_ab))//' value'
          else
            usage = '   '//trim(adjustl(self%switch))//' value'
          endif
        endif
      else
        usage = '  value'
      endif
      if (allocated(self%choices)) then
        usage = usage//', value in: ('//self%choices//')'
      endif
    elseif (self%act==action_store_star) then
      usage = '  [value]'
      if (allocated(self%choices)) then
        usage = usage//', value in: ('//self%choices//')'
      endif
    else
      if (trim(adjustl(self%switch))/=trim(adjustl(self%switch_ab))) then
        usage = '   '//trim(adjustl(self%switch))//', '//trim(adjustl(self%switch_ab))
      else
        usage = '   '//trim(adjustl(self%switch))
      endif
    endif
    prefd = '' ; if (present(pref)) prefd = pref
    usage = prefd//usage
    if (self%is_positional) usage = usage//new_line('a')//prefd//repeat(' ',10)//trim(str(self%position, .true.))//'-th argument'
    if (allocated(self%envvar)) then
      if (self%envvar /= '') then
        usage = usage//new_line('a')//prefd//repeat(' ',10)//'environment variable name "'//trim(adjustl(self%envvar))//'"'
      endif
    endif
    if (.not.self%is_required) then
      if (self%def /= '') then
        usage = usage//new_line('a')//prefd//repeat(' ',10)//'default value '//trim(adjustl(self%def))
      endif
    endif
    if (self%m_exclude/='') usage = usage//new_line('a')//prefd//repeat(' ',10)//'mutually exclude "'//self%m_exclude//'"'
    usage = usage//new_line('a')//prefd//repeat(' ',10)//trim(adjustl(self%help))
  else
    usage = ''
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction usage

  function signature(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get signature.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(in) :: self      !< CLA data.
  character(len=:), allocatable            :: signature !< Signature.
  integer(I4P)                             :: nargs     !< Number of arguments consumed by CLA.
  integer(I4P)                             :: a         !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_hidden) then
    if (self%act==action_store) then
      if (.not.self%is_positional) then
        if (allocated(self%nargs)) then
          select case(self%nargs)
          case('+')
            signature = ' value#1 [value#2 value#3...]'
          case('*')
            signature = ' [value#1 value#2 value#3...]'
          case default
            nargs = cton(str=trim(adjustl(self%nargs)),knd=1_I4P)
            signature = ''
            do a=1, nargs
              signature = signature//' value#'//trim(str(a, .true.))
            enddo
          endselect
        else
          signature = ' value'
        endif
        if (self%is_required) then
          signature = ' '//trim(adjustl(self%switch))//signature
        else
          signature = ' ['//trim(adjustl(self%switch))//signature//']'
        endif
      else
        if (self%is_required) then
          signature = ' value'
        else
          signature = ' [value]'
        endif
      endif
    elseif (self%act==action_store_star) then
      signature = ' [value]'
    else
      if (self%is_required) then
        signature = ' '//trim(adjustl(self%switch))
      else
        signature = ' ['//trim(adjustl(self%switch))//']'
      endif
    endif
  else
    signature = ''
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction signature

  ! private methods
  subroutine errored(self, error, pref, switch, val_str, log_value)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Trig error occurence and print meaningful message.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self      !< CLA data.
  integer(I4P),                 intent(in)    :: error     !< Error occurred.
  character(*), optional,       intent(in)    :: pref      !< Prefixing string.
  character(*), optional,       intent(in)    :: switch    !< CLA switch name.
  character(*), optional,       intent(in)    :: val_str   !< Value string.
  character(*), optional,       intent(in)    :: log_value !< Logical value to be casted.
  character(len=:), allocatable               :: prefd     !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  self%error = error
  if (self%error/=0) then
    prefd = '' ; if (present(pref)) prefd = pref
    select case(self%error)
    case(ERROR_OPTIONAL_NO_DEF)
      if (self%is_positional) then
        self%error_message = prefd//self%progname//': error: "'//trim(str(n=self%position))//&
                           '-th" positional option has not a default value!'
      else
        self%error_message = prefd//self%progname//': error: named option "'//self%switch//'" has not a default value!'
      endif
    case(ERROR_REQUIRED_M_EXCLUDE)
      self%error_message = prefd//self%progname//': error: named option "'//self%switch//'" cannot exclude others'//&
        ', it being requiredi, only optional ones can!'
    case(ERROR_POSITIONAL_M_EXCLUDE)
      self%error_message = prefd//self%progname//': error: "'//trim(str(n=self%position))//&
        '-th" positional option cannot exclude others, only optional named options can!'
    case(ERROR_NAMED_NO_NAME)
      self%error_message = prefd//self%progname//': error: a non positional optiona must have a switch name!'
    case(ERROR_POSITIONAL_NO_POSITION)
      self%error_message = prefd//self%progname//': error: a positional option must have a position number different from 0!'
    case(ERROR_POSITIONAL_NO_STORE)
      self%error_message = prefd//self%progname//': error: a positional option must have action set to "'//action_store//'"!'
    case(ERROR_M_EXCLUDE)
      self%error_message = prefd//self%progname//': error: the options "'//self%switch//'" and "'//self%m_exclude//&
        '" are mutually exclusive, but both have been passed!'
    case(ERROR_NOT_IN_CHOICES)
      if (self%is_positional) then
        self%error_message = prefd//self%progname//': error: value of "'//trim(str(n=self%position))//&
          '-th" positional option must be chosen in:'
      else
        self%error_message = prefd//self%progname//': error: value of named option "'//self%switch//'" must be chosen in: '
      endif
      self%error_message = self%error_message//'('//self%choices//')'
      self%error_message = self%error_message//' but "'//trim(val_str)//'" has been passed!'
    case(ERROR_MISSING_REQUIRED)
      if (.not.self%is_positional) then
        self%error_message = prefd//self%progname//': error: named option "'//trim(adjustl(self%switch))//'" is required!'
      else
        self%error_message = prefd//self%progname//': error: "'//trim(str(self%position, .true.))//&
          '-th" positional option is required!'
      endif
    case(ERROR_CASTING_LOGICAL)
      self%error_message = prefd//self%progname//': error: cannot convert "'//log_value//'" of option "'//self%switch//&
        '" to logical type!'
    case(ERROR_CHOICES_LOGICAL)
      self%error_message = prefd//self%progname//': error: cannot use "choices" value check for option "'//self%switch//&
        '" it being of logical type! The choices is, by definition of logical, limited to ".true." or ".false."'
    case(ERROR_NO_LIST)
      if (.not.self%is_positional) then
        self%error_message = prefd//self%progname//': error: named option "'//trim(adjustl(self%switch))//&
          '" has not "nargs" value but an array has been passed to "get" method!'
      else
        self%error_message = prefd//self%progname//': error: "'//trim(str(self%position, .true.))//'-th" positional option '//&
          'has not "nargs" value but an array has been passed to "get" method!'
      endif
    case(ERROR_NARGS_INSUFFICIENT)
      if (.not.self%is_positional) then
        if (self%nargs=='+') then
          self%error_message = prefd//self%progname//': error: named option "'//trim(adjustl(self%switch))//&
            '" requires at least 1 argument but no one remains!'
        else
          self%error_message = prefd//self%progname//': error: named option "'//trim(adjustl(self%switch))//'" requires '//&
            trim(adjustl(self%nargs))//' arguments but no enough ones remain!'
        endif
      else
        if (self%nargs=='+') then
          self%error_message = prefd//self%progname//': error: "'//trim(str(self%position, .true.))//&
            '-th" positional option requires at least 1 argument but no one remains'
        else
          self%error_message = prefd//self%progname//': error: "'//trim(str(self%position, .true.))//&
            '-th" positional option requires '//&
            trim(adjustl(self%nargs))//' arguments but no enough ones remain!'
        endif
      endif
    case(ERROR_VALUE_MISSING)
      self%error_message = prefd//self%progname//': error: named option "'//trim(adjustl(self%switch))//&
        '" needs a value that is not passed!'
    case(ERROR_UNKNOWN)
      self%error_message = prefd//self%progname//': error: switch "'//trim(adjustl(switch))//'" is unknown!'
    case(ERROR_ENVVAR_POSITIONAL)
      self%error_message = prefd//self%progname//': error: "'//trim(str(self%position, .true.))//'-th" positional option '//&
        'has "envvar" value that is not allowed for positional option!'
    case(ERROR_ENVVAR_NOT_STORE)
      self%error_message = prefd//self%progname//': error: named option "'//trim(adjustl(self%switch))//&
        '" is an envvar with action different from "'//action_store//'" that is not allowed!'
    case(ERROR_ENVVAR_NARGS)
      self%error_message = prefd//self%progname//': error: named option "'//trim(adjustl(self%switch))//&
        '" is an envvar that is not allowed for list valued option!'
    case(ERROR_STORE_STAR_POSITIONAL)
      self%error_message = prefd//self%progname//': error: "'//trim(str(self%position, .true.))//'-th" positional option '//&
        'has "'//action_store_star//'" action that is not allowed for positional option!'
    case(ERROR_STORE_STAR_NARGS)
      self%error_message = prefd//self%progname//': error: named option "'//trim(adjustl(self%switch))//&
        '" has "'//action_store_star//'" action that is not allowed for list valued option!'
    case(ERROR_STORE_STAR_ENVVAR)
      self%error_message = prefd//self%progname//': error: named option "'//trim(adjustl(self%switch))//&
        '" has "'//action_store_star//'" action that is not allowed for environment variable option!'
    case(ERROR_ACTION_UNKNOWN)
      self%error_message = prefd//self%progname//': error: named option "'//trim(adjustl(self%switch))//&
        '" has unknown "'//self%act//'" action!'
    endselect
    call self%print_error_message
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine errored

  subroutine check_envvar_consistency(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check data consistency for envvar CLA.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self%envvar)) then
    if (self%is_positional) then
      call self%errored(pref=pref, error=ERROR_ENVVAR_POSITIONAL)
      return
    endif
    if (.not.allocated(self%act)) then
      call self%errored(pref=pref, error=ERROR_ENVVAR_NOT_STORE)
      return
    else
      if (self%act/=action_store) then
        call self%errored(pref=pref, error=ERROR_ENVVAR_NOT_STORE)
        return
      endif
    endif
    if (allocated(self%nargs)) then
      call self%errored(pref=pref, error=ERROR_ENVVAR_NARGS)
      return
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_envvar_consistency

  subroutine check_action_consistency(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check CLA action consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self%act)) then
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
        self%act/=ACTION_PRINT_VERS) then
      call self%errored(pref=pref, error=ERROR_ACTION_UNKNOWN)
      return
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_action_consistency

  subroutine check_optional_consistency(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check optional CLA consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if ((.not.self%is_required).and.(.not.allocated(self%def))) call self%errored(pref=pref, error=ERROR_OPTIONAL_NO_DEF)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_optional_consistency

  subroutine check_m_exclude_consistency(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check mutually exclusion consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if ((self%is_required).and.(self%m_exclude/='')) then
    call self%errored(pref=pref, error=ERROR_REQUIRED_M_EXCLUDE)
    return
  endif
  if ((self%is_positional).and.(self%m_exclude/='')) then
    call self%errored(pref=pref, error=ERROR_POSITIONAL_M_EXCLUDE)
    return
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_m_exclude_consistency

  subroutine check_named_consistency(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check named CLA consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if ((.not.self%is_positional).and.(.not.allocated(self%switch))) call self%errored(pref=pref, error=ERROR_NAMED_NO_NAME)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_named_consistency

  subroutine check_positional_consistency(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check positional CLA consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if ((self%is_positional).and.(self%position==0_I4P)) then
    call self%errored(pref=pref, error=ERROR_POSITIONAL_NO_POSITION)
    return
  elseif ((self%is_positional).and.(self%act/=action_store)) then
    call self%errored(pref=pref, error=ERROR_POSITIONAL_NO_STORE)
    return
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_positional_consistency

  subroutine check_choices(self, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if CLA value is in allowed choices.
  !<
  !< @note This procedure can be called if and only if cla%choices has been allocated.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  class(*),                     intent(in)    :: val     !< CLA value.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  character(len(self%choices)), allocatable   :: toks(:) !< Tokens for parsing choices list.
  integer(I4P)                                :: Nc      !< Number of choices.
  logical                                     :: val_in  !< Flag for checking if val is in the choosen range.
  character(len=:), allocatable               :: val_str !< Value in string form.
  character(len=:), allocatable               :: tmp     !< Temporary string for avoiding GNU gfrotran bug.
  integer(I4P)                                :: c       !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  val_in = .false.
  val_str = ''
  tmp = self%choices
  call tokenize(strin=tmp, delimiter=',', toks=toks, Nt=Nc)
  select type(val)
#ifdef r16p
  type is(real(R16P))
    val_str = str(n=val)
    do c=1, Nc
      if (val==cton(str=trim(adjustl(toks(c))), knd=1._R16P)) val_in = .true.
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
    do c=1, Nc
      if (val==toks(c)) val_in = .true.
    enddo
  type is(logical)
    call self%errored(pref=pref, error=ERROR_CHOICES_LOGICAL)
  endselect
  if (.not.val_in.and.(self%error==0)) then
    call self%errored(pref=pref, error=ERROR_NOT_IN_CHOICES, val_str=val_str)
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_choices

  function check_list_size(self, Nv, val, pref) result(is_ok)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check CLA multiple values list size consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  integer(I4P),                 intent(in)    :: Nv    !< Number of values.
  character(*),                 intent(in)    :: val   !< First value.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  logical                                     :: is_ok !< Check result.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  is_ok = .true.
  if (Nv==1) then
    if (trim(adjustl(val))=='') then
      ! there is no real value, but only for nargs=+ this is a real error
      is_ok = .false.
      if (self%nargs=='+') then
        call self%errored(pref=pref, error=ERROR_NARGS_INSUFFICIENT)
      endif
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction check_list_size

  subroutine get_cla(self, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (single) value.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(command_line_argument), intent(inout) :: self  !< CLA data.
  class(*),                     intent(inout) :: val   !< CLA value.
  character(*), optional,       intent(in)    :: pref  !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_required_passed(pref=pref)) return
  if (self%act==action_store.or.self%act==action_store_star) then
    if (self%is_passed.and.allocated(self%val)) then
      call self%get_cla_from_buffer(buffer=self%val, val=val, pref=pref)
    elseif (allocated(self%def)) then ! using default value
      call self%get_cla_from_buffer(buffer=self%def, val=val, pref=pref)
    endif
    if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val, pref=pref)
  elseif (self%act==action_store_true) then
    if (self%is_passed) then
      select type(val)
      type is(logical)
        val = .true.
      endselect
    elseif (allocated(self%def)) then
      select type(val)
      type is(logical)
        read(self%def, *, iostat=self%error)val
        if (self%error/=0) call self%errored(pref=pref, error=ERROR_CASTING_LOGICAL, log_value=self%def)
      endselect
    endif
  elseif (self%act==action_store_false) then
    if (self%is_passed) then
      select type(val)
      type is(logical)
        val = .false.
      endselect
    elseif (allocated(self%def)) then
      select type(val)
      type is(logical)
        read(self%def, *, iostat=self%error)val
        if (self%error/=0) call self%errored(pref=pref, error=ERROR_CASTING_LOGICAL, log_value=self%def)
      endselect
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla

  subroutine get_cla_from_buffer(self, buffer, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (single) value from parsed value.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(command_line_argument), intent(inout) :: self   !< CLA data.
  character(*),                 intent(in)    :: buffer !< Buffer containing values (parsed or default CLA value).
  class(*),                     intent(inout) :: val    !< CLA value.
  character(*), optional,       intent(in)    :: pref   !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  select type(val)
#ifdef r16p
  type is(real(R16P))
    val = cton(pref=pref, error=self%error, str=trim(adjustl(buffer)), knd=1._R16P)
#endif
  type is(real(R8P))
    val = cton(pref=pref, error=self%error, str=trim(adjustl(buffer)), knd=1._R8P)
  type is(real(R4P))
    val = cton(pref=pref, error=self%error, str=trim(adjustl(buffer)), knd=1._R4P)
  type is(integer(I8P))
    val = cton(pref=pref, error=self%error, str=trim(adjustl(buffer)), knd=1_I8P)
  type is(integer(I4P))
    val = cton(pref=pref, error=self%error, str=trim(adjustl(buffer)), knd=1_I4P)
  type is(integer(I2P))
    val = cton(pref=pref, error=self%error, str=trim(adjustl(buffer)), knd=1_I2P)
  type is(integer(I1P))
    val = cton(pref=pref, error=self%error, str=trim(adjustl(buffer)), knd=1_I1P)
  type is(logical)
    read(buffer, *, iostat=self%error)val
    if (self%error/=0) call self%errored(pref=pref, error=ERROR_CASTING_LOGICAL, log_value=buffer)
  type is(character(*))
    val = buffer
  endselect
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_from_buffer

  subroutine get_cla_list(self, pref, val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA multiple values.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  class(*),                     intent(inout) :: val(1:)  !< CLA values.
  integer(I4P)                                :: Nv       !< Number of values.
  character(len=len(self%def)), allocatable   :: valsD(:) !< String array of values based on self%def.
  integer(I4P)                                :: v        !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.allocated(self%nargs)) then
    call self%errored(pref=pref,error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store) then
    if (self%is_passed) then
      call self%get_cla_list_from_buffer(buffer=self%val, val=val, pref=pref)
    else ! using default value
      call self%get_cla_list_from_buffer(buffer=self%def, val=val, pref=pref)
    endif
  elseif (self%act==action_store_true) then
    if (self%is_passed) then
      select type(val)
      type is(logical)
        val = .true.
      endselect
    else
      call tokenize(strin=self%def, delimiter=' ', toks=valsD, Nt=Nv)
      select type(val)
      type is(logical)
        do v=1,Nv
          read(valsD(v),*)val(v)
        enddo
      endselect
    endif
  elseif (self%act==action_store_false) then
    if (self%is_passed) then
      select type(val)
      type is(logical)
        val = .false.
      endselect
    else
      call tokenize(strin=self%def, delimiter=' ', toks=valsD, Nt=Nv)
      select type(val)
      type is(logical)
        do v=1, Nv
          read(valsD(v),*)val(v)
        enddo
      endselect
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list

  subroutine get_cla_list_from_buffer(self, buffer, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA multiple values from a buffer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(command_line_argument), intent(inout) :: self    !< CLA data.
  character(*),                 intent(in)    :: buffer  !< Buffer containing values (parsed or default CLA value).
  class(*),                     intent(inout) :: val(1:) !< CLA value.
  character(*), optional,       intent(in)    :: pref    !< Prefixing string.
  integer(I4P)                                :: Nv      !< Number of values.
  character(len=len(buffer)), allocatable     :: vals(:) !< String array of values based on buffer value.
  integer(I4P)                                :: v       !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call tokenize(strin=buffer, delimiter=args_sep, toks=vals, Nt=Nv)
  select type(val)
#ifdef r16p
  type is(real(R16P))
    do v=1, Nv
      val(v) = cton(pref=pref,error=self%error,str=trim(adjustl(vals(v))),knd=1._R16P)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref)
      if (self%error/=0) exit
    enddo
#endif
  type is(real(R8P))
    do v=1, Nv
      val(v) = cton(pref=pref,error=self%error,str=trim(adjustl(vals(v))),knd=1._R8P)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref)
      if (self%error/=0) exit
    enddo
  type is(real(R4P))
    do v=1, Nv
      val(v) = cton(pref=pref,error=self%error,str=trim(adjustl(vals(v))),knd=1._R4P)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref)
      if (self%error/=0) exit
    enddo
  type is(integer(I8P))
    do v=1, Nv
      val(v) = cton(pref=pref,error=self%error,str=trim(adjustl(vals(v))),knd=1_I8P)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref)
      if (self%error/=0) exit
    enddo
  type is(integer(I4P))
    do v=1, Nv
      val(v) = cton(pref=pref,error=self%error,str=trim(adjustl(vals(v))),knd=1_I4P)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref)
      if (self%error/=0) exit
    enddo
  type is(integer(I2P))
    do v=1, Nv
      val(v) = cton(pref=pref,error=self%error,str=trim(adjustl(vals(v))),knd=1_I2P)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref)
      if (self%error/=0) exit
    enddo
  type is(integer(I1P))
    do v=1, Nv
      val(v) = cton(pref=pref,error=self%error,str=trim(adjustl(vals(v))),knd=1_I1P)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref)
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
    do v=1, Nv
      val(v)=vals(v)
      if (allocated(self%choices).and.self%error==0) call self%check_choices(val=val(v),pref=pref)
      if (self%error/=0) exit
    enddo
  endselect
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_from_buffer

  subroutine get_cla_list_varying_R16P(self, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (multiple) value with varying size, real(R16P).
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  real(R16P), allocatable,      intent(out)   :: val(:)   !< CLA values.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  integer(I4P)                                :: Nv       !< Number of values.
  character(len=len(self%val)), allocatable   :: valsV(:) !< String array of values based on self%val.
  character(len=len(self%def)), allocatable   :: valsD(:) !< String array of values based on self%def.
  integer(I4P)                                :: v        !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.allocated(self%nargs)) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store) then
    if (self%is_passed) then
      call tokenize(strin=self%val, delimiter=ARGS_SEP, toks=valsV, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsV(1), pref=pref)) return
      allocate(real(R16P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsV(v))), knd=1._R16P)
        if (self%error/=0) exit
      enddo
    else ! using default value
      call tokenize(strin=self%def, delimiter=ARGS_SEP, toks=valsD, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsD(1), pref=pref)) return
      if (Nv==1) then
        if (trim(adjustl(valsD(1)))=='') then
          if (self%nargs=='+') then
            call self%errored(pref=pref, error=ERROR_NARGS_INSUFFICIENT)
          endif
          return
        endif
      endif
      allocate(real(R16P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsD(v))), knd=1._R16P)
        if (self%error/=0) exit
      enddo
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_R16P

  subroutine get_cla_list_varying_R8P(self, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (multiple) value with varying size, real(R8P).
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  real(R8P), allocatable,       intent(out)   :: val(:)   !< CLA values.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  integer(I4P)                                :: Nv       !< Number of values.
  character(len=len(self%val)), allocatable   :: valsV(:) !< String array of values based on self%val.
  character(len=len(self%def)), allocatable   :: valsD(:) !< String array of values based on self%def.
  integer(I4P)                                :: v        !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.allocated(self%nargs)) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store) then
    if (self%is_passed) then
      call tokenize(strin=self%val, delimiter=ARGS_SEP, toks=valsV, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsV(1), pref=pref)) return
      allocate(real(R8P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsV(v))), knd=1._R8P)
        if (self%error/=0) exit
      enddo
    else ! using default value
      call tokenize(strin=self%def, delimiter=ARGS_SEP, toks=valsD, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsD(1), pref=pref)) return
      allocate(real(R8P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsD(v))), knd=1._R8P)
        if (self%error/=0) exit
      enddo
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_R8P

  subroutine get_cla_list_varying_R4P(self, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (multiple) value with varying size, real(R4P).
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  real(R4P), allocatable,       intent(out)   :: val(:)   !< CLA values.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  integer(I4P)                                :: Nv       !< Number of values.
  character(len=len(self%val)), allocatable   :: valsV(:) !< String array of values based on self%val.
  character(len=len(self%def)), allocatable   :: valsD(:) !< String array of values based on self%def.
  integer(I4P)                                :: v        !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.allocated(self%nargs)) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store) then
    if (self%is_passed) then
      call tokenize(strin=self%val, delimiter=ARGS_SEP, toks=valsV, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsV(1), pref=pref)) return
      allocate(real(R4P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsV(v))), knd=1._R4P)
        if (self%error/=0) exit
      enddo
    else ! using default value
      call tokenize(strin=self%def, delimiter=ARGS_SEP, toks=valsD, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsD(1), pref=pref)) return
      allocate(real(R4P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsD(v))), knd=1._R4P)
        if (self%error/=0) exit
      enddo
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_R4P

  subroutine get_cla_list_varying_I8P(self, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (multiple) value with varying size, integer(I8P).
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  integer(I8P), allocatable,    intent(out)   :: val(:)   !< CLA values.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  integer(I4P)                                :: Nv       !< Number of values.
  character(len=len(self%val)), allocatable   :: valsV(:) !< String array of values based on self%val.
  character(len=len(self%def)), allocatable   :: valsD(:) !< String array of values based on self%def.
  integer(I4P)                                :: v        !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.allocated(self%nargs)) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store) then
    if (self%is_passed) then
      call tokenize(strin=self%val, delimiter=ARGS_SEP, toks=valsV, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsV(1), pref=pref)) return
      allocate(integer(I8P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsV(v))), knd=1_I8P)
        if (self%error/=0) exit
      enddo
    else ! using default value
      call tokenize(strin=self%def, delimiter=ARGS_SEP, toks=valsD, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsD(1), pref=pref)) return
      allocate(integer(I8P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsD(v))), knd=1_I8P)
        if (self%error/=0) exit
      enddo
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_I8P

  subroutine get_cla_list_varying_I4P(self, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (multiple) value with varying size, integer(I4P).
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(INOUT) :: self     !< CLA data.
  integer(I4P), allocatable,    intent(OUT)   :: val(:)   !< CLA values.
  character(*), optional,       intent(IN)    :: pref     !< Prefixing string.
  integer(I4P)                                :: Nv       !< Number of values.
  character(len=len(self%val)), allocatable   :: valsV(:) !< String array of values based on self%val.
  character(len=len(self%def)), allocatable   :: valsD(:) !< String array of values based on self%def.
  integer(I4P)                                :: v        !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.allocated(self%nargs)) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store) then
    if (self%is_passed) then
      call tokenize(strin=self%val, delimiter=ARGS_SEP, toks=valsV, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsV(1), pref=pref)) return
      allocate(integer(I4P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsV(v))), knd=1_I4P)
        if (self%error/=0) exit
      enddo
    else ! using default value
      call tokenize(strin=self%def, delimiter=ARGS_SEP, toks=valsD, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsD(1), pref=pref)) return
      allocate(integer(I4P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsD(v))), knd=1_I4P)
        if (self%error/=0) exit
      enddo
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_I4P

  subroutine get_cla_list_varying_I2P(self, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (multiple) value with varying size, integer(I2P).
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  integer(I2P), allocatable,    intent(out)   :: val(:)   !< CLA values.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  integer(I4P)                                :: Nv       !< Number of values.
  character(len=len(self%val)), allocatable   :: valsV(:) !< String array of values based on self%val.
  character(len=len(self%def)), allocatable   :: valsD(:) !< String array of values based on self%def.
  integer(I4P)                                :: v        !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.allocated(self%nargs)) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store) then
    if (self%is_passed) then
      call tokenize(strin=self%val, delimiter=ARGS_SEP, toks=valsV, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsV(1), pref=pref)) return
      allocate(integer(I2P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsV(v))), knd=1_I2P)
        if (self%error/=0) exit
      enddo
    else ! using default value
      call tokenize(strin=self%def, delimiter=ARGS_SEP, toks=valsD, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsD(1), pref=pref)) return
      allocate(integer(I2P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsD(v))), knd=1_I2P)
        if (self%error/=0) exit
      enddo
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_I2P

  subroutine get_cla_list_varying_I1P(self, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (multiple) value with varying size, integer(I1P).
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  integer(I1P), allocatable,    intent(out)   :: val(:)   !< CLA values.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  integer(I4P)                                :: Nv       !< Number of values.
  character(len=len(self%val)), allocatable   :: valsV(:) !< String array of values based on self%val.
  character(len=len(self%def)), allocatable   :: valsD(:) !< String array of values based on self%def.
  integer(I4P)                                :: v        !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.allocated(self%nargs)) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store) then
    if (self%is_passed) then
      call tokenize(strin=self%val, delimiter=ARGS_SEP, toks=valsV, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsV(1), pref=pref)) return
      allocate(integer(I1P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsV(v))), knd=1_I1P)
        if (self%error/=0) exit
      enddo
    else ! using default value
      call tokenize(strin=self%def, delimiter=ARGS_SEP, toks=valsD, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsD(1), pref=pref)) return
      allocate(integer(I1P):: val(1:Nv))
      do v=1, Nv
        val(v) = cton(pref=pref, error=self%error, str=trim(adjustl(valsD(v))), knd=1_I1P)
        if (self%error/=0) exit
      enddo
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_I1P

  subroutine get_cla_list_varying_logical(self, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (multiple) value with varying size, logical.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  logical, allocatable,         intent(out)   :: val(:)   !< CLA values.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  integer(I4P)                                :: Nv       !< Number of values.
  character(len=len(self%val)), allocatable   :: valsV(:) !< String array of values based on self%val.
  character(len=len(self%def)), allocatable   :: valsD(:) !< String array of values based on self%def.
  integer(I4P)                                :: v        !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.allocated(self%nargs)) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store) then
    if (self%is_passed) then
      call tokenize(strin=self%val, delimiter=ARGS_SEP, toks=valsV, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsV(1), pref=pref)) return
      allocate(logical:: val(1:Nv))
      do v=1,Nv
        read(valsV(v), *, iostat=self%error)val(v)
        if (self%error/=0) then
          call self%errored(pref=pref, error=ERROR_CASTING_LOGICAL, log_value=valsD(v))
          exit
        endif
      enddo
    else ! using default value
      call tokenize(strin=self%def, delimiter=ARGS_SEP, toks=valsD, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsD(1), pref=pref)) return
      allocate(logical:: val(1:Nv))
      do v=1,Nv
        read(valsD(v), *, iostat=self%error)val(v)
        if (self%error/=0) then
          call self%errored(pref=pref, error=ERROR_CASTING_LOGICAL, log_value=valsD(v))
          exit
        endif
      enddo
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_logical

  subroutine get_cla_list_varying_char(self, val, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (multiple) value with varying size, character.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: self     !< CLA data.
  character(*), allocatable,    intent(out)   :: val(:)   !< CLA values.
  character(*), optional,       intent(in)    :: pref     !< Prefixing string.
  integer(I4P)                                :: Nv       !< Number of values.
  character(len=len(self%val)), allocatable   :: valsV(:) !< String array of values based on self%val.
  character(len=len(self%def)), allocatable   :: valsD(:) !< String array of values based on self%def.
  integer(I4P)                                :: v        !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.self%is_required_passed(pref=pref)) return
  if (.not.allocated(self%nargs)) then
    call self%errored(pref=pref, error=ERROR_NO_LIST)
    return
  endif
  if (self%act==action_store) then
    if (self%is_passed) then
      call tokenize(strin=self%val, delimiter=ARGS_SEP, toks=valsV, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsV(1), pref=pref)) return
      allocate(val(1:Nv))
      do v=1, Nv
        val(v) = trim(adjustl(valsV(v)))
      enddo
    else ! using default value
      call tokenize(strin=self%def, delimiter=ARGS_SEP, toks=valsD, Nt=Nv)
      if (.not.self%check_list_size(Nv=Nv, val=valsD(1), pref=pref)) return
      allocate(val(1:Nv))
      do v=1, Nv
        val(v) = trim(adjustl(valsD(v)))
      enddo
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_varying_char

  elemental subroutine cla_assign_cla(lhs, rhs)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Assignment operator.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(command_line_argument), intent(inout) :: lhs !< Left hand side.
  type(command_line_argument),  intent(in)    :: rhs !< Rigth hand side.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! object members
  call lhs%assign_object(rhs)
  ! command_line_argument members
  if (allocated(rhs%switch   )) lhs%switch        = rhs%switch
  if (allocated(rhs%switch_ab)) lhs%switch_ab     = rhs%switch_ab
  if (allocated(rhs%act      )) lhs%act           = rhs%act
  if (allocated(rhs%def      )) lhs%def           = rhs%def
  if (allocated(rhs%nargs    )) lhs%nargs         = rhs%nargs
  if (allocated(rhs%choices  )) lhs%choices       = rhs%choices
  if (allocated(rhs%val      )) lhs%val           = rhs%val
  if (allocated(rhs%envvar   )) lhs%envvar        = rhs%envvar
                                lhs%is_required   = rhs%is_required
                                lhs%is_positional = rhs%is_positional
                                lhs%position      = rhs%position
                                lhs%is_passed     = rhs%is_passed
                                lhs%is_hidden     = rhs%is_hidden
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine cla_assign_cla

  elemental subroutine finalize(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory when finalizing.
  !---------------------------------------------------------------------------------------------------------------------------------
  type(command_line_argument), intent(inout) :: self !< CLA data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call self%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize
endmodule flap_command_line_argument_t

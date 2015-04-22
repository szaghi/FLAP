!< FLAP, Fortran command Line Arguments Parser for poor people
module Data_Type_Command_Line_Interface
!-----------------------------------------------------------------------------------------------------------------------------------
!< FLAP, Fortran command Line Arguments Parser for poor people
!<{!README-FLAP.md!}
!<
!<### ChangeLog
!<
!<{!ChangeLog-FLAP.md!}
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision                                                                ! Integers and reals precision definition.
USE, intrinsic:: ISO_FORTRAN_ENV, only: stdout=>OUTPUT_UNIT, stderr=>ERROR_UNIT ! Standard output/error logical units.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
type, abstract:: Type_Object
  character(len=:), allocatable:: progname      !< Program name.
  character(len=:), allocatable:: version       !< Program version.
  character(len=:), allocatable:: help          !< Help message.
  character(len=:), allocatable:: description   !< Detailed description.
  character(len=:), allocatable:: license       !< License description.
  character(len=:), allocatable:: authors       !< Authors list.
  integer(I4P)::                  error = 0_I4P !< Error traping flag.
  contains
    procedure:: free_object   !< Free dynamic memory.
    procedure:: errored       !< Trig error occurence and print meaningful message.
    procedure:: assign_object !< Assignment overloading.
endtype Type_Object

type, extends(Type_Object):: Type_Command_Line_Argument
  !< Command line arguments (CLA).
  !<
  !< @note If not otherwise declared the action on CLA value is set to "store" a value.
  private
  character(len=:), allocatable:: switch             !< Switch name.
  character(len=:), allocatable:: switch_ab          !< Abbreviated switch name.
  logical::                       required  =.false. !< Flag for set required argument.
  logical::                       positional=.false. !< Flag for checking if CLA is a positional or a named CLA.
  integer(I4P)::                  position  = 0_I4P  !< Position of positional CLA.
  logical::                       passed    =.false. !< Flag for checking if CLA has been passed to CLI.
  character(len=:), allocatable:: act                !< CLA value action.
  character(len=:), allocatable:: def                !< Default value.
  character(len=:), allocatable:: nargs              !< Number of arguments consumed by CLA.
  character(len=:), allocatable:: choices            !< List (comma separated) of allowable values for the argument.
  character(len=:), allocatable:: val                !< CLA value.
  contains
    ! public methods
    procedure, public:: free          => free_cla             !< Free dynamic memory.
    procedure, public:: check         => check_cla            !< Check CLA data consistency.
    procedure, public:: check_choices => check_choices_cla    !< Check if CLA value is in allowed choices.
    generic,   public:: get           => get_cla,get_cla_list !< Get CLA value(s).
    procedure, public:: print         => print_cla            !< Print CLA data with a pretty format.
    procedure, public:: signature                             !< Get CLA signature for adding to the CLI one.
    ! private methods
    procedure, private:: get_cla                     !< Get CLA (single) value from CLAs list parsed.
    procedure, private:: get_cla_list                !< Get CLA multiple values from CLAs list parsed.
    procedure, private:: assign_cla                  !< CLA assignment overloading.
    generic,   private:: assignment(=) => assign_cla !< CLA assignment overloading.
    final::              finalize_cla                !< Free dynamic memory when finalizing.
endtype Type_Command_Line_Argument

type, extends(Type_Object):: Type_Command_Line_Arguments_Group
  !< Group of CLAs for building nested commands.
  private
  character(len=:), allocatable::                 group               !< Group name (command).
  integer(I4P)::                                  Na          = 0_I4P !< Number of CLA.
  integer(I4P)::                                  Na_required = 0_I4P !< Number of command line arguments that CLI requires.
  integer(I4P)::                                  Na_optional = 0_I4P !< Number of command line arguments that are optional for CLI.
  type(Type_Command_Line_Argument), allocatable:: cla(:)              !< CLA list [1:Na].
  contains
    ! public methods
    procedure, public:: free          => free_clasg          !< Free dynamic memory.
    procedure, public:: init          => init_clasg          !< Initialize CLAs group.
    procedure, public:: check         => check_clasg         !< Check CLAs data consistency.
    procedure, public:: add           => add_cla_clasg       !< Add CLA to CLAs group.
    procedure, public:: passed        => passed_clasg        !< Check if a CLA has been passed.
    procedure, public:: defined       => defined_clasg       !< Check if a CLA has been defined.
    procedure, public:: parse_switch  => parse_switch_clasg  !< Parse a switch checking if it is a defined CLA.
    procedure, public:: print_usage   => print_usage_clasg   !< Print correct usage of CLAs group.
    procedure, public:: print_version => print_version_clasg !< Print version.
    ! private methods
    procedure, private:: assign_clasg                  !< CLAs group assignment overloading.
    generic,   private:: assignment(=) => assign_clasg !< CLAs group assignment overloading.
    final::              finalize_clasg                !< Free dynamic memory when finalizing.
endtype Type_Command_Line_Arguments_Group

type, extends(Type_Object), public:: Type_Command_Line_Interface
  !< Command Line Interface (CLI).
  private
  type(Type_Command_Line_Arguments_Group), allocatable:: clasg(:)            !< CLA list [1:Na].
#ifdef GNU
  character(100  ), allocatable::                        examples(:)         !< Examples of correct usage.
#else
  character(len=:), allocatable::                        examples(:)         !< Examples of correct usage (not work with gfortran).
#endif
  logical::                                              disable_hv = .false.!< Disable automatic 'help' and 'version' CLAs.
  contains
    ! public methods
    procedure, public:: free                                !< Free dynamic memory.
    procedure, public:: init                                !< Initialize CLI.
    procedure, public:: add_group                           !< Add CLAs group CLI.
    procedure, public:: add                                 !< Add CLA to CLI.
    procedure, public:: check                               !< Check CLAs data consistenc.
    procedure, public:: passed                              !< Check if a CLA has been passed.
    procedure, public:: defined                             !< Check if a CLA has been defined.
    procedure, public:: defined_group                       !< Check if a CLAs group has been defined.
    procedure, public:: parse                               !< Parse Command Line Interfaces.
    generic,   public:: get => get_cla_cli,get_cla_list_cli !< Get CLA value(s) from CLAs list parsed.
    procedure, public:: print_usage                         !< Print correct usage of CLI.
    procedure, public:: print_examples                      !< Print examples of correct usage of CLI.
    procedure, public:: print_version                       !< Print version.
    ! private methods
    procedure, private:: get_cla_cli                 !< Get CLA (single) value from CLAs list parsed.
    procedure, private:: get_cla_list_cli            !< Get CLA multiple values from CLAs list parsed.
    procedure, private:: assign_cli                  !< CLI assignment overloading.
    generic,   private:: assignment(=) => assign_cli !< CLI assignment overloading.
    final::              finalize                    !< Free dynamic memory when finalizing.
endtype Type_Command_Line_Interface

integer(I4P),     parameter:: max_val_len        = 1000            !< Maximum number of characters of CLA value.
character(len=*), parameter:: action_store       = 'STORE'         !< CLA that stores a value associated to its switch.
character(len=*), parameter:: action_store_true  = 'STORE_TRUE'    !< CLA that stores .true. without the necessity of a value.
character(len=*), parameter:: action_store_false = 'STORE_FALSE'   !< CLA that stores .false. without the necessity of a value.
character(len=*), parameter:: action_print_help  = 'PRINT_HELP'    !< CLA that print help message.
character(len=*), parameter:: action_print_vers  = 'PRINT_VERSION' !< CLA that print version.
character(len=*), parameter:: args_sep           = '||!||'         !< Arguments separator for multiple valued (list) CLA.
! code errors
integer(I4P), parameter:: error_cla_optional_no_def        = 1  !< Optional CLA without default value.
integer(I4P), parameter:: error_cla_named_no_name          = 2  !< Named CLA without switch name.
integer(I4P), parameter:: error_cla_positional_no_position = 3  !< Positional CLA without position.
integer(I4P), parameter:: error_cla_positional_no_store    = 4  !< Positional CLA without action_store.
integer(I4P), parameter:: error_cla_not_in_choices         = 5  !< CLA value out of a specified choices.
integer(I4P), parameter:: error_cla_missing_required       = 6  !< Missing required CLA.
integer(I4P), parameter:: error_cla_casting_logical        = 7  !< Error casting CLA value to logical type.
integer(I4P), parameter:: error_cla_no_list                = 8  !< Actual CLA is not list-values.
integer(I4P), parameter:: error_cla_nargs_insufficient     = 9  !< Multi-valued CLA with insufficient arguments.
integer(I4P), parameter:: error_cla_unknown                = 10 !< Unknown CLA (switch name).
integer(I4P), parameter:: error_clasg_consistency          = 11 !< CLAs group consistency error.
integer(I4P), parameter:: error_cli_missing_cla            = 12 !< CLA not found in CLI.
integer(I4P), parameter:: error_cli_missing_selection_cla  = 13 !< CLA selection in CLI failing.
integer(I4P), parameter:: error_cli_too_few_clas           = 14 !< Insufficient arguments for CLI.
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  ! auxiliary procedures
  elemental function Upper_Case(string)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting the lower case characters of a string to upper case one.
  !<
  !< @note This is taken form Lib_Strings.f90: chek into it for any updates.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN):: string                                        !< String to be converted.
  character(len=len(string))::   Upper_Case                                    !< Converted string.
  integer::                      n1                                            !< Characters counter.
  integer::                      n2                                            !< Characters counter.
  character(len=26), parameter:: upper_alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' !< Upper case alphabet.
  character(len=26), parameter:: lower_alphabet = 'abcdefghijklmnopqrstuvwxyz' !< Lower case alphabet.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  Upper_Case = string
  do n1=1,len(string)
    n2 = index(lower_alphabet,string(n1:n1))
    if (n2>0) Upper_Case(n1:n1) = upper_alphabet(n2:n2)
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Upper_Case

  pure subroutine tokenize(strin,delimiter,Nt,toks)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for tokenizing a string in order to parse it.
  !<
  !< @note The dummy array containing tokens must allocatable and its character elements must have the same length of the input
  !< string. If the length of the delimiter is higher than the input string one then the output tokens array is allocated with
  !< only one element set to char(0).
  !<
  !< @note This is taken form Lib_Strings.f90: chek into it for any updates.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*),          intent(IN)::               strin     !< String to be tokenized.
  character(len=*),          intent(IN)::               delimiter !< Delimiter of tokens.
  integer(I4P),              intent(OUT), optional::    Nt        !< Number of tokens.
  character(len=len(strin)), intent(OUT), allocatable:: toks(:)   !< Tokens.
  character(len=len(strin))::                           strsub    !< Temporary string.
  integer(I4P)::                                        dlen      !< Delimiter length.
  integer(I4P)::                                        c         !< Counter.
  integer(I4P)::                                        n         !< Counter.
  integer(I4P)::                                        t         !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! initialization
  if (allocated(toks)) deallocate(toks)
  strsub = strin
  dlen = len(delimiter)
  if (dlen>len(strin)) then
    allocate(toks(1:1)) ; toks(1) = char(0) ; if (present(Nt)) Nt = 1 ; return
  endif
  ! computing the number of tokens
  n = 1
  do c=1,len(strsub)-dlen ! loop over string characters
    if (strsub(c:c+dlen-1)==delimiter) n = n + 1
  enddo
  allocate(toks(1:n))
  ! tokenization
  do t=1,n ! loop over tokens
    c = index(strsub,delimiter)
    if (c>0) then
      toks(t) = strsub(1:c-1)
      strsub = strsub(c+dlen:)
    else
      toks(t) = strsub
    endif
  enddo
  if (present(Nt)) Nt = n
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine tokenize

  ! Type_Object procedures
  elemental subroutine free_object(obj)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Object), intent(INOUT):: obj !< Object data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(obj%progname   )) deallocate(obj%progname   )
  if (allocated(obj%version    )) deallocate(obj%version    )
  if (allocated(obj%help       )) deallocate(obj%help       )
  if (allocated(obj%description)) deallocate(obj%description)
  if (allocated(obj%license    )) deallocate(obj%license    )
  if (allocated(obj%authors    )) deallocate(obj%authors    )
  obj%error = 0_I4P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free_object

  subroutine errored(obj,pref,Na,switch,val_str,log_value,a1,a2,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Trig error occurence and print meaningful message.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Object),     intent(INOUT):: obj       !< Object data.
  character(*), optional, intent(IN)::    pref      !< Prefixing string.
  integer(I4P), optional, intent(IN)::    Na        !< Number of CLA passed.
  character(*), optional, intent(IN)::    switch    !< CLA switch name.
  character(*), optional, intent(IN)::    val_str   !< Value string.
  character(*), optional, intent(IN)::    log_value !< Logical value to be casted.
  integer(I4P), optional, intent(IN)::    a1,a2     !< CLAs group inconsistent indexes.
  integer(I4P),           intent(IN)::    error     !< Error occurred.
  character(len=:), allocatable::         prefd     !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  obj%error = error
  if (obj%error/=0) then
    prefd = '' ; if (present(pref)) prefd = pref
    select type(obj)
    class is(Type_Command_Line_Argument)
      select case(obj%error)
      case(error_cla_optional_no_def)
        if (obj%positional) then
          write(stderr,'(A)')prefd//obj%progname//': error: "'//trim(str(n=obj%position))//&
                             '-th" optional CLA has not a default value!'
        else
          write(stderr,'(A)')prefd//obj%progname//': error: optional "'//obj%switch//'" CLA has not a default value!'
        endif
      case(error_cla_named_no_name)
        write(stderr,'(A)')prefd//obj%progname//': error: a non positional CLA must have a switch name!'
      case(error_cla_positional_no_position)
        write(stderr,'(A)')prefd//obj%progname//': error: a positional CLA must have a position number different from 0!'
      case(error_cla_positional_no_store)
        write(stderr,'(A)')prefd//obj%progname//': error: a positional CLA must have action set to "'//action_store//'"!'
      case(error_cla_not_in_choices)
        if (obj%positional) then
          write(stderr,'(A)')prefd//obj%progname//': error: "'//trim(str(n=obj%position))//'-th" CLA value must be chosen in:'
          write(stderr,'(A)')prefd//' ('//obj%choices//') but "'//trim(val_str)//'" has been passed!'
        else
          write(stderr,'(A)')prefd//obj%progname//': error: "'//obj%switch//'" CLA value must be chosen in:'
          write(stderr,'(A)')prefd//' ('//obj%choices//') but "'//trim(val_str)//'" has been passed!'
        endif
      case(error_cla_missing_required)
        if (.not.obj%positional) then
          write(stderr,'(A)')prefd//obj%progname//': error: "'//trim(adjustl(obj%switch))//'" CLA is required!'
        else
          write(stderr,'(A)')prefd//obj%progname//': error: "'//trim(str(.true.,obj%position))//'-th" CLA is required!'
        endif
      case(error_cla_casting_logical)
        write(stderr,'(A)')prefd//obj%progname//': error: cannot convert "'//log_value//'" of CLA "'//obj%switch//&
                           '" to logical type!'
      case(error_cla_no_list)
        if (.not.obj%positional) then
          write(stderr,'(A)')prefd//obj%progname//': error: "'//trim(adjustl(obj%switch))//'" CLA has not "nargs" value'//&
                             ' but an array has been passed to "get" method!'
        else
          write(stderr,'(A)')prefd//obj%progname//': error: "'//trim(str(.true.,obj%position))//'-th" CLA '//&
                                    'has not "nargs" value but an array has been passed to "get" method!'
        endif
      case(error_cla_nargs_insufficient)
        if (.not.obj%positional) then
          write(stderr,'(A)')prefd//obj%progname//': error: "'//trim(adjustl(obj%switch))//'" CLA requires '//&
            trim(adjustl(obj%nargs))//' arguments but no enough ones remain!'
        else
          write(stderr,'(A)')prefd//obj%progname//': error: "'//trim(str(.true.,obj%position))//'-th" CLA requires '//&
            trim(adjustl(obj%nargs))//' arguments but no enough ones remain!'
        endif
      case(error_cla_unknown)
        write(stderr,'(A)')prefd//obj%progname//' error: switch "'//trim(adjustl(switch))//'" is unknown!'
      endselect

    class is(Type_Command_Line_Arguments_Group)
      select case(obj%error)
      case(error_clasg_consistency)
        if (allocated(obj%group)) then
          write(stderr,'(A)')prefd//obj%progname//': error: group (command) name: "'//obj%group//'" CLAs consistency error:'
        else
          write(stderr,'(A)')prefd//obj%progname//': error: CLAs consistency error:'
        endif
        write(stderr,'(A)')prefd//' "'//trim(str(.true.,a1))//'-th" CLA has the same switch or abbreviated switch of "'&
                           //trim(str(.true.,a2))//'-th" CLA:'
        write(stderr,'(A)')prefd//' CLA('//trim(str(.true.,a1)) //') switches = '//obj%cla(a1)%switch //' '//&
                           obj%cla(a1)%switch_ab
        write(stderr,'(A)')prefd//' CLA('//trim(str(.true.,a2))//') switches = '//obj%cla(a2)%switch//' '//&
                           obj%cla(a2)%switch_ab
      endselect

    class is(Type_Command_Line_Interface)
      select case(obj%error)
      case(error_cli_missing_cla)
        write(stderr,'(A)')prefd//obj%progname//': error: there is no CLA into CLI named "'//trim(adjustl(switch))//'"'
      case(error_cli_missing_selection_cla)
        write(stderr,'(A)')prefd//obj%progname//': error: to get a CLA value one of switch "name" or "position" must be provided!'
      case(error_cli_too_few_clas)
        ! write(stderr,'(A)')prefd//obj%progname//': error: too few arguments ('//trim(str(.true.,Na))//')'//&
                           ! ' respect the required ('//trim(str(.true.,obj%Na_required))//')'
      endselect
    endselect
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine errored

  elemental subroutine assign_object(lhs,rhs)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Object), intent(INOUT):: lhs !< Left hand side.
  class(Type_Object), intent(IN)::    rhs !< Rigth hand side.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! Type_Object members
  if (allocated(rhs%progname   )) lhs%progname    = rhs%progname
  if (allocated(rhs%version    )) lhs%version     = rhs%version
  if (allocated(rhs%help       )) lhs%help        = rhs%help
  if (allocated(rhs%description)) lhs%description = rhs%description
  if (allocated(rhs%license    )) lhs%license     = rhs%license
  if (allocated(rhs%authors    )) lhs%authors     = rhs%authors
                                  lhs%error       = rhs%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_object

  ! Type_Command_Line_Argument procedures
  elemental subroutine free_cla(cla)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla !< CLA data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! Type_Object members
  call cla%free_object
  ! Type_Command_Line_Argument members
  if (allocated(cla%switch   )) deallocate(cla%switch   )
  if (allocated(cla%switch_ab)) deallocate(cla%switch_ab)
  if (allocated(cla%act      )) deallocate(cla%act      )
  if (allocated(cla%def      )) deallocate(cla%def      )
  if (allocated(cla%nargs    )) deallocate(cla%nargs    )
  if (allocated(cla%choices  )) deallocate(cla%choices  )
  if (allocated(cla%val      )) deallocate(cla%val      )
  cla%required   = .false.
  cla%positional = .false.
  cla%position   =  0_I4P
  cla%passed     = .false.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free_cla

  elemental subroutine finalize_cla(cla)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory when finalizing.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Command_Line_Argument), intent(INOUT):: cla !< CLA data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call cla%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize_cla

  subroutine check_cla(cla,pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check CLA data consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla   !< CLA data.
  character(*), optional,            intent(IN)::    pref  !< Prefixing string.
  character(len=:), allocatable::                    prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  if ((.not.cla%required).and.(.not.allocated(cla%def))) then
    call cla%errored(pref=prefd,error=error_cla_optional_no_def)
  endif
  if ((.not.cla%positional).and.(.not.allocated(cla%switch))) then
    call cla%errored(pref=prefd,error=error_cla_named_no_name)
  elseif ((cla%positional).and.(cla%position==0_I4P)) then
    call cla%errored(pref=prefd,error=error_cla_positional_no_position)
  elseif ((cla%positional).and.(cla%act/=action_store)) then
    call cla%errored(pref=prefd,error=error_cla_positional_no_store)
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_cla

  subroutine check_choices_cla(cla,val,pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if CLA value is in allowed choices.
  !<
  !< @note This procedure can be called if and only if cla%choices has been allocated.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla     !< CLA data.
  class(*),                          intent(IN)::    val     !< CLA value.
  character(*), optional,            intent(IN)::    pref    !< Prefixing string.
  character(len=:), allocatable::                    prefd   !< Prefixing string.
  character(len(cla%choices)), allocatable::         toks(:) !< Tokens for parsing choices list.
  integer(I4P)::                                     Nc      !< Number of choices.
  logical::                                          val_in  !< Flag for checking if val is in the choosen range.
  character(len=:), allocatable::                    val_str !< Value in string form.
  character(len=:), allocatable::                    tmp     !< Temporary string for avoiding GNU gfrotran bug.
  integer(I4P)::                                     c       !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  val_in = .false.
  val_str = ''
  tmp = cla%choices
  call tokenize(strin=tmp,delimiter=',',Nt=Nc,toks=toks)
  select type(val)
#ifdef r16p
  type is(real(R16P))
    val_str = str(n=val)
    do c=1,Nc
      if (val==cton(str=trim(adjustl(toks(c))),knd=1._R16P)) val_in = .true.
    enddo
#endif
  type is(real(R8P))
    val_str = str(n=val)
    do c=1,Nc
      if (val==cton(str=trim(adjustl(toks(c))),knd=1._R8P)) val_in = .true.
    enddo
  type is(real(R4P))
    val_str = str(n=val)
    do c=1,Nc
      if (val==cton(str=trim(adjustl(toks(c))),knd=1._R4P)) val_in = .true.
    enddo
  type is(integer(I8P))
    val_str = str(n=val)
    do c=1,Nc
      if (val==cton(str=trim(adjustl(toks(c))),knd=1_I8P)) val_in = .true.
    enddo
  type is(integer(I4P))
    val_str = str(n=val)
    do c=1,Nc
      if (val==cton(str=trim(adjustl(toks(c))),knd=1_I4P)) val_in = .true.
    enddo
  type is(integer(I2P))
    val_str = str(n=val)
    do c=1,Nc
      if (val==cton(str=trim(adjustl(toks(c))),knd=1_I2P)) val_in = .true.
    enddo
  type is(integer(I1P))
    val_str = str(n=val)
    do c=1,Nc
      if (val==cton(str=trim(adjustl(toks(c))),knd=1_I1P)) val_in = .true.
    enddo
  type is(character(*))
    val_str = val
    do c=1,Nc
      if (val==toks(c)) val_in = .true.
    enddo
  endselect
  if (.not.val_in) then
    prefd = '' ; if (present(pref)) prefd = pref
    call cla%errored(pref=prefd,error=error_cla_not_in_choices,val_str=val_str)
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_choices_cla

  subroutine get_cla(cla,pref,val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (single) value.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla     !< CLA data.
  character(*), optional,            intent(IN)::    pref    !< Prefixing string.
  class(*),                          intent(INOUT):: val     !< CLA value.
  character(len=:), allocatable::                    prefd   !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  if (((.not.cla%passed).and.cla%required).or.((.not.cla%passed).and.(.not.allocated(cla%def)))) then
    call cla%errored(pref=prefd,error=error_cla_missing_required)
    return
  endif
  if (cla%act==action_store) then
    if (cla%passed) then
      select type(val)
#ifdef r16p
      type is(real(R16P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%val)),knd=1._R16P)
#endif
      type is(real(R8P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%val)),knd=1._R8P)
      type is(real(R4P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%val)),knd=1._R4P)
      type is(integer(I8P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%val)),knd=1_I8P)
      type is(integer(I4P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%val)),knd=1_I4P)
      type is(integer(I2P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%val)),knd=1_I2P)
      type is(integer(I1P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%val)),knd=1_I1P)
      type is(logical)
        read(cla%val,*,iostat=cla%error)val
        if (cla%error/=0) call cla%errored(pref=prefd,error=error_cla_casting_logical,log_value=cla%val)
      type is(character(*))
        val = cla%val
      endselect
    else ! using default value
      select type(val)
#ifdef r16p
      type is(real(R16P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%def)),knd=1._R16P)
#endif
      type is(real(R8P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%def)),knd=1._R8P)
      type is(real(R4P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%def)),knd=1._R4P)
      type is(integer(I8P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%def)),knd=1_I8P)
      type is(integer(I4P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%def)),knd=1_I4P)
      type is(integer(I2P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%def)),knd=1_I2P)
      type is(integer(I1P))
        val = cton(pref=prefd,error=cla%error,str=trim(adjustl(cla%def)),knd=1_I1P)
      type is(logical)
        read(cla%def,*,iostat=cla%error)val
        if (cla%error/=0) call cla%errored(pref=prefd,error=error_cla_casting_logical,log_value=cla%def)
      type is(character(*))
        val = cla%def
      endselect
    endif
    if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val,pref=prefd)
  elseif (cla%act==action_store_true) then
    if (cla%passed) then
      select type(val)
      type is(logical)
        val = .true.
      endselect
    else
      select type(val)
      type is(logical)
        read(cla%def,*)val
      endselect
    endif
  elseif (cla%act==action_store_false) then
    if (cla%passed) then
      select type(val)
      type is(logical)
        val = .false.
      endselect
    else
      select type(val)
      type is(logical)
        read(cla%def,*)val
      endselect
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla

  subroutine get_cla_list(cla,pref,val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (multiple) value.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla      !< CLA data.
  character(*), optional,            intent(IN)::    pref     !< Prefixing string.
  class(*),                          intent(INOUT):: val(1:)  !< CLA values.
  integer(I4P)::                                     Nv       !< Number of values.
  character(len=len(cla%val)), allocatable::         valsV(:) !< String array of values based on cla%val.
  character(len=len(cla%def)), allocatable::         valsD(:) !< String array of values based on cla%def.
  character(len=:), allocatable::                    prefd    !< Prefixing string.
  integer(I4P)::                                     v        !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  if (((.not.cla%passed).and.cla%required).or.((.not.cla%passed).and.(.not.allocated(cla%def)))) then
    call cla%errored(pref=prefd,error=error_cla_missing_required)
    return
  endif
  if (.not.allocated(cla%nargs)) then
    call cla%errored(pref=prefd,error=error_cla_no_list)
    return
  endif
  if (cla%act==action_store) then
    if (cla%passed) then
      call tokenize(strin=cla%val,delimiter=args_sep,Nt=Nv,toks=valsV)
      select type(val)
#ifdef r16p
      type is(real(R16P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsV(v))),knd=1._R16P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
#endif
      type is(real(R8P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsV(v))),knd=1._R8P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      type is(real(R4P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsV(v))),knd=1._R4P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      type is(integer(I8P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsV(v))),knd=1_I8P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      type is(integer(I4P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsV(v))),knd=1_I4P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      type is(integer(I2P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsV(v))),knd=1_I2P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      type is(integer(I1P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsV(v))),knd=1_I1P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      type is(logical)
        do v=1,Nv
          read(valsV(v),*,iostat=cla%error)val(v)
          if (cla%error/=0) then
            call cla%errored(pref=prefd,error=error_cla_casting_logical,log_value=valsD(v))
            exit
          endif
        enddo
      type is(character(*))
        do v=1,Nv
          val(v)=valsV(v)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      endselect
    else ! using default value
      call tokenize(strin=cla%def,delimiter=' ',Nt=Nv,toks=valsD)
      select type(val)
#ifdef r16p
      type is(real(R16P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsD(v))),knd=1._R16P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (error/=0) exit
        enddo
#endif
      type is(real(R8P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsD(v))),knd=1._R8P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      type is(real(R4P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsD(v))),knd=1._R4P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      type is(integer(I8P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsD(v))),knd=1_I8P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      type is(integer(I4P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsD(v))),knd=1_I4P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      type is(integer(I2P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsD(v))),knd=1_I2P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      type is(integer(I1P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=cla%error,str=trim(adjustl(valsD(v))),knd=1_I1P)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      type is(logical)
        do v=1,Nv
          read(valsD(v),*,iostat=cla%error)val(v)
          if (cla%error/=0) then
            call cla%errored(pref=prefd,error=error_cla_casting_logical,log_value=valsD(v))
            exit
          endif
        enddo
      type is(character(*))
        do v=1,Nv
          val(v)=valsD(v)
          if (allocated(cla%choices).and.cla%error==0) call cla%check_choices(val=val(v),pref=prefd)
          if (cla%error/=0) exit
        enddo
      endselect
    endif
  elseif (cla%act==action_store_true) then
    if (cla%passed) then
      select type(val)
      type is(logical)
        val = .true.
      endselect
    else
      call tokenize(strin=cla%def,delimiter=' ',Nt=Nv,toks=valsD)
      select type(val)
      type is(logical)
        do v=1,Nv
          read(valsD(v),*)val(v)
        enddo
      endselect
    endif
  elseif (cla%act==action_store_false) then
    if (cla%passed) then
      select type(val)
      type is(logical)
        val = .false.
      endselect
    else
      call tokenize(strin=cla%def,delimiter=' ',Nt=Nv,toks=valsD)
      select type(val)
      type is(logical)
        do v=1,Nv
          read(valsD(v),*)val(v)
        enddo
      endselect
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list

  subroutine print_cla(cla,pref,iostat,iomsg,unit)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Print CLA data with a pretty format.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(IN)::  cla     !< CLA data.
  character(*), optional,            intent(IN)::  pref    !< Prefixing string.
  integer(I4P), optional,            intent(OUT):: iostat  !< IO error.
  character(*), optional,            intent(OUT):: iomsg   !< IO error message.
  integer(I4P),                      intent(IN)::  unit    !< Logic unit.
  character(len=:), allocatable::                  prefd   !< Prefixing string.
  integer(I4P)::                                   iostatd !< IO error.
  character(500)::                                 iomsgd  !< Temporary variable for IO error message.
  character(len=:), allocatable::                  sig     !< CLA signature.
  integer(I4P)::                                   nargs   !< Number of arguments consumed by CLA.
  integer(I4P)::                                   a       !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  if (cla%act==action_store) then
    if (.not.cla%positional) then
      if (allocated(cla%nargs)) then
        sig = ''
        select case(cla%nargs)
        case('+') ! not yet implemented
        case('*') ! not yet implemented
        case default
          nargs = cton(str=trim(adjustl(cla%nargs)),knd=1_I4P)
          do a=1,nargs
            sig = sig//' value#'//trim(str(.true.,a))
          enddo
        endselect
        if (trim(adjustl(cla%switch))/=trim(adjustl(cla%switch_ab))) then
          sig = '   '//trim(adjustl(cla%switch))//sig//', '//trim(adjustl(cla%switch_ab))//sig
        else
          sig = '   '//trim(adjustl(cla%switch))//sig
        endif
      else
        if (trim(adjustl(cla%switch))/=trim(adjustl(cla%switch_ab))) then
          sig = '   '//trim(adjustl(cla%switch))//' value, '//trim(adjustl(cla%switch_ab))//' value'
        else
          sig = '   '//trim(adjustl(cla%switch))//' value'
        endif
      endif
      if (allocated(cla%choices)) then
        sig = sig//', value in: ('//cla%choices//')'
      endif
    else
      sig = '   value'
      if (allocated(cla%choices)) then
        sig = sig//', value in: ('//cla%choices//')'
      endif
    endif
  else
    if (trim(adjustl(cla%switch))/=trim(adjustl(cla%switch_ab))) then
      sig = '   '//trim(adjustl(cla%switch))//', '//trim(adjustl(cla%switch_ab))
    else
      sig = '   '//trim(adjustl(cla%switch))
    endif
  endif
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)prefd//sig
  sig = '       '//trim(adjustl(cla%help))
  if (cla%positional) then
    sig = sig//'; '//trim(str(.true.,cla%position))//'-th positional CLA'
  endif
  if (cla%required) then
    sig = sig//'; required'
  else
    if (cla%def /= '') then
      sig = sig//'; optional, default value '//trim(adjustl(cla%def))
    else
      sig = sig//'; optional'
    endif
  endif
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)prefd//sig
  if (present(iostat)) iostat = iostatd
  if (present(iomsg))  iomsg  = iomsgd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine print_cla

  function signature(cla) result(signd)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA signature for adding to the CLI one.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(IN):: cla   !< CLA data.
  character(len=:), allocatable::                 signd !< Temporary CLI signature.
  integer(I4P)::                                  nargs !< Number of arguments consumed by CLA.
  integer(I4P)::                                  a     !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (cla%act==action_store) then
    if (.not.cla%positional) then
      if (allocated(cla%nargs)) then
        select case(cla%nargs)
        case('+')
          signd = ' value#1 [value#2 value#3...]'
        case('*') ! not yet implemented
          signd = ' [value#1 value#2 value#3...]'
        case default
          nargs = cton(str=trim(adjustl(cla%nargs)),knd=1_I4P)
          signd = ''
          do a=1,nargs
            signd = signd//' value#'//trim(str(.true.,a))
          enddo
        endselect
      else
        signd = ' value'
      endif
      if (cla%required) then
        signd = ' '//trim(adjustl(cla%switch))//signd
      else
        signd = ' ['//trim(adjustl(cla%switch))//signd//']'
      endif
    else
      if (cla%required) then
        signd = ' value'
      else
        signd = ' [value]'
      endif
    endif
  else
    if (cla%required) then
      signd = ' '//trim(adjustl(cla%switch))
    else
      signd = ' ['//trim(adjustl(cla%switch))//']'
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction signature

  elemental subroutine assign_cla(lhs,rhs)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: lhs !< Left hand side.
  type(Type_Command_Line_Argument),  intent(IN)::    rhs !< Rigth hand side.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! Type_Object members
  call lhs%assign_object(rhs)
  ! Type_Command_Line_Argument members
  if (allocated(rhs%switch   )) lhs%switch     = rhs%switch
  if (allocated(rhs%switch_ab)) lhs%switch_ab  = rhs%switch_ab
  if (allocated(rhs%act      )) lhs%act        = rhs%act
  if (allocated(rhs%def      )) lhs%def        = rhs%def
  if (allocated(rhs%nargs    )) lhs%nargs      = rhs%nargs
  if (allocated(rhs%choices  )) lhs%choices    = rhs%choices
  if (allocated(rhs%val      )) lhs%val        = rhs%val
                                lhs%required   = rhs%required
                                lhs%positional = rhs%positional
                                lhs%position   = rhs%position
                                lhs%passed     = rhs%passed
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_cla

  ! Type_Command_Line_Arguments_Group procedures
  elemental subroutine free_clasg(clasg)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Arguments_Group), intent(INOUT):: clasg !< CLAs group data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! Type_Object members
  call clasg%free_object
  ! Type_Command_Line_Arguments_Group members
  if (allocated(clasg%group)) deallocate(clasg%group)
  if (allocated(clasg%cla)) then
    call clasg%cla%free
    deallocate(clasg%cla)
  endif
  clasg%Na          = 0_I4P
  clasg%Na_required = 0_I4P
  clasg%Na_optional = 0_I4P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free_clasg

  elemental subroutine finalize_clasg(clasg)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory when finalizing.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Command_Line_Arguments_Group), intent(INOUT):: clasg !< CLAs group data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call clasg%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize_clasg

  pure subroutine init_clasg(clasg,progname,version,group,help,description,license,authors)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for initializing CLI.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Arguments_Group), intent(INOUT):: clasg       !< CLAs group data.
  character(*), optional,                   intent(IN)::    progname    !< Program name.
  character(*), optional,                   intent(IN)::    version     !< Program version.
  character(*), optional,                   intent(IN)::    help        !< Help message introducing the CLI usage.
  character(*), optional,                   intent(IN)::    description !< Detailed description message introducing the program.
  character(*), optional,                   intent(IN)::    license     !< License description.
  character(*), optional,                   intent(IN)::    authors     !< Authors list.
  character(*), optional,                   intent(IN)::    group       !< Group name (command).
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call clasg%free
  clasg%progname    = 'program' ; if (present(progname   )) clasg%progname    = progname
  clasg%version     = 'unknown' ; if (present(version    )) clasg%version     = version
  clasg%help        = 'usage:'  ; if (present(help       )) clasg%help        = help
  clasg%description = ''        ; if (present(description)) clasg%description = description
  clasg%license     = ''        ; if (present(license    )) clasg%license     = license
  clasg%authors     = ''        ; if (present(authors    )) clasg%authors     = authors
                                  if (present(group      )) clasg%group       = group
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine init_clasg

  subroutine check_clasg(clasg,pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check CLA data consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Arguments_Group), intent(INOUT):: clasg !< CLAs group data.
  character(*), optional,                   intent(IN)::    pref  !< Prefixing string.
  character(len=:), allocatable::                           prefd !< Prefixing string.
  integer(I4P)::                                            a,aa  !< Counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  ! verifing if CLAs switches are unique
  CLA_unique: do a=1,clasg%Na
    if (.not.clasg%cla(a)%positional) then
      do aa=1,clasg%Na
        if ((a/=aa).and.(.not.clasg%cla(aa)%positional)) then
          if ((clasg%cla(a)%switch==clasg%cla(aa)%switch   ).or.(clasg%cla(a)%switch_ab==clasg%cla(aa)%switch   ).or.&
              (clasg%cla(a)%switch==clasg%cla(aa)%switch_ab).or.(clasg%cla(a)%switch_ab==clasg%cla(aa)%switch_ab)) then
            call clasg%errored(pref=prefd,error=error_clasg_consistency,a1=a,a2=aa)
            exit CLA_unique
          endif
        endif
      enddo
    endif
  enddo CLA_unique
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_clasg

  subroutine add_cla_clasg(clasg,pref,cla)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Add CLA to CLAs list.
  !<
  !< @note If not otherwise declared the action on CLA value is set to "store" a value that must be passed after the switch name
  !< or directly passed in case of positional CLA.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Arguments_Group), intent(INOUT):: clasg           !< CLAs group data.
  character(*), optional,                   intent(IN)::    pref            !< Prefixing string.
  type(Type_Command_Line_Argument),         intent(IN)::    cla             !< CLA data.
  type(Type_Command_Line_Argument), allocatable::           cla_list_new(:) !< New (extended) CLA list.
  character(len=:), allocatable::                           prefd           !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (clasg%Na>0_I4P) then
    if (.not.cla%positional) then
      allocate(cla_list_new(1:clasg%Na+1))
      cla_list_new(1:clasg%Na)=clasg%cla
      cla_list_new(clasg%Na+1)=cla
    else
      allocate(cla_list_new(1:clasg%Na+1))
      cla_list_new(1:cla%position-1)=clasg%cla(1:cla%position-1)
      cla_list_new(cla%position)=cla
      cla_list_new(cla%position+1:clasg%Na+1)=clasg%cla(cla%position:clasg%Na)
    endif
  else
    allocate(cla_list_new(1:1))
    cla_list_new(1)=cla
  endif
  call move_alloc(from=cla_list_new,to=clasg%cla)
  clasg%Na = clasg%Na + 1
  if (cla%required) then
    clasg%Na_required = clasg%Na_required + 1
  else
    clasg%Na_optional = clasg%Na_optional + 1
  endif
  if (allocated(cla_list_new)) deallocate(cla_list_new)
  prefd = '' ; if (present(pref)) prefd = pref
  call clasg%check(pref=prefd)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add_cla_clasg

  pure function passed_clasg(clasg,switch,position) result(passed)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if a CLA has been passed.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Arguments_Group), intent(IN):: clasg    !< CLAs group data.
  character(*), optional,                   intent(IN):: switch   !< Switch name.
  integer(I4P), optional,                   intent(IN):: position !< Position of positional CLA.
  logical::                                              passed   !< Check if a CLA has been passed.
  integer(I4P)::                                         a        !< CLA counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  passed = .false.
  if (clasg%Na>0) then
    if (present(switch)) then
      do a=1,clasg%Na
        if ((clasg%cla(a)%switch==switch).or.(clasg%cla(a)%switch_ab==switch)) then
          passed = clasg%cla(a)%passed
          exit
        endif
      enddo
    elseif (present(position)) then
      passed = clasg%cla(position)%passed
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction passed_clasg

  pure function defined_clasg(clasg,switch) result(defined)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if a CLA has been defined.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Arguments_Group), intent(IN):: clasg   !< CLAs group data.
  character(*),                             intent(IN):: switch  !< Switch name.
  logical::                                              defined !< Check if a CLA has been defined.
  integer(I4P)::                                         a       !< CLA counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  defined = .false.
  if (clasg%Na>0) then
    do a=1,clasg%Na
      if ((clasg%cla(a)%switch==switch).or.(clasg%cla(a)%switch_ab==switch)) then
        defined = .true.
        exit
      endif
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction defined_clasg

  subroutine parse_switch_clasg(clasg,pref,Na,switch,arg,found)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Parse a switch checking if it is a defined CLA.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Arguments_Group), intent(INOUT):: clasg   !< CLAs group data.
  character(*), optional,                   intent(IN)::    pref    !< Prefixing string.
  integer(I4P),                             intent(IN)::    Na      !< Number of arguments actually passed.
  character(*),                             intent(IN)::    switch  !< Switch name.
  integer(I4P),                             intent(INOUT):: arg     !< Actual argument number.
  logical,                                  intent(OUT)::   found   !< Flag for checking if switch is a defined CLA.
  integer(I4P)::                                            nargs   !< Number of arguments consumed by a CLA.
  character(max_val_len)::                                  val     !< Switch value.
  integer(I4P)::                                            a,aa    !< Counters.
  character(len=:), allocatable::                           prefd   !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  found = .false.
  do a=1,clasg%Na
    if (.not.clasg%cla(a)%positional) then
      if (trim(adjustl(clasg%cla(a)%switch   ))==trim(adjustl(switch)).or.&
          trim(adjustl(clasg%cla(a)%switch_ab))==trim(adjustl(switch))) then
        if (clasg%cla(a)%act==action_store) then
          if (allocated(clasg%cla(a)%nargs)) then
            clasg%cla(a)%val = ''
            select case(clasg%cla(a)%nargs)
            case('+') ! not yet implemented
            case('*') ! not yet implemented
            case default
              nargs = cton(str=trim(adjustl(clasg%cla(a)%nargs)),knd=1_I4P)
              if (arg+nargs>Na) then
                call clasg%cla(a)%errored(pref=prefd,error = error_cla_nargs_insufficient)
                clasg%error = clasg%cla(a)%error
              endif
              do aa=arg+nargs,arg+1,-1 ! decreasing loop due to gfortran bug
                call get_command_argument(aa,val)
                clasg%cla(a)%val = trim(adjustl(val))//args_sep//trim(clasg%cla(a)%val) ! decreasing loop due to gfortran bug
              enddo
              arg = arg + nargs
            endselect
          else
            arg = arg + 1
            call get_command_argument(arg,val)
            clasg%cla(a)%val = trim(adjustl(val))
          endif
        elseif (clasg%cla(a)%act==action_print_help) then
          call clasg%print_usage(pref=prefd)
        elseif (clasg%cla(a)%act==action_print_vers) then
          call clasg%print_version(pref=prefd)
        endif
        clasg%cla(a)%passed = .true.
        found = .true.
        exit
      endif
    endif
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine parse_switch_clasg

  subroutine print_usage_clasg(clasg,pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Print correct usage of CLAs group.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Arguments_Group), intent(IN):: clasg         !< CLAs group data.
  character(*), optional,                   intent(IN):: pref          !< Prefixing string.
  character(len=:), allocatable::                        cla_sign      !< Signature of current CLA.
  character(len=:), allocatable::                        cla_list_sign !< Complete signature of CLA list.
  integer(I4P)::                                         a             !< Counters.
  character(len=:), allocatable::                        prefd         !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  cla_list_sign = clasg%progname ; if (allocated(clasg%group)) cla_list_sign = clasg%progname//' '//clasg%group
  do a=1,clasg%Na
    cla_sign = clasg%cla(a)%signature()
    cla_list_sign = cla_list_sign//cla_sign
  enddo
  write(stdout,'(A)')prefd//clasg%help//' '//cla_list_sign
  if (clasg%Na_required>0) then
    write(stdout,'(A)')
    write(stdout,'(A)')prefd//' Required options:'
    do a=1,clasg%Na
      if (clasg%cla(a)%required) call clasg%cla(a)%print(pref=prefd,unit=stdout)
    enddo
  endif
  if (clasg%Na_optional>0) then
    write(stdout,'(A)')
    write(stdout,'(A)')prefd//' Optional options:'
    do a=1,clasg%Na
      if (.not.clasg%cla(a)%required) call clasg%cla(a)%print(pref=prefd,unit=stdout)
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine print_usage_clasg

  subroutine print_version_clasg(clasg,pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Print version.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Arguments_Group), intent(IN):: clasg !< CLAs group data.
  character(*), optional,                   intent(IN):: pref  !< Prefixing string.
  character(len=:), allocatable::                        prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  write(stdout,'(A)')prefd//' '//clasg%progname//' version '//clasg%version
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine print_version_clasg

  elemental subroutine assign_clasg(lhs,rhs)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Arguments_Group), intent(INOUT):: lhs !< Left hand side.
  type(Type_Command_Line_Arguments_Group),  intent(IN)::    rhs !< Right hand side.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! Type_Object members
  call lhs%assign_object(rhs)
  ! Type_Command_Line_Arguments_Group members
  if (allocated(rhs%group)) lhs%group       = rhs%group
  if (allocated(rhs%cla  )) lhs%cla         = rhs%cla
                            lhs%Na          = rhs%Na
                            lhs%Na_required = rhs%Na_required
                            lhs%Na_optional = rhs%Na_optional
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_clasg

  ! Type_Command_Line_Interface procedures
  elemental subroutine free(cli)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for freeing dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli !< CLI data.
  integer(I4P)::                                      g   !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! Type_Object members
  call cli%free_object
  ! Type_Command_Line_Interface members
  if (allocated(cli%clasg)) then
    do g=1,size(cli%clasg,dim=1)
      call cli%clasg(g)%free
    enddo
    deallocate(cli%clasg)
  endif
  if (allocated(cli%examples))  deallocate(cli%examples)
  cli%disable_hv = .false.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free

  elemental subroutine finalize(cli)
  !< Procedure for freeing dynamic memory when finalizing.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Command_Line_Interface), intent(INOUT):: cli !< CLI data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call cli%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize

  pure subroutine init(cli,progname,version,help,description,license,authors,examples,disable_hv)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for initializing CLI.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli          !< CLI data.
  character(*), optional,             intent(IN)::    progname     !< Program name.
  character(*), optional,             intent(IN)::    version      !< Program version.
  character(*), optional,             intent(IN)::    help         !< Help message introducing the CLI usage.
  character(*), optional,             intent(IN)::    description  !< Detailed description message introducing the program.
  character(*), optional,             intent(IN)::    license      !< License description.
  character(*), optional,             intent(IN)::    authors      !< Authors list.
  character(*), optional,             intent(IN)::    examples(1:) !< Examples of correct usage.
  logical,      optional,             intent(IN)::    disable_hv   !< Disable automatic inserting of 'help' and 'version' CLAs.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call cli%free
  cli%progname    = 'program' ; if (present(progname   )) cli%progname    = progname
  cli%version     = 'unknown' ; if (present(version    )) cli%version     = version
  cli%help        = 'usage: ' ; if (present(help       )) cli%help        = help
  cli%description = ''        ; if (present(description)) cli%description = description
  cli%license     = ''        ; if (present(license    )) cli%license     = license
  cli%authors     = ''        ; if (present(authors    )) cli%authors     = authors
  if (present(disable_hv)) cli%disable_hv = .true.
  if (present(examples)) then
#ifdef GNU
    allocate(cli%examples(1:size(examples)))
#else
    allocate(character(len=len(examples(1))):: cli%examples(1:size(examples))) ! does not work with gfortran 4.9.2
#endif
    cli%examples = examples
  endif
  ! initialize only the first default group
  allocate(cli%clasg(0:0))
  call cli%clasg(0)%init(progname    = cli%progname,    &
                         version     = cli%version,     &
                         help        = cli%help,        &
                         description = cli%description, &
                         license     = cli%license,     &
                         authors     = cli%authors)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine init

  subroutine add_group(cli,help,description,group)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Add CLAs group to CLI.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT)::    cli               !< CLI data.
  character(*), optional,             intent(IN)::       help              !< Help message.
  character(*), optional,             intent(IN)::       description       !< Detailed description.
  character(*), optional,             intent(IN)::       group             !< Name of the grouped CLAs.
  type(Type_Command_Line_Arguments_Group), allocatable:: clasg_list_new(:) !< New (extended) CLAs group list.
  character(len=:), allocatable::                        helpd             !< Help message.
  character(len=:), allocatable::                        descriptiond      !< Detailed description.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  allocate(clasg_list_new(0:size(cli%clasg,dim=1)))
  clasg_list_new(0:size(cli%clasg,dim=1)-1)=cli%clasg
  helpd        = 'usage: ' ; if (present(help       )) helpd        = help
  descriptiond = ''        ; if (present(description)) descriptiond = description
  call clasg_list_new(size(cli%clasg,dim=1))%init(progname    = cli%progname, &
                                                  version     = cli%version,  &
                                                  license     = cli%license,  &
                                                  help        = helpd,        &
                                                  description = descriptiond, &
                                                  authors     = cli%authors,  &
                                                  group       = group)
  deallocate(cli%clasg)
  allocate(cli%clasg(0:size(clasg_list_new,dim=1)-1))
  cli%clasg = clasg_list_new
  deallocate(clasg_list_new)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add_group

  subroutine add(cli,pref,group,switch,switch_ab,help,required,positional,position,act,def,nargs,choices,error)
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
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli        !< CLI data.
  character(*), optional,             intent(IN)::    pref       !< Prefixing string.
  character(*), optional,             intent(IN)::    group      !< Name of the grouped CLAs.
  character(*), optional,             intent(IN)::    switch     !< Switch name.
  character(*), optional,             intent(IN)::    switch_ab  !< Abbreviated switch name.
  character(*), optional,             intent(IN)::    help       !< Help message describing the CLA.
  logical,      optional,             intent(IN)::    required   !< Flag for set required argument.
  logical,      optional,             intent(IN)::    positional !< Flag for checking if CLA is a positional or a named CLA.
  integer(I4P), optional,             intent(IN)::    position   !< Position of positional CLA.
  character(*), optional,             intent(IN)::    act        !< CLA value action.
  character(*), optional,             intent(IN)::    def        !< Default value.
  character(*), optional,             intent(IN)::    nargs      !< Number of arguments consumed by CLA.
  character(*), optional,             intent(IN)::    choices    !< List of allowable values for the argument.
  integer(I4P), optional,             intent(OUT)::   error      !< Error trapping flag.
  type(Type_Command_Line_Argument)::                  cla        !< CLA data.
  character(len=:), allocatable::                     prefd      !< Prefixing string.
  integer(I4P)::                                      g          !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! initializing CLA
  if (present(switch)) then
    cla%switch    = switch
    cla%switch_ab = switch
  endif
                                             if (present(switch_ab )) cla%switch_ab  = switch_ab
  cla%help       = 'Undocumented argument' ; if (present(help      )) cla%help       = help
  cla%required   = .false.                 ; if (present(required  )) cla%required   = required
  cla%positional = .false.                 ; if (present(positional)) cla%positional = positional
  cla%position   = 0_I4P                   ; if (present(position  )) cla%position   = position
  cla%act        = action_store            ; if (present(act       )) cla%act        = trim(adjustl(Upper_Case(act)))
                                             if (present(def       )) cla%def        = def
                                             if (present(nargs     )) cla%nargs      = nargs
                                             if (present(choices   )) cla%choices    = choices
  prefd = '' ; if (present(pref)) prefd = pref
  call cla%check(pref=prefd) ; cli%error = cla%error
  ! adding CLA to CLI
  if (.not.present(group)) then
    call cli%clasg(0)%add(pref=prefd,cla=cla) ; cli%error = cli%clasg(0)%error
  else
    if (cli%defined_group(group=group,g=g)) then
      call cli%clasg(g)%add(pref=prefd,cla=cla) ; cli%error = cli%clasg(g)%error
    else
      call cli%add_group(group=group)
      call cli%clasg(size(cli%clasg,dim=1)-1)%add(pref=prefd,cla=cla) ; cli%error = cli%clasg(size(cli%clasg,dim=1)-1)%error
    endif
  endif
  if (present(error)) error = cli%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add

  subroutine check(cli,pref,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check CLAs data consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli   !< CLI data.
  character(*), optional,             intent(IN)::    pref  !< Prefixing string.
  integer(I4P), optional,             intent(OUT)::   error !< Error trapping flag.
  character(len=:), allocatable::                     prefd !< Prefixing string.
  integer(I4P)::                                      g     !< CLA counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  do g=0,size(cli%clasg,dim=1)-1
    call cli%clasg(g)%check(pref=prefd)
    cli%error = cli%clasg(g)%error
    if (present(error)) error = cli%error
    if (cli%error/=0) exit
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check

  function passed(cli,group,switch,position)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if a CLA has been passed.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(IN):: cli      !< CLI data.
  character(*), optional,             intent(IN):: group    !< Name of group (command) of CLA.
  character(*), optional,             intent(IN):: switch   !< Switch name.
  integer(I4P), optional,             intent(IN):: position !< Position of positional CLA.
  logical::                                        passed   !< Check if a CLA has been passed.
  integer(I4P)::                                   g        !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  passed = .false.
  if (.not.present(group)) then
    if (present(switch)) then
      passed = cli%clasg(0)%passed(switch=switch)
    elseif (present(position)) then
      passed = cli%clasg(0)%passed(position=position)
    endif
  else
    if (cli%defined_group(group=group,g=g)) then
      if (present(switch)) then
        passed = cli%clasg(g)%passed(switch=switch)
      elseif (present(position)) then
        passed = cli%clasg(g)%passed(position=position)
      endif
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction passed

  function defined_group(cli,g,group) result(defined)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if a CLAs group has been defined.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(IN)::  cli     !< CLI data.
  integer(I4P), optional,             intent(OUT):: g       !< Index of group.
  character(*),                       intent(IN)::  group   !< Name of group (command) of CLA.
  logical::                                         defined !< Check if a CLA has been defined.
  integer(I4P)::                                    gg,ggg  !< Counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  defined = .false.
  do gg=0,size(cli%clasg,dim=1)-1
    ggg = gg
    if (allocated(cli%clasg(gg)%group)) defined = (cli%clasg(gg)%group==group)
    if (defined) exit
  enddo
  if (present(g)) g = ggg
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction defined_group

  function defined(cli,group,switch)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if a CLA has been defined.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(IN):: cli     !< CLI data.
  character(*), optional,             intent(IN):: group   !< Name of group (command) of CLA.
  character(*),                       intent(IN):: switch  !< Switch name.
  logical::                                        defined !< Check if a CLA has been defined.
  integer(I4P)::                                   g       !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  defined = .false.
  if (.not.present(group)) then
    defined = cli%clasg(0)%defined(switch=switch)
  else
    if (cli%defined_group(group=group,g=g)) defined = cli%clasg(g)%defined(switch=switch)
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction defined

  subroutine parse(cli,pref,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Parse Command Line Interfaces by means of a previously initialized CLAs groups list.
  !<
  !< @note The leading and trailing white spaces are removed from CLA values.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli    !< CLI data.
  character(*), optional,             intent(IN)::    pref   !< Prefixing string.
  integer(I4P), optional,             intent(OUT)::   error  !< Error trapping flag.
  integer(I4P)::                                      Na     !< Number of command line arguments passed.
  character(max_val_len)::                            switch !< Switch name.
  logical::                                           found  !< Flag for checking if switch has been found in cli%cla.
  character(len=:), allocatable::                     prefd  !< Prefixing string.
  integer(I4P)::                                      a      !< Counter for CLAs.
  integer(I4P)::                                      g      !< Counter for CLAs group.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref

  ! adding help and version switches if not done by user
  if (.not.cli%disable_hv) then
    if (.not.(cli%defined(switch='--help').and.cli%defined(switch='-h'))) &
      call cli%add(pref=prefd,switch='--help',switch_ab='-h',&
                   help='Print this help message',required=.false.,def='',act='print_help')
    if (.not.(cli%defined(switch='--version').and.cli%defined(switch='-v'))) &
      call cli%add(pref=prefd,switch='--version',switch_ab='-v',&
                   help='Print version',required=.false.,def='',act='print_version')
  endif

  ! counting the passed CLA
  Na = command_argument_count()
  ! if (Na<cli%Na_required) then
  !   call cli%errored(pref=prefd,error=error_cli_too_few_clas,Na=na)
  !   call cli%print_usage(pref=prefd)
  !   if (present(error)) error = cli%error
  !   return
  ! endif

  ! checking CLI consistency
  call cli%check(pref=prefd)
  if (cli%error/=0) then
    if (present(error)) error = cli%error
    return
  endif

  ! checking if a group of CLAs (command) has been invoked
  call get_command_argument(1,switch)
  if (cli%defined_group(group=trim(adjustl(switch)),g=g)) then
    a = 1 ! parsing from the second switch passed
  else
    a = 0 ! parsing from the first switch passed
    g = 0 ! use the default group zero
  endif

  ! parsing switch
  do while (a<Na)
    a = a + 1
    call get_command_argument(a,switch)
    call cli%clasg(g)%parse_switch(Na=Na,switch=trim(adjustl(switch)),arg=a,found=found) ; cli%error = cli%clasg(g)%error
    if (.not.found) then
      if (.not.cli%clasg(g)%cla(a)%positional) then
        call cli%clasg(g)%cla(a)%errored(pref=prefd,error=error_cla_unknown,switch=trim(adjustl(switch)))
        cli%error = cli%clasg(g)%cla(a)%error
        if (present(error)) error = cli%error
        return
      else
        ! positional CLA always stores a value
        cli%clasg(g)%cla(a)%val = trim(adjustl(switch))
        cli%clasg(g)%cla(a)%passed = .true.
      endif
    endif
  enddo

  ! checking if all required CLAs have been passed
  do a=1,cli%clasg(g)%Na
    if (cli%clasg(g)%cla(a)%required) then
      if (.not.cli%clasg(g)%cla(a)%passed) then
        call cli%clasg(g)%cla(a)%errored(pref=prefd,error=error_cla_missing_required)
        call cli%print_usage(pref=prefd)
        cli%error = cli%clasg(g)%cla(a)%error
        if (present(error)) error = cli%error
        return
      endif
    endif
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine parse

  subroutine get_cla_cli(cli,pref,switch,position,error,val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for getting CLA (single) value from CLAs list parsed.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli      !< CLI data.
  character(*), optional,             intent(IN)::    pref     !< Prefixing string.
  character(*), optional,             intent(IN)::    switch   !< Switch name.
  integer(I4P), optional,             intent(IN)::    position !< Position of positional CLA.
  integer(I4P), optional,             intent(OUT)::   error    !< Error trapping flag.
  class(*),                           intent(INOUT):: val      !< CLA value.
  character(len=:), allocatable::                     prefd    !< Prefixing string.
  logical::                                           found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)::                                      a        !< Argument counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  if (present(switch)) then
    ! searching for the CLA corresponding to switch
    found = .false.
    do a=1,cli%clasg(0)%Na
      if (.not.cli%clasg(0)%cla(a)%positional) then
        if ((cli%clasg(0)%cla(a)%switch==switch).or.(cli%clasg(0)%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      call cli%errored(pref=prefd,error=error_cli_missing_cla,switch=switch)
    else
      call cli%clasg(0)%cla(a)%get(pref=prefd,val=val) ; cli%error =  cli%clasg(0)%cla(a)%error
    endif
  elseif (present(position)) then
    call cli%clasg(0)%cla(position)%get(pref=prefd,val=val) ; cli%error = cli%clasg(0)%cla(position)%error
  else
    call cli%errored(pref=prefd,error=error_cli_missing_selection_cla)
  endif
  if (present(error)) error = cli%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_cli

  subroutine get_cla_list_cli(cli,pref,switch,position,error,val)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for getting CLA multiple values from CLAs list parsed.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli      !< CLI data.
  character(*), optional,             intent(IN)::    pref     !< Prefixing string.
  character(*), optional,             intent(IN)::    switch   !< Switch name.
  integer(I4P), optional,             intent(IN)::    position !< Position of positional CLA.
  integer(I4P), optional,             intent(OUT)::   error    !< Error trapping flag.
  class(*),                           intent(INOUT):: val(1:)  !< CLA values.
  character(len=:), allocatable::                     prefd    !< Prefixing string.
  logical::                                           found    !< Flag for checking if CLA containing switch has been found.
  integer(I4P)::                                      a        !< Argument counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  error = 0
  prefd = '' ; if (present(pref)) prefd = pref
  if (present(switch)) then
    ! searching for the CLA corresponding to switch
    found = .false.
    do a=1,cli%clasg(0)%Na
      if (.not.cli%clasg(0)%cla(a)%positional) then
        if ((cli%clasg(0)%cla(a)%switch==switch).or.(cli%clasg(0)%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      call cli%errored(pref=prefd,error=error_cli_missing_cla,switch=switch)
    else
      call cli%clasg(0)%cla(a)%get(pref=prefd,val=val) ; cli%error = cli%clasg(0)%cla(a)%error
    endif
  elseif (present(position)) then
    call cli%clasg(0)%cla(position)%get(pref=prefd,val=val) ; cli%error = error
  else
    call cli%errored(pref=prefd,error=error_cli_missing_selection_cla)
  endif
  if (present(error)) error = cli%error
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_cli

  subroutine print_usage(cli,pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Print correct usage of CLI.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(IN):: cli   !< CLI data.
  character(*), optional,             intent(IN):: pref  !< Prefixing string.
  character(len=:), allocatable::                  prefd !< Prefixing string.
  integer(I4P)::                                   g     !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  do g=0,size(cli%clasg)-1
    call cli%clasg(g)%print_usage(pref=prefd)
  enddo
  call cli%print_examples(pref=prefd)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine print_usage

  subroutine print_examples(cli,pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Print correct usage examples of CLI.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(IN):: cli   !< CLI data.
  character(*), optional,             intent(IN):: pref  !< Prefixing string.
  character(len=:), allocatable::                  prefd !< Prefixing string.
  integer(I4P)::                                   e     !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(cli%examples)) then
    prefd = '' ; if (present(pref)) prefd = pref
    write(stdout,'(A)')
    write(stdout,'(A)')prefd//' Examples:'
    do e=1,size(cli%examples,dim=1)
      write(stdout,'(A)')prefd//'   -) '//trim(cli%examples(e))
    enddo
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine print_examples

  subroutine print_version(cli,pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Print version.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(IN):: cli   !< CLI data.
  character(*), optional,             intent(IN):: pref  !< Prefixing string.
  character(len=:), allocatable::                  prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  write(stdout,'(A)')prefd//' '//cli%progname//' version '//cli%version
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine print_version

  elemental subroutine assign_cli(lhs,rhs)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: lhs !< Left hand side.
  type(Type_Command_Line_Interface),  intent(IN)::    rhs !< Right hand side.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! Type_Object members
  call lhs%assign_object(rhs)
  ! Type_Command_Line_Interface members
  if (allocated(rhs%clasg   )) lhs%clasg      = rhs%clasg
  if (allocated(rhs%examples)) lhs%examples   = rhs%examples
                               lhs%disable_hv = rhs%disable_hv
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_cli
endmodule Data_Type_Command_Line_Interface

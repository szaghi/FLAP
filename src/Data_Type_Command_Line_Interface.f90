!< FLAP, Fortran command Line Arguments Parser for poor men
module Data_Type_Command_Line_Interface
!-----------------------------------------------------------------------------------------------------------------------------------
!< FLAP, Fortran command Line Arguments Parser for poor men
!<{!README-FLAP.md!}
!<
!<### ChangeLog
!<
!<{!ChangeLog-FLAP.md!}
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision                           ! Integers and reals precision definition.
USE Lib_IO_Misc, only: stdout,stderr       ! Library for IO operations.
USE Lib_Strings, only: tokenize,Upper_Case ! Library for strings operations.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
type:: Type_Command_Line_Argument
  !< Command line arguments (CLA).
  !<
  !< @note If not otherwise declared the action on CLA value is set to "store" a value.
  private
  character(len=:), allocatable:: switch             !< Switch name.
  character(len=:), allocatable:: switch_ab          !< Abbreviated switch name.
  character(len=:), allocatable:: help               !< Help message describing the CLA.
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

type:: Type_Command_Line_Arguments_Group
  !< Group of CLAs for building nested commands.
  private
  integer(I4P)::                                  Na          = 0_I4P !< Number of CLA.
  integer(I4P)::                                  Na_required = 0_I4P !< Number of command line arguments that CLI requires.
  integer(I4P)::                                  Na_optional = 0_I4P !< Number of command line arguments that are optional for CLI.
  type(Type_Command_Line_Argument), allocatable:: cla(:)              !< CLA list [1:Na].
  character(len=:), allocatable::                 help                !< Help message introducing the CLAs group.
  character(len=:), allocatable::                 description         !< Detailed description message introducing the CLAs group.
  contains
    ! public methods
    procedure, public:: free => free_clasg !< Free dynamic memory.
endtype Type_Command_Line_Arguments_Group

type, public:: Type_Command_Line_Interface
  !< Command Line Interface (CLI).
  private
  integer(I4P)::                                  Na          = 0_I4P !< Number of CLA.
  integer(I4P)::                                  Na_required = 0_I4P !< Number of command line arguments that CLI requires.
  integer(I4P)::                                  Na_optional = 0_I4P !< Number of command line arguments that are optional for CLI.
  type(Type_Command_Line_Argument), allocatable:: cla(:)              !< CLA list [1:Na].
  character(len=:), allocatable::                 progname            !< Program name.
  character(len=:), allocatable::                 version             !< Program version.
  character(len=:), allocatable::                 help                !< Help message introducing the CLI usage.
  character(len=:), allocatable::                 description         !< Detailed description message introducing the program.
#ifdef GNU
  character(100  ), allocatable::                 examples(:)         !< Examples of correct usage.
#else
  character(len=:), allocatable::                 examples(:)         !< Examples of correct usage (does not work with gfortran).
#endif
  logical::                                       disable_hv = .false.!< Disable automatic inserting of 'help' and 'version' CLAs.
  contains
    ! public methods
    procedure, public:: free                                !< Free dynamic memory.
    procedure, public:: init                                !< Initialize CLI.
    procedure, public:: add                                 !< Add CLA to CLAs list.
    procedure, public:: check                               !< Check CLAs data consistenc.
    procedure, public:: passed                              !< Check if a CLA has been passed.
    procedure, public:: parse                               !< Parse Command Line Interfaces.
    generic,   public:: get => get_cla_cli,get_cla_list_cli !< Get CLA value(s) from CLAs list parsed.
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
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  ! Type_Command_Line_Argument procedures
  elemental subroutine free_cla(cla)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla !< CLA data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(cla%switch   )) deallocate(cla%switch   )
  if (allocated(cla%switch_ab)) deallocate(cla%switch_ab)
  if (allocated(cla%help     )) deallocate(cla%help     )
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

  subroutine check_cla(cla,pref,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check CLA data consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(IN)::  cla   !< CLA data.
  character(*), optional,            intent(IN)::  pref  !< Prefixing string.
  integer(I4P),                      intent(OUT):: error !< Error trapping flag.
  character(len=:), allocatable::                  prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  error = 0
  prefd = '' ; if (present(pref)) prefd = pref
  if ((.not.cla%required).and.(.not.allocated(cla%def))) then
    error = 1
    if (cla%positional) then
      write(stderr,'(A)')prefd//' Error: the positional CLA "'//trim(str(n=cla%position))//'-th" is not set as "required"'//&
                                ' but no default value has been set!'
    else
      write(stderr,'(A)')prefd//' Error: the CLA "'//cla%switch//'" is not set as "required" but no default value has been set!'
    endif
  endif
  if ((.not.cla%positional).and.(.not.allocated(cla%switch))) then
    error = 2
    write(stderr,'(A)')prefd//' Error: a non positional CLA must have a switch name!'
  elseif ((cla%positional).and.(cla%position==0_I4P)) then
    error = 3
    write(stderr,'(A)')prefd//' Error: a positional CLA must have a position number different from 0!'
  elseif ((cla%positional).and.(cla%act/=action_store)) then
    error = 4
    write(stderr,'(A)')prefd//' Error: a positional CLA must have action set to "'//action_store//'"!'
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_cla

  subroutine check_choices_cla(cla,val,pref,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Check if CLA value is in allowed choices.
  !<
  !< @note This procedure can be called if and only if cla%choices has been allocated.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(IN)::  cla     !< CLA data.
  class(*),                          intent(IN)::  val     !< CLA value.
  character(*), optional,            intent(IN)::  pref    !< Prefixing string.
  integer(I4P),                      intent(OUT):: error   !< Error trapping flag.
  character(len=:), allocatable::                  prefd   !< Prefixing string.
  character(len(cla%choices)), allocatable::       toks(:) !< Tokens for parsing choices list.
  integer(I4P)::                                   Nc      !< Number of choices.
  logical::                                        val_in  !< Flag for checking if val is in the choosen range.
  character(len=:), allocatable::                  val_str !< Value in string form.
  character(len=:), allocatable::                  tmp     !< Temporary string for avoiding GNU gfrotran bug.
  integer(I4P)::                                   c       !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  error = 0
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
    error = 1
    prefd = '' ; if (present(pref)) prefd = pref
    if (cla%positional) then
      write(stderr,'(A)')prefd//' Error: the value of positional CLA "'//trim(str(n=cla%position))//'-th" must be chosen in:'
      write(stderr,'(A)')prefd//' ('//cla%choices//') but "'//trim(val_str)//'" has been passed!'
    else
      write(stderr,'(A)')prefd//' Error: the value of CLA "'//cla%switch//'" must be chosen in:'
      write(stderr,'(A)')prefd//' ('//cla%choices//') but "'//trim(val_str)//'" has been passed!'
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_choices_cla

  subroutine get_cla(cla,pref,val,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (single) value.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla     !< CLA data.
  character(*), optional,            intent(IN)::    pref    !< Prefixing string.
  class(*),                          intent(INOUT):: val     !< CLA value.
  integer(I4P),                      intent(OUT)::   error   !< Error trapping flag.
  character(len=:), allocatable::                    prefd   !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  error = 0
  prefd = '' ; if (present(pref)) prefd = pref
  if (((.not.cla%passed).and.cla%required).or.((.not.cla%passed).and.(.not.allocated(cla%def)))) then
    error = 1
    write(stderr,'(A)')prefd//' Error: CLA "'//trim(adjustl(cla%switch))//'" is required by CLI but it has not been passed!'
    return
  endif
  if (cla%act==action_store) then
    if (cla%passed) then
      select type(val)
#ifdef r16p
      type is(real(R16P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%val)),knd=1._R16P)
#endif
      type is(real(R8P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%val)),knd=1._R8P)
      type is(real(R4P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%val)),knd=1._R4P)
      type is(integer(I8P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%val)),knd=1_I8P)
      type is(integer(I4P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%val)),knd=1_I4P)
      type is(integer(I2P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%val)),knd=1_I2P)
      type is(integer(I1P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%val)),knd=1_I1P)
      type is(logical)
        read(cla%val,*,iostat=error)val
        if (error/=0) write(stderr,'(A)')prefd//' Error: cannot convert "'//trim(adjustl(cla%val))// &
                      '" of CLA "'//cla%switch//'" to boolean!'
      type is(character(*))
        val = cla%val
      endselect
    else ! using default value
      select type(val)
#ifdef r16p
      type is(real(R16P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%def)),knd=1._R16P)
#endif
      type is(real(R8P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%def)),knd=1._R8P)
      type is(real(R4P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%def)),knd=1._R4P)
      type is(integer(I8P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%def)),knd=1_I8P)
      type is(integer(I4P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%def)),knd=1_I4P)
      type is(integer(I2P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%def)),knd=1_I2P)
      type is(integer(I1P))
        val = cton(pref=prefd,error=error,str=trim(adjustl(cla%def)),knd=1_I1P)
      type is(logical)
        read(cla%def,*,iostat=error)val
        if (error/=0) write(stderr,'(A)')prefd//' Error: cannot convert "'//trim(adjustl(cla%def))// &
                      '" of CLA "'//cla%switch//'" to boolean!'
      type is(character(*))
        val = cla%def
      endselect
    endif
    if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val,pref=prefd,error=error)
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

  subroutine get_cla_list(cla,pref,val,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Get CLA (multiple) value.
  !<
  !< @note For logical type CLA the value is directly read without any robust error trapping.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla      !< CLA data.
  character(*), optional,            intent(IN)::    pref     !< Prefixing string.
  class(*),                          intent(INOUT):: val(1:)  !< CLA values.
  integer(I4P),                      intent(OUT)::   error    !< Error trapping flag.
  integer(I4P)::                                     Nv       !< Number of values.
  character(len=len(cla%val)), allocatable::         valsV(:) !< String array of values based on cla%val.
  character(len=len(cla%def)), allocatable::         valsD(:) !< String array of values based on cla%def.
  character(len=:), allocatable::                    prefd    !< Prefixing string.
  integer(I4P)::                                     v        !< Values counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  error = 0
  prefd = '' ; if (present(pref)) prefd = pref
  if (((.not.cla%passed).and.cla%required).or.((.not.cla%passed).and.(.not.allocated(cla%def)))) then
    error = 1
    if (.not.cla%positional) then
      write(stderr,'(A)')prefd//' Error: CLA "'//trim(adjustl(cla%switch))//'" is required by CLI but it has not been passed!'
    else
      write(stderr,'(A)')prefd//' Error: positional CLA "'//trim(str(.true.,cla%position))//'-th" '//&
                                ' is required by CLI but it has not been passed!'
    endif
    return
  endif
  if (.not.allocated(cla%nargs)) then
    error = 2
    if (.not.cla%positional) then
      write(stderr,'(A)')prefd//' Error: CLA "'//trim(adjustl(cla%switch))//'" has not "nargs" value but an array has been '//&
                                'passed to "get" method!'
    else
      write(stderr,'(A)')prefd//' Error: positional CLA "'//trim(str(.true.,cla%position))//'-th" '//&
                                'has not "nargs" value but an array has been passed to "get" method!'
    endif
    return
  endif
  if (cla%act==action_store) then
    if (cla%passed) then
      call tokenize(strin=cla%val,delimiter=args_sep,Nt=Nv,toks=valsV)
      select type(val)
#ifdef r16p
      type is(real(R16P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsV(v))),knd=1._R16P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
#endif
      type is(real(R8P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsV(v))),knd=1._R8P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      type is(real(R4P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsV(v))),knd=1._R4P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      type is(integer(I8P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsV(v))),knd=1_I8P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      type is(integer(I4P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsV(v))),knd=1_I4P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      type is(integer(I2P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsV(v))),knd=1_I2P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      type is(integer(I1P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsV(v))),knd=1_I1P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      type is(logical)
        do v=1,Nv
          read(valsV(v),*,iostat=error)val(v)
        enddo
        if (error/=0) write(stderr,'(A)')prefd//' Error: cannot convert "'//trim(adjustl(cla%val))// &
                      '" of CLA "'//cla%switch//'" to boolean!'
      type is(character(*))
        do v=1,Nv
          val(v)=valsV(v)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      endselect
    else ! using default value
      call tokenize(strin=cla%def,delimiter=' ',Nt=Nv,toks=valsD)
      select type(val)
#ifdef r16p
      type is(real(R16P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsD(v))),knd=1._R16P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
#endif
      type is(real(R8P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsD(v))),knd=1._R8P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      type is(real(R4P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsD(v))),knd=1._R4P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      type is(integer(I8P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsD(v))),knd=1_I8P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      type is(integer(I4P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsD(v))),knd=1_I4P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      type is(integer(I2P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsD(v))),knd=1_I2P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      type is(integer(I1P))
        do v=1,Nv
          val(v) = cton(pref=prefd,error=error,str=trim(adjustl(valsD(v))),knd=1_I1P)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
        enddo
      type is(logical)
        do v=1,Nv
          read(valsD(v),*,iostat=error)val(v)
        enddo
        if (error/=0) write(stderr,'(A)')prefd//' Error: cannot convert "'//trim(adjustl(cla%def))// &
                      '" of CLA "'//cla%switch//'" to boolean!'
      type is(character(*))
        do v=1,Nv
          val(v)=valsD(v)
          if (allocated(cla%choices).and.error==0) call cla%check_choices(val=val(v),pref=prefd,error=error)
          if (error/=0) exit
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

  elemental subroutine assign_cla(self1,self2)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Assignment between two CLAs.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: self1 !< Left hand side.
  type(Type_Command_Line_Argument),  intent(IN)::    self2 !< Rigth hand side.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self2%switch   )) self1%switch     = self2%switch
  if (allocated(self2%switch_ab)) self1%switch_ab  = self2%switch_ab
  if (allocated(self2%help     )) self1%help       = self2%help
  if (allocated(self2%act      )) self1%act        = self2%act
  if (allocated(self2%def      )) self1%def        = self2%def
  if (allocated(self2%nargs    )) self1%nargs      = self2%nargs
  if (allocated(self2%choices  )) self1%choices    = self2%choices
  if (allocated(self2%val      )) self1%val        = self2%val
                                  self1%required   = self2%required
                                  self1%positional = self2%positional
                                  self1%position   = self2%position
                                  self1%passed     = self2%passed
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_cla

  ! Type_Command_Line_Argument procedures
  elemental subroutine free_clasg(clasg)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Arguments_Group), intent(INOUT):: clasg !< CLAs group data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(clasg%help       )) deallocate(clasg%help       )
  if (allocated(clasg%description)) deallocate(clasg%description)
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

  elemental subroutine finalize_cla(clasg)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory when finalizing.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Command_Line_Arguments_Group), intent(INOUT):: clasg !< CLAs group data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call cla%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize_clasg

  ! Type_Command_Line_Interface procedures
  elemental subroutine free(cli)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for freeing dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli !< CLI data.
  integer(I4P)::                                      a   !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(cli%cla)) then
    do a=1,size(cli%cla,dim=1)
      call cli%cla(a)%free
    enddo
    deallocate(cli%cla)
  endif
  cli%Na          = 0_I4P
  cli%Na_required = 0_I4P
  cli%Na_optional = 0_I4P
  if (allocated(cli%progname   ))  deallocate(cli%progname   )
  if (allocated(cli%version    ))  deallocate(cli%version    )
  if (allocated(cli%help       ))  deallocate(cli%help       )
  if (allocated(cli%description))  deallocate(cli%description)
  if (allocated(cli%examples   ))  deallocate(cli%examples   )
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

  pure subroutine init(cli,progname,version,help,description,examples,disable_hv)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for initializing CLI.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli          !< CLI data.
  character(*), optional,             intent(IN)::    progname     !< Program name.
  character(*), optional,             intent(IN)::    version      !< Program version.
  character(*), optional,             intent(IN)::    help         !< Help message introducing the CLI usage.
  character(*), optional,             intent(IN)::    description  !< Detailed description message introducing the program.
  character(*), optional,             intent(IN)::    examples(1:) !< Examples of correct usage.
  logical,      optional,             intent(IN)::    disable_hv   !< Disable automatic inserting of 'help' and 'version' CLAs.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  cli%progname    = 'program' ; if (present(progname   )) cli%progname    = progname
  cli%version     = 'unknown' ; if (present(version    )) cli%version     = version
  cli%help        = 'usage: ' ; if (present(help       )) cli%help        = help
  cli%description = ''        ; if (present(description)) cli%description = description
  if (present(disable_hv)) cli%disable_hv = .true.
  if (present(examples)) then
#ifdef GNU
    allocate(cli%examples(1:size(examples)))
#else
    allocate(character(len=len(examples(1))):: cli%examples(1:size(examples))) ! does not work with gfortran 4.9.2
#endif
    cli%examples = examples
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine init

  subroutine add(cli,pref,switch,switch_ab,help,required,positional,position,act,def,nargs,choices,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for adding CLA to CLAs list.
  !<
  !< @note If not otherwise declared the action on CLA value is set to "store" a value that must be passed after the switch name
  !< or directly passed in case of positional CLA.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli             !< CLI data.
  character(*), optional,             intent(IN)::    pref            !< Prefixing string.
  character(*), optional,             intent(IN)::    switch          !< Switch name.
  character(*), optional,             intent(IN)::    switch_ab       !< Abbreviated switch name.
  character(*), optional,             intent(IN)::    help            !< Help message describing the CLA.
  logical,      optional,             intent(IN)::    required        !< Flag for set required argument.
  logical,      optional,             intent(IN)::    positional      !< Flag for checking if CLA is a positional or a named CLA.
  integer(I4P), optional,             intent(IN)::    position        !< Position of positional CLA.
  character(*), optional,             intent(IN)::    act             !< CLA value action.
  character(*), optional,             intent(IN)::    def             !< Default value.
  character(*), optional,             intent(IN)::    nargs           !< Number of arguments consumed by CLA.
  character(*), optional,             intent(IN)::    choices         !< List of allowable values for the argument.
  integer(I4P),                       intent(OUT)::   error           !< Error trapping flag.
  type(Type_Command_Line_Argument)::                  cla             !< CLA data.
  type(Type_Command_Line_Argument), allocatable::     cla_list_new(:) !< New (extended) CLA list.
  character(len=:), allocatable::                     prefd           !< Prefixing string.
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
  call cla%check(pref=prefd,error=error)
  ! adding CLA to CLI
  if (error==0) then
    if (cli%Na>0_I4P) then
      if (.not.cla%positional) then
        allocate(cla_list_new(1:cli%Na+1))
        cla_list_new(1:cli%Na)=cli%cla
        cla_list_new(cli%Na+1)=cla
      else
        allocate(cla_list_new(1:cli%Na+1))
        cla_list_new(1:cla%position-1)=cli%cla(1:cla%position-1)
        cla_list_new(cla%position)=cla
        cla_list_new(cla%position+1:cli%Na+1)=cli%cla(cla%position:cli%Na)
      endif
    else
      allocate(cla_list_new(1:1))
      cla_list_new(1)=cla
    endif
    call move_alloc(from=cla_list_new,to=cli%cla)
    cli%Na = cli%Na + 1
    if (cla%required) then
      cli%Na_required = cli%Na_required + 1
    else
      cli%Na_optional = cli%Na_optional + 1
    endif
  endif
  if (allocated(cla_list_new)) deallocate(cla_list_new)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add

  subroutine check(cli,pref,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for checking CLAs data consistency.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(IN)::  cli   !< CLI data.
  character(*), optional,             intent(IN)::  pref  !< Prefixing string.
  integer(I4P),                       intent(OUT):: error !< Error trapping flag.
  character(len=:), allocatable::                   prefd !< Prefixing string.
  integer(I4P)::                                    a     !< CLA counter.
  integer(I4P)::                                    aa    !< CLA counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  error = 0
  prefd = '' ; if (present(pref)) prefd = pref
  ! verifing if CLAs switches are unique
  CLA_unique: do a=1,cli%Na
    if (.not.cli%cla(a)%positional) then
      do aa=1,cli%Na
        if ((a/=aa).and.(.not.cli%cla(aa)%positional)) then
          if ((cli%cla(a)%switch==cli%cla(aa)%switch   ).or.(cli%cla(a)%switch_ab==cli%cla(aa)%switch   ).or.&
              (cli%cla(a)%switch==cli%cla(aa)%switch_ab).or.(cli%cla(a)%switch_ab==cli%cla(aa)%switch_ab)) then
            error = 1
            write(stderr,'(A)')prefd//' Error: the '//trim(str(.true.,a))//'-th CLA has the same switch or abbreviated switch of '&
                               //trim(str(.true.,aa))//'-th CLA:'
            write(stderr,'(A)')prefd//' CLA('//trim(str(.true.,a)) //') switches = '//cli%cla(a)%switch //' '//cli%cla(a)%switch_ab
            write(stderr,'(A)')prefd//' CLA('//trim(str(.true.,aa))//') switches = '//cli%cla(aa)%switch//' '//cli%cla(aa)%switch_ab
            exit CLA_unique
          endif
        endif
      enddo
    endif
  enddo CLA_unique
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check

  pure function passed(cli,switch,position)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for checking if a CLA has been passed.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(IN):: cli      !< CLI data.
  character(*), optional,             intent(IN):: switch   !< Switch name.
  integer(I4P), optional,             intent(IN):: position !< Position of positional CLA.
  logical::                                        passed   !< Check if a CLA has been passed.
  integer(I4P)::                                   a        !< CLA counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  passed = .false.
  if (present(switch)) then
    do a=1,cli%Na
      if ((cli%cla(a)%switch==switch).or.(cli%cla(a)%switch_ab==switch)) then
        passed = cli%cla(a)%passed
        exit
      endif
    enddo
  elseif (present(position)) then
    passed = cli%cla(position)%passed
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction passed

  subroutine parse(cli,pref,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for parsing Command Line Interfaces by means of a previously initialized CLA list.
  !<
  !< @note The leading and trailing white spaces are removed from CLA values.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli            !< CLI data.
  character(*), optional,             intent(IN)::    pref           !< Prefixing string.
  integer(I4P),                       intent(OUT)::   error          !< Error trapping flag.
  integer(I4P)::                                      Na             !< Number of command line arguments passed.
  character(max_val_len)::                            switch         !< Switch name.
  character(max_val_len)::                            val            !< Switch value.
  logical::                                           found          !< Flag for checking if switch has been found in cli%cla.
  character(len=:), allocatable::                     prefd          !< Prefixing string.
  integer(I4P)::                                      nargs          !< Number of arguments consumed by a CLA.
  integer(I4P)::                                      a              !< Counter for command line arguments.
  integer(I4P)::                                      aa             !< Counter for command line arguments.
  integer(I4P)::                                      aaa            !< Counter for command line arguments.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  error = 0
  prefd = '' ; if (present(pref)) prefd = pref
  if (.not.cli%disable_hv) then
    ! adding help and version switches if not initialized from user
    found = .false.
    do aa=1,cli%Na
      if (.not.cli%cla(aa)%positional) then
        if (cli%cla(aa)%switch=='--help'.and.cli%cla(aa)%switch_ab=='-h') found = .true.
      endif
    enddo
    if (.not.found) call cli%add(pref=prefd,switch='--help',switch_ab='-h',help='Print this help message',&
                                 required=.false.,def='',act='print_help',error=error)
    found = .false.
    do aa=1,cli%Na
      if (.not.cli%cla(aa)%positional) then
        if (cli%cla(aa)%switch=='--version'.and.cli%cla(aa)%switch_ab=='-v') found = .true.
      endif
    enddo
    if (.not.found) call cli%add(pref=prefd,switch='--version',switch_ab='-v',help='Print version',&
                                 required=.false.,def='',act='print_version',error=error)
  endif
  ! counting the passed CLA
  Na = command_argument_count()
  if (Na<cli%Na_required) then
    write(stderr,'(A)')prefd//cli%progname//': error: too few arguments ('//trim(str(.true.,Na))//')'//&
                       ' respect the required ('//trim(str(.true.,cli%Na_required))//')'
    call print_usage
    error = 1
    return
  else
    ! checking CLI consistency
    call cli%check(error=error,pref=prefd) ; if (error/=0) return
    ! parsing switch
    a = 0
    do while (a<Na)
      a = a + 1
      call get_command_argument(a,switch)
      found = .false.
      do aa=1,cli%Na
        if (.not.cli%cla(aa)%positional) then
          if (trim(adjustl(cli%cla(aa)%switch   ))==trim(adjustl(switch)).or.&
              trim(adjustl(cli%cla(aa)%switch_ab))==trim(adjustl(switch))) then
            if (cli%cla(aa)%act==action_store) then
              if (allocated(cli%cla(aa)%nargs)) then
                cli%cla(aa)%val = ''
                select case(cli%cla(aa)%nargs)
                case('+') ! not yet implemented
                case('*') ! not yet implemented
                case default
                  nargs = cton(str=trim(adjustl(cli%cla(aa)%nargs)),knd=1_I4P)
                  if (a+nargs>Na) then
                    write(stderr,'(A)')prefd//cli%progname//' error: CLA "'//trim(adjustl(cli%cla(aa)%switch))//&
                                       '" requires '//trim(str(.true.,nargs))//' arguments but no enough ones remain!'
                    error = 2
                  endif
                  ! do aaa=a+1,a+nargs ! increasing loop
                  do aaa=a+nargs,a+1,-1 ! decreasing loop due to gfortran bug
                    call get_command_argument(aaa,val)
                    ! cli%cla(aa)%val = cli%cla(aa)%val//args_sep//trim(adjustl(val)) ! increasing loop
                    cli%cla(aa)%val = trim(adjustl(val))//args_sep//trim(cli%cla(aa)%val) ! decreasing loop due to gfortran bug
                  enddo
                  ! cli%cla(aa)%val = cli%cla(aa)%val(1+len(args_sep):) ! does not work with gfortran 4.9.2
                  a = a + nargs
                endselect
              else
                a = a + 1
                call get_command_argument(a,val)
                cli%cla(aa)%val = trim(adjustl(val))
              endif
            elseif (cli%cla(aa)%act==action_print_help) then
              call print_usage
              error = -1
              return
            elseif (cli%cla(aa)%act==action_print_vers) then
              call print_version
              error = -2
              return
            endif
            cli%cla(aa)%passed = .true.
            found = .true.
          endif
        endif
      enddo
      if (.not.found) then
        if (.not.cli%cla(a)%positional) then
          write(stderr,'(A)')prefd//' Error: switch "'//trim(adjustl(switch))//'" is unknown!'
          call print_usage
          error = 3
          return
        else
          ! positional CLA always stores a value
          cli%cla(a)%val = trim(adjustl(switch))
          cli%cla(a)%passed = .true.
        endif
      endif
    enddo
  endif
  ! checking if all required CLAs have been passed
  do a=1,cli%Na
    if (cli%cla(a)%required) then
      if (.not.cli%cla(a)%passed) then
        if (.not.cli%cla(a)%positional) then
          write(stderr,'(A)')prefd//' Error: CLA "'//trim(adjustl(cli%cla(a)%switch))//&
                                    '" is required by CLI but it has not been passed!'
        else
          write(stderr,'(A)')prefd//' Error: positional CLA "'//trim(str(.true.,cli%cla(a)%position))//'-th" '//&
                                    ' is required by CLI but it has not been passed!'
        endif
        call print_usage
        error = 4
        return
      endif
    endif
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  contains
    subroutine print_usage
    !-------------------------------------------------------------------------------------------------------------------------------
    !< Procedure for printing the correct use Command Line Interface accordingly to the cli%cla passed.
    !-------------------------------------------------------------------------------------------------------------------------------
    character(len=:), allocatable:: cla_sign      !< Signature of current CLA.
    character(len=:), allocatable:: cla_list_sign !< Complete signature of CLA list.
    !-------------------------------------------------------------------------------------------------------------------------------

    !-------------------------------------------------------------------------------------------------------------------------------
    cla_list_sign = cli%progname//' '
    do a=1,cli%Na
      cla_sign = cli%cla(a)%signature()
      cla_list_sign = cla_list_sign//cla_sign
    enddo
    write(stdout,'(A)')prefd//cli%help//' '//cla_list_sign
    if (cli%Na_required>0) then
      write(stdout,'(A)')
      write(stdout,'(A)')prefd//' Required options:'
      do a=1,cli%Na
        if (cli%cla(a)%required) call cli%cla(a)%print(pref=prefd,unit=stdout)
      enddo
    endif
    if (cli%Na_optional>0) then
      write(stdout,'(A)')
      write(stdout,'(A)')prefd//' Optional options:'
      do a=1,cli%Na
        if (.not.cli%cla(a)%required) call cli%cla(a)%print(pref=prefd,unit=stdout)
      enddo
    endif
    if (allocated(cli%examples)) then
      write(stdout,'(A)')
      write(stdout,'(A)')prefd//' Examples:'
      do a=1,size(cli%examples,dim=1)
        write(stdout,'(A)')prefd//'   -) '//trim(cli%examples(a))
      enddo
    endif
    return
    !-------------------------------------------------------------------------------------------------------------------------------
    endsubroutine print_usage

    subroutine print_version
    !-------------------------------------------------------------------------------------------------------------------------------
    !< Procedure for printing the correct use Command Line Interface accordingly to the cli%cla passed.
    !-------------------------------------------------------------------------------------------------------------------------------
    character(len=:), allocatable:: cla_list_sign !< Complete signature of CLA list.
    !-------------------------------------------------------------------------------------------------------------------------------

    !-------------------------------------------------------------------------------------------------------------------------------
    write(stdout,'(A)')prefd//' '//cli%progname//' version '//cli%version
    return
    !-------------------------------------------------------------------------------------------------------------------------------
    endsubroutine print_version
  endsubroutine parse

  subroutine get_cla_cli(cli,pref,switch,position,val,error)
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
  class(*),                           intent(INOUT):: val      !< CLA value.
  integer(I4P),                       intent(OUT)::   error    !< Error trapping flag.
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
    do a=1,cli%Na
      if (.not.cli%cla(a)%positional) then
        if ((cli%cla(a)%switch==switch).or.(cli%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      write(stderr,'(A)')prefd//' Error: there is no CLA into CLI containing "'//trim(adjustl(switch))//'"'
    else
      call cli%cla(a)%get(pref=prefd,val=val,error=error)
    endif
  elseif (present(position)) then
    call cli%cla(position)%get(pref=prefd,val=val,error=error)
  else
    error = 1
    write(stderr,'(A)')prefd//' Error: to obtaining a CLA value, one of CLA switch name or CLA position must be provided!'
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_cli

  subroutine get_cla_list_cli(cli,pref,switch,position,val,error)
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
  class(*),                           intent(INOUT):: val(1:)  !< CLA values.
  integer(I4P),                       intent(OUT)::   error    !< Error trapping flag.
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
    do a=1,cli%Na
      if (.not.cli%cla(a)%positional) then
        if ((cli%cla(a)%switch==switch).or.(cli%cla(a)%switch_ab==switch)) then
          found = .true.
          exit
        endif
      endif
    enddo
    if (.not.found) then
      write(stderr,'(A)')prefd//' Error: there is no CLA into CLI containing "'//trim(adjustl(switch))//'"'
    else
      call cli%cla(a)%get(pref=prefd,val=val,error=error)
    endif
  elseif (present(position)) then
    call cli%cla(position)%get(pref=prefd,val=val,error=error)
  else
    error = 1
    write(stderr,'(A)')prefd//' Error: to obtaining a CLA value, one of CLA switch name or CLA position must be provided!'
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine get_cla_list_cli

  elemental subroutine assign_cli(self1,self2)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for assignment between two selfs.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: self1 !< Left hand side.
  type(Type_Command_Line_Interface),  intent(IN)::    self2 !< Right hand side.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self2%progname   )) self1%progname    = self2%progname
  if (allocated(self2%version    )) self1%version     = self2%version
  if (allocated(self2%help       )) self1%help        = self2%help
  if (allocated(self2%description)) self1%description = self2%description
  if (allocated(self2%cla))         self1%cla         = self2%cla
                                    self1%Na          = self2%Na
                                    self1%Na_required = self2%Na_required
                                    self1%Na_optional = self2%Na_optional
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_cli
endmodule Data_Type_Command_Line_Interface

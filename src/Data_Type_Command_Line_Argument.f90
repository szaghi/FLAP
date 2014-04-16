!> @ingroup DerivedType
!> @{
!> @defgroup Data_Type_Command_Line_ArgumentDerivedType Data_Type_Command_Line_Argument
!> @}

!> @ingroup Interface
!> @{
!> @defgroup Data_Type_Command_Line_ArgumentInterface Data_Type_Command_Line_Argument
!> Module definition of Type_Command_Line_Argument
!> @}

!> @ingroup PrivateProcedure
!> @{
!> @defgroup Data_Type_Command_Line_ArgumentPrivateProcedure Data_Type_Command_Line_Argument
!> Module definition of Type_Command_Line_Argument
!> @}

!> @ingroup PublicProcedure
!> @{
!> @defgroup Data_Type_Command_Line_ArgumentPublicProcedure Data_Type_Command_Line_Argument
!> Module definition of Type_Command_Line_Argument
!> @}

!> @brief This module contains the definition of Type_Command_Line_Argument and its procedures.
!> Type_Command_Line_Argument (CLA) is a derived type containing the useful data for handling command line arguments in order to
!> easy implement flexible a Command Line Interface (CLI).
!> @note Presently there is no support for positional CLAs, but only for named ones.
!> @note Presently there is no support for multiple valued CLAs, but only for single valued ones (or without any value, i.e. logical
!> CLA).
!> @todo Add support for positional CLAs.
!> @todo Add support for multiple valued (list of values) CLAs.
module Data_Type_Command_Line_Argument
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision ! Integers and reals precision definition.
USE Lib_IO_Misc  ! Procedures for IO and strings operations.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
public:: action_store,action_store_true,action_store_false
public:: cla_init
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
character(5),  parameter:: action_store       = 'STORE'       !< CLA that stores a value associated to its switch.
character(10), parameter:: action_store_true  = 'STORE_TRUE'  !< CLA that stores .true. without the necessity of a value.
character(11), parameter:: action_store_false = 'STORE_FALSE' !< CLA that stores .false. without the necessity of a value.
!> Derived type containing the useful data for handling command line arguments in order to easy implement flexible a Command Line
!> Interface (CLI).
!> @note If not otherwise declared the action on CLA value is set to "store" a value that must be passed after the switch name.
!> @ingroup Data_Type_Command_Line_ArgumentDerivedType
type, public:: Type_Command_Line_Argument
  character(len=:), allocatable:: switch             !< Switch name.
  character(len=:), allocatable:: switch_ab          !< Abbreviated switch name.
  character(len=:), allocatable:: help               !< Help message describing the CLA.
  logical::                       required  =.false. !< Flag for set required argument.
  logical::                       positional=.false. !< Flag for checking if CLA is a positional or a named CLA.
  integer(I4P)::                  position  = 0_I4P  !< Position of positional CLA.
  logical::                       passed    =.false. !< Flag for checking if CLA has been passed to CLI.
  character(len=:), allocatable:: act                !< CLA value action.
  character(len=:), allocatable:: def                !< Default value.
  character(len=:), allocatable:: nargs              !< Number of arguments of CLA.
  character(len=:), allocatable:: choices            !< List (comma separated) of allowable values for the argument.
  character(len=:), allocatable:: val                !< CLA value.
  contains
    procedure:: free          => free_self          ! Procedure for freeing dynamic memory.
    procedure:: init          => init_self          ! Procedure for initializing CLA.
    procedure:: get           => get_self           ! Procedure for getting CLA value.
    procedure:: check         => check_self         ! Procedure for checking CLA data consistency.
    procedure:: check_choices => check_choices_self ! Procedure for checking if CLA value is in allowed choices.
    procedure:: print         => print_self         ! Procedure for printing CLA data with a pretty format.
    procedure:: add_signature                       ! Procedure for adding CLA signature to the CLI one.
    final::     finalize                            ! Procedure for freeing dynamic memory when finalizing.
    ! operators overloading
    generic:: assignment(=) => assign_self
    ! private procedures
    procedure, pass(self1), private:: assign_self
endtype Type_Command_Line_Argument
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  !> @ingroup Data_Type_Command_Line_ArgumentPrivateProcedure
  !> @{
  !> @brief Procedure for freeing dynamic memory.
  elemental subroutine free_self(cla)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla !< CLA data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated( cla%switch   )) deallocate(cla%switch   )
  if (allocated( cla%switch_ab)) deallocate(cla%switch_ab)
  if (allocated( cla%help     )) deallocate(cla%help     )
  if (allocated( cla%act      )) deallocate(cla%act      )
  if (allocated( cla%def      )) deallocate(cla%def      )
  if (allocated( cla%nargs    )) deallocate(cla%nargs    )
  if (allocated( cla%choices  )) deallocate(cla%choices  )
  if (allocated( cla%val      )) deallocate(cla%val      )
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free_self

  !> @brief Procedure for freeing dynamic memory when finalizing.
  elemental subroutine finalize(cla)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Command_Line_Argument), intent(INOUT):: cla !< CLA data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call cla%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize

  !> @brief Procedure for initializing CLA.
  !> @note If not otherwise declared the action on CLA value is set to "store" a value that must be passed after the switch name
  !> or directly passed in case of positional CLA.
  subroutine init_self(cla,pref,switch,switch_ab,help,required,positional,position,act,def,nargs,choices,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla        !< CLA data.
  character(*), optional,            intent(IN)::    pref       !< Prefixing string.
  character(*), optional,            intent(IN)::    switch     !< Switch name.
  character(*), optional,            intent(IN)::    switch_ab  !< Abbreviated switch name.
  character(*), optional,            intent(IN)::    help       !< Help message describing the CLA.
  logical,      optional,            intent(IN)::    required   !< Flag for set required argument.
  logical,      optional,            intent(IN)::    positional !< Flag for checking if CLA is a positional or a named CLA.
  integer(I4P), optional,            intent(IN)::    position   !< Position of positional CLA.
  character(*), optional,            intent(IN)::    act        !< CLA value action.
  character(*), optional,            intent(IN)::    def        !< Default value.
  character(*), optional,            intent(IN)::    nargs      !< Number of arguments of CLA.
  character(*), optional,            intent(IN)::    choices    !< List of allowable values for the argument.
  integer(I4P),                      intent(OUT)::   error      !< Error trapping flag.
  character(len=:), allocatable::                    prefd      !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine init_self

  !> @brief Procedure for getting CLA value.
  !> @note For logical type CLA the value is directly read without any robust error trapping.
  subroutine get_self(cla,pref,val,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: cla     !< CLA data.
  character(*), optional,            intent(IN)::    pref    !< Prefixing string.
  class(*),                          intent(INOUT):: val     !< CLA value.
  integer(I4P),                      intent(OUT)::   error   !< Error trapping flag.
  character(len=:), allocatable::                    prefd   !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  if (((.not.cla%passed).and.cla%required).or.((.not.cla%passed).and.(.not.allocated(cla%def)))) then
    write(stderr,'(A)')prefd//' Error: CLA "'//trim(adjustl(cla%switch))//'" is required by CLI but it has not been passed!'
    return
  endif
  if (cla%act==action_store) then
    if (cla%passed) then
      select type(val)
#ifdef r16p
      type is(real(R16P))
        val = cton(str=trim(adjustl(cla%val)),knd=1._R16P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
#endif
      type is(real(R8P))
        val = cton(str=trim(adjustl(cla%val)),knd=1._R8P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      type is(real(R4P))
        val = cton(str=trim(adjustl(cla%val)),knd=1._R4P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      type is(integer(I8P))
        val = cton(str=trim(adjustl(cla%val)),knd=1_I8P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      type is(integer(I4P))
        val = cton(str=trim(adjustl(cla%val)),knd=1_I4P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      type is(integer(I2P))
        val = cton(str=trim(adjustl(cla%val)),knd=1_I2P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      type is(integer(I1P))
        val = cton(str=trim(adjustl(cla%val)),knd=1_I1P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      type is(logical)
        read(cla%val,*)val
      type is(character(*))
        val = cla%val
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      endselect
    else
      select type(val)
#ifdef r16p
      type is(real(R16P))
        val = cton(str=trim(adjustl(cla%def)),knd=1._R16P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
#endif
      type is(real(R8P))
        val = cton(str=trim(adjustl(cla%def)),knd=1._R8P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      type is(real(R4P))
        val = cton(str=trim(adjustl(cla%def)),knd=1._R4P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      type is(integer(I8P))
        val = cton(str=trim(adjustl(cla%def)),knd=1_I8P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      type is(integer(I4P))
        val = cton(str=trim(adjustl(cla%def)),knd=1_I4P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      type is(integer(I2P))
        val = cton(str=trim(adjustl(cla%def)),knd=1_I2P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      type is(integer(I1P))
        val = cton(str=trim(adjustl(cla%def)),knd=1_I1P)
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      type is(logical)
        read(cla%def,*)val
      type is(character(*))
        val = cla%def
        if (allocated(cla%choices)) call cla%check_choices(val=val,pref=prefd,error=error)
      endselect
    endif
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
  endsubroutine get_self

  !> @brief Procedure for checking CLA data consistency.
  subroutine check_self(cla,pref,error)
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
  endsubroutine check_self

  !> @brief Procedure for checking if CLA value is in allowed choices.
  !> @note This procedure can be called if and only if cla%choices has been allocated.
  subroutine check_choices_self(cla,val,pref,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(IN)::  cla        !< CLA data.
  class(*),                          intent(IN)::  val        !< CLA value.
  character(*), optional,            intent(IN)::  pref       !< Prefixing string.
  integer(I4P),                      intent(OUT):: error      !< Error trapping flag.
  character(len=:), allocatable::                  prefd      !< Prefixing string.
  character(len(cla%choices)), allocatable::       toks(:)    !< Tokens for parsing choices list.
  integer(I4P)::                                   Nc         !< Number of choices.
  logical::                                        val_in     !< Flag for checking if val is in the choosen range.
  character(len=:), allocatable::                  val_str    !< Value in string form.
  integer(I4P)::                                   c          !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  error = 0
  val_in = .false.
  val_str = ''
  call tokenize(strin=cla%choices,delimiter=',',Nt=Nc,toks=toks)
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
    write(stderr,'(A)')prefd//' Error: the value of CLA "'//cla%switch//'" must be chosen in: ('//cla%choices//') but "'//&
                              trim(val_str)//'" has been passed!'
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_choices_self

  !> @brief Procedure for printing CLA data with a pretty format.
  subroutine print_self(cla,pref,iostat,iomsg,unit)
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
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  if (cla%act==action_store) then
    if (.not.cla%positional) then
      if (trim(adjustl(cla%switch))/=trim(adjustl(cla%switch_ab))) then
        sig = '   ['//trim(adjustl(cla%switch))//' value] or ['//trim(adjustl(cla%switch_ab))//' value]'
      else
        sig = '   ['//trim(adjustl(cla%switch))//' value]'
      endif
      if (allocated(cla%choices)) then
        sig = sig//' with value chosen in: ('//cla%choices//')'
      endif
    else
      sig = '   [value]'
      if (allocated(cla%choices)) then
        sig = sig//' with value chosen in: ('//cla%choices//')'
      endif
    endif
  else
    if (trim(adjustl(cla%switch))/=trim(adjustl(cla%switch_ab))) then
      sig = '   ['//trim(adjustl(cla%switch))//'] or ['//trim(adjustl(cla%switch_ab))//']'
    else
      sig = '   ['//trim(adjustl(cla%switch))//']'
    endif
  endif
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)prefd//sig
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)prefd//'     '//trim(adjustl(cla%help))
  if (cla%positional) then
    write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)prefd//'     It is a positional CLA having position "'//&
                                                                 trim(str(.true.,cla%position))//'-th"'
  endif
  if (cla%required) then
    write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)prefd//'     It is a non optional CLA thus must be passed to CLI'
  else
    write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)prefd//'     It is a optional CLA which default value is "'//&
                                                                 trim(adjustl(cla%def))//'"'
  endif
  if (present(iostat)) iostat = iostatd
  if (present(iomsg))  iomsg  = iomsgd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine print_self

  !> @brief Procedure for adding CLA signature to the CLI one.
  subroutine add_signature(cla,signature)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(IN)::    cla       !< CLA data.
  character(len=:), allocatable,     intent(INOUT):: signature !< CLI signature.
  character(len=:), allocatable::                    signd     !< Temporary CLI signature.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  signd = '' ; if (allocated(signature)) signd = signature
  if (cla%act==action_store) then
    if (.not.cla%positional) then
      if (cla%required) then
        signd = trim(signd)//' '//trim(adjustl(cla%switch))//' value'
      else
        signd = trim(signd)//' ['//trim(adjustl(cla%switch))//' value]'
      endif
    else
      if (cla%required) then
        signd = trim(signd)//' value'
      else
        signd = trim(signd)//' [value]'
      endif
    endif
  else
    if (cla%required) then
      signd = trim(signd)//' '//trim(adjustl(cla%switch))
    else
      signd = trim(signd)//' ['//trim(adjustl(cla%switch))//']'
    endif
  endif
  signature = signd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add_signature

  ! Assignment (=)
  !> @brief Procedure for assignment between two selfs.
  elemental subroutine assign_self(self1,self2)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Argument), intent(INOUT):: self1
  type(Type_Command_Line_Argument),  intent(IN)::    self2
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
  endsubroutine assign_self
  !> @}

  !> @ingroup Data_Type_Command_Line_ArgumentPublicProcedure
  !> @{
  !> @brief Procedure for parsing Command Line Arguments by means of a previously initialized CLA list.
  !> @note This procedure should execute the identical statements of type bound procedure init_self.
  function cla_init(pref,switch,switch_ab,help,required,positional,position,act,def,nargs,choices,error) result(cla)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN)::  pref       !< Prefixing string.
  character(*), optional, intent(IN)::  switch     !< Switch name.
  character(*), optional, intent(IN)::  switch_ab  !< Abbreviated switch name.
  character(*), optional, intent(IN)::  help       !< Help message describing the CLA.
  logical,      optional, intent(IN)::  required   !< Flag for set required argument.
  logical,      optional, intent(IN)::  positional !< Flag for checking if CLA is a positional or a named CLA.
  integer(I4P), optional, intent(IN)::  position   !< Position of positional CLA.
  character(*), optional, intent(IN)::  act        !< CLA value action.
  character(*), optional, intent(IN)::  def        !< Default value.
  character(*), optional, intent(IN)::  nargs      !< Number of arguments of CLA.
  character(*), optional, intent(IN)::  choices    !< List of allowable values for the argument.
  integer(I4P),           intent(OUT):: error      !< Error trapping flag.
  type(Type_Command_Line_Argument)::    cla        !< CLA data.
  character(len=:), allocatable::       prefd      !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction cla_init
  !> @}
endmodule Data_Type_Command_Line_Argument

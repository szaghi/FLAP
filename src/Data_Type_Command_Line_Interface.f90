!> @ingroup DerivedType
!> @{
!> @defgroup Data_Type_Command_Line_InterfaceDerivedType Data_Type_Command_Line_Interface
!> @}

!> @ingroup Interface
!> @{
!> @defgroup Data_Type_Command_Line_InterfaceInterface Data_Type_Command_Line_Interface
!> Module definition of Type_Command_Line_Interface
!> @}

!> @ingroup PrivateProcedure
!> @{
!> @defgroup Data_Type_Command_Line_InterfacePrivateProcedure Data_Type_Command_Line_Interface
!> Module definition of Type_Command_Line_Interface
!> @}

!> @ingroup PublicProcedure
!> @{
!> @defgroup Data_Type_Command_Line_InterfacePublicProcedure Data_Type_Command_Line_Interface
!> Module definition of Type_Command_Line_Interface
!> @}

!> @brief This module contains the definition of Type_Command_Line_Interface and its procedures.
!> Type_Command_Line_Interface (CLI) is a derived type containing the useful data for implementing a Command Line Interface (CLI).
module Data_Type_Command_Line_Interface
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision                    ! Integers and reals precision definition.
USE Data_Type_Command_Line_Argument ! Definition of Type_Command_Line_Argument.
USE Lib_IO_Misc                     ! Procedures for IO and strings operations.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
integer(I4P),  parameter:: max_val_len = 1000 !< Maximum number of characters of CLA value.
!> Derived type containing the useful data for implementing flexible a Command Line Interface (CLI).
!> @ingroup Data_Type_Command_Line_InterfaceDerivedType
type, public:: Type_Command_Line_Interface
  integer(I4P)::                                  Na          = 0_I4P !< Number of CLA.
  integer(I4P)::                                  Na_required = 0_I4P !< Number of command line arguments that CLI requires.
  integer(I4P)::                                  Na_optional = 0_I4P !< Number of command line arguments that are optional for CLI.
  type(Type_Command_Line_Argument), allocatable:: cla(:)              !< CLA list [1:Na].
  contains
    procedure:: free         ! Procedure for freeing dynamic memory.
    procedure:: add_cla      ! Procedure for adding CLA to CLAs list.
    procedure:: add_init_cla ! Procedure for adding an on-the-fly-initialized CLA to CLAs list.
    procedure:: check        ! Procedure for checking CLAs data consistenc.
    procedure:: passed       ! Procedure for checking if a CLA has been passed.
    procedure:: parse        ! Procedure for parsing Command Line Interfaces by means of a previously initialized CLA list.
    procedure:: get          ! Procedure for getting CLA value from CLAs list parsed.
    final::     finalize     ! Procedure for freeing dynamic memory when finalizing.
    generic::   add => add_cla,add_init_cla
    ! operators overloading
    generic:: assignment(=) => assign_self
    ! private procedures
    procedure, pass(self1), private:: assign_self
endtype Type_Command_Line_Interface
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  !> @ingroup Data_Type_Command_Line_InterfacePrivateProcedure
  !> @{
  !> @brief Procedure for freeing dynamic memory.
  elemental subroutine free(cli)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli !< CLI data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(cli%cla)) deallocate(cli%cla)
  cli%Na          = 0_I4P
  cli%Na_required = 0_I4P
  cli%Na_optional = 0_I4P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free

  !> @brief Procedure for freeing dynamic memory when finalizing.
  elemental subroutine finalize(cli)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  type(Type_Command_Line_Interface), intent(INOUT):: cli !< CLI data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call cli%free
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine finalize

  !> @brief Procedure for adding CLA to CLAs list.
  subroutine add_cla(cli,pref,cla,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli             !< CLI data.
  character(*), optional,             intent(IN)::    pref            !< Prefixing string.
  type(Type_Command_Line_Argument),   intent(IN)::    cla             !< CLA data.
  integer(I4P),                       intent(OUT)::   error           !< Error trapping flag.
  type(Type_Command_Line_Argument), allocatable::     cla_list_new(:) !< New (extended) CLA list.
  character(len=:), allocatable::                     prefd           !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  call cla%check(pref=prefd,error=error)
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add_cla

  !> @brief Procedure for adding an on-the-fly-initialized CLA to CLAs list.
  subroutine add_init_cla(cli,pref,switch,switch_ab,help,required,positional,position,act,def,nargs,choices,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli        !< CLI data.
  character(*), optional,             intent(IN)::    pref       !< Prefixing string.
  character(*), optional,             intent(IN)::    switch     !< Switch name.
  character(*), optional,             intent(IN)::    switch_ab  !< Abbreviated switch name.
  character(*), optional,             intent(IN)::    help       !< Help message describing the CLA.
  logical,      optional,             intent(IN)::    required   !< Flag for set required argument.
  logical,      optional,             intent(IN)::    positional !< Flag for checking if CLA is a positional or a named CLA.
  integer(I4P), optional,             intent(IN)::    position   !< Position of positional CLA.
  character(*), optional,             intent(IN)::    act        !< CLA value action.
  character(*), optional,             intent(IN)::    def        !< Default value.
  character(*), optional,             intent(IN)::    nargs      !< Number of arguments of CLA.
  character(*), optional,             intent(IN)::    choices    !< List of allowable values for the argument.
  integer(I4P),                       intent(OUT)::   error      !< Error trapping flag.
  type(Type_Command_Line_Argument)::                  cla        !< CLA data.
  character(len=:), allocatable::                     prefd      !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! initializing CLA data with the identical statements of type bound procedure cla%init
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
  if (error==0) call cli%add_cla(cla=cla,pref=prefd,error=error)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine add_init_cla

  !> @brief Procedure for checking CLAs data consistency.
  subroutine check(cli,pref,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(IN)::  cli   !< CLI data.
  character(*), optional,             intent(IN)::  pref  !< Prefixing string.
  integer(I4P),                       intent(OUT):: error !< Error trapping flag.
  character(len=:), allocatable::                   prefd !< Prefixing string.
  integer(I4P)::                                    a,aa  !< CLA counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  error = 0
  prefd = '' ; if (present(pref)) prefd = pref
  do a=1,cli%Na
    call cli%cla(a)%check(pref=prefd,error=error)
    if (error/=0) exit
  enddo
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

  !> @brief Procedure for checking if a CLA has been passed.
  pure function passed(cli,switch,position)
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

  !> @brief Procedure for parsing Command Line Interfaces by means of a previously initialized CLA list.
  !> @note The leading and trailing white spaces are removed from CLA values.
  subroutine parse(cli,pref,help,examples,progname,error)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: cli            !< CLI data.
  character(*), optional,             intent(IN)::    pref           !< Prefixing string.
  character(*), optional,             intent(IN)::    help           !< Help message describing the Command Line Interface.
  character(*), optional,             intent(IN)::    examples(1:)   !< Examples of correct usage.
  character(*),                       intent(IN)::    progname       !< Program name.
  integer(I4P),                       intent(OUT)::   error          !< Error trapping flag.
  integer(I4P)::                                      Na             !< Number of command line arguments passed.
  character(max_val_len)::                            switch         !< Switch name.
  character(max_val_len)::                            val            !< Switch value.
  character(len=:), allocatable::                     cli_help       !< Dummy variable for CLI help.
  logical::                                           found          !< Flag for checking if switch has been found in cli%cla.
  character(len=:), allocatable::                     prefd          !< Prefixing string.
  integer(I4P)::                                      a,aa           !< Counter for command line arguments.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  error = 0
  prefd = '' ; if (present(pref)) prefd = pref
  ! setting the general CLI help message
  if (present(help)) then
    cli_help = help
  else
    cli_help = ' The Command Line Interface (CLI) has the following options'
  endif
  ! counting the passed CLA
  Na = command_argument_count()
  if (Na<cli%Na_required) then
    write(stderr,'(A)')prefd//' Error: the Command Line Interface requires at least '//trim(str(.true.,cli%Na_required))//&
                              ' arguments to be passed whereas only '//trim(str(.true.,Na))//' have been!'
    call print_usage
    error = 1
    return
  else
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
              a = a + 1
              call get_command_argument(a,val)
              cli%cla(aa)%val = trim(adjustl(val))
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
          error = 2
          return
        else
          ! positional CLA always  stores a value
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
        error = 3
        return
      endif
    endif
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  contains
    !> @brief Procedure for printing the correct use Command Line Interface accordingly to the cli%cla passed.
    subroutine print_usage
    !-------------------------------------------------------------------------------------------------------------------------------
    character(len=:), allocatable:: cla_list_sign !< Complete signature of CLA list.
    !-------------------------------------------------------------------------------------------------------------------------------

    !-------------------------------------------------------------------------------------------------------------------------------
    cla_list_sign = '   '//progname//' '
    do a=1,cli%Na
      call cli%cla(a)%add_signature(signature=cla_list_sign)
    enddo
    write(stdout,'(A)')prefd//cli_help
    write(stdout,'(A)')prefd//cla_list_sign
    write(stdout,'(A)')prefd//' Each Command Line Argument (CLA) has the following meaning:'
    do a=1,Cli%Na
      call cli%cla(a)%print(pref=prefd,unit=stdout)
    enddo
    if (present(examples)) then
      write(stdout,'(A)')prefd//' Usage examples:'
      do a=1,size(examples,dim=1)
        write(stdout,'(A)')prefd//'   -) '//trim(examples(a))
      enddo
    endif
    return
    !-------------------------------------------------------------------------------------------------------------------------------
    endsubroutine print_usage
  endsubroutine parse

  !> @brief Procedure for getting CLA value from CLAs list parsed.
  !> @note For logical type CLA the value is directly read without any robust error trapping.
  subroutine get(cli,pref,switch,position,val,error)
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
  endsubroutine get

  ! Assignment (=)
  !> @brief Procedure for assignment between two selfs.
  elemental subroutine assign_self(self1,self2)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  class(Type_Command_Line_Interface), intent(INOUT):: self1
  type(Type_Command_Line_Interface),  intent(IN)::    self2
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self2%cla)) self1%cla =  self2%cla
                            self1%Na  =  self2%Na
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_self
  !> @}

  !> @ingroup Data_Type_Command_Line_InterfacePublicProcedure
  !> @{
  !> @}
endmodule Data_Type_Command_Line_Interface

!> @addtogroup Program Programs
!> List of excutable programs.
!> @addtogroup DerivedType Derived Types
!> List of derived data types.
!> @addtogroup GlobalVarPar Global Variables and Parameters
!> List of global variables and parameters.
!> @addtogroup PrivateVarPar Private Variables and Parameters
!> List of private variables and parameters.
!> @addtogroup Interface Interfaces
!> List of explicitly defined interface.
!> @addtogroup Library Modules Libraries
!> List of modules containing libraries of procedures.
!> @addtogroup PublicProcedure Public Procedures
!> List of public procedures.
!> @addtogroup PrivateProcedure Private Procedures
!> List of private procedures.

!> @ingroup Program
!> @{
!> @defgroup FLAP_TestProgram FLAP_Test
!> @}

!> @brief FLAP_Test is a testing program for FLAP library, a user-friendly set of Fortran modules for handling flexible Command
!> Line Interface.
!> @ingroup FLAPProgram
program FLAP_Test
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision                                                        ! Integers and reals precision definition.
USE Data_Type_Command_Line_Interface, only: Type_Command_Line_Interface ! Definition of Type_Command_Line_Interface.
USE Lib_IO_Misc                                                         ! Procedures for IO and strings operations.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
type(Type_Command_Line_Interface):: cli    !< Command Line Interface (CLI).
character(99)::                     sval   !< String value.
real(R8P)::                         rval   !< Real value.
integer(I4P)::                      ival   !< Integer value.
logical::                           bval   !< Boolean value.
logical::                           vbval  !< Valued-boolean value.
integer(I4P)::                      error  !< Error trapping flag.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
write(stdout,'(A)')'+--> flap_test, a testing program for FLAP library'
! setting CLAs
call cli%add(switch='-string',switch_ab='-s',help='String input',required=.true.,act='store')
call cli%add(switch='-integer',switch_ab='-i',help='Integer input with fixed range',required=.false.,act='store',def='1',&
             choices='1,3,5')
call cli%add(switch='-real',switch_ab='-r',help='Real input',required=.false.,act='store',def='1.0')
call cli%add(switch='-boolean',switch_ab='-b',help='Boolean input',required=.false.,act='store_true',def='.false.')
call cli%add(switch='-boolean_val',switch_ab='-bv',help='Valued boolean input',required=.false., act='store',def='.true.')
! checking consistency of CLAs
call cli%check(error=error,pref='|-->') ; if (error/=0) stop
! parsing CLI
write(stdout,'(A)')'+--> Parsing Command Line Arguments'
call cli%parse(examples=["flap_test -s 'Hello FLAP'               ",&
                         "flap_test -s 'Hello FLAP' -i -2         ",&
                         "flap_test -s 'Hello FLAP' -i -2 -r 33.d0",&
                         "flap_test -string 'Hello FLAP' -boolean "],progname='FLAP_Test',error=error,pref='|-->')
if (error/=0) stop
! using CLI data to set FLAP_Test behaviour
call cli%get(switch='-s', val=sval, error=error,pref='|-->') ; if (error/=0) stop
call cli%get(switch='-r', val=rval, error=error,pref='|-->') ; if (error/=0) stop
call cli%get(switch='-i', val=ival, error=error,pref='|-->') ; if (error/=0) stop
call cli%get(switch='-b', val=bval, error=error,pref='|-->') ; if (error/=0) stop
call cli%get(switch='-bv',val=vbval,error=error,pref='|-->') ; if (error/=0) stop
write(stdout,'(A)'  )'+--> Your flap_test calling has the following arguments values:'
write(stdout,'(A)'  )'|--> String         input = '//trim(adjustl(sval))
write(stdout,'(A)'  )'|--> Real           input = '//str(n=rval)
write(stdout,'(A)'  )'|--> Integer        input = '//str(n=ival)
write(stdout,'(A,L)')'|--> Boolean        input = ',bval
write(stdout,'(A,L)')'|--> Valued boolean input = ',vbval
stop
!-----------------------------------------------------------------------------------------------------------------------------------
endprogram FLAP_Test

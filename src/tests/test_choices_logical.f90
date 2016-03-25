!< Test FLAP for bad usage of choices option with logical
program test_choices_logical
!-----------------------------------------------------------------------------------------------------------------------------------
!< Test FLAP for bad usage of choices option with logical
!-----------------------------------------------------------------------------------------------------------------------------------
use flap, only : command_line_interface
use penf
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
logical                      :: vbval !< Valued-boolean value.
integer(I4P)                 :: error !< Error trapping flag.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
call cli%init(progname='test_choices_logical')
call cli%add(switch='--boolean-value', switch_ab='-bv', help='A help message', &
             required=.false., def='.false.', choices='.True.,.False.', act='store', error=error)
call cli%parse(error=error)
call cli%get(switch='-bv', val=vbval, error=error)
print "(A)", "Error code: "//trim(str(error, .true.))
stop
!-----------------------------------------------------------------------------------------------------------------------------------
endprogram test_choices_logical

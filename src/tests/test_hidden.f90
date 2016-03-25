!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program test_hidden
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
!-----------------------------------------------------------------------------------------------------------------------------------
use flap, only : command_line_interface
use penf
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
type(command_line_interface) :: cli       !< Command Line Interface (CLI).
character(99)                :: a_string  !< String value.
character(99)                :: g_string  !< Ghost string value.
integer(I4P)                 :: a_integer !< Integer value.
integer(I4P)                 :: error     !< Error trapping flag.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
call cli%init(description = 'hiddens usage FLAP example')
call cli%add(switch='--string', switch_ab='-s', help='a string', required=.true., act='store', error=error) ; if (error/=0) stop
call cli%add(switch='--hidden', switch_ab='-hi', help='ghost string', required=.false., def='gstring not passed', &
             hidden=.true., act='store', error=error) ; if (error/=0) stop
call cli%add(switch='--integer', switch_ab='-i', help='a integer', required=.true., act='store', error=error) ; if (error/=0) stop
call cli%get(switch='-s', val=a_string, error=error) ; if (error/=0) stop
call cli%get(switch='-hi', val=g_string, error=error) ; if (error/=0) stop
call cli%get(switch='-i', val=a_integer, error=error) ; if (error/=0) stop
print '(A)', cli%progname//' has been called with the following argument:'
print '(A)', 'String       = '//trim(adjustl(a_string))
print '(A)', 'Ghost string = '//trim(adjustl(g_string))
print '(A)', 'Integer      = '//trim(adjustl(str(a_integer, .true.)))
stop
!-----------------------------------------------------------------------------------------------------------------------------------
endprogram test_hidden

!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_ansi_color_style
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people

use flap, only : command_line_interface
use penf

implicit none
type(command_line_interface) :: cli    !< Command Line Interface (CLI).
character(99)                :: string !< String value.
integer(I4P)                 :: error  !< Error trapping flag.

call cli%init(description = 'ANSI colored-styled FLAP example', error_color='red', error_style='underline_on')
call cli%add(switch='--string', switch_ab='-s', help='a string', &
             help_color='blue', help_style='italics_on', &
             required=.true., act='store', error=error) ; if (error/=0) stop
call cli%add(switch='--optional', switch_ab='-opt', help='an optional string', &
             help_color='green', help_style='italics_on', &
             required=.false., act='store', def='hello', error=error) ; if (error/=0) stop
call cli%get(switch='-s', val=string, error=error) ; if (error/=0) stop
print '(A)', cli%progname//' has been called with the following arguments:'
print '(A)', 'string = '//trim(adjustl(string))
call cli%get(switch='-opt', val=string, error=error) ; if (error/=0) stop
print '(A)', 'optional = '//trim(adjustl(string))
endprogram flap_test_ansi_color_style

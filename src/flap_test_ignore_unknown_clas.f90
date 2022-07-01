!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_ignore_unknown_clas
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).

use flap, only : command_line_interface, ERROR_UNKNOWN_CLAS_IGNORED
use penf

implicit none
type(command_line_interface) :: cli       !< Command Line Interface (CLI).
character(99)                :: a_string  !< String value.
integer(I4P)                 :: error     !< Error trapping flag.

call cli%init(description = 'ignore unknown CLAs usage FLAP example', ignore_unknown_clas=.true.)
call cli%add(switch='--string', switch_ab='-s', help='a string', required=.true., act='store', error=error)
call cli%get(switch='-s', val=a_string, error=error)
! if (error /= ERROR_UNKNOWN_CLAS_IGNORED) stop
print '(A)', cli%progname//' has been called with the following argument:'
print '(A)', 'String       = '//trim(adjustl(a_string))
print '(A,I5)', 'Error code   = ', error
endprogram flap_test_ignore_unknown_clas

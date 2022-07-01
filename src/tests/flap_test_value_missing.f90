!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_nargs_insufficient
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<### Usage
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).

use flap, only : command_line_interface
use penf

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
real(R8P)                    :: rval  !< Real value.
integer(I4P)                 :: error !< Error trapping flag.

call cli%init(progname='test_value_missing', description='Test missing value')
call cli%add(switch='-i', help='Real input',required=.true.,act='store',error=error)
call cli%get(switch='-i', val=rval, error=error) ; if (error/=0) stop
print '(A)' ,'Real input = '//trim(str(n=rval))
endprogram flap_test_nargs_insufficient

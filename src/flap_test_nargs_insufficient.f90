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
type(command_line_interface) :: cli     !< Command Line Interface (CLI).
real(R8P)                    :: rval(3) !< Real value.
integer(I4P)                 :: error   !< Error trapping flag.

call cli%init(progname='test_nargs_insufficient', description='Test insufficient nargs')
call cli%add(switch='-i', help='Real list input',required=.true.,act='store',nargs='3',error=error)
call cli%get(switch='-i', val=rval, error=error) ; if (error/=0) stop
print '(A)' ,'Real list input = '//trim(str(n=rval))
endprogram flap_test_nargs_insufficient

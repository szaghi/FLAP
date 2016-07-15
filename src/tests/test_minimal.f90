!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program test_minimal
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
!<
!< @note The minimal steps for using a FLAP CLI are:
!<+ `init` the CLI;
!<+ `add` at least one CLA to the CLI;
!<+ `get` the CLAs defined into the CLI;
!<
!<Note that `get` automatically calls `parse` method beacuse it is not explicitely called.
!-----------------------------------------------------------------------------------------------------------------------------------
use flap, only : command_line_interface
use penf
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
type(command_line_interface) :: cli    !< Command Line Interface (CLI).
character(99)                :: string !< String value.
integer(I4P)                 :: error  !< Error trapping flag.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
call cli%init(description = 'minimal FLAP example')
call cli%add(switch='--string', switch_ab='-s', help='a string', required=.true., act='store', error=error) ; if (error/=0) stop
call cli%get(switch='-s', val=string, error=error) ; if (error/=0) stop
print '(A)', cli%progname//' has been called with the following argument:'
print '(A)', 'String = '//trim(adjustl(string))
stop
!-----------------------------------------------------------------------------------------------------------------------------------
endprogram test_minimal

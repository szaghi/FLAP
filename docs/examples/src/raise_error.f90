!run -s raise_error raise_error --nx 33
program raise_error
!< Checks only the program can do, reported in FLAP's style.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: nx
integer                      :: error

call cli%init(progname='raise_error', usage_on_error='usage')
call cli%add(switch='--nx', help='Cells along x (even)', required=.false., act='store', def='64')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
!region check
call cli%get(switch='--nx', val=nx, error=error)
if (mod(nx, 2) /= 0) error = cli%raise_error('must be even', switch='--nx')
if (error /= 0) stop 1, quiet=.true.
!endregion check
endprogram raise_error

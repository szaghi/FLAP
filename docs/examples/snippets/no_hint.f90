program no_hint
!< error_hint=.false.: the error alone, without the "Try ... --help" line.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

call cli%init(progname='no_hint', error_hint=.false.)
call cli%add(switch='--n', help='A number', required=.false., def='1')
call cli%parse(error=error)
if (error /= 0) stop cli%exit_status(), quiet=.true.
endprogram no_hint

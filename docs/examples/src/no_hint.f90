!run -s no_hint no_hint --bogus
program no_hint
!< error_hint=.false.: the error alone, without the "Try ... --help" line.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

!region define
call cli%init(progname='no_hint', error_hint=.false.)
!endregion define
call cli%add(switch='--n', help='A number', required=.false., def='1')
call cli%parse(error=error)
if (error /= 0) stop cli%exit_status(), quiet=.true.
endprogram no_hint

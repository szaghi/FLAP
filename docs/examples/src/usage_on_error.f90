!run -s usage_on_error usage_on_error
program usage_on_error
!< After a missing required option: the usage line instead of the whole help.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

!region define
call cli%init(progname='usage_on_error', usage_on_error='usage')
!endregion define
call cli%add(switch='--mesh', help='Mesh file', required=.true., act='store')
call cli%add(switch='--cfl', help='CFL', required=.false., act='store', def='0.5')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
endprogram usage_on_error

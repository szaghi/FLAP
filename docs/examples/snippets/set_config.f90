program set_config
!< A configuration file chosen by the program, read when it exists.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

call cli%init(progname='set_config')
call cli%add(switch='--cfl', help='CFL', required=.false., act='store', def='0.5')
call cli%add(switch='--steps', help='Time steps', required=.false., act='store', def='100')
call cli%set_config(file='defaults.ini') ! skipped when missing; required=.true. makes that an error
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
print '(A)', cli%provenance()
endprogram set_config

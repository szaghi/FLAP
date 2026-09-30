!run paths paths --mesh wing.grd
!run -s paths-missing paths --mesh wnig.grd
program paths
!< File names checked by parse: must exist, readable, writable, '-' allowed.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

call cli%init(progname='paths')
!region define
call cli%add(switch='--mesh', help='Mesh file', required=.true.,  act='store', readable=.true.)
call cli%add(switch='--log',  help='Log file',  required=.false., act='store', def='-', writable=.true., allow_dash=.true.)
!endregion define
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
print '(A)', 'ok'
endprogram paths

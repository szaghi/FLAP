program deprecated
!< Deprecated options and commands: a warning, never an error.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

call cli%init(progname='deprecated')
call cli%add(switch='--grid', help='Grid file', required=.false., act='store', def='g.grd', &
             deprecated='use --mesh instead')
call cli%add(switch='--mesh', help='Mesh file', required=.false., act='store', def='m.grd')
call cli%add_group(group='legacy', description='The old solver', deprecated='use run')
call cli%add_group(group='run', description='The solver')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
print '(A)', 'ok'
endprogram deprecated

!run config config
!run config-override SOLVER_CFL=0.6 config --mesh-file body.grd post
!run -s config-missing config --config other.ini
program config
!< Values from a configuration file (INI), below the command line and the environment, above the defaults.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

!region define
call cli%init(progname='config', auto_envvar_prefix='SOLVER')
call cli%add(switch='--mesh-file', help='Mesh', required=.true., act='store')
call cli%add(switch='--cfl', help='CFL', required=.false., act='store', def='0.5')
call cli%add(switch='--config', help='Configuration file', required=.false., act='config', def='solver.ini')
call cli%add_group(group='post', description='Post processing')
call cli%add(group='post', switch='--format', help='Format', required=.false., act='store', def='vtk')
!endregion define
!region provenance
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
print '(A)', cli%provenance()
!endregion provenance
endprogram config

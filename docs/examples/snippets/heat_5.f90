program heat
!< Tutorial, chapter 5: values from the environment and from a configuration file, and where each value comes from.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

! every option gets an environment variable: HEAT_THREADS, HEAT_RUN_NX, ...
call cli%init(progname='heat', version='v0.5', description='Solve the 2D heat equation on a square plate', &
              auto_envvar_prefix='HEAT')
call cli%add(switch='--threads', help='OpenMP threads', required=.false., act='store', def='1')
! the configuration file: heat.ini unless --config (or HEAT_CONFIG) names another one
call cli%add(switch='--config', help='Configuration file', required=.false., act='config', def='heat.ini')
call cli%add_group(group='run', description='Run a simulation')
call cli%add(group='run', switch='--nx', help='Cells along each direction', required=.false., act='store', def='64')
call cli%add(group='run', switch='--cfl', help='CFL number', required=.false., act='store', def='0.25')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
! the header of the run log: every value and where it comes from
print '(A)', '# heat v0.5, parameters:'
print '(A)', cli%provenance()
endprogram heat

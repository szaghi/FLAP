program solver
!< A program another program can read and check: declared types, its JSON description, JSON errors, a run manifest.
use flap
use penf
implicit none
type(command_line_interface) :: cli
integer(I4P)                 :: steps
real(R8P)                    :: cfl
integer                      :: error

call cli%init(progname='solver', version='1.2.0', description='A solver', &
              schema_option=.true., check_option=.true., error_format_env='SOLVER_ERROR_FORMAT')
call cli%add(switch='--steps', help='Time steps', required=.true., val_type='I4P')
call cli%add(switch='--cfl', help='CFL number', required=.false., def='0.5', envvar='SOLVER_CFL', &
             val_type='R8P', min='0', max='1')
call cli%add(switch='--label', help='Label of the run', required=.false., def='run')
call cli%add(switch='--token', help='Access token', required=.false., def='', sensitive=.true.)
call cli%parse(error=error)
if (error /= 0) stop error, quiet=.true.
call cli%get(switch='--steps', val=steps, error=error)
call cli%get(switch='--cfl', val=cfl, error=error)
call cli%save_provenance('solver.manifest.json', error=error)
endprogram solver

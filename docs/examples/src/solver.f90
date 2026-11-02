!run solver_bad solver --steps abc
!run solver_json SOLVER_ERROR_FORMAT=json solver --stepz 5
!run solver_check solver --check --steps 100 --cfl 0.5 --label demo
!run -s solver_check_bad solver --check --steps 100 --cfl 7
!run solver_schema solver --schema | sed -n '/"options"/,$p'
!run solver_manifest SOLVER_CFL=0.25 solver --steps 100 --token s3cret && cat solver.manifest.json
!run solver_tool python3 -I flap_tool.py solver
!run -s solver_tool_call python3 -I flap_tool.py solver '{"--steps": 100, "--cfl": 7}'
program solver
!< A program another program can read and check: declared types, its JSON description, JSON errors, a run manifest.
use flap
use penf
implicit none
type(command_line_interface) :: cli
integer(I4P)                 :: steps
real(R8P)                    :: cfl
integer                      :: error

!region define
call cli%init(progname='solver', version='1.2.0', description='A solver', &
              schema_option=.true., check_option=.true., error_format_env='SOLVER_ERROR_FORMAT')
call cli%add(switch='--steps', help='Time steps', required=.true., val_type='I4P')
call cli%add(switch='--cfl', help='CFL number', required=.false., def='0.5', envvar='SOLVER_CFL', &
             val_type='R8P', min='0', max='1')
call cli%add(switch='--label', help='Label of the run', required=.false., def='run')
call cli%add(switch='--token', help='Access token', required=.false., def='', sensitive=.true.)
!endregion define
call cli%parse(error=error)
if (error /= 0) stop cli%exit_status(), quiet=.true.
call cli%get(switch='--steps', val=steps, error=error)
call cli%get(switch='--cfl', val=cfl, error=error)
!region manifest
call cli%save_provenance('solver.manifest.json', error=error)
!endregion manifest
endprogram solver

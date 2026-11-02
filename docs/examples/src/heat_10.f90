!as heat
!run heat_10-schema heat run --schema | head -n 12
!run heat_10-check heat --check run --steps 100 --cfl 0.4 --label demo
!run -s heat_10-check-bad heat --check run --steps 100 --cfl 7
!run -s heat_10-json HEAT_ERROR_FORMAT=json heat run --stepz 100
!run -s heat_10-status heat run --steps many
!run heat_10-dry heat --dry-run run --steps 100
!run heat_10-manifest heat run --steps 100 --token s3cret && cat heat.manifest.json
!run heat_10-skill heat --write-skill && cat heat/SKILL.md
!run heat_10-cast-schema heat run --schema | head -n 8 | cut -c1-76
!run heat_10-cast-json HEAT_ERROR_FORMAT=json heat run --stepz 100 2>&1 | cut -c1-76
!cast agents heat_10-cast-schema heat_10-check-bad heat_10-cast-json heat_10-status heat_10-dry
program heat
!< Tutorial, chapter 10: a program that another program, or an agent, can read, check and call.
use flap
use penf
implicit none
type(command_line_interface) :: cli
integer(I4P)                 :: steps
real(R8P)                    :: cfl
logical                      :: write_skill
integer                      :: error

!region init
call cli%init(progname='heat', version='v1.0', description='Solve the 2D heat equation on a square plate', &
              schema_option=.true., check_option=.true., dry_run_option=.true., error_format_env='HEAT_ERROR_FORMAT')
!endregion init
!region define
call cli%add(switch='--write-skill', help='Write the agent skill and stop', required=.false., def='.false.', act='store_true')
call cli%add_group(group='run', description='Run a simulation')
call cli%add(group='run', switch='--steps', help='Time steps', required=.true., val_type='I4P', min='1')
call cli%add(group='run', switch='--cfl', help='CFL number', required=.false., def='0.25', val_type='R8P', min='0', max='1')
call cli%add(group='run', switch='--label', help='Label of the run', required=.false., def='run')
call cli%add(group='run', switch='--token', help='Access token', required=.false., def='', sensitive=.true.)
!endregion define
!region parse
call cli%parse(error=error)
if (error /= 0) stop cli%exit_status(), quiet=.true.
!endregion parse
call cli%get(switch='--write-skill', val=write_skill, error=error)
if (write_skill) then
  !region skill
  call execute_command_line('mkdir -p heat')
  call cli%save_skill('heat/SKILL.md', error=error)
  !endregion skill
  stop
endif
if (.not.cli%run_command('run')) stop
call cli%get(group='run', switch='--steps', val=steps, error=error)
call cli%get(group='run', switch='--cfl', val=cfl, error=error)
!region dry
if (cli%is_dry_run()) then
  print '(A,I0,A)', 'would run ', steps, ' steps'
  stop
endif
!endregion dry
!region manifest
call cli%save_provenance('heat.manifest.json', error=error)
!endregion manifest
print '(A,I0,A)', 'ran ', steps, ' steps'
endprogram heat

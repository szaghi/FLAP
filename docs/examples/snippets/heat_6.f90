program heat
!< Tutorial, chapter 6: validation (exclusive options, paths, deprecations, alternate actions, checks of the program).
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: nx
integer                      :: error

! after an error, print the usage line rather than the whole help
call cli%init(progname='heat', version='v0.6', description='Solve the 2D heat equation on a square plate', &
              usage_on_error='usage')
! the initial condition: exactly one of an analytical field or a restart file, which must be readable
call cli%add(switch='--init', help='Initial field', required=.false., act='store', def='', choices='gauss,step')
call cli%add(switch='--restart', help='Restart file', required=.false., act='store', def='', readable=.true., &
             metavar='FILE')
call cli%set_mutually_exclusive_switches(switches='--init,--restart', required=.true.)
call cli%add(switch='--nx', help='Cells along each direction (even)', required=.false., act='store', def='64')
! an old option, still accepted with a warning
call cli%add(switch='--dt', help='Time step', required=.false., act='store', def='0', deprecated='use --cfl')
! an auxiliary action: works without the required options
call cli%add(switch='--list-schemes', help='List the time schemes and exit', act='alternate')
call cli%parse(error=error)
if (error == STATUS_ALTERNATE) then
  print '(A)', 'fe: explicit Euler (cfl <= 0.5)'
  print '(A)', 'cn: Crank-Nicolson (any cfl)'
  stop
endif
if (error /= 0) stop 1, quiet=.true.
! a check only the program can do, reported in FLAP's style
call cli%get(switch='--nx', val=nx, error=error)
if (mod(nx, 2) /= 0) error = cli%raise_error('must be even', switch='--nx', show_usage=.false.)
if (error /= 0) stop 1, quiet=.true.
print '(A,I0)', 'heat: nx ', nx
endprogram heat

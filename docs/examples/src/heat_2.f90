!as heat
!run heat_2 heat -vv --scheme CN --cfl 0.4 --nx 100
!run heat_2-help heat --help
!run -s heat_2-choice heat --scheme euler
!run -s heat_2-range heat --cfl 0.8
!run heat_2-clamp heat --threads 1000 --save
program heat
!< Tutorial, chapter 2: options of every kind.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: nx
integer                      :: steps
real(8)                      :: cfl
character(3)                 :: scheme
integer                      :: threads
integer                      :: verbose
character(9)                 :: save
logical                      :: saving
integer                      :: error

call cli%init(progname='heat', version='v0.2', description='Solve the 2D heat equation on a square plate')
!region define
call cli%add(switch='--nx', help='Cells along each direction', required=.false., act='store', def='64', metavar='N')
call cli%add(switch='--steps', help='Time steps', required=.false., act='store', def='100', metavar='N')
! a range: the explicit scheme is stable for cfl <= 0.5
call cli%add(switch='--cfl', help='CFL number', required=.false., act='store', def='0.25', metavar='CFL', &
             min='0', min_open=.true., max='0.5')
! choices, in any case: CN is cn
call cli%add(switch='--scheme', switch_ab='-s', help='Time scheme: explicit Euler or Crank-Nicolson', required=.false., &
             act='store', def='fe', choices='fe,cn', case_sensitive=.false.)
! a clamped range: more threads than cores are pointless
call cli%add(switch='--threads', help='OpenMP threads', required=.false., act='store', def='1', min='1', max='64', &
             clamp=.true.)
! a counter: -v, -vv, -v -v ...
call cli%add(switch='--verbose', switch_ab='-v', help='Verbosity (repeatable)', required=.false., act='count')
! an optional value: --save alone saves in the default format
call cli%add(switch='--save', help='Save the solution (format: vtk, csv)', required=.false., act='store*', def='vtk', &
             choices='vtk,csv')
!endregion define
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
!region get
call cli%get(switch='--nx', val=nx, error=error)           ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--steps', val=steps, error=error)     ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--cfl', val=cfl, error=error)         ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--scheme', val=scheme, error=error)   ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--threads', val=threads, error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--verbose', val=verbose, error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--save', val=save, error=error)       ; if (error /= 0) stop 1, quiet=.true.
saving = cli%is_passed(switch='--save')
!endregion get

print '(A,I0,A,I0,A,I0,A,F4.2,A)', 'heat: ', nx, 'x', nx, ' cells, ', steps, ' steps, cfl ', cfl, ', scheme '//trim(scheme)
print '(A,I0,A,I0)', 'threads ', threads, ', verbosity ', verbose
if (saving) print '(A)', 'saving the solution as '//trim(save)
endprogram heat

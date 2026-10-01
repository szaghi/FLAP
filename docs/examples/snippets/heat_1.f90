program heat
!< Tutorial, chapter 1: a first command line.
use flap
implicit none
type(command_line_interface) :: cli   ! the command line interface
integer                      :: nx    ! cells along each direction
integer                      :: steps ! time steps
real(8)                      :: cfl   ! CFL number
integer                      :: error ! error code

! 1. initialise
call cli%init(progname='heat', version='v0.1', description='Solve the 2D heat equation on a square plate')
! 2. define
call cli%add(switch='--nx', help='Cells along each direction', required=.false., act='store', def='64')
call cli%add(switch='--steps', help='Time steps', required=.false., act='store', def='100')
call cli%add(switch='--cfl', help='CFL number', required=.false., act='store', def='0.25')
! 3. parse
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
! 4. get
call cli%get(switch='--nx', val=nx, error=error)       ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--steps', val=steps, error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--cfl', val=cfl, error=error)     ; if (error /= 0) stop 1, quiet=.true.

print '(A,I0,A,I0,A,I0,A,F4.2)', 'heat: ', nx, 'x', nx, ' cells, ', steps, ' steps, cfl ', cfl
endprogram heat

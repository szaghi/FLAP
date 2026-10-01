!as heat
!run heat_3 heat --probe 0.5 0.25 --fields T flux --set alpha=2e-5 t_end=60
!run heat_3-default heat
!run heat_3-nofields heat --fields
!run -s heat_3-map heat --set alfa=1
!run heat_3-help heat --help
program heat
!< Tutorial, chapter 3: lists of values and KEY=VALUE parameters.
use flap
implicit none
type(command_line_interface) :: cli
real(8)                      :: probe(2)
character(4), allocatable    :: fields(:)
real(8)                      :: alpha
real(8)                      :: t_end
logical                      :: found
integer                      :: error
integer                      :: f

call cli%init(progname='heat', version='v0.3', description='Solve the 2D heat equation on a square plate')
!region define
! exactly two values: the coordinates of a probe
call cli%add(switch='--probe', help='Probe coordinates', required=.false., act='store', nargs='2', def='0.5 0.5', &
             metavar='X')
! any number of values, each one a choice: the switch alone saves nothing
call cli%add(switch='--fields', help='Fields to save', required=.false., act='store', nargs='*', def='T', &
             choices='T,flux', metavar='NAME')
! KEY=VALUE pairs overriding the physical parameters
call cli%add(switch='--set', help='Physical parameters', required=.false., act='store', nargs='+', map=.true., &
             map_keys='alpha,t_end', def='alpha=1e-4')
!endregion define
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
!region get
call cli%get(switch='--probe', val=probe, error=error)           ; if (error /= 0) stop 1, quiet=.true.
call cli%get_varying(switch='--fields', val=fields, error=error) ; if (error /= 0) stop 1, quiet=.true.
alpha = 1.0d-4 ; t_end = 10.0d0                                   ! the built-in values
call cli%get_map_value(switch='--set', key='alpha', val=alpha, found=found, error=error)
call cli%get_map_value(switch='--set', key='t_end', val=t_end, found=found, error=error)
!endregion get

print '(A,2(F5.2,1X))', 'probe at ', probe
print '(A,I0,A,*(A,:,", "))', 'saving ', size(fields), ' field(s): ', (trim(fields(f)), f=1, size(fields))
print '(A,ES8.1,A,F5.1)', 'alpha = ', alpha, ', t_end = ', t_end
endprogram heat

program map
!< KEY=VALUE options (maps): override the parameters of an input deck.
use flap
implicit none
type(command_line_interface) :: cli
real(8)                      :: cfl
integer                      :: nx
logical                      :: found
integer                      :: error

call cli%init(progname='map')
call cli%add(switch='--set', switch_ab='-s', help='Override input-deck parameters', required=.false., act='store', &
             nargs='+', map=.true., map_keys='cfl,nx,ny,t_end', def='cfl=0.8')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
cfl = 0.9_8 ; nx = 128                                                 ! the values of the input deck
call cli%get_map_value(switch='--set', key='cfl', val=cfl, found=found) ! overridden only if given
call cli%get_map_value(switch='--set', key='nx',  val=nx,  found=found)
print '(A,F4.2,A,I0)', 'cfl = ', cfl, ', nx = ', nx
endprogram map

!run map map --set cfl=0.5 nx=256
!run map-default map
!run -s map-twice map --set cfl=0.5 cfl=0.6
!run -s map-unknown map --set cfll=0.5
!run -s map-format map --set nx
!run map-help map --help
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
!region define
call cli%add(switch='--set', switch_ab='-s', help='Override input-deck parameters', required=.false., act='store', &
             nargs='+', map=.true., map_keys='cfl,nx,ny,t_end', def='cfl=0.8')
!endregion define
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
!region get
cfl = 0.9_8 ; nx = 128                                                 ! the values of the input deck
call cli%get_map_value(switch='--set', key='cfl', val=cfl, found=found) ! overridden only if given
call cli%get_map_value(switch='--set', key='nx',  val=nx,  found=found)
!endregion get
print '(A,F4.2,A,I0)', 'cfl = ', cfl, ', nx = ', nx
endprogram map

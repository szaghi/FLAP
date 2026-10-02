program store_false
!< A flag that is true unless passed.
use flap
implicit none
type(command_line_interface) :: cli
logical                      :: color
integer                      :: error

call cli%init(progname='store_false')
call cli%add(switch='--no-color', help='Plain output', required=.false., act='store_false', def='.true.')
call cli%get(switch='--no-color', val=color, error=error)
if (error /= 0) stop 1, quiet=.true.
print '(A,L1)', 'color = ', color
endprogram store_false

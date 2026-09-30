program minimal
!< A minimal FLAP program: one required option.
use flap
implicit none
type(command_line_interface) :: cli
character(99)                :: string
integer                      :: error

call cli%init(description='minimal FLAP example')
call cli%add(switch='--string', switch_ab='-s', help='a string', required=.true., act='store', error=error)
if (error /= 0) stop 1, quiet=.true.
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='-s', val=string, error=error)
if (error /= 0) stop 1, quiet=.true.
print '(A)', 'String = '//trim(string)
endprogram minimal

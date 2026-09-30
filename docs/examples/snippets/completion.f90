program completion
!< The program offers its own completion scripts and man page.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

call cli%init(progname='completion', version='v1.0', description='A solver', &
              completion_options=.true., man_option=.true.)
call cli%add(switch='--mesh', switch_ab='-m', help='Mesh file', required=.true., act='store')
call cli%add(switch='--scheme', help='Space scheme', required=.false., act='store', def='weno5', choices='weno5,muscl')
call cli%add_group(group='post', description='Post processing')
call cli%add(group='post', switch='--format', help='Format', required=.false., act='store', def='vtk', &
             choices='vtk,vtu')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
endprogram completion

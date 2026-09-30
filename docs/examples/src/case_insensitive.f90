!run case_insensitive case_insensitive --MESH wing.grd RUN
program case_insensitive
!< Switches and command names matched in any case.
use flap
implicit none
type(command_line_interface) :: cli
character(99)                :: mesh
integer                      :: error

!region define
call cli%init(progname='case_insensitive', case_insensitive=.true.) ! before any add
!endregion define
call cli%add(switch='--mesh', help='Mesh file', required=.true., act='store')
call cli%add_group(group='run', description='Run')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--mesh', val=mesh, error=error)
print '(A,L1)', 'mesh = '//trim(mesh)//', run = ', cli%run_command('run')
endprogram case_insensitive

!run environment environment --mesh-file body.grd
!run environment-env SOLVER_MESH_FILE=wing.grd MY_TOKEN=abc environment
!run environment-both SOLVER_MESH_FILE=wing.grd environment --mesh-file body.grd
!run environment-list SOLVER_MESH_FILE=wing.grd SOLVER_WORKERS='1, 2 ,3' SOLVER_FAST=yes environment
!run environment-help environment --help
program environment
!< Values from environment variables: explicit names (envvar) and generated ones (auto_envvar_prefix).
use flap
implicit none
type(command_line_interface) :: cli
character(99)                :: mesh
character(99)                :: token
integer, allocatable         :: workers(:)
logical                      :: fast
integer                      :: error

!region define
call cli%init(progname='environment', auto_envvar_prefix='SOLVER')
call cli%add(switch='--mesh-file', help='Mesh', required=.true., act='store')                   ! SOLVER_MESH_FILE
call cli%add(switch='--workers', help='Workers', required=.false., act='store', nargs='+', def='1') ! SOLVER_WORKERS
call cli%add(switch='--fast', help='Fast mode', required=.false., act='store_true', def='.false.')  ! SOLVER_FAST
call cli%add(switch='--token', help='API token', required=.false., act='store', def='none', envvar='MY_TOKEN')
!endregion define
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--mesh-file', val=mesh, error=error)
call cli%get_varying(switch='--workers', val=workers, error=error)
call cli%get(switch='--fast', val=fast, error=error)
call cli%get(switch='--token', val=token, error=error)
print '(A,*(I0,:,","))', 'mesh = '//trim(mesh)//', token = '//trim(token)//', workers = ', workers
print '(A,L1)', 'fast = ', fast
print '(A)', cli%provenance()
endprogram environment

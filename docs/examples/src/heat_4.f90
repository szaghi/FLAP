!as heat
!run heat_4-help heat --help
!run heat_4-run-help heat run --help
!run heat_4 heat --threads 4 run --nx 128 -v post --format csv
!run heat_4-alias heat r
!run heat_4-info heat info
program heat
!< Tutorial, chapter 4: commands, with their options and aliases.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: threads
integer                      :: error

call cli%init(progname='heat', version='v0.4', description='Solve the 2D heat equation on a square plate')
!region define
! the top level: options before any command
call cli%add(switch='--threads', help='OpenMP threads', required=.false., act='store', def='1')
! the commands
call cli%add_group(group='run', aliases='r', description='Run a simulation')
call cli%add_group(group='post', aliases='p', description='Post-process the results')
call cli%add_group(group='info', description='Print the build information')
! the options of each command
call cli%add(group='run', switch='--nx', help='Cells along each direction', required=.false., act='store', def='64')
call cli%add(group='run', switch='--cfl', help='CFL number', required=.false., act='store', def='0.25')
call cli%add(group='post', switch='--format', help='Output format', required=.false., act='store', def='vtk', &
             choices='vtk,csv')
! one definition, copied into two commands: each copy has its own value
call cli%add(switch='--verbose', switch_ab='-v', help='Verbosity (repeatable)', required=.false., act='count')
call cli%copy_options(to_group='run', switches='--verbose')
call cli%copy_options(to_group='post', switches='--verbose')
!endregion define
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--threads', val=threads, error=error)
print '(A,I0,A)', 'heat on ', threads, ' thread(s)'
!region dispatch
! several commands can be called on one command line: one block each
if (cli%run_command('run')) call run
if (cli%run_command('post')) call post
if (cli%run_command('info')) print '(A)', 'heat v0.4, built with FLAP'
!endregion dispatch

contains
  !region run
  subroutine run
  !< The run command.
  integer :: nx, verbose, e
  real(8) :: cfl

  call cli%get(group='run', switch='--nx', val=nx, error=e)
  call cli%get(group='run', switch='--cfl', val=cfl, error=e)
  call cli%get(group='run', switch='--verbose', val=verbose, error=e)
  print '(A,I0,A,F4.2,A,I0)', 'run: nx ', nx, ', cfl ', cfl, ', verbosity ', verbose
  endsubroutine run
  !endregion run

  subroutine post
  !< The post command.
  character(3) :: format
  integer      :: verbose, e

  call cli%get(group='post', switch='--format', val=format, error=e)
  call cli%get(group='post', switch='--verbose', val=verbose, error=e)
  print '(A,I0)', 'post: format '//format//', verbosity ', verbose
  endsubroutine post
endprogram heat

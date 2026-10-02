program exclusive_groups
!< Two commands that cannot be called on the same command line.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

call cli%init(progname='exclusive_groups')
call cli%add_group(group='run', description='Run a simulation')
call cli%add_group(group='clean', description='Remove the results')
call cli%set_mutually_exclusive_groups(group1='run', group2='clean')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
if (cli%run_command('run')) print '(A)', 'running'
if (cli%run_command('clean')) print '(A)', 'cleaning'
endprogram exclusive_groups

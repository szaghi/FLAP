program ignore_env
!< Reproducible runs: every environment lookup turned off.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: threads
integer                      :: error

call cli%init(progname='ignore_env', ignore_env=.true.)
call cli%add(switch='--threads', help='Threads', required=.false., act='store', def='1', envvar='OMP_NUM_THREADS')
call cli%get(switch='--threads', val=threads, error=error)
print '(A,I0)', 'threads = ', threads
endprogram ignore_env

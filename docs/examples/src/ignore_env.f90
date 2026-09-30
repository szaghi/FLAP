!run ignore_env OMP_NUM_THREADS=64 ignore_env
program ignore_env
!< Reproducible runs: every environment lookup turned off.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: threads
integer                      :: error

!region define
call cli%init(progname='ignore_env', ignore_env=.true.)
call cli%add(switch='--threads', help='Threads', required=.false., act='store', def='1', envvar='OMP_NUM_THREADS')
!endregion define
call cli%get(switch='--threads', val=threads, error=error)
print '(A,I0)', 'threads = ', threads
endprogram ignore_env

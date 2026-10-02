!run passed passed
!run passed-env OMP_NUM_THREADS=8 passed
!run passed-cli OMP_NUM_THREADS=8 passed --threads 2
program passed
!< Whether an option was passed on the command line, and where its value comes from.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: threads
integer                      :: error

call cli%init(progname='passed')
call cli%add(switch='--threads', help='Threads', required=.false., act='store', def='1', envvar='OMP_NUM_THREADS')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--threads', val=threads, error=error)
!region query
print '(A,I0,A,L1)', 'threads = ', threads, ', passed on the command line: ', cli%is_passed(switch='--threads')
select case(cli%get_source(switch='--threads'))
case(SOURCE_COMMANDLINE) ; print '(A)', 'from the command line'
case(SOURCE_ENVIRONMENT) ; print '(A)', 'from the environment'
case(SOURCE_CONFIG)      ; print '(A)', 'from the configuration file'
case(SOURCE_DEFAULT)     ; print '(A)', 'the default'
endselect
!endregion query
endprogram passed

!run ranges ranges --cfl 0.5 --threads 999
!run -s ranges-error ranges --cfl 1.5
!run ranges-help ranges --help
program ranges
!< Numeric ranges, checked by get: open or closed bounds, or clamped values.
use flap
implicit none
type(command_line_interface) :: cli
real(8)                      :: cfl
integer                      :: threads
integer                      :: error

call cli%init(progname='ranges')
!region define
call cli%add(switch='--cfl', help='CFL number', required=.false., act='store', def='0.8', &
             min='0', min_open=.true., max='1')                 ! (0, 1]
call cli%add(switch='--threads', help='OpenMP threads', required=.false., act='store', def='1', &
             min='1', max='256', clamp=.true.)                  ! [1, 256], out-of-range values clamped
!endregion define
call cli%get(switch='--cfl', val=cfl, error=error)
if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--threads', val=threads, error=error)
print '(A,F4.2,A,I0)', 'cfl = ', cfl, ', threads = ', threads
endprogram ranges

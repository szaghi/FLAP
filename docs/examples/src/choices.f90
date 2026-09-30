!run choices choices --level 3 --scheme WENO5
!run -s choices-error choices --level 2
!run choices-help choices --help
program choices
!< Values restricted to a list of choices.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: level
character(9)                 :: scheme
integer                      :: error

call cli%init(progname='choices')
!region define
call cli%add(switch='--level', switch_ab='-l', help='Verbosity level', required=.false., act='store', def='1', &
             choices='1,3,5')
! case_sensitive=.false.: WENO5 matches weno5, and get returns the declared spelling
call cli%add(switch='--scheme', help='Space scheme', required=.false., act='store', def='muscl', &
             choices='weno5,muscl', case_sensitive=.false.)
!endregion define
call cli%get(switch='--level', val=level, error=error)
if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--scheme', val=scheme, error=error)
if (error /= 0) stop 1, quiet=.true.
print '(A,I0,A)', 'level = ', level, ', scheme = '//trim(scheme)
endprogram choices

!run own_version own_version --version
!run own_version-help own_version --help
program own_version
!< A program defining its own --version: a builtin leaves its place to it.
use flap
implicit none
type(command_line_interface) :: cli
logical                      :: version
integer                      :: error

!region define
call cli%init(progname='own_version')
call cli%add(switch='--version', switch_ab='-V', help='Print the build information', required=.false., def='.false.', &
             act='store_true')
!endregion define
call cli%parse(error=error)
if (error /= 0) stop cli%exit_status(), quiet=.true.
call cli%get(switch='--version', val=version, error=error)
if (version) print '(A)', 'own_version 1.2.3, built with its own information'
endprogram own_version

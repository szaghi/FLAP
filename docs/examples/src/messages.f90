!run messages messages
program messages
!< The error message, the signature and the help as text, for the program's own log or interface.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: quiet
integer                      :: error

!region text
open(newunit=quiet, status='scratch')
call cli%init(progname='messages', description='Messages as text', &
              error_lun=quiet, usage_lun=quiet)                    ! FLAP prints nowhere: the program reports
call cli%add(switch='--nx', help='Cells', required=.false., act='store', def='64')
call cli%parse(args='--nxx 4', error=error)
if (error /= 0) print '(A,I0,A)', 'code ', error, ': '//cli%error_message
print '(A)', 'signature:'//cli%signature() ! the arguments, as in the usage line
print '(A)', cli%usage(g=0)                 ! the help of the top level (g: the index of a command)
!endregion text
endprogram messages

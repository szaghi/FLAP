!run messages messages
program messages
!< The signature and the help as text, for the program's own log or interface.
use flap
implicit none
type(command_line_interface) :: cli

call cli%init(progname='messages', description='The usage as text')
call cli%add(switch='--nx', help='Cells', required=.false., act='store', def='64')
!region text
print '(A)', 'signature:'//cli%signature() ! the arguments, as in the usage line
print '(A)', cli%usage(g=0)                 ! the help of the top level (g: the index of a command)
!endregion text
endprogram messages

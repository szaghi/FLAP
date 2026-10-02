!run units units --nxx 4 || cat flap.log
program units
!< The help and the errors written to units of the program: here a log file.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: log
integer                      :: error

!region define
open(newunit=log, file='flap.log', action='write')
call cli%init(progname='units', usage_lun=log, error_lun=log) ! the help and the errors go to the log
!endregion define
call cli%add(switch='--nx', help='Cells', required=.false., act='store', def='64')
call cli%parse(error=error)
close(log)
if (error /= 0) stop 1, quiet=.true.
endprogram units

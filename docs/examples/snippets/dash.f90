program dash
!< A path option accepting - for the standard input.
use flap
implicit none
type(command_line_interface) :: cli
character(99)                :: input, line
integer                      :: error, unit

call cli%init(progname='dash')
call cli%add(switch='--input', help='Input file, - for the standard input', required=.true., must_exist=.true., allow_dash=.true.)
call cli%parse(error=error)
if (error /= 0) stop cli%exit_status(), quiet=.true.
call cli%get(switch='--input', val=input, error=error)
if (trim(input) == '-') then
  read(*, '(A)') line
else
  open(newunit=unit, file=trim(input), action='read')
  read(unit, '(A)') line
  close(unit)
endif
print '(A)', trim(line)
endprogram dash

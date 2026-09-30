program positional
!< Positional arguments, matched by their position among the values that are not switches.
use flap
implicit none
type(command_line_interface) :: cli
character(99)                :: input
real                         :: scale
logical                      :: verbose
integer                      :: error

call cli%init(progname='positional')
call cli%add(positional=.true., position=1, help='Input file', required=.true., act='store', metavar='INPUT')
call cli%add(positional=.true., position=2, help='Scale factor', required=.false., act='store', def='1.0', &
             metavar='SCALE')
call cli%add(switch='--verbose', help='Verbose', required=.false., act='store_true', def='.false.')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
call cli%get(position=1, val=input, error=error)
call cli%get(position=2, val=scale, error=error)
call cli%get(switch='--verbose', val=verbose, error=error)
print '(A,F4.2,A,L1)', 'input = '//trim(input)//', scale = ', scale, ', verbose = ', verbose
endprogram positional

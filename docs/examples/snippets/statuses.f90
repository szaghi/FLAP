program statuses
!< standalone=.false.: parse returns the statuses (help printed, ...) instead of ending the program.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

call cli%init(progname='statuses', version='v2.4.0', standalone=.false., no_args_is_help=.true.)
call cli%add(switch='--mesh', help='Mesh file', required=.false., act='store', def='m.grd')
call cli%parse(error=error)
select case(error)
case(0)
  print '(A)', 'running'
case(STATUS_PRINT_H, STATUS_PRINT_V, STATUS_PRINT_M)
  print '(A)', 'help, version or Markdown printed: cleaning up, then exit status 0'
case(STATUS_NO_ARGS)
  stop 2, quiet=.true.
case default
  stop 1, quiet=.true.
endselect
endprogram statuses

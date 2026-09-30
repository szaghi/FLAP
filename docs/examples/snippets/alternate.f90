program alternate
!< An alternate action (--list-models): parse returns STATUS_ALTERNATE, skipping the value checks.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

call cli%init(progname='alternate')
call cli%add(switch='--mesh',        help='Mesh file',                       required=.true., act='store')
call cli%add(switch='--list-models', help='List the turbulence models and exit', act='alternate')
call cli%parse(error=error)
if (error == STATUS_ALTERNATE) then
  if (cli%is_passed(switch='--list-models')) print '(A)', 'spalart-allmaras, k-omega-sst'
  stop
elseif (error /= 0) then
  stop 1, quiet=.true.
endif
print '(A)', 'running'
endprogram alternate

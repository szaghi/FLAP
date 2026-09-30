program exclusive
!< Options that cannot be used together: a pair (exclude) and sets (at most one, or exactly one, of them).
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

call cli%init(progname='exclusive', usage_on_error='usage')
call cli%add(switch='--json', help='JSON output', required=.false., act='store_true', def='.false.', exclude='--csv')
call cli%add(switch='--csv',  help='CSV output',  required=.false., act='store_true', def='.false.', exclude='--json')
call cli%add(switch='--mesh',    switch_ab='-m', help='Mesh file',    required=.false., act='store', def='')
call cli%add(switch='--restart', switch_ab='-r', help='Restart file', required=.false., act='store', def='')
call cli%add(switch='--left',  help='Go left',  required=.false., act='store_true', def='.false.')
call cli%add(switch='--right', help='Go right', required=.false., act='store_true', def='.false.')
call cli%set_mutually_exclusive_switches(switches='--mesh,--restart', required=.true.) ! exactly one
call cli%set_mutually_exclusive_switches(switches='--left,--right')                    ! at most one
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
print '(A)', 'ok'
endprogram exclusive

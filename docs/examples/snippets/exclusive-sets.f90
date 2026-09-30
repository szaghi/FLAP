call cli%add(switch='--mesh',    switch_ab='-m', help='Mesh file',    required=.false., act='store', def='')
call cli%add(switch='--restart', switch_ab='-r', help='Restart file', required=.false., act='store', def='')
call cli%add(switch='--left',  help='Go left',  required=.false., act='store_true', def='.false.')
call cli%add(switch='--right', help='Go right', required=.false., act='store_true', def='.false.')
call cli%set_mutually_exclusive_switches(switches='--mesh,--restart', required=.true.) ! exactly one
call cli%set_mutually_exclusive_switches(switches='--left,--right')                    ! at most one

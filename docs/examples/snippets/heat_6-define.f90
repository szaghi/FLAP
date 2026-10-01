! the initial condition: exactly one of an analytical field or a restart file, which must be readable
call cli%add(switch='--init', help='Initial field', required=.false., act='store', def='', choices='gauss,step')
call cli%add(switch='--restart', help='Restart file', required=.false., act='store', def='', readable=.true., &
             metavar='FILE')
call cli%set_mutually_exclusive_switches(switches='--init,--restart', required=.true.)
call cli%add(switch='--nx', help='Cells along each direction (even)', required=.false., act='store', def='64')
! an old option, still accepted with a warning
call cli%add(switch='--dt', help='Time step', required=.false., act='store', def='0', deprecated='use --cfl')
! an auxiliary action: works without the required options
call cli%add(switch='--list-schemes', help='List the time schemes and exit', act='alternate')

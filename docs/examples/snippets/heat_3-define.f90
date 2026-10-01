! exactly two values: the coordinates of a probe
call cli%add(switch='--probe', help='Probe coordinates', required=.false., act='store', nargs='2', def='0.5 0.5', &
             metavar='X')
! any number of values, each one a choice: the switch alone saves nothing
call cli%add(switch='--fields', help='Fields to save', required=.false., act='store', nargs='*', def='T', &
             choices='T,flux', metavar='NAME')
! KEY=VALUE pairs overriding the physical parameters
call cli%add(switch='--set', help='Physical parameters', required=.false., act='store', nargs='+', map=.true., &
             map_keys='alpha,t_end', def='alpha=1e-4')

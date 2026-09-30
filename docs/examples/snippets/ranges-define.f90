call cli%add(switch='--cfl', help='CFL number', required=.false., act='store', def='0.8', &
             min='0', min_open=.true., max='1')                 ! (0, 1]
call cli%add(switch='--threads', help='OpenMP threads', required=.false., act='store', def='1', &
             min='1', max='256', clamp=.true.)                  ! [1, 256], out-of-range values clamped

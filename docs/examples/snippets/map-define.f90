call cli%add(switch='--set', switch_ab='-s', help='Override input-deck parameters', required=.false., act='store', &
             nargs='+', map=.true., map_keys='cfl,nx,ny,t_end', def='cfl=0.8')

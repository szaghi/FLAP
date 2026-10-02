! a flag with its negation: the last one passed wins
call cli%add(switch='--restart', switch_neg='--no-restart', help='Restart from the checkpoint', required=.false., &
             act='store_true', def='.true.')

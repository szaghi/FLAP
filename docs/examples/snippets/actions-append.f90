! append: one value per occurrence
call cli%add(switch='--include', switch_ab='-I', help='Include directory (repeatable)', required=.false., &
             act='append', def='.')

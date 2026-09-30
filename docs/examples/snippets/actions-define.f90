! count: -v -v, -vv or --verbose --verbose give 2
call cli%add(switch='--verbose', switch_ab='-v', help='Verbosity (repeatable)', required=.false., act='count')
! append: one value per occurrence
call cli%add(switch='--include', switch_ab='-I', help='Include directory (repeatable)', required=.false., &
             act='append', def='.')
! store*: the value is optional, the switch alone gives the default
call cli%add(switch='--format', help='Output format', required=.false., act='store*', def='text')
! a flag with its negation: the last one passed wins
call cli%add(switch='--restart', switch_neg='--no-restart', help='Restart from the checkpoint', required=.false., &
             act='store_true', def='.true.')
! a hidden flag: parsed, but not shown in the help
call cli%add(switch='--debug-internal', help='Internal debug flag', required=.false., act='store_true', def='.false.', &
             hidden=.true.)

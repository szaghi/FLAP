! count: -v -v, -vv or --verbose --verbose give 2
call cli%add(switch='--verbose', switch_ab='-v', help='Verbosity (repeatable)', required=.false., act='count')

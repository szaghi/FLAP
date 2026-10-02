! store*: the value is optional, the switch alone gives the default
call cli%add(switch='--format', help='Output format', required=.false., act='store*', def='text')

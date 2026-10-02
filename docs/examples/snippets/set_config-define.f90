call cli%add(switch='--cfl', help='CFL', required=.false., act='store', def='0.5')
call cli%add(switch='--steps', help='Time steps', required=.false., act='store', def='100')
call cli%set_config(file='defaults.ini') ! skipped when missing; required=.true. makes that an error

call cli%init(progname='solver', version='1.2.0', description='A solver', &
              schema_option=.true., check_option=.true., error_format_env='SOLVER_ERROR_FORMAT')
call cli%add(switch='--steps', help='Time steps', required=.true., val_type='I4P')
call cli%add(switch='--cfl', help='CFL number', required=.false., def='0.5', envvar='SOLVER_CFL', &
             val_type='R8P', min='0', max='1')
call cli%add(switch='--label', help='Label of the run', required=.false., def='run')
call cli%add(switch='--token', help='Access token', required=.false., def='', sensitive=.true.)

call cli%init(progname='environment', auto_envvar_prefix='SOLVER')
call cli%add(switch='--mesh-file', help='Mesh', required=.true., act='store')                   ! SOLVER_MESH_FILE
call cli%add(switch='--workers', help='Workers', required=.false., act='store', nargs='+', def='1') ! SOLVER_WORKERS
call cli%add(switch='--fast', help='Fast mode', required=.false., act='store_true', def='.false.')  ! SOLVER_FAST
call cli%add(switch='--token', help='API token', required=.false., act='store', def='none', envvar='MY_TOKEN')

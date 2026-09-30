call cli%init(progname='ignore_env', ignore_env=.true.)
call cli%add(switch='--threads', help='Threads', required=.false., act='store', def='1', envvar='OMP_NUM_THREADS')

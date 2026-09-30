! defined once at the top level, then copied into the commands
call cli%add(switch='--jobs',    switch_ab='-j', help='Parallel jobs', required=.false., act='store', def='1')
call cli%add(switch='--verbose', help='Verbose', required=.false., act='store_true', def='.false.')
call cli%copy_options(to_group='compile')                     ! --jobs and --verbose
call cli%copy_options(to_group='link', switches='--verbose')  ! --verbose only

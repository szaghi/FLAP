call cli%init(progname='own_version')
call cli%add(switch='--version', switch_ab='-V', help='Print the build information', required=.false., def='.false.', &
             act='store_true')

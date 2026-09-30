call cli%add(positional=.true., position=1, help='Input file', required=.true., act='store', metavar='INPUT')
call cli%add(positional=.true., position=2, help='Scale factor', required=.false., act='store', def='1.0', &
             metavar='SCALE')
call cli%add(switch='--verbose', help='Verbose', required=.false., act='store_true', def='.false.')

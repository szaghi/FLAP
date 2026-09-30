call cli%add(switch='--mesh', help='Mesh file', required=.true.,  act='store', readable=.true.)
call cli%add(switch='--log',  help='Log file',  required=.false., act='store', def='-', writable=.true., allow_dash=.true.)

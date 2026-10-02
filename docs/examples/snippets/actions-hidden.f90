! a hidden flag: parsed, but not shown in the help
call cli%add(switch='--debug-internal', help='Internal debug flag', required=.false., act='store_true', def='.false.', &
             hidden=.true.)

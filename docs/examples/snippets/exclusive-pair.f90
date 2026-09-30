call cli%add(switch='--json', help='JSON output', required=.false., act='store_true', def='.false.', exclude='--csv')
call cli%add(switch='--csv',  help='CSV output',  required=.false., act='store_true', def='.false.', exclude='--json')

call cli%add(switch='--mesh',        help='Mesh file',                       required=.true., act='store')
call cli%add(switch='--list-models', help='List the turbulence models and exit', act='alternate')

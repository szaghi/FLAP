call cli%add(switch='--grid', help='Grid file', required=.false., act='store', def='g.grd', &
             deprecated='use --mesh instead')
call cli%add(switch='--mesh', help='Mesh file', required=.false., act='store', def='m.grd')
call cli%add_group(group='legacy', description='The old solver', deprecated='use run')
call cli%add_group(group='run', description='The solver')

call cli%init(progname='colors', description='Coloured output', error_color='red', error_style='bold_on')
call cli%add(switch='--mesh', switch_ab='-m', help='Mesh file', required=.false., act='store', def='m.grd', &
             help_color='cyan', help_style='bold_on')
call cli%add(switch='--cfl', help='CFL number', required=.false., act='store', def='0.5', help_color='yellow')

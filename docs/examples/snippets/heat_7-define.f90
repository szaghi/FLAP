call cli%add(switch='--nx', help='Cells along each direction', required=.false., act='store', def='64', metavar='N', &
             help_color='cyan', help_style='bold_on')
call cli%add(switch='--scheme', help='Time scheme', required=.false., act='store', def='fe', choices='fe,cn', &
             help_color='cyan', help_style='bold_on')
call cli%add_group(group='run', description='Run a simulation')
call cli%add(group='run', switch='--cfl', help='CFL number', required=.false., act='store', def='0.25')

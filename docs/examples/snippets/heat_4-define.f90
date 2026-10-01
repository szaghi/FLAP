! the top level: options before any command
call cli%add(switch='--threads', help='OpenMP threads', required=.false., act='store', def='1')
! the commands
call cli%add_group(group='run', aliases='r', description='Run a simulation')
call cli%add_group(group='post', aliases='p', description='Post-process the results')
call cli%add_group(group='info', description='Print the build information')
! the options of each command
call cli%add(group='run', switch='--nx', help='Cells along each direction', required=.false., act='store', def='64')
call cli%add(group='run', switch='--cfl', help='CFL number', required=.false., act='store', def='0.25')
call cli%add(group='post', switch='--format', help='Output format', required=.false., act='store', def='vtk', &
             choices='vtk,csv')
! one definition, copied into two commands: each copy has its own value
call cli%add(switch='--verbose', switch_ab='-v', help='Verbosity (repeatable)', required=.false., act='count')
call cli%copy_options(to_group='run', switches='--verbose')
call cli%copy_options(to_group='post', switches='--verbose')

call cli%add_group(group='run', description='Run a simulation')
call cli%add_group(group='clean', description='Remove the results')
call cli%set_mutually_exclusive_groups(group1='run', group2='clean')

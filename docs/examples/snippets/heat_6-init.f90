! after an error, print the usage line rather than the whole help
call cli%init(progname='heat', version='v0.6', description='Solve the 2D heat equation on a square plate', &
              usage_on_error='usage')

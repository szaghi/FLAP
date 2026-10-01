! a command line given as a string
call cli%parse(args='--nx 128', error=error)
call check(error == 0 .and. cli%get_source(switch='--nx') == SOURCE_COMMANDLINE, 'parse --nx 128')
call cli%get(switch='--nx', val=nx, error=error)
call check(nx == 128, 'get --nx')

! parse another command line with the same definitions
call cli%reset_parse
call cli%parse(args='', error=error)
call check(cli%get_source(switch='--nx') == SOURCE_DEFAULT, 'the default')

! errors and statuses are returned, never stop the program (standalone=.false.)
call cli%reset_parse
call cli%parse(args='--nx 1 --nx 2', error=error)
call check(error == ERROR_DUPLICATED_CLAS, 'a repeated switch')
call cli%reset_parse
call cli%parse(args='--help', error=error)
call check(error == STATUS_PRINT_H, '--help returns a status')
call check(caught('Optional switches:'), 'the help is written on the unit')

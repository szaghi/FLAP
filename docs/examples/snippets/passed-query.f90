print '(A,I0,A,L1)', 'threads = ', threads, ', passed on the command line: ', cli%is_passed(switch='--threads')
select case(cli%get_source(switch='--threads'))
case(SOURCE_COMMANDLINE) ; print '(A)', 'from the command line'
case(SOURCE_ENVIRONMENT) ; print '(A)', 'from the environment'
case(SOURCE_CONFIG)      ; print '(A)', 'from the configuration file'
case(SOURCE_DEFAULT)     ; print '(A)', 'the default'
endselect

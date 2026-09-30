program aliases
!< Command aliases, and options defined once and copied into several commands.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: jobs
logical                      :: verbose
integer                      :: error

call cli%init(progname='aliases', description='A build tool')
call cli%add_group(group='compile', aliases='co, c', description='Compile the sources')
call cli%add_group(group='link', description='Link the objects')
! defined once at the top level, then copied into the commands
call cli%add(switch='--jobs',    switch_ab='-j', help='Parallel jobs', required=.false., act='store', def='1')
call cli%add(switch='--verbose', help='Verbose', required=.false., act='store_true', def='.false.')
call cli%copy_options(to_group='compile')                     ! --jobs and --verbose
call cli%copy_options(to_group='link', switches='--verbose')  ! --verbose only
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
if (cli%run_command('co')) then        ! an alias is the command
  call cli%get(group='compile', switch='-j', val=jobs, error=error)
  print '(A,I0)', 'compile, jobs = ', jobs
endif
if (cli%run_command('link')) then
  call cli%get(group='link', switch='--verbose', val=verbose, error=error)
  print '(A,L1)', 'link, verbose = ', verbose
endif
endprogram aliases

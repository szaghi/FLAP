!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_nested
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).

use flap, only : command_line_interface
use penf

implicit none
type(command_line_interface) :: cli           !< Command Line Interface (CLI).
logical                      :: authors_print !< Boolean value.
character(500)               :: message       !< Message value.
integer(I4P)                 :: error         !< Error trapping flag.

authors_print = .false.

! initialize Command Line Interface
call cli%init(progname    = 'test_nested',                                       &
              version     = 'v2.1.5',                                            &
              authors     = 'Stefano Zaghi',                                     &
              license     = 'MIT',                                               &
              description = 'Toy program for testing FLAP with nested commands', &
              examples    = ['test_nested                      ',                &
                             'test_nested -h                   ',                &
                             'test_nested init                 ',                &
                             'test_nested commit -m "fix bug-1"',                &
                             'test_nested tag -a "v2.1.5"      '])

! set a Command Line Argument without a group to trigger authors names printing
call cli%add(switch='--authors',switch_ab='-a',help='Print authors names',required=.false.,act='store_true',def='.false.')

! set Command Line Arguments Groups, i.e. commands
call cli%add_group(group='init',description='fake init versioning')
call cli%add_group(group='commit',description='fake commit changes to current branch')
call cli%add_group(group='tag',description='fake tag current commit')
call cli%set_mutually_exclusive_groups(group1='init',group2='commit')

! set Command Line Arguments of commit command
call cli%add(group='commit',switch='--message',switch_ab='-m',help='Commit message',required=.false.,act='store',def='')

! set Command Line Arguments of commit command
call cli%add(group='tag',switch='--annotate',switch_ab='-a',help='Tag annotation',required=.false.,act='store',def='')

! parse Command Line Interface
call cli%parse(error=error)
if (error/=0) then
  print '(A)', 'Error code: '//trim(str(n=error))
  stop
endif

! use Command Line Interface data to trigger program behaviour
call cli%get(switch='-a',val=authors_print,error=error) ; if (error/=0) stop
if (authors_print) then
  print '(A)','Authors: '//cli%authors
elseif (cli%run_command('init')) then
  print '(A)','init (fake) versioning'
elseif (cli%run_command('commit')) then
  call cli%get(group='commit',switch='-m',val=message,error=error) ; if (error/=0) stop
  print '(A)','commit changes to current branch with message "'//trim(message)//'"'
elseif (cli%run_command('tag')) then
  call cli%get(group='tag',switch='-a',val=message,error=error) ; if (error/=0) stop
  print '(A)','tag current branch with message "'//trim(message)//'"'
else
  print '(A)','cowardly you are doing nothing... try at least "-h" option!'
endif
endprogram flap_test_nested

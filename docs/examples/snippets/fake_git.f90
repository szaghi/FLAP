program fake_git
!< A toy git: a top-level option and three commands, each with its own options and help.
use flap
implicit none
type(command_line_interface) :: cli
character(256)               :: message
character(256)               :: annotation
logical                      :: authors
integer                      :: error

call cli%init(progname    = 'fake_git',                                  &
              version     = 'v2.1.5',                                    &
              authors     = 'Stefano Zaghi',                             &
              license     = 'MIT',                                       &
              description = 'A toy git-like program demonstrating FLAP', &
              examples    = ['fake_git --help                ',          &
                             'fake_git init                  ',          &
                             'fake_git commit -m "fix bug #1"',          &
                             'fake_git tag -a "v2.1.5"       '])
! a top-level option
call cli%add(switch='--authors', switch_ab='-a', help='Print the authors', required=.false., act='store_true', &
             def='.false.', error=error)
! the commands
call cli%add_group(group='init',   description='Initialise versioning')
call cli%add_group(group='commit', description='Commit changes to the current branch')
call cli%add_group(group='tag',    description='Tag the current commit')
! the options of the commands
call cli%add(group='commit', switch='--message', switch_ab='-m', help='Commit message', required=.false., act='store', &
             def='', error=error)
call cli%add(group='tag', switch='--annotate', switch_ab='-a', help='Tag annotation', required=.false., act='store', &
             def='', error=error)
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.

call cli%get(switch='-a', val=authors, error=error)
if (authors) print '(A)', 'Authors: '//cli%authors
if (cli%run_command('init')) print '(A)', 'Initialising versioning'
if (cli%run_command('commit')) then
  call cli%get(group='commit', switch='-m', val=message, error=error)
  print '(A)', 'Committing with message: "'//trim(message)//'"'
endif
if (cli%run_command('tag')) then
  call cli%get(group='tag', switch='-a', val=annotation, error=error)
  print '(A)', 'Tagging with annotation: "'//trim(annotation)//'"'
endif
endprogram fake_git

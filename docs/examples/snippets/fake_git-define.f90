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

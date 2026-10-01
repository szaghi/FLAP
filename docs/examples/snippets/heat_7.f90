program heat
!< Tutorial, chapter 7: a polished help, colours, man page, Markdown and shell completion.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

call cli%init(progname    = 'heat',                                                        &
              version     = 'v1.0',                                                        &
              description = 'Solve the 2D heat equation on a square plate',               &
              authors     = 'The heat team',                                               &
              license     = 'MIT',                                                         &
              examples    = ['heat --nx 128 run         ',                                 &
                             'heat run --cfl 0.4        ',                                 &
                             'heat --install-completion '],                                &
              epilog      = 'Report bugs at https://example.org/heat/issues',              &
              error_color = 'red', error_style='bold_on',                                  &
              man_option  = .true.,                                                        & ! --man
              completion_options = .true.)                                                   ! --show/--install-completion
call cli%add(switch='--nx', help='Cells along each direction', required=.false., act='store', def='64', metavar='N', &
             help_color='cyan', help_style='bold_on')
call cli%add(switch='--scheme', help='Time scheme', required=.false., act='store', def='fe', choices='fe,cn', &
             help_color='cyan', help_style='bold_on')
call cli%add_group(group='run', description='Run a simulation')
call cli%add(group='run', switch='--cfl', help='CFL number', required=.false., act='store', def='0.25')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
print '(A)', 'running'
endprogram heat

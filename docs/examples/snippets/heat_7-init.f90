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

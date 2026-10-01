call cli%add(switch='--nx', help='Cells along each direction', required=.false., act='store', def='64', metavar='N')
call cli%add(switch='--steps', help='Time steps', required=.false., act='store', def='100', metavar='N')
! a range: the explicit scheme is stable for cfl <= 0.5
call cli%add(switch='--cfl', help='CFL number', required=.false., act='store', def='0.25', metavar='CFL', &
             min='0', min_open=.true., max='0.5')
! choices, in any case: CN is cn
call cli%add(switch='--scheme', switch_ab='-s', help='Time scheme: explicit Euler or Crank-Nicolson', required=.false., &
             act='store', def='fe', choices='fe,cn', case_sensitive=.false.)
! a clamped range: more threads than cores are pointless
call cli%add(switch='--threads', help='OpenMP threads', required=.false., act='store', def='1', min='1', max='64', &
             clamp=.true.)
! a counter: -v, -vv, -v -v ...
call cli%add(switch='--verbose', switch_ab='-v', help='Verbosity (repeatable)', required=.false., act='count')
! an optional value: --save alone saves in the default format
call cli%add(switch='--save', help='Save the solution (format: vtk, csv)', required=.false., act='store*', def='vtk', &
             choices='vtk,csv')

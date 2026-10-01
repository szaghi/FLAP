call cli%parse(error=error)
if (error == STATUS_ALTERNATE) then
  print '(A)', 'fe: explicit Euler (cfl <= 0.5)'
  print '(A)', 'cn: Crank-Nicolson (any cfl)'
  stop
endif
if (error /= 0) stop 1, quiet=.true.
! a check only the program can do, reported in FLAP's style
call cli%get(switch='--nx', val=nx, error=error)
if (mod(nx, 2) /= 0) error = cli%raise_error('must be even', switch='--nx', show_usage=.false.)
if (error /= 0) stop 1, quiet=.true.

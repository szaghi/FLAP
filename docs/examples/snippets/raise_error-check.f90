call cli%get(switch='--nx', val=nx, error=error)
if (mod(nx, 2) /= 0) error = cli%raise_error('must be even', switch='--nx')
if (error /= 0) stop 1, quiet=.true.

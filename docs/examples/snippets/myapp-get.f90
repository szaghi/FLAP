call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.

call cli%get(switch='-i',        val=input,   error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='-o',        val=output,  error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='-n',        val=n,       error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='-t',        val=tol,     error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--verbose', val=verbose, error=error) ; if (error /= 0) stop 1, quiet=.true.

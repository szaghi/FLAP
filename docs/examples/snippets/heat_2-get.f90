call cli%get(switch='--nx', val=nx, error=error)           ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--steps', val=steps, error=error)     ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--cfl', val=cfl, error=error)         ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--scheme', val=scheme, error=error)   ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--threads', val=threads, error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--verbose', val=verbose, error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--save', val=save, error=error)       ; if (error /= 0) stop 1, quiet=.true.
saving = cli%is_passed(switch='--save')

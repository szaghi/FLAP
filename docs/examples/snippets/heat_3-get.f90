call cli%get(switch='--probe', val=probe, error=error)           ; if (error /= 0) stop 1, quiet=.true.
call cli%get_varying(switch='--fields', val=fields, error=error) ; if (error /= 0) stop 1, quiet=.true.
alpha = 1.0d-4 ; t_end = 10.0d0                                   ! the built-in values
call cli%get_map_value(switch='--set', key='alpha', val=alpha, found=found, error=error)
call cli%get_map_value(switch='--set', key='t_end', val=t_end, found=found, error=error)

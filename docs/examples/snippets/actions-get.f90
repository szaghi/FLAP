call cli%get(switch='--verbose', val=verbosity, error=error)
call cli%get_varying(switch='--include', val=include, error=error)
call cli%get(switch='--format', val=format, error=error)
call cli%get(switch='--restart', val=restart, error=error)

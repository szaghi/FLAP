call cli%get(switch='--mesh', val=mesh, error=error)
call cli%get(switch='--coords', val=coords, error=error)          ! a fixed-size array of the right size
call cli%get_varying(switch='--fields', val=fields, error=error)   ! allocatable arrays, any size
call cli%get_varying(switch='--weights', val=weights, error=error)

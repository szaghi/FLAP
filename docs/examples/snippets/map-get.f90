cfl = 0.9_8 ; nx = 128                                                 ! the values of the input deck
call cli%get_map_value(switch='--set', key='cfl', val=cfl, found=found) ! overridden only if given
call cli%get_map_value(switch='--set', key='nx',  val=nx,  found=found)

call cli%add(switch='--mesh', help='Mesh file', required=.true., act='store', metavar='FILE')
! exactly 3 values
call cli%add(switch='--coords', help='X Y Z of the probe', required=.false., act='store', nargs='3', def='0 0 0')
! zero or more values: the switch alone is an empty list
call cli%add(switch='--fields', help='Fields to save', required=.false., act='store', nargs='*', def='u', &
             metavar='NAME')
! one or more values
call cli%add(switch='--weights', help='Weights', required=.false., act='store', nargs='+', def='1.0')

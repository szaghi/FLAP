program lists
!< Lists of values: a fixed number (nargs='3') or any number (nargs='+', '*'), and value placeholders (metavar).
use flap
implicit none
type(command_line_interface) :: cli
character(99)                :: mesh
integer                      :: coords(3)
character(9), allocatable    :: fields(:)
real(8), allocatable         :: weights(:)
integer                      :: error
integer                      :: i

call cli%init(progname='lists')
call cli%add(switch='--mesh', help='Mesh file', required=.true., act='store', metavar='FILE')
! exactly 3 values
call cli%add(switch='--coords', help='X Y Z of the probe', required=.false., act='store', nargs='3', def='0 0 0')
! zero or more values: the switch alone is an empty list
call cli%add(switch='--fields', help='Fields to save', required=.false., act='store', nargs='*', def='u', &
             metavar='NAME')
! one or more values
call cli%add(switch='--weights', help='Weights', required=.false., act='store', nargs='+', def='1.0')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--mesh', val=mesh, error=error)
call cli%get(switch='--coords', val=coords, error=error)          ! a fixed-size array of the right size
call cli%get_varying(switch='--fields', val=fields, error=error)   ! allocatable arrays, any size
call cli%get_varying(switch='--weights', val=weights, error=error)
if (error /= 0) stop 1, quiet=.true.
print '(A)', 'mesh    = '//trim(mesh)
print '(A,3(I0,1X))', 'coords  = ', coords
print '(A,I0,A,*(A,:,1X))', 'fields  = (', size(fields), ') ', (trim(fields(i)), i=1, size(fields))
print '(A,*(F5.2,1X))', 'weights = ', weights
endprogram lists

subroutine define(cli)
!< The definitions of heat (in a real program, a module procedure shared by heat and its tests).
type(command_line_interface), intent(inout) :: cli

call cli%init(progname='heat', standalone=.false., usage_lun=lun, error_lun=lun)
call cli%add(switch='--nx', help='Cells along each direction', required=.false., act='store', def='64')
endsubroutine define

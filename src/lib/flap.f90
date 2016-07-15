!< FLAP, Fortran command Line Arguments Parser for poor people
module flap
!-----------------------------------------------------------------------------------------------------------------------------------
!< FLAP, Fortran command Line Arguments Parser for poor people
!<{!README-FLAP.md!}
!-----------------------------------------------------------------------------------------------------------------------------------
use flap_command_line_argument_t, only : command_line_argument
use flap_command_line_arguments_group_t, only : command_line_arguments_group
use flap_command_line_interface_t, only : command_line_interface
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
public :: command_line_argument
public :: command_line_arguments_group
public :: command_line_interface
!-----------------------------------------------------------------------------------------------------------------------------------
endmodule flap

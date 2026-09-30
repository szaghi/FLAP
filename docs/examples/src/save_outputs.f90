!run save_outputs save_outputs && ls save_outputs.* && sed -n 1,12p save_outputs.bash
program save_outputs
!< Every generated output, saved by the program itself.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: error

call cli%init(progname='save_outputs', description='A solver')
call cli%add(switch='--mesh', switch_ab='-m', help='Mesh file', required=.false., act='store', def='m.grd')
call cli%add(switch='--scheme', help='Space scheme', required=.false., act='store', def='weno5', choices='weno5,muscl')
!region save
call cli%save_man_page(man_file='save_outputs.1', error=error)
call cli%save_usage_to_markdown(markdown_file='save_outputs.md', error=error)
call cli%save_bash_completion(bash_file='save_outputs.bash', error=error)
call cli%save_zsh_completion(zsh_file='save_outputs.zsh', error=error)
call cli%save_fish_completion(fish_file='save_outputs.fish', error=error)
call cli%save_powershell_completion(powershell_file='save_outputs.ps1', error=error)
!endregion save
endprogram save_outputs

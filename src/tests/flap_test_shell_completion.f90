!< Shell completion scripts: bash file-name fallback and zsh (issue #125, step 4.2; #11 12a-12b, T12.1-T12.2).
program flap_test_shell_completion
!< Shell completion scripts: bash file-name fallback and zsh (issue #125, step 4.2; #11 12a-12b, T12.1-T12.2).
!<
!< The bash script is registered with `complete -o default`, so an empty completion (a free value) falls back to file names.
!< The zsh script is the bash one behind bashcompinit. The bash function is run for real (bash is always there), through a
!< driver script; zsh is checked (syntax and a completion) only when it is installed.
use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, delete_file, read_back, &
                            read_file, run_command, scratch_file, write_file
use penf, only : I4P

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI).
character(:), allocatable    :: out      !< Output.
character(:), allocatable    :: script   !< Script text.
character(:), allocatable    :: bash     !< Bash script file.
character(:), allocatable    :: zsh      !< Zsh script file.
character(:), allocatable    :: driver   !< Driver script file.
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: error    !< Error trapping flag.
integer(I4P)                 :: exitstat !< Exit status of a command.

bash = scratch_file('bash')
zsh = scratch_file('zsh')
driver = scratch_file('driver')
call capture_open(lun)
call define
! T12.1: bash, registered with -o default
call cli%save_bash_completion(bash_file=bash, error=error)
call assert_equal(error, 0_I4P, 'bash script saved')
script = read_file(bash)
call assert_contains(script, 'complete -o default -F _completion flap_test_shell_completion', 'bash: -o default')
! the bash function, run: switches, a command's switches, a free value (empty: readline completes file names), choices
call assert_equal(completed('bash', bash, 'prog --me', 1), '[--mesh]', 'bash: a switch')
call assert_equal(completed('bash', bash, 'prog compile --o', 2), '[--opt]', 'bash: a switch of a command')
call assert_equal(completed('bash', bash, 'prog --mesh ""', 2), '[]', 'bash: a free value, nothing (then file names)')
call assert_equal(completed('bash', bash, 'prog --scheme ""', 2), '[weno5 muscl]', 'bash: choices')
! T12.2: zsh, the bash script behind bashcompinit
call cli%save_zsh_completion(zsh_file=zsh, error=error)
call assert_equal(error, 0_I4P, 'zsh script saved')
script = read_file(zsh)
call assert_contains(script, 'autoload -U +X compinit && compinit', 'zsh: compinit first')
call assert_contains(script, 'autoload -U +X bashcompinit && bashcompinit', 'zsh: bashcompinit')
call assert_contains(script, 'complete -o default -F _completion flap_test_shell_completion', 'zsh: the bash registration')
call assert(index(script, '#!/usr/bin/env bash') == 0, 'zsh: no bash shebang')
! (the probe always exits 0: some compilers report a failing command through cmdstat)
call run_command('if command -v zsh > /dev/null; then echo yes; else echo no; fi', exitstat, out)
if (index(out, 'yes') > 0) then
  call run_command('zsh -n '//zsh, exitstat, out)
  call assert_equal(exitstat, 0_I4P, 'zsh: syntax')
  ! zsh's compgen does not filter by the current word: compadd does, in the real completion (_bash_complete)
  call assert_contains(completed('zsh', zsh, 'prog --me', 1), '--mesh', 'zsh: a switch among the candidates')
  call assert_equal(completed('zsh', zsh, 'prog --scheme ""', 2), '[weno5 muscl]', 'zsh: choices')
endif
call delete_file(bash)
call delete_file(zsh)
call delete_file(driver)
! an unwritable file is reported
call cli%save_zsh_completion(zsh_file='/nonexistent/dir/x.zsh', error=error)
call assert(error /= 0, 'zsh: unwritable file reported')
out = read_back(lun)
call capture_close(lun)

contains
  subroutine define()
  !< Define the CLI.

  call cli%init(progname='flap_test_shell_completion', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--mesh', help='mesh', required=.false., act='store', def='', error=error)
  call cli%add(switch='--scheme', help='scheme', required=.false., act='store', def='muscl', choices='weno5,muscl', &
               error=error)
  call cli%add_group(group='compile', description='compile', error=error)
  call cli%add(group='compile', switch='--opt', help='optimization', required=.false., act='store', def='0', error=error)
  call assert_equal(error, 0_I4P, 'add the options')
  endsubroutine define

  function completed(shell, file, words, cword) result(reply)
  !< Run the completion function of a script in a shell for the words, and return COMPREPLY as [w1 w2 ...] (the first
  !< line of the output). In zsh the function runs in sh emulation, as bashcompinit runs it.
  character(*), intent(in)      :: shell  !< Shell, bash or zsh.
  character(*), intent(in)      :: file   !< Completion script.
  character(*), intent(in)      :: words  !< Words of the command line, shell syntax.
  integer(I4P), intent(in)      :: cword  !< Index of the word to complete (0 is the program).
  character(len=:), allocatable :: reply  !< COMPREPLY.
  character(len=:), allocatable :: call_  !< The call of the completion function.
  character(len=:), allocatable :: output !< Output.
  integer(I4P)                  :: stat   !< Exit status.
  integer(I4P)                  :: e      !< End of the first line.

  call_ = 'COMP_WORDS=('//words//'); COMP_CWORD='//achar(48 + cword)//'; _completion; printf "[%s]\n" "${COMPREPLY[*]}"'
  if (shell == 'zsh') then
    call write_file(driver, 'source '//file//new_line('a')//"emulate sh -c '"//call_//"'"//new_line('a'))
  else
    call write_file(driver, '. '//file//new_line('a')//call_//new_line('a'))
  endif
  call run_command(shell//' '//driver, stat, output)
  call assert_equal(stat, 0_I4P, shell//': completion of "'//words//'" runs')
  ! the reply line (the shell may print other lines before it)
  reply = ''
  e = index(output, '[')
  if (e == 0) return
  reply = output(e:)
  e = index(reply, new_line('a'))
  if (e > 0) reply = reply(:e-1)
  endfunction completed
endprogram flap_test_shell_completion

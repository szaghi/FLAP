!< Shell completion scripts: bash file-name fallback, zsh, fish, PowerShell (issue #125, step 4.2; #11 12, T12.1-T12.4).
program flap_test_shell_completion
!< Shell completion scripts: bash file-name fallback, zsh, fish, PowerShell (issue #125, step 4.2; #11 12, T12.1-T12.4).
!<
!< The bash script is registered with `complete -o default`, so an empty completion (a free value) falls back to file names.
!< The zsh script is the bash one behind bashcompinit. The bash function is run for real (bash is always there), through a
!< driver script; zsh and fish are checked (syntax and completions) only when installed. The fish script is native: long
!< (-l), one-letter (-s) and multi-letter old-style (-o) switches, choices, file names for free values, commands and aliases.
!< FLAP_TEST_FISH_FUNCTIONS, if set, is prepended to fish_function_path (a fish unpacked outside /usr). The PowerShell script
!< registers a native completer, queried with TabExpansion2 when pwsh is present; an empty result lets PowerShell complete
!< paths (a free value).
use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, delete_file, read_back, &
                            read_file, run_command, scratch_file, write_file
use penf, only : I4P

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI).
type(command_line_interface) :: other    !< Another program (B41).
character(:), allocatable    :: out      !< Output.
character(:), allocatable    :: script   !< Script text.
character(:), allocatable    :: bash     !< Bash script file.
character(:), allocatable    :: zsh      !< Zsh script file.
character(:), allocatable    :: fish     !< Fish script file.
character(:), allocatable    :: ps1      !< PowerShell script file.
character(:), allocatable    :: driver   !< Driver script file.
character(:), allocatable    :: bash2    !< Bash script file of another program.
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: error    !< Error trapping flag.
integer(I4P)                 :: exitstat !< Exit status of a command.

bash = scratch_file('bash')
zsh = scratch_file('zsh')
fish = scratch_file('fish')
ps1 = scratch_file('ps1')
driver = scratch_file('driver')
call capture_open(lun)
call define
! T12.1: bash, registered with -o default
call cli%save_bash_completion(bash_file=bash, error=error)
call assert_equal(error, 0_I4P, 'bash script saved')
script = read_file(bash)
call assert_contains(script, 'complete -o default -F _flap_test_shell_completion_completion flap_test_shell_completion', &
                     'bash: -o default')
! the bash function, run: switches, a command's switches, a free value (empty: readline completes file names), choices
call assert_equal(completed('bash', bash, 'prog --me', 1), '[--mesh]', 'bash: a switch')
call assert_equal(completed('bash', bash, 'prog compile --o', 2), '[--opt]', 'bash: a switch of a command')
call assert_equal(completed('bash', bash, 'prog --mesh ""', 2), '[]', 'bash: a free value, nothing (then file names)')
call assert_equal(completed('bash', bash, 'prog --scheme ""', 2), '[weno5 muscl]', 'bash: choices')
! B37 (#125, step 6.6): an option already typed is not offered again (any spelling, inline value included); a repeatable
! one (append, count) is; a negation is its own spelling
call assert_equal(completed('bash', bash, 'prog --mesh a --me', 3), '[]', 'bash: --mesh typed')
call assert_equal(completed('bash', bash, 'prog -m a --me', 3), '[]', 'bash: -m typed')
call assert_equal(completed('bash', bash, 'prog --mesh=a --me', 2), '[]', 'bash: --mesh=a typed')
call assert_equal(completed('bash', bash, 'prog --scheme weno5 --s', 3), '[]', 'bash: a choice option typed')
call assert_equal(completed('bash', bash, 'prog --restart --re', 2), '[]', 'bash: a flag typed')
call assert_equal(completed('bash', bash, 'prog --restart --no', 2), '[--no-restart]', 'bash: the negation still')
call assert_equal(completed('bash', bash, 'prog --inc a --in', 3), '[--inc]', 'bash: append, repeatable')
call assert_equal(completed('bash', bash, 'prog --verbose --verb', 2), '[--verbose]', 'bash: count, repeatable')
call assert_equal(completed('bash', bash, 'prog --mesh a --sc', 3), '[--scheme]', 'bash: the others offered')
! the options of the command typed last; the value of an option is never taken for a command
call assert_equal(completed('bash', bash, 'prog compile link --l', 3), '[--lib]', 'bash: the last command')
call assert_equal(completed('bash', bash, 'prog co --o', 2), '[--opt]', 'bash: a command by its alias')
call assert_equal(completed('bash', bash, 'prog --mesh compile --sc', 3), '[--scheme]', 'bash: a value named as a command')
call assert_equal(completed('bash', bash, 'prog compile -O 2 --o', 4), '[]', 'bash: a command option typed')
call assert_equal(completed('bash', bash, 'prog --jobs 2 compile --o', 4), '[--opt]', 'bash: a top-level value skipped')
! B41 (#126): every program has its own function, so that two FLAP programs complete in the same shell
call assert(index(script, new_line('a')//'_completion()') == 0, 'bash: no function shared by every program')
bash2 = scratch_file('bash2')
call other%init(progname='/opt/bin/other-tool.x', usage_lun=lun, error_lun=lun)
call other%add(switch='--zzz', help='zzz', required=.false., act='store', def='z', error=error)
call other%save_bash_completion(bash_file=bash2, error=error)
call assert_equal(error, 0_I4P, 'bash script of another program saved')
call assert_contains(read_file(bash2), new_line('a')//'_other_tool_x_completion()', &
                     'bash: the function named after the program, its basename made an identifier')
call assert_contains(read_file(bash2), 'complete -o default -F _other_tool_x_completion other-tool.x', &
                     'bash: the registration of another program')
call write_file(driver, '. '//bash//new_line('a')//'. '//bash2//new_line('a')// &
                'COMP_WORDS=(prog --me); COMP_CWORD=1; _flap_test_shell_completion_completion; '// &
                'printf "[%s]\n" "${COMPREPLY[*]}"'//new_line('a')// &
                'COMP_WORDS=(other --z); COMP_CWORD=1; _other_tool_x_completion; printf "[%s]\n" "${COMPREPLY[*]}"'// &
                new_line('a'))
call run_command('bash '//driver, exitstat, out)
call assert_equal(exitstat, 0_I4P, 'bash: two programs sourced')
call assert_contains(out, '[--mesh]'//new_line('a')//'[--zzz]', 'bash: each program completes its own options')
call delete_file(bash2)
! T12.2: zsh, the bash script behind bashcompinit
call cli%save_zsh_completion(zsh_file=zsh, error=error)
call assert_equal(error, 0_I4P, 'zsh script saved')
script = read_file(zsh)
call assert_contains(script, 'autoload -U +X compinit && compinit', 'zsh: compinit first')
call assert_contains(script, 'autoload -U +X bashcompinit && bashcompinit', 'zsh: bashcompinit')
call assert_contains(script, 'complete -o default -F _flap_test_shell_completion_completion flap_test_shell_completion', &
                     'zsh: the bash registration')
call assert(index(script, '#!/usr/bin/env bash') == 0, 'zsh: no bash shebang')
! (the probe always exits 0: some compilers report a failing command through cmdstat)
call run_command('if command -v zsh > /dev/null; then echo yes; else echo no; fi', exitstat, out)
if (index(out, 'yes') > 0) then
  call run_command('zsh -n '//zsh, exitstat, out)
  call assert_equal(exitstat, 0_I4P, 'zsh: syntax')
  ! zsh's compgen does not filter by the current word: compadd does, in the real completion (_bash_complete)
  call assert_contains(completed('zsh', zsh, 'prog --me', 1), '--mesh', 'zsh: a switch among the candidates')
  call assert_equal(completed('zsh', zsh, 'prog --scheme ""', 2), '[weno5 muscl]', 'zsh: choices')
  call assert(index(completed('zsh', zsh, 'prog --mesh a --me', 3), '--mesh') == 0, 'zsh: an option typed, not offered')
  call assert_contains(completed('zsh', zsh, 'prog compile link --l', 3), '--lib', 'zsh: the last command')
endif
! T12.3: fish, native
call cli%save_fish_completion(fish_file=fish, error=error)
call assert_equal(error, 0_I4P, 'fish script saved')
script = read_file(fish)
call assert_contains(script, "complete -c flap_test_shell_completion -n '__fish_use_subcommand' -f -a 'compile co' "// &
                     "-d 'compile'", 'fish: the command and its alias')
call assert_contains(script, "-l mesh -s m -d 'mesh' -r -F", 'fish: a free value, file names')
call assert_contains(script, "-l scheme -d 'scheme' -x -a 'weno5 muscl'", 'fish: choices')
call assert_contains(script, "-n '__fish_seen_subcommand_from compile co' -l opt -s O -d 'optimization' -r -F", &
                     'fish: an option of a command, one-letter short switch')
call assert_contains(script, "-l jobs -o jn -d 'jobs' -r -F", 'fish: a multi-letter short switch, old-style -o')
call assert_contains(script, "-l restart -d 'restart'", 'fish: a flag')
call assert_contains(script, "-l no-restart -d 'restart'", 'fish: its negation')
call assert_contains(script, "-d 'it"//achar(92)//"'s quoted'", 'fish: a quote escaped') ! achar(92): a backslash
call assert(index(script, 'secret') == 0, 'fish: hidden excluded')
call run_command('if command -v fish > /dev/null; then echo yes; else echo no; fi', exitstat, out)
if (index(out, 'yes') > 0) then
  call run_command('fish --no-execute '//fish, exitstat, out)
  call assert_equal(exitstat, 0_I4P, 'fish: syntax')
  call assert_equal(fish_completed(fish, 'flap_test_shell_completion --me'), '--mesh', 'fish: a switch')
  call assert_equal(fish_completed(fish, 'flap_test_shell_completion --scheme '), 'muscl weno5', 'fish: choices')
  call assert_equal(fish_completed(fish, 'flap_test_shell_completion compile --o'), '--opt', 'fish: a switch of a command')
  call assert_equal(fish_completed(fish, 'flap_test_shell_completion c'), 'co compile', 'fish: commands and aliases')
  call assert_equal(fish_completed(fish, 'flap_test_shell_completion --no-r'), '--no-restart', 'fish: a negation')
endif
call delete_file(bash)
call delete_file(zsh)
call delete_file(fish)
! T12.4: PowerShell, a native argument completer
call cli%save_powershell_completion(powershell_file=ps1, error=error)
call assert_equal(error, 0_I4P, 'PowerShell script saved')
script = read_file(ps1)
call assert_contains(script, "Register-ArgumentCompleter -Native -CommandName 'flap_test_shell_completion'", &
                     'PowerShell: native completer')
call assert_contains(script, "'co' = 'compile'", 'PowerShell: an alias maps to its command')
call assert_contains(script, "@{ n = '--scheme'; d = 'scheme'; c = @('weno5', 'muscl'); v = $true }", 'PowerShell: choices')
call assert_contains(script, "@{ n = '--quote'; d = 'it''s quoted'; c = $null; v = $true }", 'PowerShell: a quote escaped')
call assert_contains(script, "@{ n = '--no-restart'; d = 'restart'; c = $null; v = $false }", 'PowerShell: a negation')
call assert(index(script, 'secret') == 0, 'PowerShell: hidden excluded')
call run_command('if command -v pwsh > /dev/null; then echo yes; else echo no; fi', exitstat, out)
if (index(out, 'yes') > 0) then
  call assert_equal(ps_completed(ps1, 'flap_test_shell_completion --me'), '[--mesh]', 'PowerShell: a switch')
  call assert_equal(ps_completed(ps1, 'flap_test_shell_completion --scheme '), '[weno5 muscl]', 'PowerShell: choices')
  call assert_equal(ps_completed(ps1, 'flap_test_shell_completion compile --o'), '[--opt]', 'PowerShell: a command switch')
  call assert_equal(ps_completed(ps1, 'flap_test_shell_completion co --o'), '[--opt]', 'PowerShell: through an alias')
  call assert_equal(ps_completed(ps1, 'flap_test_shell_completion c'), '[co compile]', 'PowerShell: commands and aliases')
  call assert_equal(ps_completed(ps1, 'flap_test_shell_completion --no-r'), '[--no-restart]', 'PowerShell: a negation')
endif
call delete_file(ps1)
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
  call cli%add(switch='--mesh', switch_ab='-m', help='mesh', required=.false., act='store', def='', error=error)
  call cli%add(switch='--scheme', help='scheme', required=.false., act='store', def='muscl', choices='weno5,muscl', &
               error=error)
  call cli%add(switch='--restart', switch_neg='--no-restart', help='restart', required=.false., act='store_true', &
               def='.false.', error=error)
  call cli%add(switch='--quote', help="it's quoted", required=.false., act='store', def='', error=error)
  call cli%add(switch='--jobs', switch_ab='-jn', help='jobs', required=.false., act='store', def='1', error=error)
  call cli%add(switch='--secret', help='secret', required=.false., act='store', def='', hidden=.true., error=error)
  call cli%add_group(group='compile', aliases='co', description='compile', error=error)
  call cli%add(group='compile', switch='--opt', switch_ab='-O', help='optimization', required=.false., act='store', &
               def='0', error=error)
  call cli%add(switch='--inc', help='include', required=.false., act='append', def='', error=error)
  call cli%add(switch='--verbose', help='verbose', required=.false., act='count', error=error)
  call cli%add_group(group='link', description='link', error=error)
  call cli%add(group='link', switch='--lib', help='library', required=.false., act='store', def='', error=error)
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

  call_ = 'COMP_WORDS=('//words//'); COMP_CWORD='//achar(48 + cword)//'; _flap_test_shell_completion_completion; '// &
          'printf "[%s]\n" "${COMPREPLY[*]}"'
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

  function fish_completed(file, line) result(words)
  !< Run fish's own completion of a command line (complete -C) with a script, and return the completed words, sorted and
  !< blank separated (the descriptions dropped).
  character(*), intent(in)      :: file   !< Completion script.
  character(*), intent(in)      :: line   !< Command line.
  character(len=:), allocatable :: words  !< Completed words.
  character(len=:), allocatable :: output !< Output.
  integer(I4P)                  :: stat   !< Exit status.

  call write_file(driver, 'set -q FLAP_TEST_FISH_FUNCTIONS; and set -p fish_function_path $FLAP_TEST_FISH_FUNCTIONS'// &
                  new_line('a')//'source '//file//new_line('a')// &
                  "complete -C '"//line//"' | string replace -r '"//achar(92)//"t.*' '' | sort | string join ' '"// &
                  new_line('a')//'exit 0'//new_line('a')) ! string join exits 1 with a single word
  call run_command('fish '//driver, stat, output)
  call assert_equal(stat, 0_I4P, 'fish: completion of "'//line//'" runs')
  words = output
  if (index(words, new_line('a')) > 0) words = words(:index(words, new_line('a'))-1)
  endfunction fish_completed

  function ps_completed(file, line) result(words)
  !< Query PowerShell's completion (TabExpansion2) of a command line with a script, and return the completed words as
  !< [w1 w2 ...].
  character(*), intent(in)      :: file   !< Completion script.
  character(*), intent(in)      :: line   !< Command line.
  character(len=:), allocatable :: words  !< Completed words.
  character(len=:), allocatable :: output !< Output.
  character(len=:), allocatable :: psdrv  !< Driver script (pwsh -File wants the .ps1 extension).
  integer(I4P)                  :: stat   !< Exit status.
  integer(I4P)                  :: e      !< Position.

  psdrv = scratch_file('driver.ps1')
  call write_file(psdrv, '. '//file//new_line('a')//"$l = '"//line//"'"//new_line('a')// &
                  '"[" + ((TabExpansion2 -inputScript $l -cursorColumn $l.Length).CompletionMatches.CompletionText '// &
                  '-join " ") + "]"'//new_line('a'))
  call run_command('pwsh -NoProfile -NonInteractive -File '//psdrv, stat, output)
  call delete_file(psdrv)
  call assert_equal(stat, 0_I4P, 'PowerShell: completion of "'//line//'" runs')
  words = ''
  e = index(output, '[')
  if (e == 0) return
  words = output(e:)
  e = index(words, new_line('a'))
  if (e > 0) words = words(:e-1)
  endfunction ps_completed
endprogram flap_test_shell_completion

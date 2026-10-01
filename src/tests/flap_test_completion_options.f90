!< --show-completion and --install-completion (issue #125, step 4.3; #113 1.2-1.4, T1.1-T1.12).
program flap_test_completion_options
!< --show-completion and --install-completion (issue #125, step 4.3; #113 1.2-1.4, T1.1-T1.12).
!<
!< With init(completion_options=.true.) the top level gets two builtins taking an optional shell (default: the basename of
!< $SHELL): --show-completion writes the completion script to the version unit (stdout), --install-completion writes it to
!< $HOME/.<prog>-completion.<ext> and appends one marked source line to the shell's rc file if absent (never rewriting it,
!< never creating directories). Every install runs in a child with a fake HOME, the directory of this executable (a build
!< directory): the real HOME is never touched.
use flap, only : command_line_interface, ERROR_COMPLETION_INSTALL, ERROR_COMPLETION_SHELL, ERROR_UNKNOWN, &
                 STATUS_SHOW_COMPLETION
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, delete_file, &
                            read_back, read_file, reinvoke, write_file
use penf, only : I4P, str

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI).
character(:), allocatable    :: out      !< Standard output of a child, or captured output.
character(:), allocatable    :: err      !< Standard error of a child.
character(:), allocatable    :: home     !< Fake home: the directory of this executable.
character(:), allocatable    :: script   !< Completion script.
character(:), allocatable    :: rc       !< Content of an rc file.
character(:), allocatable    :: before   !< Content of an rc file before the install.
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: error    !< Error trapping flag.
integer(I4P)                 :: exitstat !< Exit status of a child.

home = executable_dir()
if (child_case() == 1) then
  ! standalone: the real command line; a status stops the program with exit status 0, an error is printed and returned
  call define(standalone=.true.)
  call cli%parse(error=error)
  print '(A)', 'error='//trim(str(error, .true.))
  stop
endif

call capture_open(lun)
! T1.1: --show-completion bash writes the bash script to stdout, then stops (exit 0)
call reinvoke(1_I4P, exitstat, out, err, args='--show-completion bash')
call assert_equal(exitstat, 0_I4P, 'T1.1 exit status')
call define(standalone=.false.)
script = cli%completion_script('bash')
call assert_contains(script, 'complete -o default -F _flapcomp_completion flapcomp', 'completion_script(bash)')
call assert_contains(out, script, 'T1.1 stdout is the bash script')
call assert(index(out, 'error=') == 0, 'T1.1 stopped')
! T1.2: the shell from $SHELL, and every shell by name
call reinvoke(1_I4P, exitstat, out, err, args='--show-completion', env='SHELL=/bin/bash')
call assert_contains(out, 'complete -o default -F _flapcomp_completion flapcomp', 'T1.2 SHELL=/bin/bash')
call reinvoke(1_I4P, exitstat, out, err, args='--show-completion', env='SHELL=/usr/bin/zsh')
call assert_contains(out, 'bashcompinit', 'T1.2 SHELL=/usr/bin/zsh')
call reinvoke(1_I4P, exitstat, out, err, args='--show-completion fish')
call assert_contains(out, 'complete -c flapcomp', 'fish by name')
call reinvoke(1_I4P, exitstat, out, err, args='--show-completion powershell')
call assert_contains(out, "Register-ArgumentCompleter -Native -CommandName 'flapcomp'", 'powershell by name')
! T1.3: an unknown or unset shell
call reinvoke(1_I4P, exitstat, out, err, args='--show-completion', env='SHELL=/bin/tcsh')
call assert_contains(out, 'error='//trim(str(ERROR_COMPLETION_SHELL, .true.)), 'T1.3 SHELL=/bin/tcsh: error')
call assert_contains(err, 'bash, zsh, fish, powershell', 'T1.3 the supported shells')
call reinvoke(1_I4P, exitstat, out, err, args='--show-completion', env='-u SHELL')
call assert_contains(out, 'error='//trim(str(ERROR_COMPLETION_SHELL, .true.)), 'T1.3 SHELL unset: error')
! T1.4, T1.5: install for bash, twice: the script written, one marker line
call delete_file(home//'/.bashrc')
call reinvoke(1_I4P, exitstat, out, err, args='--install-completion bash', env="'HOME="//home//"'")
call assert_equal(exitstat, 0_I4P, 'T1.4 exit status')
call assert(index(out, 'error=') == 0, 'T1.4 stopped')
call assert_contains(out, '.flapcomp-completion.bash', 'T1.4 what it did')
call assert_contains(read_file(home//'/.flapcomp-completion.bash'), script, 'T1.4 script file')
rc = read_file(home//'/.bashrc')
call assert_equal(count_of(rc, '# FLAP completion: flapcomp'), 1_I4P, 'T1.4 one marker line')
call assert_contains(rc, 'source "'//home//'/.flapcomp-completion.bash"', 'T1.4 the source line')
call reinvoke(1_I4P, exitstat, out, err, args='--install-completion bash', env="'HOME="//home//"'")
call assert_equal(exitstat, 0_I4P, 'T1.5 exit status')
call assert(index(out, 'error=') == 0, 'T1.5 stopped')
call assert_contains(out, 'already loaded', 'T1.5 the script refreshed, the rc file untouched')
rc = read_file(home//'/.bashrc')
call assert_equal(count_of(rc, '# FLAP completion: flapcomp'), 1_I4P, 'T1.5 idempotent')
! T1.6: an existing rc file is preserved, one line appended
before = 'export X=1'//new_line('a')//'alias ll="ls -l"'//new_line('a')
call write_file(home//'/.bashrc', before)
call reinvoke(1_I4P, exitstat, out, err, args='--install-completion', env="'HOME="//home//"' SHELL=/bin/bash")
call assert_equal(exitstat, 0_I4P, 'T1.6 exit status')
rc = read_file(home//'/.bashrc')
call assert_equal(rc(1:len(before)), before, 'T1.6 content preserved')
call assert_equal(count_of(rc, '# FLAP completion: flapcomp'), 1_I4P, 'T1.6 one line appended')
call delete_file(home//'/.bashrc')
call delete_file(home//'/.flapcomp-completion.bash')
! zsh: .zshrc
call delete_file(home//'/.zshrc')
call reinvoke(1_I4P, exitstat, out, err, args='--install-completion zsh', env="'HOME="//home//"'")
call assert_equal(exitstat, 0_I4P, 'zsh: exit status')
call assert_equal(count_of(read_file(home//'/.zshrc'), '# FLAP completion: flapcomp'), 1_I4P, 'zsh: .zshrc')
call assert_contains(read_file(home//'/.flapcomp-completion.zsh'), 'bashcompinit', 'zsh: script file')
call delete_file(home//'/.zshrc')
call delete_file(home//'/.flapcomp-completion.zsh')
! T1.7: fish without ~/.config/fish: the rc file cannot be opened (no directory is created)
call reinvoke(1_I4P, exitstat, out, err, args='--install-completion fish', env="'HOME="//home//"'")
call assert_contains(out, 'error='//trim(str(ERROR_COMPLETION_INSTALL, .true.)), 'T1.7 fish without its directory')
call assert_contains(err, 'run fish once', 'T1.7 the advice')
call delete_file(home//'/.flapcomp-completion.fish')
! PowerShell is not installed (its profile path needs pwsh)
call reinvoke(1_I4P, exitstat, out, err, args='--install-completion powershell', env="'HOME="//home//"'")
call assert_contains(out, 'error='//trim(str(ERROR_COMPLETION_SHELL, .true.)), 'PowerShell install: error')
call assert_contains(err, '--show-completion powershell', 'PowerShell install: the instructions')
! T1.8: HOME unset
call reinvoke(1_I4P, exitstat, out, err, args='--install-completion bash', env='-u HOME')
call assert_contains(out, 'error='//trim(str(ERROR_COMPLETION_INSTALL, .true.)), 'T1.8 HOME unset')

! non-standalone: the status is returned, the script written to the version unit (no install here: it would use the
! real HOME)
call define(standalone=.false.)
call cli%parse(args='--show-completion fish', error=error)
call assert_equal(error, STATUS_SHOW_COMPLETION, 'non-standalone: STATUS_SHOW_COMPLETION')
out = read_back(lun)
call assert_contains(out, 'complete -c flapcomp', 'non-standalone: the fish script written')
! T1.10: the help lists the options; the scripts complete the shells
call define(standalone=.false.)
out = cli%usage(g=0)
call assert_contains(out, ' [--show-completion [SHELL]]', 'T1.10 usage: --show-completion')
call assert_contains(out, ' [--install-completion [SHELL]]', 'T1.10 usage: --install-completion')
call assert_contains(cli%completion_script('bash'), 'bash zsh fish powershell', 'the scripts complete the shells')
call assert_equal(cli%completion_script('tcsh'), '', 'completion_script of an unknown shell: empty')
! T1.9: off by default: an unknown switch
call cli%init(progname='flapcomp', error_lun=lun, usage_lun=lun, version_lun=lun, error_hint=.false.)
call cli%parse(args='--show-completion bash', error=error)
call assert_equal(error, ERROR_UNKNOWN, 'T1.9 off: unknown switch')
out = read_back(lun)
call capture_close(lun)

contains
  subroutine define(standalone)
  !< Define the CLI.
  logical, intent(in) :: standalone !< Stop after a status.

  if (standalone) then
    call cli%init(progname='flapcomp', completion_options=.true., error_hint=.false.)
  else
    call cli%init(progname='flapcomp', completion_options=.true., standalone=.false., error_lun=lun, usage_lun=lun, &
                  version_lun=lun, error_hint=.false.)
  endif
  call cli%add(switch='--mesh', help='mesh', required=.false., act='store', def='', error=error)
  call cli%add_group(group='compile', description='compile', error=error)
  call cli%add(group='compile', switch='--opt', help='optimization', required=.false., act='store', def='0', error=error)
  endsubroutine define

  function executable_dir() result(dir)
  !< The absolute directory of this executable (HOME of the children must not depend on their working directory).
  character(len=:), allocatable :: dir    !< Directory.
  character(len=4096)           :: cwd    !< Current directory.
  integer(I4P)                  :: length !< Length of the executable path.
  integer(I4P)                  :: p      !< Position of the last '/'.
  integer(I4P)                  :: u      !< Unit.

  call get_command_argument(0, length=length)
  allocate(character(length) :: dir)
  call get_command_argument(0, value=dir)
  p = index(dir, '/', back=.true.)
  if (p > 0) then
    dir = dir(:p-1)
  else
    dir = '.'
  endif
  if (dir(1:1) /= '/') then
    call execute_command_line('pwd > '//dir//'/.flapcomp.pwd')
    open(newunit=u, file=dir//'/.flapcomp.pwd', action='read')
    read(u, '(A)') cwd
    close(u, status='delete')
    dir = trim(cwd)//'/'//dir
  endif
  endfunction executable_dir

  function count_of(text, what) result(n)
  !< Number of occurrences of a substring.
  character(*), intent(in) :: text !< Text.
  character(*), intent(in) :: what !< Substring.
  integer(I4P)             :: n    !< Occurrences.
  integer(I4P)             :: p    !< Position.
  integer(I4P)             :: i    !< Found position.

  n = 0
  p = 1
  do
    i = index(text(p:), what)
    if (i == 0) exit
    n = n + 1
    p = p + i + len(what) - 1
  enddo
  endfunction count_of
endprogram flap_test_completion_options

!< no_args_is_help: a command line (or command) without arguments prints the help (issue #125, step 1.4; #113-2).
program flap_test_no_args_is_help
!< no_args_is_help: a command line (or command) without arguments prints the help (issue #125, step 1.4; #113-2).
!<
!< In-process scenarios use standalone=.false.; the child (scenario 1) checks the standalone exit: status 2, no STOP banner.
use flap, only : command_line_interface, STATUS_NO_ARGS
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, read_back, &
                            reinvoke
use penf, only : I4P

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI) of the child.
character(:), allocatable    :: out      !< Captured output.
character(:), allocatable    :: err      !< Standard error of the child.
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: exitstat !< Exit status of the child.
integer(I4P)                 :: error    !< Error trapping flag.

if (child_case() == 1) then
  call cli%init(progname='flap_test_no_args_is_help', no_args_is_help=.true.)
  call cli%add(switch='--int', switch_ab='-i', help='an integer', required=.false., act='store', def='1', error=error)
  call cli%parse(args='', error=error)
  print '(A)', 'AFTER PARSE'
  stop
endif

call capture_open(lun)

! T2.1 no arguments: the help, not parsed (T2.8: the flag survives the later add_group)
call check('', STATUS_NO_ARGS, 'no arguments')
call assert_contains(out, '--int', 'no arguments: the top-level help')
! T2.2 with arguments: normal parse
call check('-i 3', 0_I4P, 'with arguments')
call assert(index(out, 'usage:') == 0, 'with arguments: no help')
! T2.3 a required option missing: the help, not the error
call check('', STATUS_NO_ARGS, 'no arguments, required option missing', required=.true.)
call assert(index(out, 'is required') == 0, 'no arguments, required option missing: no error message')
! T2.4 flag off: today's behaviour
call check('', 0_I4P, 'flag off, no arguments', flag=.false.)
call assert_equal(int(len(out), I4P), 0_I4P, 'flag off, no arguments: nothing printed')
! T2.5 command with the flag, invoked alone: its help
call check('commit', STATUS_NO_ARGS, 'commit alone')
call assert_contains(out, '--message', 'commit alone: the help of the command')
! T2.6 command with arguments: normal parse
call check('commit -m x', 0_I4P, 'commit -m x')
! a command without the flag, invoked alone: normal parse
call check('tag', 0_I4P, 'tag alone (no flag on the command)')

call capture_close(lun)

! T2.7 standalone: exit status 2, the usage on stderr, no STOP banner
call reinvoke(1_I4P, exitstat, out, err)
call assert_equal(exitstat, 2_I4P, 'standalone: exit status 2')
call assert(index(out, 'AFTER PARSE') == 0, 'standalone: parse does not return')
call assert_contains(err, '--int', 'standalone: the usage on stderr')
call assert(index(err, 'STOP') == 0, 'standalone: no STOP banner')

contains
  subroutine check(args, expected, message, required, flag)
  !< Define a CLI (commit has no_args_is_help, tag has not), parse without stopping, check the status and read the output.
  character(*), intent(in)           :: args     !< Command line.
  integer(I4P), intent(in)           :: expected !< Expected status or error.
  character(*), intent(in)           :: message  !< Description of the check.
  logical,      intent(in), optional :: required !< Add a required option (not passed).
  logical,      intent(in), optional :: flag     !< no_args_is_help of the top level (default .true.).
  type(command_line_interface)       :: cli      !< Command Line Interface (CLI).
  logical                            :: flag_    !< no_args_is_help of the top level, local variable.
  integer(I4P)                       :: error    !< Error trapping flag.

  flag_ = .true. ; if (present(flag)) flag_ = flag
  call cli%init(progname='prog', standalone=.false., no_args_is_help=flag_, usage_lun=lun, error_lun=lun, version_lun=lun)
  call cli%add(switch='--int', switch_ab='-i', help='an integer', required=.false., act='store', def='1', error=error)
  if (present(required)) then
    if (required) call cli%add(switch='--must', help='required', required=.true., act='store', error=error)
  endif
  call cli%add_group(group='commit', description='commit changes', no_args_is_help=.true.)
  call cli%add(group='commit', switch='--message', switch_ab='-m', help='message', required=.false., act='store', &
               def='m', error=error)
  call cli%add_group(group='tag', description='tag a commit')
  call cli%add(group='tag', switch='--name', help='name', required=.false., act='store', def='t', error=error)
  out = read_back(lun) ! drop the output of the definitions
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected, message//': status')
  out = read_back(lun)
  endsubroutine check
endprogram flap_test_no_args_is_help

!< A repeated command is an error (issue #125, B36, step 6.1; issue #87).
program flap_test_command_repeated
!< A repeated command is an error (issue #125, B36, step 6.1; issue #87).
!<
!< A command name (or one of its aliases) met a second time on the command line used to restart the command's arguments,
!< silently dropping the values given before it (`commit -m x commit` gave an empty message). It is now
!< `ERROR_COMMAND_REPEATED`, a syntax error reported before the help and the other statuses (D3, D5).
use flap, only : command_line_interface, ERROR_COMMAND_REPEATED, STATUS_PRINT_H
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
character(:), allocatable    :: out   !< Captured output.
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.

call capture_open(lun)

! the command repeated, with or without its values
call check_repeated('commit -m x commit', 'commit', 'the values before the repetition')
call check_repeated('commit -m x commit -m y', 'commit', 'the switch repeated too')
call check_repeated('init init', 'init', 'a command without values')
call check_repeated('init commit -m x init', 'init', 'another command in between')
! an alias is the same command; the message names the second spelling when it is an alias
call check_repeated('commit -m x ci', 'commit" (as "ci")', 'the command, then its alias')
call check_repeated('ci commit', 'commit', 'the alias, then the command')
! a syntax error comes before the help (D3)
call define
call cli%parse(args='commit --help commit', error=error)
call assert_equal(error, ERROR_COMMAND_REPEATED, 'before --help')
out = read_back(lun)
call define
call cli%parse(args='commit --help', error=error)
call assert_equal(error, STATUS_PRINT_H, 'the help of one command still works')
out = read_back(lun)

! not repeated
! two different commands
call define
call cli%parse(args='init commit -m x', error=error)
call assert(error /= ERROR_COMMAND_REPEATED, 'two different commands')
out = read_back(lun)
! a value equal to the command name stays a value (B04)
call define
call cli%parse(args='commit -m commit', error=error)
call assert_equal(error, 0_I4P, 'a value equal to the command name: error')
call check_message('commit', 'a value equal to the command name')
! parsing again after reset_parse does not see the previous call as a repetition
call cli%reset_parse
call cli%parse(args='commit -m y', error=error)
call assert_equal(error, 0_I4P, 'parse again after reset_parse')
call check_message('y', 'parse again after reset_parse')
out = read_back(lun)
call capture_close(lun)

contains
  subroutine define()
  !< Define a CLI with two commands, commit with the alias ci.
  integer(I4P) :: e !< Error trapping flag.

  call cli%init(progname='flap_test_command_repeated', standalone=.false., error_hint=.false., error_lun=lun, &
                usage_lun=lun, version_lun=lun)
  call cli%add_group(group='init', description='init')
  call cli%add_group(group='commit', description='commit', aliases='ci', error=e)
  call assert_equal(e, 0_I4P, 'add_group commit')
  call cli%add(group='commit', switch='--message', switch_ab='-m', help='message', required=.false., act='store', def='', &
               error=e)
  call assert_equal(e, 0_I4P, 'add --message')
  endsubroutine define

  subroutine check_repeated(args, command, what)
  !< A repeated command: the error and its message.
  character(*), intent(in) :: args    !< Command line.
  character(*), intent(in) :: command !< The command repeated, as the message names it.
  character(*), intent(in) :: what    !< Case.
  integer(I4P)             :: e       !< Error trapping flag.

  call define
  call cli%parse(args=args, error=e)
  call assert_equal(e, ERROR_COMMAND_REPEATED, what//': error')
  call assert_contains(read_back(lun), 'command "'//command, what//': message')
  endsubroutine check_repeated

  subroutine check_message(expected, what)
  !< The value of commit --message.
  character(*), intent(in) :: expected !< Expected message.
  character(*), intent(in) :: what     !< Case.
  character(99)            :: message  !< Value of --message.
  integer(I4P)             :: e        !< Error trapping flag.

  call cli%get(group='commit', switch='--message', val=message, error=e)
  call assert_equal(e, 0_I4P, what//': get')
  call assert_equal(trim(message), expected, what//': message')
  endsubroutine check_message
endprogram flap_test_command_repeated

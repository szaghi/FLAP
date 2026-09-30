!< Subcommand aliases: add_group(aliases=) (issue #125, step 3.4; #77 2.2-2.3, T2.1-T2.10).
program flap_test_group_alias
!< Subcommand aliases: add_group(aliases=) (issue #125, step 3.4; #77 2.2-2.3, T2.1-T2.10).
!<
!< A command invoked by an alias is the command itself: every query (run_command, get(group=), exclusions) resolves an
!< alias to the canonical name. An alias equal to a command name or to another alias is ERROR_GROUP_ALIAS, returned by
!< add_group and kept on the command, so that parse fails too. T2.10 (no aliases: outputs unchanged) is flap_test_golden.
!< Every get has its own variable (nvfortran, B33).
use flap, only : command_line_interface, ERROR_GROUP_ALIAS, ERROR_GROUP_M_EXCLUDE
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, delete_file, read_back, &
                            read_file, scratch_file
use penf, only : I4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
character(:), allocatable    :: out   !< Captured output.
character(:), allocatable    :: bash  !< Bash completion file.
character(99)                :: s     !< Character value (every get before its check).
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.
logical                      :: v     !< Flag value.

bash = scratch_file('bash')
call capture_open(lun)
! T2.1, T2.2: invoked by an alias, with its options
call run('co -t')
call assert(cli%run_command('checkout'), 'co: run_command(checkout)')
call assert(cli%run_command('co'), 'co: run_command(co)')
call assert(.not.cli%run_command('commit'), 'co: commit not run')
v = track_of('checkout', error)
call assert(v .and. error == 0, 'co -t: --track of checkout')
! T2.3: get through an alias reads the canonical command
v = track_of('ck', error)
call assert(v .and. error == 0, 'get(group=ck) reads checkout')
call run('checkout')
v = track_of('co', error)
call assert(.not.v .and. error == 0, 'checkout: get(group=co), default')
call assert(cli%run_command('ck'), 'checkout: run_command(ck)')
! T2.6: the aliases survive a later add_group (tag is added after checkout)
call run('ck')
call assert(cli%run_command('checkout'), 'ck after a later add_group')
! an alias as an option value is a value (B04)
call run('commit --msg co')
s = msg_of(error)
call assert(trim(s) == 'co' .and. error == 0, 'commit --msg co: the value')
call assert(.not.cli%run_command('checkout'), 'commit --msg co: checkout not run')
! case-insensitive commands include the aliases (F14)
call run('CO', nocase=.true.)
call assert(cli%run_command('checkout'), 'CO with case_insensitive')
! T2.7: mutually exclusive commands declared through an alias
call define
call cli%set_mutually_exclusive_groups(group1='co', group2='commit')
call cli%parse(args='co commit --msg m', error=error)
call assert_equal(error, ERROR_GROUP_M_EXCLUDE, 'exclusive through an alias: both called')
call define
call cli%add_group(group='push', description='push', exclude='ck', error=error)
call assert_equal(error, 0_I4P, 'add_group exclude=ck')
call cli%parse(args='push co', error=error)
call assert_equal(error, ERROR_GROUP_M_EXCLUDE, 'add_group(exclude=alias): both called')
out = read_back(lun)
! T2.8: the help lists the aliases
call define
out = cli%usage(g=0)
call assert_contains(out, '  checkout, co, ck', 'help: checkout, co, ck')
call assert_contains(out, '  commit'//new_line('a'), 'help: commit without aliases')
! T2.9: the bash completion offers the aliases
call cli%save_bash_completion(bash_file=bash, error=error)
call assert_equal(error, 0_I4P, 'bash completion saved')
out = read_file(bash)
call assert_contains(out, 'compgen -W "checkout co ck commit tag"', 'bash completion: command words')
call assert_contains(out, 'checkout|co|ck|commit|tag) group="$w"', 'bash completion: command pattern')
call assert_contains(out, '[ "$group" == "checkout" ] || [ "$group" == "co" ] || [ "$group" == "ck" ]', &
                     'bash completion: the options of an alias')
call delete_file(bash)
! T2.4, T2.5: clashes
call bad(group='x', aliases='commit', what='an alias equal to a command')
call bad(group='x', aliases='co', what='an alias equal to another alias')
call bad(group='co', aliases='', what='a command equal to an alias')
call bad(group='x', aliases='y,y', what='an alias twice')
call bad(group='x', aliases='x', what='an alias equal to its command')
call bad(group='x', aliases='y,', what='a blank alias')
call capture_close(lun)

contains
  subroutine define(nocase)
  !< Define the CLI.
  logical, intent(in), optional :: nocase !< Case-insensitive commands.

  call cli%init(progname='flap_test_group_alias', error_lun=lun, usage_lun=lun, error_hint=.false., &
                case_insensitive=nocase)
  call cli%add_group(group='checkout', aliases='co, ck', description='switch branches', error=error)
  call assert_equal(error, 0_I4P, 'add_group checkout, co, ck')
  call cli%add(group='checkout', switch='--track', switch_ab='-t', help='track', required=.false., act='store_true', &
               def='.false.', error=error)
  call cli%add_group(group='commit', description='record changes', error=error)
  call cli%add(group='commit', switch='--msg', switch_ab='-m', help='message', required=.false., act='store', def='', &
               error=error)
  call cli%add_group(group='tag', description='tag', error=error)
  call assert_equal(error, 0_I4P, 'add the commands')
  endsubroutine define

  subroutine run(args, nocase)
  !< Define the CLI and parse a command line.
  character(*), intent(in)           :: args   !< Command line.
  logical,      intent(in), optional :: nocase !< Case-insensitive commands.

  call define(nocase=nocase)
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, 'parse "'//args//'"')
  endsubroutine run

  function track_of(group, e) result(val)
  !< Value of --track of a command.
  character(*), intent(in)  :: group !< Command.
  integer(I4P), intent(out) :: e     !< Error.
  logical                   :: val   !< Value.

  val = .false.
  call cli%get(group=group, switch='--track', val=val, error=e)
  endfunction track_of

  function msg_of(e) result(val)
  !< Value of --msg of commit.
  integer(I4P), intent(out) :: e   !< Error.
  character(99)             :: val !< Value.

  val = ''
  call cli%get(group='commit', switch='--msg', val=val, error=e)
  endfunction msg_of

  subroutine bad(group, aliases, what)
  !< A command with a clashing alias: error from add_group, and from parse.
  character(*), intent(in) :: group   !< Command.
  character(*), intent(in) :: aliases !< Aliases.
  character(*), intent(in) :: what    !< Description.

  call define
  call cli%add_group(group=group, aliases=aliases, description='bad', error=error)
  call assert_equal(error, ERROR_GROUP_ALIAS, what//': add_group error')
  out = read_back(lun)
  call assert_contains(out, 'alias', what//': message')
  call cli%parse(args='tag', error=error)
  call assert_equal(error, ERROR_GROUP_ALIAS, what//': parse error')
  endsubroutine bad
endprogram flap_test_group_alias

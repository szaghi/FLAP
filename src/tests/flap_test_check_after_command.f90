!< --check and --dry-run after a command name, and set_mutually_exclusive_groups with an undefined command (issue #129).
program flap_test_check_after_command
!< --check and --dry-run after a command name, and set_mutually_exclusive_groups with an undefined command (issue #129).
!< Every call has its own CLI (nvfortran, B33).
use flap, only : command_line_interface, ERROR_MISSING_GROUP, ERROR_OUT_OF_RANGE, ERROR_UNKNOWN, STATUS_CHECK
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P

implicit none

call check_after('run --steps 5 --check', STATUS_CHECK, 'after the command')
call check_after('run --check --steps 5', STATUS_CHECK, 'right after the command name')
call check_after('run --steps 50 --check', ERROR_OUT_OF_RANGE, 'after the command, invalid')
call check_after('run --steps 5 -- --check', 0_I4P, 'after --: an argument of the program')
call check_after('own --check', 0_I4P, 'a command defining its own --check keeps it')
call check_dry_run
call check_manifest
call check_exclusive_groups

contains
  subroutine define(cli, lun)
  !< A CLI with --check and --dry-run, a command with a typed option, a command with its own --check.
  type(command_line_interface), intent(out) :: cli   !< CLI.
  integer(I4P),                 intent(in)  :: lun   !< Capture unit.
  integer(I4P)                              :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun, version_lun=lun, standalone=.false., &
                check_option=.true., dry_run_option=.true.)
  call cli%add_group(group='run', description='run')
  call cli%add(group='run', switch='--steps', help='s', required=.true., val_type='I4P', max='9', error=error)
  call cli%add(group='run', switch='--rest', help='r', required=.false., def='', nargs='*', error=error)
  call cli%add_group(group='own', description='own')
  call cli%add(group='own', switch='--check', help='c', required=.false., def='.false.', act='store_true', error=error)
  endsubroutine define

  subroutine check_after(args, expected, message)
  !< The result of a command line.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error or status.
  character(*), intent(in)     :: message  !< Description.
  type(command_line_interface) :: cli      !< CLI.
  integer(I4P)                 :: lun      !< Capture unit.
  integer(I4P)                 :: error    !< Error trapping flag.

  call capture_open(lun)
  call define(cli, lun)
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected, message)
  call capture_close(lun)
  endsubroutine check_after

  subroutine check_dry_run
  !< --dry-run after the command.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call define(cli, lun)
  call cli%parse(args='run --steps 5 --dry-run', error=error)
  call assert_equal(error, 0_I4P, 'dry run after the command: parsed')
  call assert_equal(cli%is_dry_run(), .true., 'dry run after the command')
  call capture_close(lun)
  endsubroutine check_dry_run

  subroutine check_manifest
  !< The manifest records the line as parsed, the builtin first.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call define(cli, lun)
  call cli%parse(args='run --steps 5 --dry-run', error=error)
  call assert_contains(cli%provenance(format='json'), '"arguments": ["--dry-run","run","--steps","5"]', 'manifest')
  call capture_close(lun)
  endsubroutine check_manifest

  subroutine check_exclusive_groups
  !< An undefined command is an error, reported; defined ones are set.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call define(cli, lun)
  call cli%set_mutually_exclusive_groups(group1='run', group2='nope', error=error)
  call assert_equal(error, ERROR_MISSING_GROUP, 'exclusive: undefined second')
  call assert_contains(read_back(lun), 'there is no group (command) named "nope"', 'exclusive: printed')
  call cli%set_mutually_exclusive_groups(group1='', group2='run', error=error)
  call assert_equal(error, ERROR_MISSING_GROUP, 'exclusive: the top level is not a command')
  call cli%set_mutually_exclusive_groups(group1='run', group2='own', error=error)
  call assert_equal(error, 0_I4P, 'exclusive: defined')
  call cli%parse(args='run --steps 5 own', error=error)
  call assert(error /= 0, 'exclusive: both called')
  call capture_close(lun)
  endsubroutine check_exclusive_groups
endprogram flap_test_check_after_command

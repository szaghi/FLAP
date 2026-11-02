!< The --dry-run builtin (issue #129).
program flap_test_dry_run
!< The --dry-run builtin (issue #129). Every call has its own CLI (nvfortran, B33).
use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open
use penf, only : I4P

implicit none

call check_passed
call check_absent
call check_disabled
call check_own_switch
call check_implicit_parse
call check_check_wins

contains
  subroutine define(cli, lun, enabled)
  !< Define a CLI.
  type(command_line_interface), intent(out) :: cli     !< CLI.
  integer(I4P),                 intent(in)  :: lun     !< Capture unit.
  logical,                      intent(in)  :: enabled !< Enable the option.
  integer(I4P)                              :: error   !< Error trapping flag.

  call cli%init(progname='prog', version='1', error_lun=lun, usage_lun=lun, version_lun=lun, standalone=.false., &
                dry_run_option=enabled, check_option=.true.)
  call cli%add(switch='--n', help='n', required=.false., def='1', error=error)
  endsubroutine define

  subroutine check_passed
  !< Passed: no status, the program runs, manifest and description report it.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call define(cli, lun, .true.)
  call cli%parse(args='--dry-run --n 2', error=error)
  call assert_equal(error, 0_I4P, 'no status')
  call assert_equal(cli%is_dry_run(), .true., 'passed')
  call assert_contains(cli%provenance(format='json'), '"dry_run": true', 'manifest')
  call assert_contains(cli%json_schema(), '"dry_run": true', 'description')
  call assert(index(cli%provenance(), '--dry-run') == 0, 'a builtin stays out of the values')
  call assert_contains(cli%usage(g=0), '--dry-run', 'help')
  call capture_close(lun)
  endsubroutine check_passed

  subroutine check_absent
  !< Available, not passed.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call define(cli, lun, .true.)
  call cli%parse(args='--n 2', error=error)
  call assert_equal(cli%is_dry_run(), .false., 'not passed')
  call assert_contains(cli%provenance(format='json'), '"dry_run": false', 'manifest: not passed')
  call capture_close(lun)
  endsubroutine check_absent

  subroutine check_disabled
  !< Not enabled: an unknown switch, and the manifest stays as it was.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call define(cli, lun, .false.)
  call assert_contains(cli%json_schema(), '"dry_run": false', 'description: not enabled')
  call cli%parse(args='--n 2', error=error)
  call assert_equal(cli%is_dry_run(), .false., 'not enabled')
  call assert(index(cli%provenance(format='json'), 'dry_run') == 0, 'manifest: not enabled')
  call cli%reset_parse
  call cli%parse(args='--dry-run', error=error)
  call assert(error /= 0, 'not enabled: unknown switch')
  call capture_close(lun)
  endsubroutine check_disabled

  subroutine check_own_switch
  !< The program owns a --dry-run: FLAP leaves it alone.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.
  logical                      :: own   !< Value of the option.

  call capture_open(lun)
  call cli%init(progname='prog', error_lun=lun, usage_lun=lun, standalone=.false., dry_run_option=.true.)
  call cli%add(switch='--dry-run', help='own', required=.false., def='.false.', act='store_true', error=error)
  call cli%parse(args='--dry-run', error=error)
  call assert_equal(error, 0_I4P, 'own: parsed')
  call assert_equal(cli%is_dry_run(), .false., 'own: not the builtin')
  call cli%get(switch='--dry-run', val=own, error=error)
  call assert_equal(own, .true., 'own: the value of the program')
  call capture_close(lun)
  endsubroutine check_own_switch

  subroutine check_implicit_parse
  !< It parses first, like get: here the real command line, empty.
  type(command_line_interface) :: cli !< CLI.
  integer(I4P)                 :: lun !< Capture unit.

  call capture_open(lun)
  call define(cli, lun, .true.)
  call assert_equal(cli%is_dry_run(), .false., 'parses first')
  call assert_equal(cli%is_parsed(), .true., 'parsed')
  call capture_close(lun)
  endsubroutine check_implicit_parse

  subroutine check_check_wins
  !< --check still validates and returns its status.
  type(command_line_interface) :: cli   !< CLI.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call define(cli, lun, .true.)
  call cli%parse(args='--check --dry-run', error=error)
  call assert(error < 0, '--check: its status')
  call capture_close(lun)
  endsubroutine check_check_wins
endprogram flap_test_dry_run

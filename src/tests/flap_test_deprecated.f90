!< Deprecated options and commands: a warning, never an error (issue #125, step 2.8; #11 10.1, T10.1-T10.6).
program flap_test_deprecated
!< Deprecated options and commands: a warning, never an error (issue #125, step 2.8; #11 10.1, T10.1-T10.6).
!<
!< A deprecated option warns when its value comes from the command line or the environment (not from a configuration file
!< or its default, as in click); a deprecated command warns when called. The help marks them. The warnings go to error_lun,
!< captured here. The child (case 1) parses with FLAP_TEST_DEPRECATED_GRID set.
use flap, only : command_line_interface, ERROR_DEPRECATED_REQUIRED
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, delete_file, &
                            read_back, reinvoke, scratch_file, write_file
use penf, only : I4P, str

implicit none
character(*), parameter      :: WARN = 'flap_test_deprecated: warning: ' !< Start of a warning (no colours: no error_color).
type(command_line_interface) :: cli                                      !< Command Line Interface (CLI).
character(:), allocatable    :: ini                                      !< Configuration file.
character(:), allocatable    :: out                                      !< Captured output.
character(:), allocatable    :: err                                      !< Standard error of the child.
integer(I4P)                 :: lun                                      !< Capture unit.
integer(I4P)                 :: exitstat                                 !< Exit status.
integer(I4P)                 :: error                                    !< Error trapping flag.

ini = scratch_file('ini')
if (child_case() == 1) then
  call capture_open(lun)
  call define
  call cli%parse(args='', error=error)
  out = read_back(lun)
  call capture_close(lun)
  print '(A)', 'error='//trim(str(error, .true.))//' '//out
  stop
endif

call capture_open(lun)
! T10.1: from the command line, a warning and no error
call run('--grid w.grd')
call assert_equal(error, 0_I4P, 'deprecated option on the command line: no error')
call assert_contains(out, WARN//'option "--grid" is deprecated: use --mesh instead', 'deprecated option: warning')
call run('--old')
call assert_contains(out, WARN//'option "--old" is deprecated'//new_line('a'), 'deprecated without message: warning')
! T10.3: default and configuration file: no warning
call run('')
call assert(index(out, 'warning') == 0, 'deprecated option by default: no warning')
call write_file(ini, 'grid = c.grd'//new_line('a'))
call run('', config=.true.)
call assert(index(out, 'warning') == 0, 'deprecated option from the configuration file: no warning')
call delete_file(ini)
! T10.5: a deprecated command warns when called, not otherwise
call run('legacy')
call assert_equal(error, 0_I4P, 'deprecated command called: no error')
call assert_contains(out, WARN//'command "legacy" is deprecated: use run', 'deprecated command called: warning')
call run('run')
call assert(index(out, 'warning') == 0, 'deprecated command not called: no warning')
! T10.6: the help marks them
call define
call assert_contains(cli%usage(g=0), 'Old grid (DEPRECATED: use --mesh instead)', 'help: deprecated option marked')
call assert_contains(cli%usage(g=0), 'Old flag (DEPRECATED)', 'help: deprecated without message marked')
call assert_contains(cli%usage(g=0), 'the old run (DEPRECATED: use run)', 'help: deprecated command marked')
! T10.4: a required option cannot be deprecated
call cli%init(progname='flap_test_deprecated', error_lun=lun, usage_lun=lun)
call cli%add(switch='--must', help='must', required=.true., act='store', deprecated='no', error=error)
call assert_equal(error, ERROR_DEPRECATED_REQUIRED, 'required and deprecated: definition error')
call capture_close(lun)

! T10.2: from the environment, a warning
call reinvoke(1_I4P, exitstat, out, err, env='FLAP_TEST_DEPRECATED_GRID=e.grd')
call assert_equal(exitstat, 0_I4P, 'deprecated option from the environment: exit status (stderr: '//err//')')
call assert_contains(out, 'error=0 '//WARN//'option "--grid" is deprecated', 'deprecated option from the environment')

contains
  subroutine define(config)
  !< Define the CLI.
  logical, intent(in), optional :: config !< Read the configuration file.

  call cli%init(progname='flap_test_deprecated', error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--grid', help='Old grid', required=.false., act='store', def='g.grd', &
               envvar='FLAP_TEST_DEPRECATED_GRID', deprecated='use --mesh instead', error=error)
  call cli%add(switch='--old', help='Old flag', required=.false., act='store_true', def='.false.', deprecated='', &
               error=error)
  call cli%add(switch='--mesh', help='Mesh', required=.false., act='store', def='m.grd', error=error)
  call cli%add_group(group='legacy', description='the old run', deprecated='use run')
  call cli%add_group(group='run', description='run')
  if (present(config)) then
    if (config) call cli%set_config(file=ini)
  endif
  endsubroutine define

  subroutine run(args, config)
  !< Define the CLI and parse a command line, capturing the output.
  character(*), intent(in)           :: args   !< Command line.
  logical,      intent(in), optional :: config !< Read the configuration file.

  call define(config=config)
  call cli%parse(args=args, error=error)
  out = read_back(lun)
  endsubroutine run
endprogram flap_test_deprecated

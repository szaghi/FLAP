!< Where each value comes from: get_source and the provenance report (issue #125, step 2.6; #11 6.1-6.2, T6.1-T6.7).
program flap_test_source
!< Where each value comes from: get_source and the provenance report (issue #125, step 2.6; #11 6.1-6.2, T6.1-T6.7).
!<
!< get_source returns a SOURCE_* constant; provenance returns one line per visible option of the top level and of the called
!< commands: name = value [source]. The child (case 1) parses with FLAP_TEST_SOURCE_MESH set and prints get_source of --mesh
!< and the provenance.
use flap, only : command_line_interface, ERROR_MISSING_CLA, ERROR_MISSING_GROUP, SOURCE_COMMANDLINE, SOURCE_CONFIG, &
                 SOURCE_DEFAULT, SOURCE_ENVIRONMENT, SOURCE_NONE
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, delete_file, &
                            reinvoke, scratch_file, write_file
use penf, only : I4P, str

implicit none
character(*), parameter      :: NL = new_line('a') !< Line end.
type(command_line_interface) :: cli                !< Command Line Interface (CLI).
character(:), allocatable    :: ini                !< Configuration file.
character(:), allocatable    :: report             !< Provenance report.
character(:), allocatable    :: out                !< Output of the child.
character(:), allocatable    :: err                !< Standard error of the child.
integer(I4P)                 :: lun                !< Capture unit.
integer(I4P)                 :: exitstat           !< Exit status.
integer(I4P)                 :: error              !< Error trapping flag.

ini = scratch_file('ini')
if (child_case() == 1) then
  call capture_open(lun)
  call define
  call cli%parse(args='--threads 4', error=error)
  print '(A)', 'error='//trim(str(error, .true.))//' mesh_source='//trim(str(cli%get_source(switch='--mesh'), .true.))
  print '(A)', cli%provenance()
  call capture_close(lun)
  stop
endif

call capture_open(lun)
call write_file(ini, 'cfl = 0.8'//NL)
call define
call cli%parse(args='--mesh m.grd --threads 32 --fields rho u post', error=error)
call assert_equal(error, 0_I4P, 'parse')
! T6.1, T6.3, T6.4: one per source
call assert_equal(cli%get_source(switch='--threads'), SOURCE_COMMANDLINE, 'command line')
call assert_equal(cli%get_source(switch='--cfl'), SOURCE_CONFIG, 'config file')
call assert_equal(cli%get_source(switch='--order'), SOURCE_DEFAULT, 'default')
call assert_equal(cli%get_source(group='post', switch='--format'), SOURCE_DEFAULT, 'default of a command option')
call assert_equal(cli%get_source(position=1_I4P), SOURCE_DEFAULT, 'default of a positional')
call assert_equal(cli%get_source(switch='--verbose'), SOURCE_DEFAULT, 'default of a flag')
! T6.5: undefined options and groups
call assert_equal(cli%get_source(switch='--nope', error=error), SOURCE_NONE, 'undefined switch: no source')
call assert_equal(error, ERROR_MISSING_CLA, 'undefined switch: missing CLA')
call assert_equal(cli%get_source(group='nope', switch='--cfl', error=error), SOURCE_NONE, 'undefined group: no source')
call assert_equal(error, ERROR_MISSING_GROUP, 'undefined group: missing group')
call assert_equal(cli%get_source(switch='--cfl', error=error), SOURCE_CONFIG, 'error reset by a later get_source')
call assert_equal(error, 0_I4P, 'defined switch: no error')
! T6.7: explicit sources are the command line, the environment and the file
call assert(cli%get_source(switch='--threads') < SOURCE_DEFAULT .and. cli%get_source(switch='--cfl') < SOURCE_DEFAULT .and. &
            cli%get_source(switch='--order') >= SOURCE_DEFAULT, 'explicit sources below SOURCE_DEFAULT')
! T6.6: the report, one line per visible option, hidden options and builtins excluded
report = cli%provenance()
call assert_contains(report, '--threads', 'report: --threads')
call assert_contains(report, '= 32', 'report: value from the command line')
call assert_contains(report, '[command line]', 'report: command line source')
call assert_contains(report, '= 0.8', 'report: value from the file')
call assert_contains(report, '[config: '//ini//']', 'report: config source with the file')
call assert_contains(report, '= 2', 'report: default value')
call assert_contains(report, '[default]', 'report: default source')
call assert_contains(report, '= rho u', 'report: list value')
call assert_contains(report, '= .false.', 'report: flag value')
call assert_contains(report, 'post --format', 'report: option of a called command, with the command name')
call assert_contains(report, '= in.dat', 'report: positional value')
call assert_equal(count_of(report, '--threads'), 1_I4P, 'report: each option once')
call assert_equal(count_of(report, NL), 7_I4P, 'report: 8 lines, 7 top-level options and 1 of post')
call assert(index(report, '--secret') == 0, 'report: hidden option excluded')
call assert(index(report, '--help') == 0 .and. index(report, '--version') == 0, 'report: builtins excluded')
call define
call cli%parse(args='--mesh m.grd', error=error)
call assert(index(cli%provenance(), 'post --format') == 0, 'report: a command not called is excluded')
call capture_close(lun)

! T6.2: the environment, with its variable
call reinvoke(1_I4P, exitstat, out, err, env='FLAP_TEST_SOURCE_MESH=env.grd')
call assert_equal(exitstat, 0_I4P, 'environment: exit status (stderr: '//err//')')
call assert_contains(out, 'error=0 mesh_source='//trim(str(SOURCE_ENVIRONMENT, .true.)), 'environment: get_source')
call assert_contains(out, '= env.grd', 'environment: report value')
call assert_contains(out, '[environment: FLAP_TEST_SOURCE_MESH]', 'environment: report source with the variable')
call delete_file(ini)

contains
  subroutine define()
  !< Define the CLI.
  call cli%init(progname='flap_test_source', error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--mesh', help='mesh', required=.true., act='store', envvar='FLAP_TEST_SOURCE_MESH', error=error)
  call cli%add(switch='--threads', help='threads', required=.false., act='store', def='1', error=error)
  call cli%add(switch='--cfl', help='cfl', required=.false., act='store', def='0.5', error=error)
  call cli%add(switch='--order', help='order', required=.false., act='store', def='2', error=error)
  call cli%add(switch='--fields', help='fields', required=.false., act='store', nargs='+', def='rho', error=error)
  call cli%add(switch='--verbose', help='verbose', required=.false., act='store_true', def='.false.', error=error)
  call cli%add(switch='--secret', help='hidden', required=.false., act='store', def='s', hidden=.true., error=error)
  call cli%add(positional=.true., position=1, help='input', required=.false., def='in.dat', error=error)
  call cli%add_group(group='post', description='post processing')
  call cli%add(group='post', switch='--format', help='format', required=.false., act='store', def='vtk', error=error)
  call cli%set_config(file=ini)
  endsubroutine define

  pure function count_of(string, substring) result(n)
  !< Number of occurrences of a substring.
  character(*), intent(in) :: string    !< String.
  character(*), intent(in) :: substring !< Substring.
  integer(I4P)             :: n         !< Occurrences.
  integer(I4P)             :: i         !< Position.
  integer(I4P)             :: p         !< Next occurrence.

  n = 0
  i = 1
  do
    p = index(string(i:), substring)
    if (p == 0) exit
    n = n + 1
    i = i + p + len(substring) - 1
    if (i > len(string)) exit
  enddo
  endfunction count_of
endprogram flap_test_source

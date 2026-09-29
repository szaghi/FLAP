!< Non-terminating mode: with standalone=.false. parse returns the help/version/markdown status (issue #125, step 1.1; #11-1).
program flap_test_standalone
!< Non-terminating mode: with standalone=.false. parse returns the help/version/markdown status (issue #125, step 1.1; #11-1).
!<
!< Statuses follow decision D3: syntax errors win, then help, version, markdown. Every scenario uses a fresh CLI. The child
!< (scenario 1) checks that the default, standalone mode still stops after the help.
use flap, only : command_line_interface, ERROR_UNKNOWN, STATUS_PRINT_H, STATUS_PRINT_M, STATUS_PRINT_V
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, delete_file, &
                            read_back, reinvoke, scratch_file
use penf, only : I4P

implicit none
character(*), parameter      :: VERSION = 'v9.8.7-test' !< Program version.
type(command_line_interface) :: cli                     !< Command Line Interface (CLI) of the child.
character(:), allocatable    :: out                     !< Output of a child, or captured output.
character(:), allocatable    :: err                     !< Standard error of a child.
character(:), allocatable    :: progname                !< Program name of the markdown scenario.
integer(I4P)                 :: lun                     !< Capture unit.
integer(I4P)                 :: exitstat                !< Exit status.
integer(I4P)                 :: error                   !< Error trapping flag.
logical                      :: exists                  !< The markdown file exists.

if (child_case() == 1) then
  call cli%init(progname='flap_test_standalone')
  call cli%add(switch='--int', switch_ab='-i', help='an integer', required=.false., act='store', def='1', error=error)
  call cli%parse(args='--help', error=error)
  print '(A)', 'AFTER PARSE'
  stop
endif

call capture_open(lun)

! T1.1 help, T1.2 version
call check('--help', STATUS_PRINT_H, '--help: status')
call assert_contains(out, 'usage:', '--help: the usage is printed')
call check('--version', STATUS_PRINT_V, '--version: status')
call assert_contains(out, VERSION, '--version: the version is printed')
! T1.3 help of a command (T1.5: standalone survives add_group, done after init)
call check('compile --help', STATUS_PRINT_H, 'compile --help: status')
call assert_contains(out, '--level', 'compile --help: the usage of the command is printed')
! D3: help before version, whatever their order
call check('--version --help', STATUS_PRINT_H, '--version --help: help wins')
call check('--help --version', STATUS_PRINT_H, '--help --version: help wins')
! D3: syntax errors before statuses, also in a later command
call check('--help --bogus', ERROR_UNKNOWN, '--help --bogus: the unknown switch wins')
call check('--bogus --help', ERROR_UNKNOWN, '--bogus --help: the unknown switch wins')
call check('--help compile --bogus', ERROR_UNKNOWN, '--help compile --bogus: the unknown switch of the command wins')
! a missing required option does not hide the help
call check('--help', STATUS_PRINT_H, '--help without the required option: status', required=.true.)
! markdown: the file is written, then the status is returned
progname = scratch_file('markdown')
call delete_file(progname//'.md')
call check('--markdown', STATUS_PRINT_M, '--markdown: status', name=progname)
inquire(file=progname//'.md', exist=exists)
call assert(exists, '--markdown: the markdown file is written')
call delete_file(progname//'.md')

call capture_close(lun)

! T1.4 the default mode still stops (exit status 0) after printing the help
call reinvoke(1_I4P, exitstat, out, err)
call assert_equal(exitstat, 0_I4P, 'standalone by default: exit status (stderr: '//err//')')
call assert(index(out, 'AFTER PARSE') == 0, 'standalone by default: parse does not return')
call assert_contains(err, 'usage:', 'standalone by default: the usage is printed')

contains
  subroutine check(args, expected, message, required, name)
  !< Define a CLI with a command, parse a command line without stopping and check the returned status or error.
  character(*), intent(in)           :: args     !< Command line.
  integer(I4P), intent(in)           :: expected !< Expected status or error.
  character(*), intent(in)           :: message  !< Description of the check.
  logical,      intent(in), optional :: required !< Add a required option (not passed).
  character(*), intent(in), optional :: name     !< Program name.
  type(command_line_interface)       :: cli      !< Command Line Interface (CLI).
  integer(I4P)                       :: error    !< Error trapping flag.

  if (present(name)) then
    call cli%init(progname=name, version=VERSION, standalone=.false., usage_lun=lun, version_lun=lun, error_lun=lun)
  else
    call cli%init(progname='flap_test_standalone', version=VERSION, standalone=.false., usage_lun=lun, version_lun=lun, &
                  error_lun=lun)
  endif
  call cli%add(switch='--int', switch_ab='-i', help='an integer', required=.false., act='store', def='1', error=error)
  if (present(required)) then
    if (required) call cli%add(switch='--must', help='required', required=.true., act='store', error=error)
  endif
  call cli%add_group(group='compile', description='compile the code')
  call cli%add(group='compile', switch='--level', help='optimization level', required=.false., act='store', def='2', &
               error=error)
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected, message)
  out = read_back(lun)
  endsubroutine check
endprogram flap_test_standalone

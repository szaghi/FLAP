!< Self-test of the FLAP test utilities (assertions, output capture, self re-invocation).
program flap_test_harness
!< Self-test of the FLAP test utilities (assertions, output capture, self re-invocation).
!<
!< Run without arguments: the parent checks the helpers directly and re-invokes itself to run the child scenarios.
use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, read_back, reinvoke
use penf, only : I4P, R8P

implicit none
character(*), parameter :: ENV_NAME = 'FLAP_TEST_HARNESS_ENV' !< Environment variable read by the child.

select case(child_case())
case(0)
  call check_assertions
  call check_capture
  call check_reinvoke
case(1)
  call child_cli
case(2)
  call child_env
case(3)
  call child_stdin
case(4)
  call assert(.false., 'deliberate failure')
case(5)
  call assert_equal(1_I4P, 2_I4P, 'deliberate integer mismatch')
case(6)
  call child_long_line
endselect

contains
  subroutine check_assertions()
  !< Passing assertions of every kind.

  call assert(.true., 'assert')
  call assert_contains('abc', 'b', 'assert_contains')
  call assert_equal('abc', 'abc', 'character')
  call assert_equal('abc  ', 'abc', 'character, trailing blanks')
  call assert_equal(.true., .true., 'logical')
  call assert_equal(42_I4P, 42_I4P, 'integer')
  call assert_equal(0.5_R8P, 0.5_R8P, 'real, exact')
  call assert_equal(0.1_R8P + 0.2_R8P, 0.3_R8P, 'real, tolerance', tol=1e-12_R8P)
  call assert_equal([1_I4P, 2_I4P], [1_I4P, 2_I4P], 'integer array')
  call assert_equal([1._R8P, 2._R8P], [1._R8P, 2._R8P], 'real array')
  endsubroutine check_assertions

  subroutine check_capture()
  !< FLAP errors written to a capture unit are read back, and the capture restarts after each read.
  type(command_line_interface) :: cli   !< Command line interface.
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call cli%init(progname='flap_test_harness', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--x', help='a value', required=.false., act='store', def='0', error=error)
  call assert_equal(error, 0_I4P, 'add --x')
  call cli%parse(args='--bogus', error=error)
  call assert(error /= 0, 'unknown switch is an error')
  call assert_contains(read_back(lun), '--bogus', 'captured error message')
  call assert_equal(read_back(lun), '', 'capture restarts after read_back')
  call capture_close(lun)
  endsubroutine check_capture

  subroutine check_reinvoke()
  !< Child scenarios: arguments, program termination, environment, standard input, exit statuses, long lines.
  character(:), allocatable :: out      !< Child standard output.
  character(:), allocatable :: err      !< Child standard error.
  integer(I4P)              :: exitstat !< Child exit status.

  call reinvoke(1_I4P, exitstat, out, err, args='--x 42')
  call assert_equal(exitstat, 0_I4P, 'arguments: exit status')
  call assert_equal(out, 'x=42'//new_line('a'), 'arguments: output')

  call reinvoke(1_I4P, exitstat, out, err, args='--help')
  call assert_equal(exitstat, 0_I4P, '--help: exit status')
  call assert_contains(err, '--x', '--help: usage on stderr')

  call reinvoke(2_I4P, exitstat, out, err, env=ENV_NAME//'=hello')
  call assert_equal(out, 'env=[hello]'//new_line('a'), 'environment: set')
  call reinvoke(2_I4P, exitstat, out, err, env='-u '//ENV_NAME)
  call assert_equal(out, 'env=unset'//new_line('a'), 'environment: unset')

  call reinvoke(3_I4P, exitstat, out, err, stdin='line one')
  call assert_equal(out, 'stdin=[line one]'//new_line('a'), 'standard input')
  call reinvoke(3_I4P, exitstat, out, err)
  call assert_equal(out, 'stdin=eof'//new_line('a'), 'standard input: /dev/null by default')

  call reinvoke(4_I4P, exitstat, out, err)
  call assert_equal(exitstat, 1_I4P, 'failed assert: exit status')
  call assert_contains(err, 'FAIL: deliberate failure', 'failed assert: message')

  call reinvoke(5_I4P, exitstat, out, err)
  call assert_equal(exitstat, 1_I4P, 'failed assert_equal: exit status')
  call assert_contains(err, 'expected 2, got 1', 'failed assert_equal: message')

  call reinvoke(6_I4P, exitstat, out, err)
  call assert_equal(int(len(out), I4P), 1001_I4P, 'long line read back whole')
  endsubroutine check_reinvoke

  subroutine child_cli()
  !< Child scenario 1: a CLI with one option, printing its value.
  type(command_line_interface) :: cli   !< Command line interface.
  integer(I4P)                 :: x     !< Option value.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='flap_test_harness')
  call cli%add(switch='--x', help='a value', required=.false., act='store', def='0', error=error)
  call cli%get(switch='--x', val=x, error=error)
  call assert_equal(error, 0_I4P, 'child: get --x')
  print '(A,I0)', 'x=', x
  endsubroutine child_cli

  subroutine child_env()
  !< Child scenario 2: print an environment variable.
  character(64) :: value  !< Variable value.
  integer(I4P)  :: status !< Retrieval status.

  call get_environment_variable(ENV_NAME, value=value, status=status)
  if (status == 0) then
    print '(A)', 'env=['//trim(value)//']'
  else
    print '(A)', 'env=unset'
  endif
  endsubroutine child_env

  subroutine child_stdin()
  !< Child scenario 3: echo the first line of standard input.
  character(64) :: line   !< Line read.
  integer(I4P)  :: iostat !< I/O status.

  read(*, '(A)', iostat=iostat) line
  if (iostat == 0) then
    print '(A)', 'stdin=['//trim(line)//']'
  else
    print '(A)', 'stdin=eof'
  endif
  endsubroutine child_stdin

  subroutine child_long_line()
  !< Child scenario 6: print a line longer than the read chunk.

  print '(A)', repeat('x', 1000)
  endsubroutine child_long_line
endprogram flap_test_harness

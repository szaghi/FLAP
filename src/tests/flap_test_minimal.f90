!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_minimal
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
!<
!< @note The minimal steps for using a FLAP CLI are:
!<+ `init` the CLI;
!<+ `add` at least one CLA to the CLI;
!<+ `get` the CLAs defined into the CLI;
!<
!<Note that `get` automatically calls `parse` method beacuse it is not explicitely called.
!<
!< Run with arguments it is the example program above; run without arguments it checks its own scenarios.

use flap, only : command_line_interface, ERROR_MISSING_REQUIRED, ERROR_VALUE_MISSING
use flap_test_utils, only : assert_contains, assert_equal, capture_close, capture_open, read_back
use penf

implicit none
integer(I4P) :: lun !< Capture unit for FLAP messages in self-test mode.

if (command_argument_count() > 0) then
  call example
else
  call self_test
endif

contains
  subroutine example()
  !< The example program: parse the real command line.
  type(command_line_interface) :: cli    !< Command Line Interface (CLI).
  character(99)                :: string !< String value.
  integer(I4P)                 :: error  !< Error trapping flag.

  call cli%init(description = 'minimal FLAP example')
  call cli%add(switch='--string', switch_ab='-s', help='a string', required=.true., act='store', error=error) ; if (error/=0) stop
  call cli%get(switch='-s', val=string, error=error) ; if (error/=0) stop
  print '(A)', cli%progname//' has been called with the following argument:'
  print '(A)', 'String = '//trim(adjustl(string))
  endsubroutine example

  subroutine self_test()
  !< Check the example CLI against a set of command lines.
  character(99) :: string !< String value.
  integer(I4P)  :: error  !< Error trapping flag.

  call capture_open(lun)

  call run('-s hello', string, error)
  call assert_equal(error, 0_I4P, '-s hello: error')
  call assert_equal(string, 'hello', '-s hello: value')

  call run('--string hello', string, error)
  call assert_equal(error, 0_I4P, '--string hello: error')
  call assert_equal(string, 'hello', '--string hello: value')

  call run('', string, error)
  call assert_equal(error, ERROR_MISSING_REQUIRED, 'no arguments: error')
  call assert_contains(read_back(lun), '--string', 'no arguments: message names the switch')

  call run('-s', string, error)
  call assert_equal(error, ERROR_VALUE_MISSING, '-s without value: error')

  call capture_close(lun)
  endsubroutine self_test

  subroutine run(args, string, error)
  !< Define the example CLI (messages captured), parse a command line and get the value.
  character(*),  intent(in)    :: args   !< Command line.
  character(99), intent(inout) :: string !< String value.
  integer(I4P),  intent(out)   :: error  !< Error trapping flag.
  type(command_line_interface) :: cli    !< Command Line Interface (CLI).

  call cli%init(progname='flap_test_minimal', description='minimal FLAP example', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--string', switch_ab='-s', help='a string', required=.true., act='store', error=error)
  call assert_equal(error, 0_I4P, 'add --string')
  string = ''
  call cli%parse(args=args, error=error)
  if (error /= 0) return
  call cli%get(switch='-s', val=string, error=error)
  endsubroutine run
endprogram flap_test_minimal

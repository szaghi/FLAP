!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_ignore_unknown_clas
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
!<
!< Run with arguments it is the example program above; run without arguments it checks its own scenarios.
use flap, only : command_line_interface, ERROR_MISSING_REQUIRED, ERROR_UNKNOWN_CLAS_IGNORED
use flap_test_utils, only : assert_equal, capture_close, capture_open
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
  type(command_line_interface) :: cli       !< Command Line Interface (CLI).
  character(99)                :: a_string  !< String value.
  integer(I4P)                 :: error     !< Error trapping flag.

  call cli%init(description = 'ignore unknown CLAs usage FLAP example', ignore_unknown_clas=.true.)
  call cli%add(switch='--string', switch_ab='-s', help='a string', required=.true., act='store', error=error)
  call cli%get(switch='-s', val=a_string, error=error)
  ! if (error /= ERROR_UNKNOWN_CLAS_IGNORED) stop
  print '(A)', cli%progname//' has been called with the following argument:'
  print '(A)', 'String       = '//trim(adjustl(a_string))
  print '(A,I5)', 'Error code   = ', error
  endsubroutine example

  subroutine self_test()
  !< Unknown switches are ignored (parse reports ERROR_UNKNOWN_CLAS_IGNORED) and known values are still read.
  character(99) :: a_string    !< String value.
  integer(I4P)  :: parse_error !< Error of parse.
  integer(I4P)  :: get_error   !< Error of get.

  call capture_open(lun)
  call run('-s a', a_string, parse_error, get_error)
  call assert_equal(parse_error, 0_I4P, '-s a: parse error')
  call assert_equal(get_error, 0_I4P, '-s a: get error')
  call assert_equal(a_string, 'a', '-s a: value')

  call run('-s a --bogus', a_string, parse_error, get_error)
  call assert_equal(parse_error, ERROR_UNKNOWN_CLAS_IGNORED, '-s a --bogus: parse error')
  call assert_equal(a_string, 'a', '-s a --bogus: value')
  ! B20 (#125): the error returned by get depends on where the unknown switch is; these assertions pin the current
  ! behaviour and flip when B20 is fixed
  call assert_equal(get_error, 0_I4P, '-s a --bogus: get error (B20, current behaviour)')
  call run('--bogus -s a', a_string, parse_error, get_error)
  call assert_equal(parse_error, ERROR_UNKNOWN_CLAS_IGNORED, '--bogus -s a: parse error')
  call assert_equal(a_string, 'a', '--bogus -s a: value')
  call assert_equal(get_error, ERROR_UNKNOWN_CLAS_IGNORED, '--bogus -s a: get error (B20, current behaviour)')

  call run('--bogus', a_string, parse_error, get_error)
  call assert_equal(parse_error, ERROR_MISSING_REQUIRED, '--bogus only: a missing required switch is still an error')
  call capture_close(lun)
  endsubroutine self_test

  subroutine run(args, a_string, parse_error, get_error)
  !< Define the example CLI (messages captured), parse a command line and get the value.
  character(*),  intent(in)    :: args        !< Command line.
  character(99), intent(out)   :: a_string    !< String value.
  integer(I4P),  intent(out)   :: parse_error !< Error of parse.
  integer(I4P),  intent(out)   :: get_error   !< Error of get.
  type(command_line_interface) :: cli         !< Command Line Interface (CLI).

  call cli%init(progname='flap_test_ignore_unknown_clas', description='ignore unknown CLAs usage FLAP example', &
                ignore_unknown_clas=.true., error_lun=lun, usage_lun=lun)
  call cli%add(switch='--string', switch_ab='-s', help='a string', required=.true., act='store', error=get_error)
  call assert_equal(get_error, 0_I4P, 'add --string')
  a_string = ''
  call cli%parse(args=args, error=parse_error)
  get_error = -1
  if (parse_error /= 0 .and. parse_error /= ERROR_UNKNOWN_CLAS_IGNORED) return
  call cli%get(switch='-s', val=a_string, error=get_error)
  endsubroutine run
endprogram flap_test_ignore_unknown_clas

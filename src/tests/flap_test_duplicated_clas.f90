!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_duplicated_clas
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
!<
!< Run with arguments it is the example program above; run without arguments it checks its own scenarios.
use flap, only : command_line_interface, ERROR_DUPLICATED_CLAS
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
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  real(R8P)                    :: rval  !< Real value.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='test_duplicated_clas', description='Test passed duplicated CLAS')
  call cli%add(switch='--i', switch_ab='-i', help='input', required=.true., act='store', error=error) ; if (error/=0) stop
  call cli%get(switch='-i', val=rval, error=error) ; if (error/=0) stop
  print '(A)' ,'Input = '//trim(str(n=rval))
  endsubroutine example

  subroutine self_test()
  !< A CLA passed twice, by the same or by the other spelling, is an error.
  real(R8P)    :: rval  !< Real value.
  integer(I4P) :: error !< Error trapping flag.

  call capture_open(lun)
  call run('-i 1.5', rval, error)
  call assert_equal(error, 0_I4P, '-i 1.5: error')
  call assert_equal(rval, 1.5_R8P, '-i 1.5: value')
  call run('-i 1 -i 2', rval, error)
  call assert_equal(error, ERROR_DUPLICATED_CLAS, '-i 1 -i 2: error')
  call assert_contains(read_back(lun), 'has been passed more than once', '-i 1 -i 2: message')
  call run('-i 1 --i 2', rval, error)
  call assert_equal(error, ERROR_DUPLICATED_CLAS, '-i 1 --i 2: error')
  ! B01 (#125): parsing stops at the first duplicate, so a later error does not replace it
  call run('-i 1 -i 2 --bogus', rval, error)
  call assert_equal(error, ERROR_DUPLICATED_CLAS, '-i 1 -i 2 --bogus: the duplicate is reported')
  ! B01 (#125): the error is raised on the duplicated CLA, not on the CLA at the token index (out of bounds here)
  call run_list('-l 1 2 3 4 5 6 -l 7', error)
  call assert_equal(error, ERROR_DUPLICATED_CLAS, '-l 1 2 3 4 5 6 -l 7: error')
  call assert_contains(read_back(lun), 'switch "-l" has been passed more than once', '-l 1 2 3 4 5 6 -l 7: message')
  call capture_close(lun)
  endsubroutine self_test

  subroutine run_list(args, error)
  !< Define a CLI with a list CLA (messages captured) and parse a command line.
  character(*), intent(in)     :: args  !< Command line.
  integer(I4P), intent(out)    :: error !< Error trapping flag of parse.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).

  call cli%init(progname='test_duplicated_clas', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--list', switch_ab='-l', help='list', required=.false., act='store', nargs='*', def='0', error=error)
  call assert_equal(error, 0_I4P, 'add --list')
  call cli%parse(args=args, error=error)
  endsubroutine run_list

  subroutine run(args, rval, error)
  !< Define the example CLI (messages captured), parse a command line and get the value.
  character(*), intent(in)     :: args  !< Command line.
  real(R8P),    intent(out)    :: rval  !< Real value.
  integer(I4P), intent(out)    :: error !< Error trapping flag.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).

  call cli%init(progname='test_duplicated_clas', description='Test passed duplicated CLAS', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--i', switch_ab='-i', help='input', required=.true., act='store', error=error)
  call assert_equal(error, 0_I4P, 'add --i')
  rval = 0._R8P
  call cli%parse(args=args, error=error)
  if (error /= 0) return
  call cli%get(switch='-i', val=rval, error=error)
  endsubroutine run
endprogram flap_test_duplicated_clas

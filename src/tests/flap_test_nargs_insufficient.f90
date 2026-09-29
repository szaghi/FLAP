!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_nargs_insufficient
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<### Usage
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
!<
!< Run with arguments it is the example program above; run without arguments it checks its own scenarios.
use flap, only : command_line_interface, ERROR_NARGS_INSUFFICIENT
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
  type(command_line_interface) :: cli     !< Command Line Interface (CLI).
  real(R8P)                    :: rval(3) !< Real value.
  integer(I4P)                 :: error   !< Error trapping flag.

  call cli%init(progname='test_nargs_insufficient', description='Test insufficient nargs')
  call cli%add(switch='-i', help='Real list input',required=.true.,act='store',nargs='3',error=error)
  call cli%get(switch='-i', val=rval, error=error) ; if (error/=0) stop
  print '(A)' ,'Real list input = '//trim(str(n=rval))
  endsubroutine example

  subroutine self_test()
  !< A CLA with nargs='3' needs exactly three values.
  real(R8P)    :: rval(3) !< Real values.
  integer(I4P) :: error   !< Error trapping flag.

  call capture_open(lun)
  call run('-i 1 2 3', rval, error)
  call assert_equal(error, 0_I4P, '-i 1 2 3: error')
  call assert_equal(rval, [1._R8P, 2._R8P, 3._R8P], '-i 1 2 3: values')
  call run('-i 1 2', rval, error)
  call assert_equal(error, ERROR_NARGS_INSUFFICIENT, '-i 1 2: error')
  call run('-i', rval, error)
  call assert_equal(error, ERROR_NARGS_INSUFFICIENT, '-i without values: error')
  ! B19 (#125): too MANY values are also reported as "insufficient"; this assertion flips when B19 is fixed
  call run('-i 1 2 3 4', rval, error)
  call assert_equal(error, ERROR_NARGS_INSUFFICIENT, '-i 1 2 3 4: error (B19, current behaviour)')
  call capture_close(lun)
  endsubroutine self_test

  subroutine run(args, rval, error)
  !< Define the example CLI (messages captured), parse a command line and get the values.
  character(*), intent(in)     :: args    !< Command line.
  real(R8P),    intent(out)    :: rval(3) !< Real values.
  integer(I4P), intent(out)    :: error   !< Error trapping flag.
  type(command_line_interface) :: cli     !< Command Line Interface (CLI).

  call cli%init(progname='test_nargs_insufficient', description='Test insufficient nargs', error_lun=lun, usage_lun=lun)
  call cli%add(switch='-i', help='Real list input', required=.true., act='store', nargs='3', error=error)
  call assert_equal(error, 0_I4P, 'add -i')
  rval = 0._R8P
  call cli%parse(args=args, error=error)
  if (error /= 0) return
  call cli%get(switch='-i', val=rval, error=error)
  endsubroutine run
endprogram flap_test_nargs_insufficient

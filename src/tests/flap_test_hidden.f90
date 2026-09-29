!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_hidden
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
!<
!< Run with arguments it is the example program above; run without arguments it checks its own scenarios.
use flap, only : command_line_interface, ERROR_MISSING_REQUIRED
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open
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
  character(99)                :: g_string  !< Ghost string value.
  integer(I4P)                 :: a_integer !< Integer value.
  integer(I4P)                 :: error     !< Error trapping flag.

  call cli%init(description = 'hiddens usage FLAP example')
  call cli%add(switch='--string', switch_ab='-s', help='a string', required=.true., act='store', error=error) ; if (error/=0) stop
  call cli%add(switch='--hidden', switch_ab='-hi', help='ghost string', required=.false., def='gstring not passed', &
               hidden=.true., act='store', error=error) ; if (error/=0) stop
  call cli%add(switch='--integer', switch_ab='-i', help='a integer', required=.true., act='store', error=error) ; if (error/=0) stop
  call cli%get(switch='-s', val=a_string, error=error) ; if (error/=0) stop
  call cli%get(switch='-hi', val=g_string, error=error) ; if (error/=0) stop
  call cli%get(switch='-i', val=a_integer, error=error) ; if (error/=0) stop
  print '(A)', cli%progname//' has been called with the following argument:'
  print '(A)', 'String       = '//trim(adjustl(a_string))
  print '(A)', 'Ghost string = '//trim(adjustl(g_string))
  print '(A)', 'Integer      = '//trim(adjustl(str(a_integer, .true.)))
  endsubroutine example

  subroutine self_test()
  !< A hidden CLA works like any other but does not appear in the help.
  type(command_line_interface) :: cli       !< Command Line Interface (CLI).
  character(99)                :: a_string  !< String value.
  character(99)                :: g_string  !< Ghost string value.
  integer(I4P)                 :: a_integer !< Integer value.
  integer(I4P)                 :: error     !< Error trapping flag.

  call capture_open(lun)
  call run(cli, '-s a -i 3', error)
  call assert_equal(error, 0_I4P, '-s a -i 3: parse error')
  call cli%get(switch='-s', val=a_string, error=error)
  call assert_equal(a_string, 'a', '-s a -i 3: string')
  call cli%get(switch='-hi', val=g_string, error=error)
  call assert_equal(g_string, 'gstring not passed', '-s a -i 3: hidden default')
  call cli%get(switch='-i', val=a_integer, error=error)
  call assert_equal(a_integer, 3_I4P, '-s a -i 3: integer')
  call assert_contains(cli%usage(g=0), '--string', 'usage lists --string')
  call assert(index(cli%usage(g=0), '--hidden') == 0, 'usage does not list --hidden')

  call run(cli, '-s a -hi g -i 3', error)
  call assert_equal(error, 0_I4P, '-s a -hi g -i 3: parse error')
  call cli%get(switch='-hi', val=g_string, error=error)
  call assert_equal(g_string, 'g', '-s a -hi g -i 3: hidden value')

  call run(cli, '-s a', error)
  call assert_equal(error, ERROR_MISSING_REQUIRED, '-s a: missing required --integer')
  call capture_close(lun)
  endsubroutine self_test

  subroutine run(cli, args, error)
  !< Define the example CLI (messages captured) and parse a command line.
  type(command_line_interface), intent(out) :: cli   !< Command Line Interface (CLI).
  character(*),                 intent(in)  :: args  !< Command line.
  integer(I4P),                 intent(out) :: error !< Error trapping flag.

  call cli%init(progname='flap_test_hidden', description='hiddens usage FLAP example', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--string', switch_ab='-s', help='a string', required=.true., act='store', error=error)
  call assert_equal(error, 0_I4P, 'add --string')
  call cli%add(switch='--hidden', switch_ab='-hi', help='ghost string', required=.false., def='gstring not passed', &
               hidden=.true., act='store', error=error)
  call assert_equal(error, 0_I4P, 'add --hidden')
  call cli%add(switch='--integer', switch_ab='-i', help='a integer', required=.true., act='store', error=error)
  call assert_equal(error, 0_I4P, 'add --integer')
  call cli%parse(args=args, error=error)
  endsubroutine run
endprogram flap_test_hidden

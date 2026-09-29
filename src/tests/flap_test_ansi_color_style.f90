!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_ansi_color_style
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!< Run with arguments it is the example program above; run without arguments it checks its own scenarios.

use flap, only : command_line_interface, ERROR_MISSING_REQUIRED
use flap_test_utils, only : assert_contains, assert_equal, capture_close, capture_open, read_back
use penf

implicit none
character(1), parameter :: ESC = achar(27) !< ANSI escape character.
integer(I4P)            :: lun             !< Capture unit for FLAP messages in self-test mode.

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

  call cli%init(description = 'ANSI colored-styled FLAP example', error_color='red', error_style='underline_on')
  call cli%add(switch='--string', switch_ab='-s', help='a string', &
               help_color='blue', help_style='italics_on', &
               required=.true., act='store', error=error) ; if (error/=0) stop
  call cli%add(switch='--optional', switch_ab='-opt', help='an optional string', &
               help_color='green', help_style='italics_on', &
               required=.false., act='store', def='hello', error=error) ; if (error/=0) stop
  call cli%get(switch='-s', val=string, error=error) ; if (error/=0) stop
  print '(A)', cli%progname//' has been called with the following arguments:'
  print '(A)', 'string = '//trim(adjustl(string))
  call cli%get(switch='-opt', val=string, error=error) ; if (error/=0) stop
  print '(A)', 'optional = '//trim(adjustl(string))
  endsubroutine example

  subroutine self_test()
  !< Error messages and help carry the requested ANSI colors and styles (help_color/help_style apply to the switch names).
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  character(:), allocatable    :: text  !< Captured messages.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call cli%init(progname='flap_test_ansi_color_style', description='ANSI colored-styled FLAP example', &
                error_color='red', error_style='underline_on', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--string', switch_ab='-s', help='a string', help_color='blue', help_style='italics_on', &
               required=.true., act='store', error=error)
  call assert_equal(error, 0_I4P, 'add --string')
  call cli%add(switch='--optional', switch_ab='-opt', help='an optional string', help_color='green', help_style='italics_on', &
               required=.false., act='store', def='hello', error=error)
  call assert_equal(error, 0_I4P, 'add --optional')
  call cli%parse(args='', error=error)
  call assert_equal(error, ERROR_MISSING_REQUIRED, 'missing --string: error')
  text = read_back(lun)
  call assert_contains(text, ESC//'[4m'//ESC//'[31merror'//ESC//'[0m'//ESC//'[0m', 'error label: underline + red')
  call assert_contains(text, ESC//'[3m'//ESC//'[34m--string'//ESC//'[0m'//ESC//'[0m', '--string: italics + blue')
  call assert_contains(text, ESC//'[3m'//ESC//'[32m-opt'//ESC//'[0m'//ESC//'[0m', '-opt: italics + green')
  call assert_contains(cli%usage(g=0), ESC//'[3m'//ESC//'[34m-s'//ESC//'[0m'//ESC//'[0m', 'usage: -s italics + blue')
  call capture_close(lun)
  endsubroutine self_test
endprogram flap_test_ansi_color_style

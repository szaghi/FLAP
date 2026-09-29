!< Long argument values and examples are kept whole (issue #125, B05).
program flap_test_long_values
!< Long argument values and examples are kept whole (issue #125, B05).
!<
!< A 10000-character value is passed on the real command line (child process) and in a string, and a 600-character example
!< is printed by the help: none of them may be truncated.
use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, reinvoke
use penf, only : I4P

implicit none
integer(I4P), parameter :: LONG = 10000_I4P !< Length of the long value.

select case(child_case())
case(0)
  call check_command_line
  call check_string
  call check_examples
case(1)
  call child_print_length
endselect

contains
  subroutine define_cli(cli, lun)
  !< Define a CLI with one string option and a long example.
  type(command_line_interface), intent(out)          :: cli   !< Command Line Interface (CLI).
  integer(I4P),                 intent(in), optional :: lun   !< Unit for usage and error messages.
  integer(I4P)                                       :: error !< Error trapping flag.

  if (present(lun)) then
    call cli%init(progname='flap_test_long_values', examples=['flap_test_long_values -s '//repeat('e', 575)], &
                  error_lun=lun, usage_lun=lun)
  else
    call cli%init(progname='flap_test_long_values', examples=['flap_test_long_values -s '//repeat('e', 575)])
  endif
  call cli%add(switch='--string', switch_ab='-s', help='a string', required=.true., act='store', error=error)
  call assert_equal(error, 0_I4P, 'add --string')
  endsubroutine define_cli

  subroutine child_print_length()
  !< Child scenario: parse the real command line and print the length and the last character of the value.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  character(2*LONG)            :: val   !< Value (buffer longer than the value).
  integer(I4P)                 :: error !< Error trapping flag.

  call define_cli(cli)
  call cli%get(switch='-s', val=val, error=error)
  call assert_equal(error, 0_I4P, 'child: get -s')
  print '(I0,1X,A)', len_trim(val), val(len_trim(val):len_trim(val))
  endsubroutine child_print_length

  subroutine check_command_line()
  !< A long value on the real command line is read whole.
  character(:), allocatable :: out      !< Child standard output.
  character(:), allocatable :: err      !< Child standard error.
  integer(I4P)              :: exitstat !< Child exit status.

  call reinvoke(1_I4P, exitstat, out, err, args='-s '//repeat('a', LONG - 1)//'z')
  call assert_equal(exitstat, 0_I4P, 'command line: exit status (stderr: '//err//')')
  call assert_equal(out, '10000 z'//new_line('a'), 'command line: 10000-character value kept whole')
  endsubroutine check_command_line

  subroutine check_string()
  !< A long value in an arguments string is read whole.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  character(2*LONG)            :: val   !< Value (buffer longer than the value).
  integer(I4P)                 :: lun   !< Capture unit.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call define_cli(cli, lun)
  call cli%parse(args='-s '//repeat('b', LONG - 1)//'z', error=error)
  call assert_equal(error, 0_I4P, 'string: parse')
  call cli%get(switch='-s', val=val, error=error)
  call assert_equal(int(len_trim(val), I4P), LONG, 'string: 10000-character value kept whole')
  call assert(val(LONG:LONG) == 'z', 'string: last character')
  call capture_close(lun)
  endsubroutine check_string

  subroutine check_examples()
  !< A 600-character example is printed whole by the help.
  type(command_line_interface) :: cli !< Command Line Interface (CLI).

  call define_cli(cli)
  call assert_contains(cli%usage(g=0_I4P), 'flap_test_long_values -s '//repeat('e', 575), '600-character example kept whole')
  endsubroutine check_examples
endprogram flap_test_long_values

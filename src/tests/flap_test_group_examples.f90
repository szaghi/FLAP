!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_group_examples
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
!<
!< Run with arguments it is the example program above; run without arguments it checks its own scenarios.

use, intrinsic :: iso_fortran_env, only : error_unit
use flap, only : command_line_interface, ERROR_UNKNOWN
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
  !< The example program: parse the real command line and print the values.
  type(command_line_interface) :: cli       !< Command Line Interface (CLI).
  character(99)                :: a_string  !< String value.
  integer(I4P)                 :: int_value !< Integer value.
  real(R4P)                    :: f_value   !< Float value.
  integer(I4P)                 :: error     !< Error trapping flag.

  call define_cli(cli, error_unit)

  print '(A)', cli%progname//' has been called with the following arguments:'
  call cli%get(switch='-s', val=a_string, error=error)
  print '(A)', 'String       = '//trim(adjustl(a_string))
  if(cli%run_command('gwe')) then 
    call cli%get(group = 'gwe', switch = '-i', val=int_value, error=error)
    print '(A)', 'Integer      = '//trim(str(int_value))
  endif
  if(cli%run_command('gne')) then 
    call cli%get(group = 'gne', switch = '-f', val=f_value, error=error)
    print '(A)', 'Float        = '//trim(str(f_value))
  endif
  print '(A,I0)', 'Error code   = ', error
  endsubroutine example

  subroutine define_cli(cli, lun)
  !< Define the example CLI.
  type(command_line_interface), intent(out) :: cli   !< Command Line Interface (CLI).
  integer(I4P),                 intent(in)  :: lun   !< Unit for usage and error messages.
  integer(I4P)                              :: error !< Error trapping flag.

  call cli%init(error_lun=lun, usage_lun=lun,                                           &
                description = 'group examples usage FLAP example',                    &
                examples = ["flap_test_group_examples -s 'test string'      ",          &
                            "flap_test_group_examples --string 'test string'"])

  call cli%add(switch='--string', switch_ab='-s',  help='String input', required=.false., act='store',  def='test', error=error)

  call cli%add_group(group = 'gwe', description = 'Group with examples',                &
                     examples = ["flap_test_group_examples gwe --integer 32",           &
                                 "flap_test_group_examples gwe -i 12       "])
  call cli%add(group = "gwe",                                                           &
               switch='--integer', switch_ab='-i', help='Integer input', required=.false., act='store', def='-1',   error=error)

  call cli%add_group(group = 'gne', description = 'Group without examples')
  call cli%add(group = 'gne',                                                           &
               switch='--float', switch_ab='-f',   help='Float input', required=.false., act='store',   def='-1.0', error=error)
  endsubroutine define_cli

  subroutine self_test()
  !< Group options, the top-level option and options of the wrong group (group usage and examples: flap_test_golden).
  type(command_line_interface) :: cli       !< Command Line Interface (CLI).
  character(99)                :: a_string  !< String value.
  integer(I4P)                 :: int_value !< Integer value.
  real(R4P)                    :: f_value   !< Float value.
  integer(I4P)                 :: error     !< Error trapping flag.

  call capture_open(lun)

  call parse('', cli, error)
  call assert_equal(error, 0_I4P, 'no arguments: error')
  call cli%get(switch='-s', val=a_string, error=error)
  call assert_equal(a_string, 'test', 'no arguments: --string default')
  call assert_equal(cli%run_command('gwe'), .false., 'no arguments: gwe not called')

  call parse('-s x gwe -i 12', cli, error)
  call assert_equal(error, 0_I4P, '-s x gwe -i 12: error')
  call cli%get(switch='-s', val=a_string, error=error)
  call assert_equal(a_string, 'x', '-s x gwe -i 12: --string')
  call assert_equal(cli%run_command('gwe'), .true., '-s x gwe -i 12: gwe called')
  call cli%get(group='gwe', switch='-i', val=int_value, error=error)
  call assert_equal(int_value, 12_I4P, '-s x gwe -i 12: --integer')

  call parse('gne -f 2.5', cli, error)
  call assert_equal(cli%run_command('gne'), .true., 'gne -f 2.5: gne called')
  call cli%get(group='gne', switch='-f', val=f_value, error=error)
  call assert_equal(real(f_value, R8P), 2.5_R8P, 'gne -f 2.5: --float')

  call parse('gwe -f 1', cli, error)
  call assert_equal(error, ERROR_UNKNOWN, 'gwe -f 1: --float belongs to gne')

  call capture_close(lun)
  endsubroutine self_test

  subroutine parse(args, cli, error)
  !< Define the example CLI (messages captured) and parse a command line.
  character(*),                 intent(in)  :: args  !< Command line.
  type(command_line_interface), intent(out) :: cli   !< Command Line Interface (CLI).
  integer(I4P),                 intent(out) :: error !< Error trapping flag of parse.

  call define_cli(cli, lun)
  call cli%parse(args=args, error=error)
  endsubroutine parse
endprogram flap_test_group_examples

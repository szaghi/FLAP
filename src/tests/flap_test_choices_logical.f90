!< Test FLAP for bad usage of choices option with logical
program flap_test_choices_logical
!< Test FLAP for bad usage of choices option with logical
!<
!< Run with arguments it is the example program above; run without arguments it checks its own scenarios.
use flap, only : command_line_interface, ERROR_CASTING_LOGICAL, ERROR_CHOICES_LOGICAL
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
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  logical                      :: vbval !< Valued-boolean value.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='test_choices_logical')
  call cli%add(switch='--boolean-value', switch_ab='-bv', help='A help message', &
               required=.false., def='.false.', choices='.True.,.False.', act='store', error=error)
  call cli%parse(error=error)
  call cli%get(switch='-bv', val=vbval, error=error)
  print "(A)", "Error code: "//trim(str(error, .true.))
  endsubroutine example

  subroutine self_test()
  !< `choices` is accepted by `add` on a logical CLA, but every `get` into a logical rejects it.
  integer(I4P) :: error !< Error trapping flag.

  call capture_open(lun)
  call run('', error)
  call assert_equal(error, ERROR_CHOICES_LOGICAL, 'default value: get error')
  call run('-bv .true.', error)
  call assert_equal(error, ERROR_CHOICES_LOGICAL, '-bv .true.: get error')
  call run('-bv maybe', error)
  call assert_equal(error, ERROR_CASTING_LOGICAL, '-bv maybe: casting is checked before choices')
  call capture_close(lun)
  endsubroutine self_test

  subroutine run(args, error)
  !< Define the example CLI (messages captured), parse a command line and get the value.
  character(*), intent(in)     :: args  !< Command line.
  integer(I4P), intent(out)    :: error !< Error trapping flag of get.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  logical                      :: vbval !< Valued-boolean value.

  call cli%init(progname='test_choices_logical', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--boolean-value', switch_ab='-bv', help='A help message', &
               required=.false., def='.false.', choices='.True.,.False.', act='store', error=error)
  call assert_equal(error, 0_I4P, 'add accepts choices on a logical CLA')
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, 'parse "'//args//'"')
  call cli%get(switch='-bv', val=vbval, error=error)
  endsubroutine run
endprogram flap_test_choices_logical

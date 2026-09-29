!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_action_store
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
use flap, only : command_line_interface, ERROR_MISSING_REQUIRED, ERROR_NARGS_INSUFFICIENT, ERROR_VALUE_MISSING
use flap_test_utils, only : assert, assert_equal, capture_close, capture_open
use penf

implicit none
character(*), parameter :: REQUIRED = '--read foo --multiple_rrs --multiple_ros --multiple_rrp baz --multiple_rop '// &
                                   '--multiple_rr3 1 2 3 --multiple_ro3' !< Required CLAs.
integer(I4P)            :: lun !< Capture unit for FLAP messages in self-test mode.

if (command_argument_count() > 0) then
  call example
else
  call self_test
endif

contains
  subroutine example()
  !< The example program: parse the real command line and print every value.
  type(command_line_interface) :: cli         !< Command Line Interface (CLI).
  character(99)                :: string_r    !< String value.
  character(99)                :: string_i    !< String value.
  character(99)                :: string_o    !< String value.
  character(99)                :: string_w    !< String value.
  character(99), allocatable   :: string_m(:) !< List of string values.
  integer(I4P)                 :: error       !< Error trapping flag.
  integer(I4P)                 :: i           !< Counter.

  call define_cli(cli, error_unit)

  call cli%get(switch='-r', val=string_r, error=error) ; if (error/=0) stop
  call cli%get(switch='-i', val=string_i, error=error) ; if (error/=0) stop
  call cli%get(switch='-w', val=string_w, error=error) ; if (error/=0) stop
  call cli%get(switch='-o', val=string_o, error=error) ; if (error/=0) stop
  print '(A)', cli%progname//' has been called with the following arguments:'
  print '(A)', '--read         = '//trim(adjustl(string_r))
  print '(A)', '--input        = '//trim(adjustl(string_i))
  print '(A)', '--output       = '//trim(adjustl(string_o))
  print '(A)', '--write        = '//trim(adjustl(string_w))
  ! store nargs=*
  print '(A)', '--multiple required CLA with required values (*) : '
  call cli%get_varying(switch='-mrrs', val=string_m, error=error) ; if (error/=0) stop
  do i=1, size(string_m, dim=1)
     print '(A)', '   '//trim(adjustl(string_m(i)))
  enddo
  deallocate(string_m)
  print '(A)', '--multiple required CLA with optional values (*) : '
  call cli%get_varying(switch='-mros', val=string_m, error=error) ; if (error/=0) stop
  do i=1, size(string_m, dim=1)
     print '(A)', '   '//trim(adjustl(string_m(i)))
  enddo
  deallocate(string_m)
  print '(A)', '--multiple optional CLA with optional values (*) : '
  call cli%get_varying(switch='-moos', val=string_m, error=error) ; if (error/=0) stop
  do i=1, size(string_m, dim=1)
     print '(A)', '   '//trim(adjustl(string_m(i)))
  enddo
  deallocate(string_m)
  ! store nargs=+
  print '(A)', '--multiple required CLA with required values (+) : '
  call cli%get_varying(switch='-mrrp', val=string_m, error=error) ; if (error/=0) stop
  do i=1, size(string_m, dim=1)
     print '(A)', '   '//trim(adjustl(string_m(i)))
  enddo
  deallocate(string_m)
  print '(A)', '--multiple required CLA with optional values (+) : '
  call cli%get_varying(switch='-mrop', val=string_m, error=error) ; if (error/=0) stop
  do i=1, size(string_m, dim=1)
     print '(A)', '   '//trim(adjustl(string_m(i)))
  enddo
  deallocate(string_m)
  print '(A)', '--multiple optional CLA with optional values (+) : '
  call cli%get_varying(switch='-moop', val=string_m, error=error) ; if (error/=0) stop
  do i=1, size(string_m, dim=1)
     print '(A)', '   '//trim(adjustl(string_m(i)))
  enddo
  deallocate(string_m)
  ! store nargs=3
  print '(A)', '--multiple required CLA with required values (3) : '
  call cli%get_varying(switch='-mrr3', val=string_m, error=error) ; if (error/=0) stop
  do i=1, size(string_m, dim=1)
     print '(A)', '   '//trim(adjustl(string_m(i)))
  enddo
  deallocate(string_m)
  print '(A)', '--multiple required CLA with optional values (3) : '
  call cli%get_varying(switch='-mro3', val=string_m, error=error) ; if (error/=0) stop
  do i=1, size(string_m, dim=1)
     print '(A)', '   '//trim(adjustl(string_m(i)))
  enddo
  deallocate(string_m)
  print '(A)', '--multiple optional CLA with optional values (3) : '
  call cli%get_varying(switch='-moo3', val=string_m, error=error) ; if (error/=0) stop
  do i=1, size(string_m, dim=1)
     print '(A)', '   '//trim(adjustl(string_m(i)))
  enddo
  deallocate(string_m)

  if (cli%is_passed(switch='-w')) then
     print '(A)', 'I am writing on "'//trim(adjustl(string_w))//'"'
  else
     print '(A)', 'I am writing on "'//trim(adjustl(string_o))//'"'
  endif
  endsubroutine example

  subroutine define_cli(cli, lun)
  !< Define the example CLI.
  type(command_line_interface), intent(out) :: cli   !< Command Line Interface (CLI).
  integer(I4P),                 intent(in)  :: lun   !< Unit for usage and error messages.
  integer(I4P)                              :: error !< Error trapping flag.

  call cli%init(error_lun=lun, usage_lun=lun,                                                                        &
                description = 'test action store CLA with required/optional values',                                     &
                examples=['flap_test_action_store --read foo '          //                                               &
                                                 '--input '             //                                               &
                                                 '--multiple_rrs '      //                                               &
                                                 '--multiple_ros '      //                                               &
                                                 '--multiple_rrp baz '  //                                               &
                                                 '--multiple_rop '      //                                               &
                                                 '--multiple_rr3 1 2 3 '//                                               &
                                                 '--multiple_ro3'       //                                               &
                                                 '                                                                     ',&
                          'flap_test_action_store --read foo '          //                                               &
                                                 '--input bar '         //                                               &
                                                 '--multiple_rrs '      //                                               &
                                                 '--multiple_ros '      //                                               &
                                                 '--multiple_rrp baz '  //                                               &
                                                 '--multiple_rop '      //                                               &
                                                 '--multiple_rr3 1 2 3 '//                                               &
                                                 '--multiple_ro3'       //                                               &
                                                 '                                                                 ',    &
                          'flap_test_action_store --read foo '          //                                               &
                                                 '--input bar '         //                                               &
                                                 '--write fee '         //                                               &
                                                 '--multiple_rrs '      //                                               &
                                                 '--multiple_ros '      //                                               &
                                                 '--multiple_rrp baz '  //                                               &
                                                 '--multiple_rop '      //                                               &
                                                 '--multiple_rr3 1 2 3 '//                                               &
                                                 '--multiple_ro3'       //                                               &
                                                 '                                                     ',                &
                          'flap_test_action_store --read foo '          //                                               &
                                                 '--input bar '         //                                               &
                                                 '--write fee '         //                                               &
                                                 '--output '            //                                               &
                                                 '--multiple_rrs '      //                                               &
                                                 '--multiple_ros '      //                                               &
                                                 '--multiple_rrp baz '  //                                               &
                                                 '--multiple_rop '      //                                               &
                                                 '--multiple_rr3 1 2 3 '//                                               &
                                                 '--multiple_ro3'       //                                               &
                                                 '                                            ',                         &
                          'flap_test_action_store --read foo '          //                                               &
                                                 '--input bar '         //                                               &
                                                 '--write fee '         //                                               &
                                                 '--output fie '        //                                               &
                                                 '--multiple_rrs '      //                                               &
                                                 '--multiple_ros '      //                                               &
                                                 '--multiple_rrp baz '  //                                               &
                                                 '--multiple_rop '      //                                               &
                                                 '--multiple_rr3 1 2 3 '//                                               &
                                                 '--multiple_ro3'       //                                               &
                                                 '                                        ',                             &
                          'flap_test_action_store --read foo '          //                                               &
                                                 '--input bar '         //                                               &
                                                 '--write fee '         //                                               &
                                                 '--output fie '        //                                               &
                                                 '--multiple_rrs '      //                                               &
                                                 '--multiple_ros '      //                                               &
                                                 '--multiple_rrp baz '  //                                               &
                                                 '--multiple_rop '      //                                               &
                                                 '--multiple_rr3 1 2 3 '//                                               &
                                                 '--multiple_ro3 '      //                                               &
                                                 '--multiple_oos'       //                                               &
                                                 '                         ',                                            &
                          'flap_test_action_store --read foo '          //                                               &
                                                 '--input bar '         //                                               &
                                                 '--write fee '         //                                               &
                                                 '--output fie '        //                                               &
                                                 '--multiple_rrs '      //                                               &
                                                 '--multiple_ros '      //                                               &
                                                 '--multiple_rrp baz '  //                                               &
                                                 '--multiple_rop '      //                                               &
                                                 '--multiple_rr3 1 2 3 '//                                               &
                                                 '--multiple_ro3 '      //                                               &
                                                 '--multiple_oos foe'   //                                               &
                                                 '                     ',                                                &
                          'flap_test_action_store --read foo '          //                                               &
                                                 '--input bar '         //                                               &
                                                 '--write fee '         //                                               &
                                                 '--output fie '        //                                               &
                                                 '--multiple_rrs '      //                                               &
                                                 '--multiple_ros '      //                                               &
                                                 '--multiple_rrp baz '  //                                               &
                                                 '--multiple_rop '      //                                               &
                                                 '--multiple_rr3 1 2 3 '//                                               &
                                                 '--multiple_ro3 '      //                                               &
                                                 '--multiple_oop '      //                                               &
                                                 '--multiple_oos foe'   //                                               &
                                                 '      ',                                                               &
                          'flap_test_action_store --read foo '          //                                               &
                                                 '--input bar '         //                                               &
                                                 '--write fee '         //                                               &
                                                 '--output fie '        //                                               &
                                                 '--multiple_rrs '      //                                               &
                                                 '--multiple_ros '      //                                               &
                                                 '--multiple_rrp baz '  //                                               &
                                                 '--multiple_rop '      //                                               &
                                                 '--multiple_rr3 1 2 3 '//                                               &
                                                 '--multiple_ro3 '      //                                               &
                                                 '--multiple_oop foo '  //                                               &
                                                 '--multiple_oos foe  ',                                                 &
                          'flap_test_action_store --read foo '          //                                               &
                                                 '--input bar '         //                                               &
                                                 '--write fee '         //                                               &
                                                 '--output fie '        //                                               &
                                                 '--multiple_rrs '      //                                               &
                                                 '--multiple_ros '      //                                               &
                                                 '--multiple_rrp baz '  //                                               &
                                                 '--multiple_rop '      //                                               &
                                                 '--multiple_rr3 1 2 3 '//                                               &
                                                 '--multiple_ro3 '      //                                               &
                                                 '--multiple_oop foo '  //                                               &
                                                 '--multiple_oo3      ',                                                 &
                          'flap_test_action_store --read foo '          //                                               &
                                                 '--input bar '         //                                               &
                                                 '--write fee '         //                                               &
                                                 '--output fie '        //                                               &
                                                 '--multiple_rrs '      //                                               &
                                                 '--multiple_ros '      //                                               &
                                                 '--multiple_rrp baz '  //                                               &
                                                 '--multiple_rop '      //                                               &
                                                 '--multiple_rr3 1 2 3 '//                                               &
                                                 '--multiple_ro3 '      //                                               &
                                                 '--multiple_oop foo '  //                                               &
                                                 '--multiple_oo3 a b c'                                                  &
                          ])
  call cli%add(switch='--read', switch_ab='-r',           &
               help='a required CLA with required value', &
               required=.true.,                           &
               val_required=.true.,                       &
               act='store',                               &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--input', switch_ab='-i',          &
               help='a required CLA with optional value', &
               required=.true.,                           &
               val_required=.false.,                      &
               def='default.i',                           &
               act='store',                               &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--write', switch_ab='-w',                     &
               help='an optional CLA with required value if passed', &
               required=.false.,                                     &
               def='default.w',                                      &
               act='store',                                          &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--output', switch_ab='-o',          &
               help='an optional CLA with optional value', &
               required=.false.,                           &
               val_required=.false.,                       &
               def='default.o',                            &
               act='store',                                &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  ! store nargs=*
  call cli%add(switch='--multiple_rrs', switch_ab='-mrrs',              &
               help='a required CLA with required multiple (*) values', &
               required=.true.,                                         &
               val_required=.true.,                                     &
               def='default.rss1 default.rss2 default.rss3',            &
               act='store',                                             &
               nargs='*',                                               &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--multiple_ros', switch_ab='-mros',              &
               help='a required CLA with optional multiple (*) values', &
               required=.true.,                                         &
               val_required=.false.,                                    &
               def='default.ros1 default.ros2',                         &
               act='store',                                             &
               nargs='*',                                               &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--multiple_oos', switch_ab='-moos',               &
               help='an optional CLA with optional multiple (*) values', &
               required=.false.,                                         &
               val_required=.false.,                                     &
               def='default.oos1 default.oos2 default.oos3',             &
               act='store',                                              &
               nargs='*',                                                &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  ! store nargs=+
  call cli%add(switch='--multiple_rrp', switch_ab='-mrrp',              &
               help='a required CLA with required multiple (+) values', &
               required=.true.,                                         &
               val_required=.true.,                                     &
               act='store',                                             &
               nargs='+',                                               &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--multiple_rop', switch_ab='-mrop',              &
               help='a required CLA with optional multiple (+) values', &
               required=.true.,                                         &
               val_required=.false.,                                    &
               def='default.rop1 default.rop2',                         &
               act='store',                                             &
               nargs='+',                                               &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--multiple_oop', switch_ab='-moop',               &
               help='an optional CLA with optional multiple (+) values', &
               required=.false.,                                         &
               val_required=.false.,                                     &
               def='default.oop1 default.oop2 default.oop3',             &
               act='store',                                              &
               nargs='+',                                                &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  ! store nargs=3
  call cli%add(switch='--multiple_rr3', switch_ab='-mrr3',              &
               help='a required CLA with required multiple (3) values', &
               required=.true.,                                         &
               val_required=.true.,                                     &
               act='store',                                             &
               nargs='3',                                               &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--multiple_ro3', switch_ab='-mro3',              &
               help='a required CLA with optional multiple (3) values', &
               required=.true.,                                         &
               val_required=.false.,                                    &
               def='default.ro31 default.ro32 default.ro33',            &
               act='store',                                             &
               nargs='3',                                               &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--multiple_oo3', switch_ab='-moo3',               &
               help='an optional CLA with optional multiple (3) values', &
               required=.false.,                                         &
               val_required=.false.,                                     &
               def='default.oo31 default.oo32 default.oo33',             &
               act='store',                                              &
               nargs='3',                                                &
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  endsubroutine define_cli

  subroutine self_test()
  !< Required and optional values: a CLA with an optional value falls back to its default when passed alone.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)

  call parse(REQUIRED//' --input', cli)
  call check_scalar(cli, '-r', 'foo', 'required value')
  call check_scalar(cli, '-i', 'default.i', 'required CLA passed without its optional value: default')
  call check_scalar(cli, '-w', 'default.w', 'optional CLA not passed: default')
  call check_scalar(cli, '-o', 'default.o', 'optional CLA not passed: default')
  call check_list(cli, '-mrrs', [character(12) :: 'default.rss1', 'default.rss2', 'default.rss3'], &
                   "nargs='*' passed alone: default")
  call check_list(cli, '-mros', [character(12) :: 'default.ros1', 'default.ros2'], "nargs='*' passed alone: default")
  call check_list(cli, '-moos', [character(12) :: 'default.oos1', 'default.oos2', 'default.oos3'], "nargs='*' not passed: default")
  call check_list(cli, '-mrrp', [character(12) :: 'baz'], "nargs='+' value")
  call check_list(cli, '-mrop', [character(12) :: 'default.rop1', 'default.rop2'], "nargs='+' with optional values alone: default")
  call check_list(cli, '-moop', [character(12) :: 'default.oop1', 'default.oop2', 'default.oop3'], "nargs='+' not passed: default")
  call check_list(cli, '-mrr3', [character(12) :: '1', '2', '3'], "nargs='3' values")
  ! B28 (#125): a default must have nargs values (it had 2 for nargs='3', a definition error now)
  call check_list(cli, '-mro3', [character(12) :: 'default.ro31', 'default.ro32', 'default.ro33'], &
                   "nargs='3' passed alone: default")
  call check_list(cli, '-moo3', [character(12) :: 'default.oo31', 'default.oo32', 'default.oo33'], "nargs='3' not passed: default")

  call parse(REQUIRED//' --input bar --write fee --output fie --multiple_oos foe --multiple_oop foo --multiple_oo3 a b c', cli)
  call check_scalar(cli, '-i', 'bar', 'optional value passed')
  call check_scalar(cli, '-w', 'fee', 'optional CLA passed')
  call check_scalar(cli, '-o', 'fie', 'optional CLA with optional value passed')
  call check_list(cli, '-moos', [character(12) :: 'foe'], "nargs='*' values")
  call check_list(cli, '-moop', [character(12) :: 'foo'], "nargs='+' values")
  call check_list(cli, '-moo3', [character(12) :: 'a', 'b', 'c'], "nargs='3' values")

  call parse(REQUIRED//' --input --output', cli)
  call check_scalar(cli, '-o', 'default.o', 'optional CLA passed without its optional value: default')

  call parse(REQUIRED(12:)//' --input', cli, error)
  call assert_equal(error, ERROR_MISSING_REQUIRED, '--read missing: error')
  call parse('--read '//REQUIRED(12:)//' --input', cli, error)
  call assert_equal(error, ERROR_VALUE_MISSING, '--read without its required value: error')
  call parse(REQUIRED//' --input --write', cli, error)
  call assert_equal(error, ERROR_VALUE_MISSING, '--write without its required value: error')
  call parse('--read foo --multiple_rrs --multiple_ros --multiple_rrp baz --multiple_rop --multiple_rr3 1 2 --multiple_ro3 '// &
             '--input', cli, error)
  call assert_equal(error, ERROR_NARGS_INSUFFICIENT, "nargs='3' with 2 values: error")
  call parse('--read foo --multiple_rrs --multiple_ros --multiple_rrp --multiple_rop --multiple_rr3 1 2 3 --multiple_ro3 '// &
             '--input', cli, error)
  call assert_equal(error, ERROR_NARGS_INSUFFICIENT, "nargs='+' with a required value passed alone: error")
  call capture_close(lun)
  endsubroutine self_test

  subroutine parse(args, cli, error)
  !< Define the example CLI (messages captured) and parse a command line; without `error`, the parse must succeed.
  character(*),                 intent(in)            :: args  !< Command line.
  type(command_line_interface), intent(out)           :: cli   !< Command Line Interface (CLI).
  integer(I4P),                 intent(out), optional :: error !< Error trapping flag of parse.
  integer(I4P)                                        :: err   !< Error trapping flag.

  call define_cli(cli, lun)
  call cli%parse(args=args, error=err)
  if (present(error)) then
    error = err
  else
    call assert_equal(err, 0_I4P, 'parse "'//args//'"')
  endif
  endsubroutine parse

  subroutine check_scalar(cli, switch, expected, message)
  !< Check the value of a scalar CLA.
  type(command_line_interface), intent(inout) :: cli      !< Command Line Interface (CLI).
  character(*),                 intent(in)    :: switch   !< Switch.
  character(*),                 intent(in)    :: expected !< Expected value.
  character(*),                 intent(in)    :: message  !< Description of the check.
  character(99)                               :: val      !< Value.
  integer(I4P)                                :: error    !< Error trapping flag.

  call cli%get(switch=switch, val=val, error=error)
  call assert_equal(error, 0_I4P, switch//' '//message//': error')
  call assert_equal(val, expected, switch//' '//message)
  endsubroutine check_scalar

  subroutine check_list(cli, switch, expected, message)
  !< Check the values of a list CLA.
  type(command_line_interface), intent(inout) :: cli         !< Command Line Interface (CLI).
  character(*),                 intent(in)    :: switch      !< Switch.
  character(*),                 intent(in)    :: expected(:) !< Expected values.
  character(*),                 intent(in)    :: message     !< Description of the check.
  character(99), allocatable                  :: val(:)      !< Values.
  integer(I4P)                                :: error       !< Error trapping flag.
  integer(I4P)                                :: v           !< Counter.

  call cli%get_varying(switch=switch, val=val, error=error)
  call assert_equal(error, 0_I4P, switch//' '//message//': error')
  call assert_equal(int(size(val), I4P), int(size(expected), I4P), switch//' '//message//': size')
  do v = 1, int(size(expected), I4P)
    call assert_equal(val(v), expected(v), switch//' '//message)
  enddo
  endsubroutine check_list
endprogram flap_test_action_store

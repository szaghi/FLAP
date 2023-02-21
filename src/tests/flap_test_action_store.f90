!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_action_store
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).

use flap, only : command_line_interface
use penf

implicit none
type(command_line_interface) :: cli         !< Command Line Interface (CLI).
character(99)                :: string_r    !< String value.
character(99)                :: string_i    !< String value.
character(99)                :: string_o    !< String value.
character(99)                :: string_w    !< String value.
character(99), allocatable   :: string_m(:) !< List of string values.
integer(I4P)                 :: error       !< Error trapping flag.
integer(I4P)                 :: i           !< Counter.

call cli%init(description = 'test action store CLA with required/optional values',                                     &
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
             error=error) ; if (error/=0) stop
call cli%add(switch='--input', switch_ab='-i',          &
             help='a required CLA with optional value', &
             required=.true.,                           &
             val_required=.false.,                      &
             def='default.i',                           &
             act='store',                               &
             error=error) ; if (error/=0) stop
call cli%add(switch='--write', switch_ab='-w',                     &
             help='an optional CLA with required value if passed', &
             required=.false.,                                     &
             def='default.w',                                      &
             act='store',                                          &
             error=error) ; if (error/=0) stop
call cli%add(switch='--output', switch_ab='-o',          &
             help='an optional CLA with optional value', &
             required=.false.,                           &
             val_required=.false.,                       &
             def='default.o',                            &
             act='store',                                &
             error=error) ; if (error/=0) stop
! store nargs=*
call cli%add(switch='--multiple_rrs', switch_ab='-mrrs',              &
             help='a required CLA with required multiple (*) values', &
             required=.true.,                                         &
             val_required=.true.,                                     &
             def='default.rss1 default.rss2 default.rss3',            &
             act='store',                                             &
             nargs='*',                                               &
             error=error) ; if (error/=0) stop
call cli%add(switch='--multiple_ros', switch_ab='-mros',              &
             help='a required CLA with optional multiple (*) values', &
             required=.true.,                                         &
             val_required=.false.,                                    &
             def='default.ros1 default.ros2',                         &
             act='store',                                             &
             nargs='*',                                               &
             error=error) ; if (error/=0) stop
call cli%add(switch='--multiple_oos', switch_ab='-moos',               &
             help='an optional CLA with optional multiple (*) values', &
             required=.false.,                                         &
             val_required=.false.,                                     &
             def='default.oos1 default.oos2 default.oos3',             &
             act='store',                                              &
             nargs='*',                                                &
             error=error) ; if (error/=0) stop
! store nargs=+
call cli%add(switch='--multiple_rrp', switch_ab='-mrrp',              &
             help='a required CLA with required multiple (+) values', &
             required=.true.,                                         &
             val_required=.true.,                                     &
             act='store',                                             &
             nargs='+',                                               &
             error=error) ; if (error/=0) stop
call cli%add(switch='--multiple_rop', switch_ab='-mrop',              &
             help='a required CLA with optional multiple (+) values', &
             required=.true.,                                         &
             val_required=.false.,                                    &
             def='default.rop1 default.rop2',                         &
             act='store',                                             &
             nargs='+',                                               &
             error=error) ; if (error/=0) stop
call cli%add(switch='--multiple_oop', switch_ab='-moop',               &
             help='an optional CLA with optional multiple (+) values', &
             required=.false.,                                         &
             val_required=.false.,                                     &
             def='default.oop1 default.oop2 default.oop3',             &
             act='store',                                              &
             nargs='+',                                                &
             error=error) ; if (error/=0) stop
! store nargs=3
call cli%add(switch='--multiple_rr3', switch_ab='-mrr3',              &
             help='a required CLA with required multiple (3) values', &
             required=.true.,                                         &
             val_required=.true.,                                     &
             act='store',                                             &
             nargs='3',                                               &
             error=error) ; if (error/=0) stop
call cli%add(switch='--multiple_ro3', switch_ab='-mro3',              &
             help='a required CLA with optional multiple (3) values', &
             required=.true.,                                         &
             val_required=.false.,                                    &
             def='default.ro31 default.ro32',                         &
             act='store',                                             &
             nargs='3',                                               &
             error=error) ; if (error/=0) stop
call cli%add(switch='--multiple_oo3', switch_ab='-moo3',               &
             help='an optional CLA with optional multiple (3) values', &
             required=.false.,                                         &
             val_required=.false.,                                     &
             def='default.oo31 default.oo32 default.oo33',             &
             act='store',                                              &
             nargs='3',                                                &
             error=error) ; if (error/=0) stop

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
endprogram flap_test_action_store

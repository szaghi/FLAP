!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program test_string
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
!-----------------------------------------------------------------------------------------------------------------------------------
use flap, only : command_line_interface
use penf
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
type(command_line_interface) :: cli        !< Command Line Interface (CLI).
character(99)                :: sval       !< String value.
real(R8P)                    :: rval       !< Real value.
real(R8P)                    :: prval      !< Positional real value.
integer(I4P)                 :: ival       !< Integer value.
integer(I4P)                 :: ieval      !< Exclusive integer value.
logical                      :: bval       !< Boolean value.
logical                      :: vbval      !< Valued-boolean value.
integer(I8P)                 :: ilist(1:3) !< Integer list values.
integer(I4P)                 :: error      !< Error trapping flag.
integer(I4P)                 :: l          !< Counter.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
! initialize Command Line Interface
call cli%init(progname    = 'test_sting',                                                 &
              version     = 'v2.1.5',                                                     &
              authors     = 'Stefano Zaghi',                                              &
              license     = 'MIT',                                                        &
              description = 'Toy program for testing FLAP with a fake string input',      &
              examples    = ["test_sting -s 'Hello FLAP'                               ", &
                             "test_sting -s 'Hello FLAP' -i -2 # printing error...     ", &
                             "test_sting -s 'Hello FLAP' -i 3 -ie 1 # printing error...", &
                             "test_sting -s 'Hello FLAP' -i 3 -r 33.d0                 ", &
                             "test_sting -s 'Hello FLAP' --integer_list 10 -3 87       ", &
                             "test_sting 33.0 -s 'Hello FLAP' -i 5                     ", &
                             "test_sting --string 'Hello FLAP' --boolean               "],&
              epilog      = new_line('a')//"And that's how to FLAP your life")

! set Command Line Arguments
call cli%add(switch='--string',switch_ab='-s',help='String input',required=.true.,act='store',error=error)
call cli%add(switch='--integer_ex',switch_ab='-ie',help='Exclusive integer input',required=.false.,act='store',def='-1',error=error)
call cli%add(switch='--integer',switch_ab='-i',help='Integer input with fixed range',required=.false.,act='store',&
             def='1',choices='1,3,5',exclude='-ie',error=error)
call cli%add(switch='--real',switch_ab='-r',help='Real input',required=.false.,act='store',def='1.0',error=error)
call cli%add(switch='--boolean',switch_ab='-b',help='Boolean input',required=.false.,act='store_true',def='.false.',&
             error=error)
call cli%add(switch='--boolean_val',switch_ab='-bv',help='Valued boolean input',required=.false., act='store',&
             def='.true.',error=error)
call cli%add(switch='--integer_list',switch_ab='-il',help='Integer list input',required=.false.,act='store',&
             nargs='3',def='1 8 32',error=error)
call cli%add(positional=.true.,position=1,help='Positional real input',required=.false.,def='1.0',error=error)

! parse Command Line Interface
call cli%parse(args="-s 'FAKE INVOCATION FROM STRING' --integer_list 10 -3 87",error=error)
if (error/=0) stop

! use Command Line Interface data to set test_string behaviour
call cli%get(switch='-s',    val=sval,  error=error) ; if (error/=0) stop
call cli%get(switch='-r',    val=rval,  error=error) ; if (error/=0) stop
call cli%get(switch='-i',    val=ival,  error=error) ; if (error/=0) stop
call cli%get(switch='-ie',   val=ieval, error=error) ; if (error/=0) stop
call cli%get(switch='-b',    val=bval,  error=error) ; if (error/=0) stop
call cli%get(switch='-bv',   val=vbval, error=error) ; if (error/=0) stop
call cli%get(switch='-il',   val=ilist, error=error) ; if (error/=0) stop
call cli%get(position=1_I4P, val=prval, error=error) ; if (error/=0) stop
print '(A)'   ,'test_string has been called with the following arguments values:'
print '(A)'   ,'String            input = '//trim(adjustl(sval))
print '(A)'   ,'Real              input = '//str(n=rval)
print '(A)'   ,'Integer           input = '//str(n=ival)
print '(A)'   ,'Exclusive integer input = '//str(n=ieval)
print '(A,L1)','Boolean           input = ',bval
print '(A,L1)','Valued boolean    input = ',vbval
print '(A)'   ,'Positional real   input = '//str(n=prval)
print '(A)'   ,'Integer list inputs:'
do l=1,3
  print '(A)' ,'Input('//trim(str(l, .true.))//') = '//trim(str(n=ilist(l)))
enddo
stop
!-----------------------------------------------------------------------------------------------------------------------------------
endprogram test_string

!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program test_basic
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision                                                        ! Integers and reals precision definition.
USE Data_Type_Command_Line_Interface, only: Type_Command_Line_Interface ! Definition of Type_Command_Line_Interface.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
type(Type_Command_Line_Interface) :: cli          !< Command Line Interface (CLI).
character(99)                     :: sval         !< String value.
real(R8P)                         :: rval         !< Real value.
real(R8P)                         :: prval        !< Positional real value.
integer(I4P)                      :: ival         !< Integer value.
integer(I4P)                      :: ieval        !< Exclusive integer value.
integer(I4P)                      :: envi         !< Environment set integer value.
logical                           :: bval         !< Boolean value.
logical                           :: vbval        !< Valued-boolean value.
integer(I8P)                      :: ilist(1:3)   !< Integer list values.
real(R8P),    allocatable         :: vlistR8P(:)  !< Varying size real list values.
real(R4P),    allocatable         :: vlistR4P(:)  !< Varying size real list values.
integer(I8P), allocatable         :: vlistI8P(:)  !< Varying size integer list values.
integer(I4P), allocatable         :: vlistI4P(:)  !< Varying size integer list values.
integer(I2P), allocatable         :: vlistI2P(:)  !< Varying size integer list values.
integer(I1P), allocatable         :: vlistI1P(:)  !< Varying size integer list values.
logical,      allocatable         :: vlistBool(:) !< Varying size boolean list values.
character(10),allocatable         :: vlistChar(:) !< Varying size character list values.
character(99),allocatable         :: garbage(:)   !< Varying size character list for trailing garbage values.
integer(I4P)                      :: error        !< Error trapping flag.
integer(I4P)                      :: l            !< Counter.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
! initializing Command Line Interface
call cli%init(progname    = 'test_basic',                                                 &
              version     = 'v2.1.5',                                                     &
              authors     = 'Stefano Zaghi',                                              &
              license     = 'MIT',                                                        &
              help        = 'Usage: ',                                                    &
              description = 'Toy program for testing FLAP',                               &
              examples    = ["test_basic -s 'Hello FLAP'                               ", &
                             "test_basic -s 'Hello FLAP' -i -2 # printing error...     ", &
                             "test_basic -s 'Hello FLAP' -i 3 -ie 1 # printing error...", &
                             "test_basic -s 'Hello FLAP' -i 3 -r 33.d0                 ", &
                             "test_basic -s 'Hello FLAP' --integer_list 10 -3 87       ", &
                             "test_basic -s 'Hello FLAP' --man_file FLAP.1             ", &
                             "test_basic 33.0 -s 'Hello FLAP' -i 5                     ", &
                             "test_basic --string 'Hello FLAP' --boolean               "],&
              epilog      = new_line('a')//"And that's how to FLAP your life")
! setting Command Line Argumenst
call cli%add(switch='--string',switch_ab='-s',help='String input',required=.true.,act='store',error=error)
if (error/=0) stop
call cli%add(switch='--integer_ex',switch_ab='-ie',help='Exclusive integer input',required=.false.,act='store',def='-1',error=error)
if (error/=0) stop
call cli%add(switch='--integer',switch_ab='-i',help='Integer input with fixed range',required=.false.,act='store',&
             def='1',choices='1,3,5',exclude='-ie',error=error)
if (error/=0) stop
call cli%add(switch='--real',switch_ab='-r',help='Real input',required=.false.,act='store',def='1.0',error=error)
if (error/=0) stop
call cli%add(switch='--boolean',switch_ab='-b',help='Boolean input',required=.false.,act='store_true',def='.false.',&
             error=error)
if (error/=0) stop
call cli%add(switch='--boolean_val',switch_ab='-bv',help='Valued boolean input',required=.false., act='store',&
             def='.true.',error=error)
if (error/=0) stop
call cli%add(switch='--integer_list',switch_ab='-il',help='Integer list input',required=.false.,act='store',&
             nargs='3',def='1 8 32',error=error)
if (error/=0) stop
call cli%add(positional=.true.,position=1,help='Positional real input',required=.false.,def='1.0',error=error)
if (error/=0) stop
call cli%add(switch='--env',switch_ab='-e',help='Environment input',required=.false.,act='store',def='-1',envvar='FLAP_NUM_INT',&
             error=error)
if (error/=0) stop
call cli%add(switch='--man_file',help='Save manual into man_file',required=.false.,act='store',def='test_basic.1',error=error)
if (error/=0) stop
call cli%add(switch='--varying_listR8P',switch_ab='-vlR8P',help='Varying size real R8P list input',required=.false.,act='store',&
             nargs='*',def='1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0',error=error)
if (error/=0) stop
call cli%add(switch='--varying_listR4P',switch_ab='-vlR4P',help='Varying size real R4P list input',required=.false.,act='store',&
             nargs='*',def='1.0 2.0 3.0 4.0',error=error)
if (error/=0) stop
call cli%add(switch='--varying_listI8P',switch_ab='-vlI8P',help='Varying size integer I8P list input',required=.false.,act='store',&
             nargs='*',def='1 2 3 4 5 6 7 8',error=error)
if (error/=0) stop
call cli%add(switch='--varying_listI4P',switch_ab='-vlI4P',help='Varying size integer I4P list input',required=.false.,act='store',&
             nargs='*',def='1 2 3 4',error=error)
if (error/=0) stop
call cli%add(switch='--varying_listI2P',switch_ab='-vlI2P',help='Varying size integer I2P list input',required=.false.,act='store',&
             nargs='*',def='1 2',error=error)
if (error/=0) stop
call cli%add(switch='--varying_listI1P',switch_ab='-vlI1P',help='Varying size integer I1P list input',required=.false.,act='store',&
             nargs='+',def='1',error=error)
if (error/=0) stop
call cli%add(switch='--varying_listBool',switch_ab='-vlBool',help='Varying size boolean list input',required=.false.,act='store',&
             nargs='*',def='T F T T F',error=error)
if (error/=0) stop
call cli%add(switch='--varying_listChar',switch_ab='-vlChar',help='Varying size character list input',required=.false.,act='store',&
             nargs='*',def='foo bar baz',error=error)
if (error/=0) stop
! parsing Command Line Interface
call cli%parse(error=error)
if (error/=0) stop
! using Command Line Interface data to set test_basic behaviour
call cli%get(        switch='-s',      val=sval,      error=error) ; if (error/=0) stop
call cli%get(        switch='-r',      val=rval,      error=error) ; if (error/=0) stop
call cli%get(        switch='-i',      val=ival,      error=error) ; if (error/=0) stop
call cli%get(        switch='-ie',     val=ieval,     error=error) ; if (error/=0) stop
call cli%get(        switch='-b',      val=bval,      error=error) ; if (error/=0) stop
call cli%get(        switch='-bv',     val=vbval,     error=error) ; if (error/=0) stop
call cli%get(        switch='-il',     val=ilist,     error=error) ; if (error/=0) stop
call cli%get(        switch='-e',      val=envi,      error=error) ; if (error/=0) stop
call cli%get(        position=1_I4P,   val=prval,     error=error) ; if (error/=0) stop
call cli%get_varying(switch='-vlR8P',  val=vlistR8P,  error=error) ; if (error/=0) stop
call cli%get_varying(switch='-vlR4P',  val=vlistR4P,  error=error) ; if (error/=0) stop
call cli%get_varying(switch='-vlI8P',  val=vlistI8P,  error=error) ; if (error/=0) stop
call cli%get_varying(switch='-vlI4P',  val=vlistI4P,  error=error) ; if (error/=0) stop
call cli%get_varying(switch='-vlI2P',  val=vlistI2P,  error=error) ; if (error/=0) stop
call cli%get_varying(switch='-vlI1P',  val=vlistI1P,  error=error) ; if (error/=0) stop
call cli%get_varying(switch='-vlBool', val=vlistBool, error=error) ; if (error/=0) stop
call cli%get_varying(switch='-vlChar', val=vlistChar, error=error) ; if (error/=0) stop
call cli%get_varying(switch='--',      val=garbage,   error=error) ; if (error/=0) stop
print '(A)'   ,'test_basic has been called with the following arguments values:'
print '(A)'   ,'String              input = '//trim(adjustl(sval))
print '(A)'   ,'Real                input = '//str(n=rval)
print '(A)'   ,'Integer             input = '//str(n=ival)
print '(A)'   ,'Exclusive   integer input = '//str(n=ieval)
print '(A)'   ,'Environment integer input = '//str(n=envi)
print '(A,L1)','Boolean             input = ',bval
print '(A,L1)','Valued boolean      input = ',vbval
print '(A)'   ,'Positional real     input = '//str(n=prval)
print '(A)'   ,'Integer list inputs:'
do l=1, 3
  print '(A)' ,'  Input('//trim(str(.true.,l))//') = '//trim(str(n=ilist(l)))
enddo
if (allocated(vlistR8P)) then
  print '(A)'   ,'Varying size real R8P list inputs:'
  do l=1, size(vlistR8P)
    print '(A)' ,'  Input('//trim(str(.true.,l))//') = '//trim(str(n=vlistR8P(l)))
  enddo
else
  print '(A)'   ,'Problems occuour with varying size real R8P list!'
endif
if (allocated(vlistR4P)) then
  print '(A)'   ,'Varying size real R4P list inputs:'
  do l=1, size(vlistR4P)
    print '(A)' ,'  Input('//trim(str(.true.,l))//') = '//trim(str(n=vlistR4P(l)))
  enddo
else
  print '(A)'   ,'Problems occuour with varying size real R4P list!'
endif
if (allocated(vlistI8P)) then
  print '(A)'   ,'Varying size integer I8P list inputs:'
  do l=1, size(vlistI8P)
    print '(A)' ,'  Input('//trim(str(.true.,l))//') = '//trim(str(n=vlistI8P(l)))
  enddo
else
  print '(A)'   ,'Problems occuour with varying size integer I8P list!'
endif
if (allocated(vlistI4P)) then
  print '(A)'   ,'Varying size integer I4P list inputs:'
  do l=1, size(vlistI4P)
    print '(A)' ,'  Input('//trim(str(.true.,l))//') = '//trim(str(n=vlistI4P(l)))
  enddo
else
  print '(A)'   ,'Problems occuour with varying size integer I4P list!'
endif
if (allocated(vlistI2P)) then
  print '(A)'   ,'Varying size integer I2P list inputs:'
  do l=1, size(vlistI2P)
    print '(A)' ,'  Input('//trim(str(.true.,l))//') = '//trim(str(n=vlistI2P(l)))
  enddo
else
  print '(A)'   ,'Problems occuour with varying size integer I2P list!'
endif
if (allocated(vlistI1P)) then
  print '(A)'   ,'Varying size integer I1P list inputs:'
  do l=1, size(vlistI1P)
    print '(A)' ,'  Input('//trim(str(.true.,l))//') = '//trim(str(n=vlistI1P(l)))
  enddo
else
  print '(A)'   ,'Problems occuour with varying size integer I1P list!'
endif
if (allocated(vlistBool)) then
  print '(A)'   ,'Varying size boolean list inputs:'
  do l=1, size(vlistBool)
    print '(A,L1)' ,'  Input('//trim(str(.true.,l))//') = ',vlistBool(l)
  enddo
else
  print '(A)'   ,'Problems occuour with varying size boolean list!'
endif
if (allocated(vlistChar)) then
  print '(A)'   ,'Varying size character list inputs:'
  do l=1, size(vlistChar)
    print '(A)' ,'  Input('//trim(str(.true.,l))//') = '//vlistChar(l)
  enddo
else
  print '(A)'   ,'Problems occuour with varying size character list!'
endif
if (allocated(garbage)) then
  print '(A)'   ,'You have used implicit "--" option for collecting list of "trailing garbage" values that are:'
  do l=1, size(garbage)
    print '(A)' ,'  Garbage('//trim(str(.true.,l))//') = '//garbage(l)
  enddo
endif
if (cli%passed(switch='--man_file')) then
  call cli%get(switch='--man_file',val=sval,error=error) ; if (error/=0) stop
  print '(A)','Saving man page'
  call cli%save_man_page(error=error,man_file=trim(adjustl(sval)))
endif
stop
!-----------------------------------------------------------------------------------------------------------------------------------
endprogram test_basic

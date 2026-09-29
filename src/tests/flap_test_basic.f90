!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_basic
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
use flap, only : command_line_interface, ERROR_M_EXCLUDE, ERROR_NARGS_INSUFFICIENT, ERROR_NOT_IN_CHOICES
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, reinvoke
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
  !< The example program: parse the real command line and print every value.
  type(command_line_interface) :: cli          !< Command Line Interface (CLI).
  character(99)                :: sval         !< String value.
  real(R8P)                    :: rval         !< Real value.
  real(R8P)                    :: prval        !< Positional real value.
  integer(I4P)                 :: ival         !< Integer value.
  integer(I4P)                 :: ieval        !< Exclusive integer value.
  integer(I4P)                 :: envi         !< Environment set integer value.
  logical                      :: bval         !< Boolean value.
  logical                      :: vbval        !< Valued-boolean value.
  integer(I8P)                 :: ilist(1:3)   !< Integer list values.
  real(R8P),     allocatable   :: vlistR8P(:)  !< Varying size real list values.
  real(R4P),     allocatable   :: vlistR4P(:)  !< Varying size real list values.
  integer(I8P),  allocatable   :: vlistI8P(:)  !< Varying size integer list values.
  integer(I4P),  allocatable   :: vlistI4P(:)  !< Varying size integer list values.
  integer(I2P),  allocatable   :: vlistI2P(:)  !< Varying size integer list values.
  integer(I1P),  allocatable   :: vlistI1P(:)  !< Varying size integer list values.
  logical,       allocatable   :: vlistBool(:) !< Varying size boolean list values.
  character(10), allocatable   :: vlistChar(:) !< Varying size character list values.
  character(99), allocatable   :: garbage(:)   !< Varying size character list for trailing garbage values.
  integer(I4P)                 :: error        !< Error trapping flag.
  integer(I4P)                 :: l            !< Counter.

  call define_cli(cli, error_unit)

  ! parse Command Line Interface
  ! this is optional: if skipped the first call to cli%get will automatically call cli%parse
  call cli%parse(error=error)
  if (error/=0) stop

  ! use Command Line Interface data to set test_basic behaviour
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
    print '(A)' ,'  Input('//trim(str(l, .true.))//') = '//trim(str(n=ilist(l)))
  enddo
  if (allocated(vlistR8P)) then
    print '(A)'   ,'Varying size real R8P list inputs:'
    do l=1, size(vlistR8P)
      print '(A)' ,'  Input('//trim(str(l, .true.))//') = '//trim(str(n=vlistR8P(l)))
    enddo
  else
    print '(A)'   ,'Problems occuour with varying size real R8P list!'
  endif
  if (allocated(vlistR4P)) then
    print '(A)'   ,'Varying size real R4P list inputs:'
    do l=1, size(vlistR4P)
      print '(A)' ,'  Input('//trim(str(l, .true.))//') = '//trim(str(n=vlistR4P(l)))
    enddo
  else
    print '(A)'   ,'Problems occuour with varying size real R4P list!'
  endif
  if (allocated(vlistI8P)) then
    print '(A)'   ,'Varying size integer I8P list inputs:'
    do l=1, size(vlistI8P)
      print '(A)' ,'  Input('//trim(str(l, .true.))//') = '//trim(str(n=vlistI8P(l)))
    enddo
  else
    print '(A)'   ,'Problems occuour with varying size integer I8P list!'
  endif
  if (allocated(vlistI4P)) then
    print '(A)'   ,'Varying size integer I4P list inputs:'
    do l=1, size(vlistI4P)
      print '(A)' ,'  Input('//trim(str(l, .true.))//') = '//trim(str(n=vlistI4P(l)))
    enddo
  else
    print '(A)'   ,'Problems occuour with varying size integer I4P list!'
  endif
  if (allocated(vlistI2P)) then
    print '(A)'   ,'Varying size integer I2P list inputs:'
    do l=1, size(vlistI2P)
      print '(A)' ,'  Input('//trim(str(l, .true.))//') = '//trim(str(n=vlistI2P(l)))
    enddo
  else
    print '(A)'   ,'Problems occuour with varying size integer I2P list!'
  endif
  if (allocated(vlistI1P)) then
    print '(A)'   ,'Varying size integer I1P list inputs:'
    do l=1, size(vlistI1P)
      print '(A)' ,'  Input('//trim(str(l, .true.))//') = '//trim(str(n=vlistI1P(l)))
    enddo
  else
    print '(A)'   ,'Problems occuour with varying size integer I1P list!'
  endif
  if (allocated(vlistBool)) then
    print '(A)'   ,'Varying size boolean list inputs:'
    do l=1, size(vlistBool)
      print '(A,L1)' ,'  Input('//trim(str(l, .true.))//') = ',vlistBool(l)
    enddo
  else
    print '(A)'   ,'Problems occuour with varying size boolean list!'
  endif
  if (allocated(vlistChar)) then
    print '(A)'   ,'Varying size character list inputs:'
    do l=1, size(vlistChar)
      print '(A)' ,'  Input('//trim(str(l, .true.))//') = '//vlistChar(l)
    enddo
  else
    print '(A)'   ,'Problems occuour with varying size character list!'
  endif
  if (allocated(garbage)) then
    print '(A)'   ,'You have used implicit "--" option for collecting list of "trailing garbage" values that are:'
    do l=1, size(garbage)
      print '(A)' ,'  Garbage('//trim(str(l, .true.))//') = '//garbage(l)
    enddo
  endif
  if (cli%is_passed(switch='--man_file')) then
    call cli%get(switch='--man_file',val=sval,error=error) ; if (error/=0) stop
    print '(A)','Saving man page'
    call cli%save_man_page(error=error,man_file=trim(adjustl(sval)))
  endif
  endsubroutine example

  subroutine define_cli(cli, lun)
  !< Define the example CLI.
  type(command_line_interface), intent(out) :: cli   !< Command Line Interface (CLI).
  integer(I4P),                 intent(in)  :: lun   !< Unit for usage and error messages.
  integer(I4P)                              :: error !< Error trapping flag.

  ! initialize Command Line Interface
  call cli%init(error_lun=lun, usage_lun=lun, progname    = 'test_basic',                                                 &
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

  ! set Command Line Argumenst
  call cli%add(switch='--string',switch_ab='-s',help='String input',required=.true.,act='store',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--integer_ex',switch_ab='-ie',help='Exclusive integer input',required=.false.,act='store',&
             def='-1',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--integer',switch_ab='-i',help='Integer input with fixed range',required=.false.,act='store',&
               def='1',choices='1,3,5',exclude='-ie',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--real',switch_ab='-r',help='Real input',required=.false.,act='store',def='1.0',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--boolean',switch_ab='-b',help='Boolean input',required=.false.,act='store_true',def='.false.',&
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--boolean_val',switch_ab='-bv',help='Valued boolean input',required=.false., act='store',&
               def='.true.',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--integer_list',switch_ab='-il',help='Integer list input',required=.false.,act='store',&
               nargs='3',def='1 8 32',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(positional=.true.,position=1,help='Positional real input',required=.false.,def='1.0',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--env',switch_ab='-e',help='Environment input',required=.false.,act='store',def='-1',envvar='FLAP_NUM_INT',&
               error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--man_file',help='Save manual into man_file',required=.false.,act='store',def='test_basic.1',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--varying_listR8P',switch_ab='-vlR8P',help='Varying size real R8P list input',required=.false.,act='store',&
               nargs='*',def='1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--varying_listR4P',switch_ab='-vlR4P',help='Varying size real R4P list input',required=.false.,act='store',&
               nargs='*',def='1.0 2.0 3.0 4.0',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--varying_listI8P',switch_ab='-vlI8P',help='Varying size integer I8P list input',&
             required=.false.,act='store',&
               nargs='*',def='1 2 3 4 5 6 7 8',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--varying_listI4P',switch_ab='-vlI4P',help='Varying size integer I4P list input',&
             required=.false.,act='store',&
               nargs='*',def='1 2 3 4',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--varying_listI2P',switch_ab='-vlI2P',help='Varying size integer I2P list input',&
             required=.false.,act='store',&
               nargs='*',def='1 2',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--varying_listI1P',switch_ab='-vlI1P',help='Varying size integer I1P list input',&
             required=.false.,act='store',&
               nargs='+',def='1',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--varying_listBool',switch_ab='-vlBool',help='Varying size boolean list input',required=.false.,act='store',&
               nargs='*',def='T F T T F',error=error)
  call assert_equal(error, 0_I4P, 'add')
  call cli%add(switch='--varying_listChar',switch_ab='-vlChar',help='Varying size character list input',&
             required=.false.,act='store',&
               nargs='*',def='foo bar baz',error=error)
  call assert_equal(error, 0_I4P, 'add')
  endsubroutine define_cli

  subroutine self_test()
  !< Check defaults, every value type, the positional, choices, exclusion, trailing values and the environment.
  type(command_line_interface) :: cli          !< Command Line Interface (CLI).
  character(99)                :: sval         !< String value.
  real(R8P)                    :: rval         !< Real value.
  real(R8P)                    :: prval        !< Positional real value.
  integer(I4P)                 :: ival         !< Integer value.
  integer(I4P)                 :: ieval        !< Exclusive integer value.
  integer(I4P)                 :: envi         !< Environment set integer value.
  logical                      :: bval         !< Boolean value.
  logical                      :: vbval        !< Valued-boolean value.
  integer(I8P)                 :: ilist(1:3)   !< Integer list values.
  real(R8P),     allocatable   :: vlistR8P(:)  !< Varying size real list values.
  real(R4P),     allocatable   :: vlistR4P(:)  !< Varying size real list values.
  integer(I8P),  allocatable   :: vlistI8P(:)  !< Varying size integer list values.
  integer(I4P),  allocatable   :: vlistI4P(:)  !< Varying size integer list values.
  integer(I2P),  allocatable   :: vlistI2P(:)  !< Varying size integer list values.
  integer(I1P),  allocatable   :: vlistI1P(:)  !< Varying size integer list values.
  logical,       allocatable   :: vlistBool(:) !< Varying size boolean list values.
  character(10), allocatable   :: vlistChar(:) !< Varying size character list values.
  character(99), allocatable   :: garbage(:)   !< Trailing values after "--".
  character(:),  allocatable   :: out          !< Child standard output.
  character(:),  allocatable   :: err          !< Child standard error.
  integer(I4P)                 :: exitstat     !< Child exit status.
  integer(I4P)                 :: error        !< Error trapping flag.

  call capture_open(lun)

  ! defaults
  call parse('-s hello', cli)
  call cli%get(switch='-s', val=sval, error=error) ; call assert_equal(sval, 'hello', 'default: -s')
  call cli%get(switch='-r', val=rval, error=error) ; call assert_equal(rval, 1._R8P, 'default: -r')
  call cli%get(switch='-i', val=ival, error=error) ; call assert_equal(ival, 1_I4P, 'default: -i')
  call cli%get(switch='-ie', val=ieval, error=error) ; call assert_equal(ieval, -1_I4P, 'default: -ie')
  call cli%get(switch='-b', val=bval, error=error) ; call assert_equal(bval, .false., 'default: -b')
  call cli%get(switch='-bv', val=vbval, error=error) ; call assert_equal(vbval, .true., 'default: -bv')
  call cli%get(switch='-il', val=ilist, error=error)
  call assert_equal(int(ilist, I4P), [1_I4P, 8_I4P, 32_I4P], 'default: -il')
  call cli%get(switch='-e', val=envi, error=error) ; call assert_equal(envi, -1_I4P, 'default: -e')
  call cli%get(position=1_I4P, val=prval, error=error) ; call assert_equal(prval, 1._R8P, 'default: positional')
  call cli%get_varying(switch='-vlR8P', val=vlistR8P, error=error)
  call assert_equal(vlistR8P, [1._R8P, 2._R8P, 3._R8P, 4._R8P, 5._R8P, 6._R8P, 7._R8P, 8._R8P], 'default: -vlR8P')
  call cli%get_varying(switch='-vlR4P', val=vlistR4P, error=error)
  call assert_equal(real(vlistR4P, R8P), [1._R8P, 2._R8P, 3._R8P, 4._R8P], 'default: -vlR4P')
  call cli%get_varying(switch='-vlI8P', val=vlistI8P, error=error)
  call assert_equal(int(vlistI8P, I4P), [1_I4P, 2_I4P, 3_I4P, 4_I4P, 5_I4P, 6_I4P, 7_I4P, 8_I4P], 'default: -vlI8P')
  call cli%get_varying(switch='-vlI4P', val=vlistI4P, error=error)
  call assert_equal(vlistI4P, [1_I4P, 2_I4P, 3_I4P, 4_I4P], 'default: -vlI4P')
  call cli%get_varying(switch='-vlI2P', val=vlistI2P, error=error)
  call assert_equal(int(vlistI2P, I4P), [1_I4P, 2_I4P], 'default: -vlI2P')
  call cli%get_varying(switch='-vlI1P', val=vlistI1P, error=error)
  call assert_equal(int(vlistI1P, I4P), [1_I4P], 'default: -vlI1P')
  call cli%get_varying(switch='-vlBool', val=vlistBool, error=error)
  call assert(all(vlistBool .eqv. [.true., .false., .true., .true., .false.]), 'default: -vlBool')
  call cli%get_varying(switch='-vlChar', val=vlistChar, error=error)
  call assert_equal(int(size(vlistChar), I4P), 3_I4P, 'default: -vlChar size')
  call assert(vlistChar(1) == 'foo' .and. vlistChar(2) == 'bar' .and. vlistChar(3) == 'baz', 'default: -vlChar')
  call cli%get_varying(switch='--', val=garbage, error=error)
  call assert_equal(error, 0_I4P, 'no trailing values: error')
  call assert(.not.allocated(garbage), 'no trailing values: nothing returned')

  ! passed values
  call parse('-s hello -i 3 -r 33.0 -b -bv .false. -il 10 -3 87 -vlI4P 5 6 -vlBool F T -vlChar x y', cli)
  call cli%get(switch='-i', val=ival, error=error) ; call assert_equal(ival, 3_I4P, 'passed: -i')
  call cli%get(switch='-r', val=rval, error=error) ; call assert_equal(rval, 33._R8P, 'passed: -r')
  call cli%get(switch='-b', val=bval, error=error) ; call assert_equal(bval, .true., 'passed: -b')
  call cli%get(switch='-bv', val=vbval, error=error) ; call assert_equal(vbval, .false., 'passed: -bv')
  call cli%get(switch='-il', val=ilist, error=error)
  call assert_equal(int(ilist, I4P), [10_I4P, -3_I4P, 87_I4P], 'passed: -il')
  call cli%get_varying(switch='-vlI4P', val=vlistI4P, error=error)
  call assert_equal(vlistI4P, [5_I4P, 6_I4P], 'passed: -vlI4P')
  call cli%get_varying(switch='-vlBool', val=vlistBool, error=error)
  call assert(size(vlistBool) == 2 .and. all(vlistBool .eqv. [.false., .true.]), 'passed: -vlBool')
  call cli%get_varying(switch='-vlChar', val=vlistChar, error=error)
  call assert(size(vlistChar) == 2 .and. vlistChar(1) == 'x' .and. vlistChar(2) == 'y', 'passed: -vlChar')

  ! positional before the named options
  call parse('33.0 -s hello', cli)
  call cli%get(position=1_I4P, val=prval, error=error) ; call assert_equal(prval, 33._R8P, 'positional value')

  ! nargs='*' without values keeps the default list (current behaviour); nargs='+' requires at least one value
  call parse('-s hello -vlI4P', cli)
  call cli%get_varying(switch='-vlI4P', val=vlistI4P, error=error)
  call assert_equal(vlistI4P, [1_I4P, 2_I4P, 3_I4P, 4_I4P], "nargs='*' without values: default")
  call parse('-s hello -vlI1P', cli, error)
  call assert_equal(error, ERROR_NARGS_INSUFFICIENT, "nargs='+' without values: error")

  ! trailing values after "--"
  call parse('-s hello -- a b', cli)
  call cli%get_varying(switch='--', val=garbage, error=error)
  call assert(size(garbage) == 2 .and. garbage(1) == 'a' .and. garbage(2) == 'b', 'trailing values after --')

  ! exclusion: -i excludes -ie
  call parse('-s hello -i 3 -ie 1', cli, error)
  call assert_equal(error, ERROR_M_EXCLUDE, '-i with -ie: error')

  ! choices: checked by get
  call parse('-s hello -i 2 -r 5.0', cli)
  call cli%get(switch='-i', val=ival, error=error)
  call assert_equal(error, ERROR_NOT_IN_CHOICES, '-i 2: not in choices')
  ! B22 (#125): after a failed get, the next scalar gets return the same error without reading their value; this
  ! assertion pins the current behaviour and flips when B22 is fixed
  rval = -99._R8P
  call cli%get(switch='-r', val=rval, error=error)
  call assert(error == ERROR_NOT_IN_CHOICES .and. rval == -99._R8P, 'get -r after a failed get (B22, current behaviour)')

  ! environment variable: read only when the bare switch is passed (current semantics, #11 feature 3 changes it)
  call reinvoke(1_I4P, exitstat, out, err, args='-s hello -e', env='FLAP_NUM_INT=7')
  call assert_equal(exitstat, 0_I4P, 'env with bare -e: exit status (stderr: '//err//')')
  call assert_contains(out, 'Environment integer input = +7', 'env with bare -e: value from FLAP_NUM_INT')
  call reinvoke(1_I4P, exitstat, out, err, args='-s hello', env='FLAP_NUM_INT=7')
  call assert_contains(out, 'Environment integer input = -1', 'env without -e: default, the variable is ignored')

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
endprogram flap_test_basic

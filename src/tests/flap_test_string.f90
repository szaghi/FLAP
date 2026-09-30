!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_string
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
!<
!< Run with arguments it is the example program above (which parses a fixed string, not the command line); run without
!< arguments it checks its own scenarios.

use, intrinsic :: iso_fortran_env, only : error_unit
use flap, only : command_line_interface, ERROR_VALUE_MISSING
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
  !< The example program: parse a fixed string instead of the command line and print every value.
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

  call define_cli(cli, error_unit)

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
  endsubroutine example

  subroutine define_cli(cli, lun)
  !< Define the example CLI.
  type(command_line_interface), intent(out) :: cli   !< Command Line Interface (CLI).
  integer(I4P),                 intent(in)  :: lun   !< Unit for usage and error messages.
  integer(I4P)                              :: error !< Error trapping flag.

  ! initialize Command Line Interface
  call cli%init(error_lun=lun, usage_lun=lun, progname    = 'test_sting',                                                 &
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
  endsubroutine define_cli

  subroutine self_test()
  !< Parsing a string: quoted values keep their blanks and inner quotes of the other kind.
  character(99) :: sval       !< String value.
  integer(I8P)  :: ilist(1:3) !< Integer list values.
  integer(I4P)  :: error      !< Error trapping flag.

  call capture_open(lun)
  call run("-s 'FAKE INVOCATION FROM STRING' --integer_list 10 -3 87", sval, error, ilist)
  call assert_equal(error, 0_I4P, 'example string: error')
  call assert_equal(sval, 'FAKE INVOCATION FROM STRING', 'example string: single-quoted value with blanks')
  call assert_equal(int(ilist, I4P), [10_I4P, -3_I4P, 87_I4P], 'example string: list')
  call run('-s "double quoted"', sval, error)
  call assert_equal(sval, 'double quoted', 'double-quoted value with blanks')
  call run("-s 'say ""hi""'", sval, error)
  call assert_equal(sval, 'say "hi"', 'double quotes inside single quotes')
  call run("-s 'a  b'", sval, error)
  call assert_equal(sval, 'a  b', 'inner blanks preserved')
  ! B03 (#125): single-pass quote scanner, shell-like
  call run('-s "it''s"', sval, error)
  call assert_equal(error, 0_I4P, 'single quote inside double quotes: error')
  call assert_equal(sval, "it's", 'single quote inside double quotes')
  call run('-s "it''s a ''test''"', sval, error)
  call assert_equal(sval, "it's a 'test'", 'single quotes inside double quotes, with blanks')
  call run('-s ab"c d"e', sval, error)
  call assert_equal(sval, 'abc de', 'quoted part joined to the adjacent text (no blank inserted)')
  ! blanks around every argument are stripped downstream, exactly as for the real command line
  call run("-s '  padded  '", sval, error)
  call assert_equal(sval, 'padded', 'blanks around a quoted value are stripped, as on the command line')
  call run('-s'//achar(9)//'tab', sval, error)
  call assert_equal(sval, 'tab', 'a tab separates arguments')
  call run('-s "unterminated', sval, error)
  call assert_equal(sval, 'unterminated', 'an unterminated quote extends to the end of the string')
  ! D17 reversed (#125 step 2.11): an explicitly empty argument is the empty string, like -s "" on the command line
  call run("-s ''", sval, error)
  call assert_equal(error, 0_I4P, '-s '''': an empty argument is a value')
  call assert_equal(sval, '', '-s '''': the empty string')
  call capture_close(lun)
  endsubroutine self_test

  subroutine run(args, sval, error, ilist)
  !< Define the example CLI (messages captured), parse a string and get the values.
  character(*),  intent(in)            :: args       !< Arguments string.
  character(99), intent(out)           :: sval       !< String value.
  integer(I4P),  intent(out)           :: error      !< Error trapping flag.
  integer(I8P),  intent(out), optional :: ilist(1:3) !< Integer list values.
  type(command_line_interface)         :: cli        !< Command Line Interface (CLI).

  call define_cli(cli, lun)
  sval = ''
  call cli%parse(args=args, error=error)
  if (error /= 0) return
  call cli%get(switch='-s', val=sval, error=error)
  if (present(ilist)) call cli%get(switch='-il', val=ilist, error=error)
  endsubroutine run
endprogram flap_test_string

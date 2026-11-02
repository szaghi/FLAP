!< Declared value types: validated by parse, whatever the source of the value (issue #128).
program flap_test_val_type
!< Declared value types: validated by parse, whatever the source of the value (issue #128).
!<
!< Every `get` call site has its own variable, in its own helper (the nvfortran bug of `class(*)` dummies, see CLAUDE.md).
use flap, only : command_line_interface, ERROR_CASTING_LOGICAL, ERROR_CASTING_NUMBER, ERROR_NOT_IN_CHOICES, ERROR_OUT_OF_RANGE, &
                 ERROR_TYPE_DEFINITION, ERROR_TYPE_MISMATCH, STATUS_ALTERNATE
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, delete_file, &
                            read_back, reinvoke, scratch_file, write_file
use penf, only : I1P, I2P, I4P, I8P, R4P, R8P

implicit none
character(*), parameter   :: PROG = 'flap_test_val_type' !< Program name.
integer(I4P)              :: lun      !< Capture unit.
character(:), allocatable :: out      !< Output of a child.
character(:), allocatable :: err      !< Errors of a child.
character(:), allocatable :: text     !< Captured messages.
integer(I4P)              :: exitstat !< Exit status of a child.

select case(child_case())
case(1)
  call child_env('--other 1')
  stop
case(2)
  call child_flag_env
  stop
case(3)
  call child_not_called
  stop
endselect

call capture_open(lun)

! T1.3 a bad value, command line
call parse_one('--n abc', 'I4P', ERROR_CASTING_NUMBER, 'T1.3 command line')
call assert_contains(read_back(lun), 'cannot convert "abc" of option "--n" to an integer!', 'T1.3 message')
call parse_one('--n /', 'I4P', ERROR_CASTING_NUMBER, 'T1.1 a slash at parse')
call parse_one('--n 2*5', 'I8P', ERROR_CASTING_NUMBER, 'T1.1 a repeat count at parse')
call parse_one('--n 1,5', 'R8P', ERROR_CASTING_NUMBER, 'T1.2 a decimal comma at parse')
call parse_one('--n 5', 'I4P', 0_I4P, 'a valid integer')
call parse_one('--n 2.5', 'R4P', 0_I4P, 'a valid real')
call parse_one('--n 2.5', 'R16P', 0_I4P, 'a valid quad')
call parse_one('--n 2.5', 'I4P', ERROR_CASTING_NUMBER, 'a real is not an integer')
call parse_one('--n T', 'logical', 0_I4P, 'a valid logical')
call parse_one('--n maybe', 'logical', ERROR_CASTING_LOGICAL, 'an invalid logical')
call parse_one('--n /', 'character', 0_I4P, 'any text is a character')
call parse_one('--n 5', 'i4p', 0_I4P, 'the name in any case')
! T1.4 the kind is part of the declaration
call parse_one('--n 200', 'I1P', ERROR_CASTING_NUMBER, 'T1.4 200 does not fit I1P')
call parse_one('--n 100', 'I1P', 0_I4P, 'T1.4 100 fits I1P')
call parse_one('--n -128', 'I1P', 0_I4P, 'T1.4 the lowest I1P')
call parse_one('--n -129', 'I1P', ERROR_CASTING_NUMBER, 'T1.4 below I1P')
call parse_one('--n 40000', 'I2P', ERROR_CASTING_NUMBER, 'T1.4 does not fit I2P')
call parse_one('--n 99999999999', 'I4P', ERROR_CASTING_NUMBER, 'T1.4 does not fit I4P')
call parse_one('--n 99999999999', 'I8P', 0_I4P, 'T1.4 fits I8P')
text = read_back(lun)

! T1.3 environment and configuration file, in child processes or through the file
call reinvoke(1_I4P, exitstat, out, err, env='FLAP_TEST_VT_N=abc')
call assert_equal(exitstat, 0_I4P, 'T1.3 environment: child')
call assert_contains(out, 'error=50', 'T1.3 environment: error from parse')
call check_config

! T1.5 lists
call parse_list('--l 1 x 3', 'nargs', ERROR_CASTING_NUMBER, 'T1.5 nargs, one bad item')
call parse_list('--l 1 2 3', 'nargs', 0_I4P, 'T1.5 nargs, valid')
call parse_list('--l 1 --l x', 'append', ERROR_CASTING_NUMBER, 'T1.5 append, one bad item')
call parse_list('--l 1 --l 2', 'append', 0_I4P, 'T1.5 append, valid')
call parse_list('--other', 'star', 0_I4P, 'T1.5 star list absent')
call parse_list('--l', 'star', 0_I4P, 'T1.5 star list empty')
text = read_back(lun)

! T1.6, T1.7 definitions
call define_one(def='x', val_type='I4P', expected=ERROR_TYPE_DEFINITION, message='T1.6 bad default')
call define_one(def='', val_type='I4P', expected=0_I4P, message='T1.6 a blank default is no value')
call define_one(def='1 x', val_type='I4P', nargs='+', expected=ERROR_TYPE_DEFINITION, message='T1.6 bad list default')
call define_one(def='1 2', val_type='I4P', nargs='+', expected=0_I4P, message='T1.6 valid list default')
call define_one(def='5', val_type='I4P', min='10', expected=ERROR_TYPE_DEFINITION, message='T1.6 default out of range')
call define_one(def='x', val_type='I4P', group='cmd', expected=ERROR_TYPE_DEFINITION, message='T1.6 command not called')
call assert_contains(read_back(lun), 'the default "x" does not fit it', 'T1.6 message')
call define_one(def='1', val_type='complex', expected=ERROR_TYPE_DEFINITION, message='T1.7 unknown name')
call define_one(def='a=1', val_type='character', map=.true., nargs='+', expected=ERROR_TYPE_DEFINITION, message='T1.7 map')
call define_one(def='.false.', val_type='logical', act='alternate', expected=ERROR_TYPE_DEFINITION, message='T1.7 alternate')
call define_one(def='.false.', val_type='I4P', act='store_true', expected=ERROR_TYPE_DEFINITION, message='T1.7 flag not logical')
call define_one(def='.false.', val_type='logical', act='store_true', expected=0_I4P, message='T1.7 flag logical')
call define_one(def='0', val_type='R8P', act='count', expected=ERROR_TYPE_DEFINITION, message='T1.7 count not integer')
call define_one(def='0', val_type='I4P', act='count', expected=0_I4P, message='T1.7 count integer')
call define_one(def='f', val_type='character', act='config', expected=ERROR_TYPE_DEFINITION, message='T1.7 config')
call define_one(def='1', val_type='I4P', must_exist=.true., expected=ERROR_TYPE_DEFINITION, message='T1.7 path not character')
call define_one(def='a', val_type='character', min='0', expected=ERROR_TYPE_DEFINITION, message='T1.7 range on character')
call define_one(def='T', val_type='logical', choices='T,F', expected=ERROR_TYPE_DEFINITION, message='T1.7 choices on logical')
call define_one(def='1', val_type='I4P', choices='1,x', expected=ERROR_TYPE_DEFINITION, message='T1.7 a choice not of the type')
text = read_back(lun)

! T1.8, T1.9 get against the declaration
call get_i8('--n 5', 0_I4P, 'T1.8 I4P into I8P')
call get_character('--n 5', 0_I4P, 'T1.8 I4P into character')
call get_i2('--n 5', ERROR_TYPE_MISMATCH, 'T1.9 I4P into I2P, the value fits')
call assert_contains(read_back(lun), 'option "--n" is declared I4P: it cannot be read into an integer(I2P)!', 'T1.9 message')
call get_r8('--n 5', ERROR_TYPE_MISMATCH, 'T1.9 I4P into R8P')
call get_after_mismatch
call get_varying_i2
call get_fixed_list
text = read_back(lun)

! T1.10 choices and range at parse
call parse_constrained('--n 7', ERROR_NOT_IN_CHOICES, 'T1.10 not in choices')
call parse_constrained('--n 2', 0_I4P, 'T1.10 in choices')
call parse_constrained('--r 2', ERROR_OUT_OF_RANGE, 'T1.10 out of range')
call parse_constrained('--r 0.5', 0_I4P, 'T1.10 in range')
call parse_constrained('--w z', ERROR_NOT_IN_CHOICES, 'T1.10 character not in choices')
call parse_constrained('--w a', 0_I4P, 'T1.10 character in choices')
call parse_constrained('--c 50', 0_I4P, 'T1.10 clamp is no error')
text = read_back(lun)

! T1.11 an alternate action bypasses the validation
call check_alternate

! T1.12 a command not called: its environment value is not checked; called, it is
call reinvoke(3_I4P, exitstat, out, err, env='FLAP_TEST_VT_C=abc')
call assert_equal(exitstat, 0_I4P, 'T1.12 child')
call assert_contains(out, 'not called error=0', 'T1.12 not called')
call assert_contains(out, 'called error=50', 'T1.12 called')

! a flag from the environment
call reinvoke(2_I4P, exitstat, out, err, env='FLAP_TEST_VT_F=junk')
call assert_contains(out, 'error=10', 'a typed flag, junk in the environment')

! T1.13 copy_options keeps the type
call check_copy

! T1.14 an untyped option behaves as before: the failure is in get
call check_untyped
call capture_close(lun)

contains
  subroutine parse_one(args, val_type, expected, message)
  !< Parse a typed option.
  character(*), intent(in)     :: args     !< Command line.
  character(*), intent(in)     :: val_type !< Declared type.
  integer(I4P), intent(in)     :: expected !< Expected error of parse.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  integer(I4P)                 :: error    !< Error trapping flag.

  call cli%init(progname=PROG, error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--n', help='n', required=.false., def='', val_type=val_type, error=error)
  call assert_equal(error, 0_I4P, message//': add')
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected, message)
  endsubroutine parse_one

  subroutine parse_list(args, kind_of_list, expected, message)
  !< Parse a typed list.
  character(*), intent(in)     :: args         !< Command line.
  character(*), intent(in)     :: kind_of_list !< nargs, append or star.
  integer(I4P), intent(in)     :: expected     !< Expected error of parse.
  character(*), intent(in)     :: message      !< Description of the check.
  type(command_line_interface) :: cli          !< Command Line Interface (CLI).
  integer(I4P)                 :: error        !< Error trapping flag.

  call cli%init(progname=PROG, error_lun=lun, usage_lun=lun, error_hint=.false.)
  select case(kind_of_list)
  case('nargs')
    call cli%add(switch='--l', help='l', required=.false., def='1', nargs='+', val_type='I4P', error=error)
  case('append')
    call cli%add(switch='--l', help='l', required=.false., def='', act='append', val_type='I4P', error=error)
  case('star')
    call cli%add(switch='--l', help='l', required=.false., def='', nargs='*', val_type='I4P', error=error)
  endselect
  call assert_equal(error, 0_I4P, message//': add')
  call cli%add(switch='--other', help='o', required=.false., act='store_true', def='.false.', error=error)
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected, message)
  endsubroutine parse_list

  subroutine define_one(def, val_type, expected, message, nargs, act, min, must_exist, choices, map, group)
  !< Define a typed option.
  character(*), intent(in)           :: def        !< Default.
  character(*), intent(in)           :: val_type   !< Declared type.
  integer(I4P), intent(in)           :: expected   !< Expected error of add.
  character(*), intent(in)           :: message    !< Description of the check.
  character(*), intent(in), optional :: nargs      !< Number of values.
  character(*), intent(in), optional :: act        !< Action.
  character(*), intent(in), optional :: min        !< Minimum.
  logical,      intent(in), optional :: must_exist !< A path.
  character(*), intent(in), optional :: choices    !< Choices.
  logical,      intent(in), optional :: map        !< A map.
  character(*), intent(in), optional :: group      !< Command.
  type(command_line_interface)       :: cli        !< Command Line Interface (CLI).
  integer(I4P)                       :: error      !< Error trapping flag.

  call cli%init(progname=PROG, error_lun=lun, usage_lun=lun, error_hint=.false.)
  if (present(group)) then
    call cli%add_group(group=group, help='g')
    call cli%add(group=group, switch='--n', help='n', required=.false., def=def, val_type=val_type, error=error)
  else
    call cli%add(switch='--n', help='n', required=.false., def=def, nargs=nargs, act=act, min=min, must_exist=must_exist, &
                 choices=choices, map=map, val_type=val_type, error=error)
  endif
  call assert_equal(error, expected, message)
  endsubroutine define_one

  subroutine typed(cli, args)
  !< A CLI with one I4P option, parsed.
  type(command_line_interface), intent(inout) :: cli   !< Command Line Interface (CLI).
  character(*),                 intent(in)    :: args  !< Command line.
  integer(I4P)                                :: error !< Error trapping flag.

  call cli%init(progname=PROG, error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--n', help='n', required=.false., def='1', val_type='I4P', error=error)
  call assert_equal(error, 0_I4P, 'typed: add')
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, 'typed: parse')
  endsubroutine typed

  subroutine get_i8(args, expected, message)
  !< Get into an I8P.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  integer(I8P)                 :: v        !< Value.
  integer(I4P)                 :: error    !< Error trapping flag.

  call typed(cli, args)
  call cli%get(switch='--n', val=v, error=error)
  call assert_equal(error, expected, message)
  call assert(v == 5_I8P, message//': value')
  endsubroutine get_i8

  subroutine get_character(args, expected, message)
  !< Get into a character.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  character(8)                 :: v        !< Value.
  integer(I4P)                 :: error    !< Error trapping flag.

  call typed(cli, args)
  call cli%get(switch='--n', val=v, error=error)
  call assert_equal(error, expected, message)
  call assert_equal(trim(v), '5', message//': value')
  endsubroutine get_character

  subroutine get_i2(args, expected, message)
  !< Get into an I2P.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  integer(I2P)                 :: v        !< Value.
  integer(I4P)                 :: error    !< Error trapping flag.

  v = -1_I2P
  call typed(cli, args)
  call cli%get(switch='--n', val=v, error=error)
  call assert_equal(error, expected, message)
  call assert(v == -1_I2P, message//': not assigned')
  endsubroutine get_i2

  subroutine get_r8(args, expected, message)
  !< Get into an R8P.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  real(R8P)                    :: v        !< Value.
  integer(I4P)                 :: error    !< Error trapping flag.

  call typed(cli, args)
  call cli%get(switch='--n', val=v, error=error)
  call assert_equal(error, expected, message)
  endsubroutine get_r8

  subroutine get_after_mismatch
  !< A get that may read the type works after one that may not: the error does not stay behind.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I2P)                 :: bad   !< Too narrow.
  character(8)                 :: good  !< Always allowed.
  integer(I4P)                 :: error !< Error trapping flag.

  call typed(cli, '--n 5')
  call cli%get(switch='--n', val=bad, error=error)
  call assert_equal(error, ERROR_TYPE_MISMATCH, 'mismatch first')
  call cli%get(switch='--n', val=good, error=error)
  call assert_equal(error, 0_I4P, 'then a valid get')
  endsubroutine get_after_mismatch

  subroutine get_varying_i2
  !< A varying get is checked too.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I2P), allocatable    :: v(:)  !< Values.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname=PROG, error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--l', help='l', required=.false., def='1 2', nargs='+', val_type='I4P', error=error)
  call cli%parse(args='--l 3 4', error=error)
  call assert_equal(error, 0_I4P, 'varying: parse')
  call cli%get_varying(switch='--l', val=v, error=error)
  call assert_equal(error, ERROR_TYPE_MISMATCH, 'varying: I4P into I2P')
  endsubroutine get_varying_i2

  subroutine get_fixed_list
  !< A fixed-size get is checked too.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  real(R4P)                    :: v(2)  !< Values.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname=PROG, error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--l', help='l', required=.false., def='1 2', nargs='2', val_type='R8P', error=error)
  call cli%parse(args='--l 3 4', error=error)
  call assert_equal(error, 0_I4P, 'fixed: parse')
  call cli%get(switch='--l', val=v, error=error)
  call assert_equal(error, ERROR_TYPE_MISMATCH, 'fixed: R8P into R4P')
  endsubroutine get_fixed_list

  subroutine parse_constrained(args, expected, message)
  !< Choices and ranges of typed options, checked by parse.
  character(*), intent(in)     :: args     !< Command line.
  integer(I4P), intent(in)     :: expected !< Expected error of parse.
  character(*), intent(in)     :: message  !< Description of the check.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  integer(I4P)                 :: error    !< Error trapping flag.

  call cli%init(progname=PROG, error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--n', help='n', required=.false., def='1', choices='1,2', val_type='I4P', error=error)
  call assert_equal(error, 0_I4P, message//': --n')
  call cli%add(switch='--r', help='r', required=.false., def='0.5', min='0', max='1', val_type='R8P', error=error)
  call assert_equal(error, 0_I4P, message//': --r')
  call cli%add(switch='--w', help='w', required=.false., def='a', choices='a,b', val_type='character', error=error)
  call assert_equal(error, 0_I4P, message//': --w')
  call cli%add(switch='--c', help='c', required=.false., def='1', min='0', max='9', clamp=.true., val_type='I4P', error=error)
  call assert_equal(error, 0_I4P, message//': --c')
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected, message)
  endsubroutine parse_constrained

  subroutine check_config
  !< A bad value from the configuration file.
  type(command_line_interface)  :: cli   !< Command Line Interface (CLI).
  character(len=:), allocatable :: file  !< Configuration file.
  integer(I4P)                  :: error !< Error trapping flag.

  file = scratch_file('flap_test_val_type.ini')
  call write_file(file, 'n = abc')
  call cli%init(progname=PROG, error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%set_config(file)
  call cli%add(switch='--n', help='n', required=.false., def='1', val_type='I4P', error=error)
  call cli%parse(args='', error=error)
  call assert_equal(error, ERROR_CASTING_NUMBER, 'T1.3 configuration file')
  call delete_file(file)
  text = read_back(lun)
  endsubroutine check_config

  subroutine check_alternate
  !< An alternate action passed with a bad typed value.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname=PROG, error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--list', help='l', required=.false., act='alternate', error=error)
  call cli%add(switch='--n', help='n', required=.false., def='1', val_type='I4P', error=error)
  call cli%parse(args='--list --n abc', error=error)
  call assert_equal(error, STATUS_ALTERNATE, 'T1.11 alternate')
  endsubroutine check_alternate

  subroutine check_copy
  !< The type of a copied option is kept and enforced.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname=PROG, error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add_group(group='a', help='a')
  call cli%add_group(group='b', help='b')
  call cli%add(group='a', switch='--n', help='n', required=.false., def='1', val_type='I4P', error=error)
  call cli%copy_options(from_group='a', to_group='b', error=error)
  call assert_equal(error, 0_I4P, 'T1.13 copy')
  call cli%parse(args='b --n abc', error=error)
  call assert_equal(error, ERROR_CASTING_NUMBER, 'T1.13 enforced')
  text = read_back(lun)
  endsubroutine check_copy

  subroutine check_untyped
  !< An untyped option: parse accepts, get fails.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: v     !< Value.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname=PROG, error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--n', help='n', required=.false., def='1', error=error)
  call cli%parse(args='--n abc', error=error)
  call assert_equal(error, 0_I4P, 'T1.14 parse accepts')
  call cli%get(switch='--n', val=v, error=error)
  call assert_equal(error, ERROR_CASTING_NUMBER, 'T1.14 get fails')
  text = read_back(lun)
  endsubroutine check_untyped

  subroutine child_env(args)
  !< A typed option from the environment.
  character(*), intent(in)     :: args  !< Command line.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname=PROG)
  call cli%add(switch='--n', help='n', required=.false., def='1', envvar='FLAP_TEST_VT_N', val_type='I4P', error=error)
  call cli%add(switch='--other', help='o', required=.false., def='1', error=error)
  call cli%parse(args=args, error=error)
  print '(A,I0)', 'error=', error
  endsubroutine child_env

  subroutine child_flag_env
  !< A typed flag from the environment.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname=PROG)
  call cli%add(switch='--f', help='f', required=.false., act='store_true', def='.false.', envvar='FLAP_TEST_VT_F', &
               val_type='logical', error=error)
  call cli%parse(args='', error=error)
  print '(A,I0)', 'error=', error
  endsubroutine child_flag_env

  subroutine child_not_called
  !< A bad environment value of a typed option of a command, called or not.
  type(command_line_interface) :: cli1  !< Command Line Interface (CLI).
  type(command_line_interface) :: cli2  !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli1%init(progname=PROG)
  call cli1%add_group(group='cmd', help='c')
  call cli1%add(group='cmd', switch='--c', help='c', required=.false., def='1', envvar='FLAP_TEST_VT_C', val_type='I4P', &
                error=error)
  call cli1%parse(args='', error=error)
  print '(A,I0)', 'not called error=', error
  call cli2%init(progname=PROG)
  call cli2%add_group(group='cmd', help='c')
  call cli2%add(group='cmd', switch='--c', help='c', required=.false., def='1', envvar='FLAP_TEST_VT_C', val_type='I4P', &
                error=error)
  call cli2%parse(args='cmd', error=error)
  print '(A,I0)', 'called error=', error
  endsubroutine child_not_called
endprogram flap_test_val_type

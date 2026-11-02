!< Validate-only mode: --check (issue #128).
program flap_test_check
!< Validate-only mode: --check (issue #128).
!<
!< The children stop by themselves in standalone mode: reaching the body of the program prints BODY.
use flap, only : command_line_interface, ERROR_CASTING_NUMBER, ERROR_UNKNOWN, STATUS_CHECK
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, delete_file, &
                            read_back, reinvoke, scratch_file, write_file
use penf, only : I4P

implicit none
integer(I4P)              :: lun      !< Capture unit.
character(:), allocatable :: out      !< Output of a child.
character(:), allocatable :: err      !< Errors of a child.
character(:), allocatable :: file     !< A file.
integer(I4P)              :: exitstat !< Exit status of a child.

select case(child_case())
case(1)
  call child(.true.)
  stop
case(2)
  call child(.false.)
  stop
case(3)
  call child_json
  stop
case(4)
  call child_ignore
  stop
case(5)
  call child_owned
  stop
case(6)
  call child_review
  stop
endselect

! T4.1 valid: exit 0, the body of the program not run
call run('--check --steps 5 --a')
call assert_equal(exitstat, 0_I4P, 'T4.1 exit status')
call assert_contains(out, 'prog: command line valid', 'T4.1 verdict')
call assert(index(out, 'BODY') == 0, 'T4.1 no body')
! without --check the program runs
call run('--steps 5 --a')
call assert_contains(out, 'BODY', 'no --check, the body')
! T4.2 a typed value
call run('--check --steps abc --a')
call assert_equal(exitstat, 2_I4P, 'T4.2 exit status')
call assert_contains(err, 'cannot convert "abc"', 'T4.2 message')
call assert(index(out, 'BODY') == 0, 'T4.2 no body')
call assert(index(out, 'valid') == 0, 'T4.2 no verdict')
! T4.3 an error before --check is reached, and after it
call run('--bogus --check --steps 5 --a')
call assert_equal(exitstat, 2_I4P, 'T4.3 before')
call assert(index(out, 'BODY') == 0, 'T4.3 no body')
call run('--check --bogus --steps 5 --a')
call assert_equal(exitstat, 2_I4P, 'T4.3 after')
! T4.4 the other stages
call run('--check --a')
call assert_equal(exitstat, 2_I4P, 'T4.4 required missing')
call run('--check --steps 5')
call assert_equal(exitstat, 2_I4P, 'T4.4 required set')
call run('--check --steps 5 --a --b')
call assert_equal(exitstat, 2_I4P, 'T4.4 set violated')
call run('--check --steps 5 --a --path /nonexistent-dir/x')
call assert_equal(exitstat, 3_I4P, 'T4.4 path missing')
call run('--check --steps 5 --a --conf /nonexistent-dir/x')
call assert_equal(exitstat, 3_I4P, 'T4.4 configuration file missing')
file = scratch_file('check.ini')
call write_file(file, 'steps = abc')
call run('--check --a --conf "'//file//'"')
call assert_equal(exitstat, 2_I4P, 'T4.4 a bad value in the configuration file')
call delete_file(file)
! T4.5 what has not been validated is named; of the commands called only
call run('--check --steps 5 --a --label x')
call assert_contains(out, 'not type-checked:', 'T4.5 listed')
call assert_contains(out, '--label', 'T4.5 untyped')
call assert(index(out, '--steps') == 0, 'T4.5 typed left out')
call assert(index(out, '--a') == 0, 'T4.5 flag left out')
call assert(index(out, '--secret') == 0, 'T4.5 hidden left out')
call assert(index(out, 'run --note') == 0, 'T4.5 a command not called')
call run('--check --steps 5 --a run')
call assert_contains(out, 'run --note', 'T4.5 a command called')
! T4.6 not standalone
call check_not_standalone
! T4.7 JSON
call reinvoke(3_I4P, exitstat, out, err, args='--check --steps 5')
call assert_equal(exitstat, 0_I4P, 'T4.7 exit status')
call assert_contains(out, '{"schema_version":1,"level":"result","valid":true,"unchecked":["--label"]}', 'T4.7 valid')
call reinvoke(3_I4P, exitstat, out, err, args='--check --steps abc')
call assert_equal(exitstat, 2_I4P, 'T4.7 exit status, invalid')
call assert_contains(err, '"level":"error","code":50', 'T4.7 the error line')
call assert_contains(out, '{"schema_version":1,"level":"result","valid":false}', 'T4.7 invalid')
! T4.8 after --: not the builtin
call run('--steps 5 --a -- --check')
call assert_contains(out, 'BODY', 'T4.8 a trailing argument')
! T4.9 not enabled: unknown
call reinvoke(2_I4P, exitstat, out, err, args='--check --steps 5 --a')
call assert_contains(err, '"--check" is unknown', 'T4.9 unknown')
! T4.10 the option of the program
call reinvoke(5_I4P, exitstat, out, err, args='--check 7')
call assert_contains(out, 'mine=7', 'T4.10 its value')
! help comes first
call run('--check --help')
call assert_equal(exitstat, 0_I4P, 'help: exit status')
call assert_contains(err//out, 'usage:', 'help comes first')
call assert(index(out, 'command line valid') == 0, 'help: no verdict')
! an alternate action is valid, and the program does not run
call run('--check --list')
call assert_equal(exitstat, 0_I4P, 'alternate: exit status')
call assert(index(out, 'BODY') == 0, 'alternate: no body')
! an ignored unknown argument is reported
call reinvoke(4_I4P, exitstat, out, err, args='--check --bogus')
call assert_equal(exitstat, 0_I4P, 'ignored: exit status')
call assert_contains(out, 'ignored:', 'ignored: reported')
call assert_contains(out, '--bogus', 'ignored: named')
! the tokens of a command are its own (the builtin is top level only)
call reinvoke(6_I4P, exitstat, out, err, args='run --check')
call assert_contains(out, 'BODY', 'the --check of a command')
call reinvoke(6_I4P, exitstat, out, err, args='--check run --check')
call assert(index(out, 'BODY') == 0, 'the builtin, then the --check of a command')
! what can fail only at get is named: an untyped count with a range, a flag from the environment
call reinvoke(6_I4P, exitstat, out, err, args='--check -vvv')
call assert_contains(out, 'not type-checked:', 'a count: listed')
call assert_contains(out, '-v', 'a count: named')
call reinvoke(6_I4P, exitstat, out, err, args='--check', env='FLAP_TEST_CK=abc')
call assert_contains(out, '--f', 'a flag from the environment: named')
call reinvoke(6_I4P, exitstat, out, err, args='--check', env='-u FLAP_TEST_CK')
call assert(index(out, '--f') == 0, 'a flag not from the environment: not named')
! an alternate action skips the validation, and says so
call run('--check --list --steps abc')
call assert_equal(exitstat, 0_I4P, 'alternate, a bad value: exit status')
call assert_contains(out, 'an alternate action skips the validation', 'alternate: says so')
call assert_contains(out, '--steps', 'alternate: nothing has been checked')

contains
  subroutine run(args)
  !< Run the reference program with --check enabled.
  character(*), intent(in) :: args !< Command line.

  call reinvoke(1_I4P, exitstat, out, err, args=args)
  endsubroutine run

  subroutine define(cli, check_option, standalone, lun)
  !< The reference program.
  type(command_line_interface), intent(out)          :: cli          !< Command Line Interface (CLI).
  logical,                      intent(in)           :: check_option !< --check enabled.
  logical,                      intent(in), optional :: standalone   !< Standalone mode.
  integer(I4P),                 intent(in), optional :: lun          !< Unit of every output.
  integer(I4P)                                       :: error        !< Error trapping flag.

  call cli%init(progname='prog', check_option=check_option, standalone=standalone, error_lun=lun, usage_lun=lun, version_lun=lun)
  call cli%add(switch='--steps', help='s', required=.true., val_type='I4P', error=error)
  call cli%add(switch='--label', help='l', required=.false., def='x', error=error)
  call cli%add(switch='--a', help='a', required=.false., act='store_true', def='.false.', error=error)
  call cli%add(switch='--b', help='b', required=.false., act='store_true', def='.false.', error=error)
  call cli%add(switch='--list', help='list', required=.false., act='alternate', error=error)
  call cli%add(switch='--secret', help='s', required=.false., def='1', hidden=.true., error=error)
  call cli%add(switch='--path', help='p', required=.false., def='', must_exist=.true., allow_dash=.true., error=error)
  call cli%add(switch='--conf', help='c', required=.false., def='', act='config', error=error)
  call cli%set_mutually_exclusive_switches(switches='--a,--b', required=.true., error=error)
  call cli%add_group(group='run', help='r')
  call cli%add(group='run', switch='--note', help='n', required=.false., def='x', error=error)
  call assert_equal(error, 0_I4P, 'definitions')
  endsubroutine define

  subroutine child(check_option)
  !< The reference program.
  logical, intent(in)          :: check_option !< --check enabled.
  type(command_line_interface) :: cli          !< Command Line Interface (CLI).
  integer(I4P)                 :: error        !< Error trapping flag.

  call define(cli, check_option)
  call cli%parse(error=error)
  print '(A)', 'BODY'
  endsubroutine child

  subroutine child_json
  !< JSON format.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', check_option=.true., error_format='json')
  call cli%add(switch='--steps', help='s', required=.true., val_type='I4P', error=error)
  call cli%add(switch='--label', help='l', required=.false., def='x', error=error)
  call cli%parse(error=error)
  endsubroutine child_json

  subroutine child_ignore
  !< An ignored unknown argument.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', check_option=.true., ignore_unknown_clas=.true.)
  call cli%parse(error=error)
  endsubroutine child_ignore

  subroutine child_review
  !< A command with its own --check; what parse cannot validate without a declared type.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', check_option=.true.)
  call cli%add(switch='-v', help='v', required=.false., act='count', max='2', error=error)
  call cli%add(switch='--f', help='f', required=.false., act='store_true', def='.false.', envvar='FLAP_TEST_CK', error=error)
  call cli%add_group(group='run', help='r')
  call cli%add(group='run', switch='--check', help='its own', required=.false., act='store_true', def='.false.', error=error)
  call cli%parse(error=error)
  print '(A)', 'BODY'
  endsubroutine child_review

  subroutine child_owned
  !< A program owning --check, the builtin not enabled.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: mine  !< Its value.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog')
  call cli%add(switch='--check', help='mine', required=.false., def='1', error=error)
  call cli%parse(error=error)
  call cli%get(switch='--check', val=mine, error=error)
  print '(A,I0)', 'mine=', mine
  endsubroutine child_owned

  subroutine check_not_standalone
  !< T4.6 parse returns the status or the error.
  type(command_line_interface) :: cli1  !< Command Line Interface (CLI).
  type(command_line_interface) :: cli2  !< Command Line Interface (CLI).
  type(command_line_interface) :: cli3  !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.
  character(:), allocatable    :: text  !< Captured text.

  call capture_open(lun)
  call define(cli1, .true., .false., lun)
  call cli1%parse(args='--check --steps 5 --a', error=error)
  call assert_equal(error, STATUS_CHECK, 'T4.6 valid')
  text = read_back(lun)
  call assert_contains(text, 'command line valid', 'T4.6 verdict')
  call define(cli2, .true., .false., lun)
  call cli2%parse(args='--check --steps abc --a', error=error)
  call assert_equal(error, ERROR_CASTING_NUMBER, 'T4.6 invalid')
  text = read_back(lun)
  call define(cli3, .true., .false., lun)
  call cli3%parse(args='--bogus --check', error=error)
  call assert_equal(error, ERROR_UNKNOWN, 'T4.6 unknown first')
  call capture_close(lun)
  endsubroutine check_not_standalone
endprogram flap_test_check

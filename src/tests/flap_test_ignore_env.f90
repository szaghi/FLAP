!< init(ignore_env=.true.) turns every environment lookup off (issue #125, step 2.2; #77 3.2, T3.1-T3.4).
program flap_test_ignore_env
!< init(ignore_env=.true.) turns every environment lookup off (issue #125, step 2.2; #77 3.2, T3.1-T3.4).
!<
!< Without arguments the program checks its scenarios, re-invoking itself with the variable FLAP_TEST_IGNORE_ENV set; the
!< children parse a bare `--e` (case 1: environment read, case 2: ignore_env, case 3: ignore_env and --e of a command added
!< after another add_group) and print `error=<code> [<value>]`. The static check of the single lookup is in flap_test_envvar.
use flap, only : command_line_interface, ERROR_VALUE_MISSING
use flap_test_utils, only : assert_contains, assert_equal, capture_close, capture_open, child_case, reinvoke
use penf, only : I4P, str

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI).
character(:), allocatable    :: out      !< Standard output of a child.
character(:), allocatable    :: err      !< Standard error of a child.
character(20)                :: val      !< Value of --e.
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: exitstat !< Exit status.
integer(I4P)                 :: error    !< Error trapping flag.

select case(child_case())
case(1)
  call child(ignore_env=.false., command=.false.)
  stop
case(2)
  call child(ignore_env=.true., command=.false.)
  stop
case(3)
  call child(ignore_env=.true., command=.true.)
  stop
endselect

! T3.2: without ignore_env the bare switch reads the variable (unchanged)
call reinvoke(1_I4P, exitstat, out, err, env='FLAP_TEST_IGNORE_ENV=from_env')
call assert_equal(exitstat, 0_I4P, 'environment read: exit status (stderr: '//err//')')
call assert_contains(out, 'error=0 [from_env]', 'environment read: the value of the variable')
! T3.1: with ignore_env the bare switch has no value
call reinvoke(2_I4P, exitstat, out, err, env='FLAP_TEST_IGNORE_ENV=from_env')
call assert_contains(out, 'error='//trim(str(ERROR_VALUE_MISSING, .true.))//' ', 'ignore_env: value missing')
! T3.4: ignore_env applies to the commands, also those added after other add_group
call reinvoke(3_I4P, exitstat, out, err, env='FLAP_TEST_IGNORE_ENV=from_env')
call assert_contains(out, 'error='//trim(str(ERROR_VALUE_MISSING, .true.))//' ', 'ignore_env, command: value missing')

call capture_open(lun)
! a value passed on the command line is not affected
call define(ignore_env=.true.)
call cli%parse(args='--e given', error=error)
call assert_equal(error, 0_I4P, 'ignore_env, --e given: parse')
call cli%get(switch='--e', val=val, error=error)
call assert_equal(trim(val), 'given', 'ignore_env, --e given: value')
! T3.3: the help still shows the variable
call define(ignore_env=.true.)
call assert_contains(cli%usage(g=0), 'environment variable name "FLAP_TEST_IGNORE_ENV"', &
                     'ignore_env: the help shows the variable')
call capture_close(lun)

contains
  subroutine define(ignore_env)
  !< Define a CLI with an option reading FLAP_TEST_IGNORE_ENV.
  logical, intent(in) :: ignore_env !< Ignore the environment.

  call cli%init(progname='flap_test_ignore_env', ignore_env=ignore_env, error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--e', help='a value', required=.false., act='store', def='d', envvar='FLAP_TEST_IGNORE_ENV', &
               error=error)
  call assert_equal(error, 0_I4P, 'add --e')
  endsubroutine define

  subroutine child(ignore_env, command)
  !< Parse a bare --e (of the command run if requested) and print the error and the value.
  logical, intent(in) :: ignore_env !< Ignore the environment.
  logical, intent(in) :: command    !< --e belongs to the command run, added after another add_group.
  character(:), allocatable :: group !< Group of --e.
  character(20)             :: v     !< Value of --e: a local, not the host val.

  call capture_open(lun)
  call cli%init(progname='flap_test_ignore_env', ignore_env=ignore_env, error_lun=lun, usage_lun=lun, error_hint=.false.)
  group = ''
  if (command) then
    group = 'run'
    call cli%add_group(group='first', description='a command')
    call cli%add_group(group=group, description='run')
  endif
  call cli%add(group=group, switch='--e', help='a value', required=.false., act='store', def='d', &
               envvar='FLAP_TEST_IGNORE_ENV', error=error)
  call cli%parse(args=trim(group//' --e'), error=error)
  ! one get call site per variable: nvfortran 26.5 miscompiles several (B33)
  v = ''
  if (error == 0) call cli%get(group=group, switch='--e', val=v, error=error)
  call capture_close(lun)
  print '(A)', 'error='//trim(str(error, .true.))//' ['//trim(v)//']'
  endsubroutine child
endprogram flap_test_ignore_env

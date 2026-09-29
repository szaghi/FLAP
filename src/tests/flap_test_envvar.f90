!< Environment variables are read through one helper, read_env (issue #125, step 0.D.2; #77 T3.2, T3.6).
program flap_test_envvar
!< Environment variables are read through one helper, read_env (issue #125, step 0.D.2; #77 T3.2, T3.6).
!<
!< Without arguments the program checks its scenarios, re-invoking itself with the environment of each one; the child
!< (scenario 1) parses `--e` and prints `error=<code> len=<length> [<value>]`. The static check lists the library sources
!< (`FLAP_TEST_LIB_DIR`, default `src/lib`) calling the intrinsic: only flap_utils_m, where read_env is.
use flap, only : command_line_interface, ERROR_VALUE_MISSING
use flap_test_utils, only : assert_contains, assert_equal, child_case, reinvoke, run_command
use penf, only : I4P, str

implicit none
character(:), allocatable :: out      !< Standard output of a child.
character(:), allocatable :: err      !< Standard error of a child.
character(:), allocatable :: lib_dir  !< Directory of the library sources.
character(512)            :: buffer   !< Environment buffer.
integer(I4P)              :: exitstat !< Exit status.
integer(I4P)              :: status   !< Retrieval status.

if (child_case() == 1) then
  call child
  stop
endif

call reinvoke(1_I4P, exitstat, out, err, env='FLAP_TEST_ENV=hello')
call assert_equal(exitstat, 0_I4P, 'env set: exit status (stderr: '//err//')')
call assert_contains(out, 'error=0 len=5 [hello]', 'env set: value of the variable')

call reinvoke(1_I4P, exitstat, out, err, env="'FLAP_TEST_ENV=  two words  '")
call assert_contains(out, 'error=0 len=9 [two words]', 'env with blanks around: blanks stripped')

call reinvoke(1_I4P, exitstat, out, err, env='FLAP_TEST_ENV='//repeat('x', 600))
call assert_contains(out, 'error=0 len=600 ', 'env longer than 500 characters: not truncated')

call reinvoke(1_I4P, exitstat, out, err, env='FLAP_TEST_ENV=')
call assert_contains(out, 'error=0 len=0 []', 'env set and empty: empty value')

call reinvoke(1_I4P, exitstat, out, err, env='-u FLAP_TEST_ENV')
call assert_contains(out, 'error='//trim(str(ERROR_VALUE_MISSING, .true.))//' ', 'env unset: value missing')

lib_dir = 'src/lib'
call get_environment_variable('FLAP_TEST_LIB_DIR', value=buffer, status=status)
if (status == 0) lib_dir = trim(buffer)
call run_command("grep -li 'get_environment_variable *(' '"//lib_dir//"'/*.[fF]90 | sed 's|.*/||'", exitstat, out)
if (len(out) > 0) then
  if (out(len(out):) == new_line('a')) out = out(:len(out)-1)
endif
call assert_equal(trim(adjustl(out)), 'flap_utils_m.f90', 'the library reads the environment only in read_env (flap_utils_m)')

contains
  subroutine child
  !< Parse `--e` and print the error code, the length and the value.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  character(1000)              :: val   !< Value.
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='flap_test_envvar')
  call cli%add(switch='--e', help='from the environment', required=.false., act='store', def='none', &
               envvar='FLAP_TEST_ENV', error=error)
  call cli%parse(args='--e', error=error)
  val = ''
  if (error == 0) call cli%get(switch='--e', val=val, error=error)
  print '(A)', 'error='//trim(str(error, .true.))//' len='//trim(str(len_trim(val), .true.))//' ['//trim(val)//']'
  endsubroutine child
endprogram flap_test_envvar

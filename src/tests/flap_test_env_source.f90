!< The environment as a value source of an absent option (issue #125, step 2.3; #11 3.1-3.2, T3.1-T3.8, T3.11; D2).
program flap_test_env_source
!< The environment as a value source of an absent option (issue #125, step 2.3; #11 3.1-3.2, T3.1-T3.8, T3.11; D2).
!<
!< Precedence: command line > environment variable (set and non-empty) > default. A flag (store_true/store_false) reads
!< its value from the variable: 1/0, true/false, t/f, yes/no, y/n, on/off, in any case. The children parse their real
!< command line under the environment set by the parent and print `error=<code> mesh=[] level=[] verbose=<T|F>
!< cache=<T|F> n=[] verbose_error=<code>` (case 1; case 2 with ignore_env). Every get has its own variable (nvfortran, B33).
use flap, only : command_line_interface, ERROR_CASTING_LOGICAL, ERROR_ENVVAR_NARGS, ERROR_ENVVAR_NOT_STORE, &
                 ERROR_ENVVAR_POSITIONAL, ERROR_MISSING_REQUIRED
use flap_test_utils, only : assert_contains, assert_equal, capture_close, capture_open, child_case, reinvoke
use penf, only : I4P, str

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI).
character(:), allocatable    :: out      !< Standard output of a child.
character(:), allocatable    :: err      !< Standard error of a child.
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: exitstat !< Exit status.
integer(I4P)                 :: error    !< Error trapping flag.

select case(child_case())
case(1)
  call child(ignore_env=.false.)
  stop
case(2)
  call child(ignore_env=.true.)
  stop
endselect

! T3.1, T3.4: environment only; a required option is satisfied by it
call check('', 'FLAP_ES_MESH=m.grd FLAP_ES_LEVEL=5', 'error=0 mesh=[m.grd] level=[5]', 'environment only')
! T3.2: the command line wins
call check('--mesh x --level 7', 'FLAP_ES_MESH=m.grd FLAP_ES_LEVEL=5', 'error=0 mesh=[x] level=[7]', 'command line wins')
! T3.3: an empty (or blank) variable is unset: the default
call check('--mesh x', 'FLAP_ES_LEVEL=', 'level=[1]', 'empty variable: default')
call check('--mesh x', "'FLAP_ES_LEVEL=  '", 'level=[1]', 'blank variable: default')
! a required option without variable and command line value: missing
call check('', '-u FLAP_ES_MESH', 'error='//trim(str(ERROR_MISSING_REQUIRED, .true.))//' ', 'required, nothing: missing')
call check('', 'FLAP_ES_MESH=', 'error='//trim(str(ERROR_MISSING_REQUIRED, .true.))//' ', 'required, empty variable: missing')
! T3.5: the bare switch still reads the variable
call check('--mesh x --level', 'FLAP_ES_LEVEL=9', 'level=[9]', 'bare switch')
! T3.7: flags from the environment
call check('--mesh x', 'FLAP_ES_VERBOSE=yes FLAP_ES_CACHE=no', 'verbose=T cache=F', 'flags yes/no')
call check('--mesh x', 'FLAP_ES_VERBOSE=1 FLAP_ES_CACHE=0', 'verbose=T cache=F', 'flags 1/0')
call check('--mesh x', 'FLAP_ES_VERBOSE=On FLAP_ES_CACHE=OFF', 'verbose=T cache=F', 'flags on/off, any case')
call check('--mesh x', 'FLAP_ES_VERBOSE=t FLAP_ES_CACHE=false', 'verbose=T cache=F', 'flags t/false')
call check('--mesh x', 'FLAP_ES_VERBOSE=N FLAP_ES_CACHE=Y', 'verbose=F cache=T', 'flags N/Y')
call check('--mesh x', '-u FLAP_ES_VERBOSE -u FLAP_ES_CACHE', 'verbose=F cache=T', 'flags, no variables: defaults')
call check('--mesh x --verbose --cache', 'FLAP_ES_VERBOSE=no FLAP_ES_CACHE=yes', 'verbose=T cache=F', &
           'flags on the command line win')
! T3.8: an invalid logical is reported by get
call check('--mesh x', 'FLAP_ES_VERBOSE=maybe', 'verbose_error='//trim(str(ERROR_CASTING_LOGICAL, .true.)), &
           'flag from an invalid logical')
! the options of a command read the environment too
call check('run', 'FLAP_ES_MESH=m FLAP_ES_RUN_N=4', 'n=[4]', 'option of a command')
! ignore_env: the environment is not a source
call reinvoke(2_I4P, exitstat, out, err, args='--mesh x', env='FLAP_ES_LEVEL=5 FLAP_ES_VERBOSE=yes')
call assert_contains(out, 'level=[1] verbose=F', 'ignore_env: defaults')

! definitions: flags accept an envvar; positionals (T3.11), store* and lists (until the CSV split, F22) do not; a fresh
! CLI for each invalid definition, since a failed add is returned again by the next one (B34)
call capture_open(lun)
call cli%init(progname='flap_test_env_source', error_lun=lun, usage_lun=lun)
call cli%add(switch='--flag', help='flag', required=.false., act='store_true', def='.false.', envvar='FLAP_F', error=error)
call assert_equal(error, 0_I4P, 'store_true with envvar: allowed')
call cli%add(switch='--off', help='flag', required=.false., act='store_false', def='.true.', envvar='FLAP_O', error=error)
call assert_equal(error, 0_I4P, 'store_false with envvar: allowed')
call cli%add(positional=.true., position=1, help='p', required=.false., def='p', envvar='FLAP_P', error=error)
call assert_equal(error, ERROR_ENVVAR_POSITIONAL, 'positional with envvar: error')
call cli%init(progname='flap_test_env_source', error_lun=lun, usage_lun=lun)
call cli%add(switch='--star', help='s', required=.false., act='store*', def='s', envvar='FLAP_S', error=error)
call assert_equal(error, ERROR_ENVVAR_NOT_STORE, 'store* with envvar: error')
call cli%init(progname='flap_test_env_source', error_lun=lun, usage_lun=lun)
call cli%add(switch='--list', help='l', required=.false., act='store', nargs='+', def='1', envvar='FLAP_L', error=error)
call assert_equal(error, ERROR_ENVVAR_NARGS, 'list with envvar: error until F22')
call capture_close(lun)

contains
  subroutine check(args, env, expected, message)
  !< Run the child with a command line and an environment and check its output.
  character(*), intent(in) :: args     !< Command line of the child.
  character(*), intent(in) :: env      !< Environment of the child (env operands).
  character(*), intent(in) :: expected !< Expected output fragment.
  character(*), intent(in) :: message  !< Description of the check.

  call reinvoke(1_I4P, exitstat, out, err, args=args, env=env)
  call assert_equal(exitstat, 0_I4P, message//': exit status (stderr: '//err//')')
  call assert_contains(out, expected, message)
  endsubroutine check

  subroutine child(ignore_env)
  !< Define the CLI, parse the real command line and print the values.
  logical, intent(in) :: ignore_env    !< Ignore the environment.
  character(99)       :: mesh          !< Value of --mesh.
  character(99)       :: level         !< Value of --level.
  character(99)       :: n             !< Value of run --n.
  logical             :: verbose       !< Value of --verbose.
  logical             :: cache         !< Value of --cache.
  integer(I4P)        :: verbose_error !< Error of the get of --verbose.

  call capture_open(lun)
  call cli%init(progname='flap_test_env_source', ignore_env=ignore_env, error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--mesh', help='mesh', required=.true., act='store', envvar='FLAP_ES_MESH', error=error)
  call cli%add(switch='--level', help='level', required=.false., act='store', def='1', envvar='FLAP_ES_LEVEL', error=error)
  call cli%add(switch='--verbose', help='verbose', required=.false., act='store_true', def='.false.', &
               envvar='FLAP_ES_VERBOSE', error=error)
  call cli%add(switch='--cache', help='cache', required=.false., act='store_false', def='.true.', envvar='FLAP_ES_CACHE', &
               error=error)
  call cli%add_group(group='run', description='run')
  call cli%add(group='run', switch='--n', help='n', required=.false., act='store', def='0', envvar='FLAP_ES_RUN_N', &
               error=error)
  call cli%parse(error=error)
  mesh = '' ; level = '' ; n = '' ; verbose = .false. ; cache = .false. ; verbose_error = -1
  if (error == 0) then
    call cli%get(switch='--mesh', val=mesh, error=error)
    call cli%get(switch='--level', val=level, error=error)
    call cli%get(switch='--verbose', val=verbose, error=verbose_error)
    call cli%get(switch='--cache', val=cache, error=error)
    call cli%get(group='run', switch='--n', val=n, error=error)
  endif
  call capture_close(lun)
  print '(A)', 'error='//trim(str(error, .true.))//' mesh=['//trim(mesh)//'] level=['//trim(level)//'] verbose='// &
               merge('T', 'F', verbose)//' cache='//merge('T', 'F', cache)//' n=['//trim(n)//'] verbose_error='// &
               trim(str(verbose_error, .true.))
  endsubroutine child
endprogram flap_test_env_source

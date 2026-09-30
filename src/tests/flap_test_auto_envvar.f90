!< auto_envvar_prefix generates the variable of every option without envvar (issue #125, step 2.3; #11 3.3, T3.9-T3.10).
program flap_test_auto_envvar
!< auto_envvar_prefix generates the variable of every option without envvar (issue #125, step 2.3; #11 3.3, T3.9-T3.10).
!<
!< The name is PREFIX[_GROUP]_NAME, upper case, NAME being the long switch without its dashes, '-' becoming '_'. Named
!< store/store_true/store_false options, lists included, get one; an explicit envvar wins; positionals, store*, count and
!< append do not. The child (case 1) parses its real command line and prints the values; every get
!< has its own variable (nvfortran, B33).
use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, reinvoke
use penf, only : I4P, str

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI).
character(:), allocatable    :: out      !< Standard output of a child.
character(:), allocatable    :: err      !< Standard error of a child.
character(:), allocatable    :: usage    !< Usage of the top level.
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: exitstat !< Exit status.
integer(I4P)                 :: error    !< Error trapping flag.

if (child_case() == 1) then
  call child
  stop
endif

call capture_open(lun)
call define(prefix='solver')
usage = cli%usage(g=0)
! T3.9: generated names, top level and command
call assert_contains(usage, 'environment variable name "SOLVER_MESH_FILE"', 'generated: --mesh-file')
call assert_contains(usage, 'environment variable name "SOLVER_LEVEL"', 'generated: --level')
call assert_contains(usage, 'environment variable name "SOLVER_VERBOSE"', 'generated: flag --verbose')
call assert_contains(usage, 'environment variable name "SOLVER_X"', 'generated: -x (no long switch)')
! the name of a command option (SOLVER_POST_PROC_FORMAT) is checked by the child below, reading it
! T3.10: an explicit envvar wins
call assert_contains(usage, 'environment variable name "MY_OUT"', 'explicit envvar kept')
call assert(index(usage, 'SOLVER_OUT') == 0, 'explicit envvar: no generated name')
! no name for positionals, store*, count, append and the builtins
call assert(index(usage, 'SOLVER_STAR') == 0, 'no name for store*')
call assert(index(usage, 'SOLVER_COUNT') == 0, 'no name for count')
call assert(index(usage, 'SOLVER_APP') == 0, 'no name for append')
call assert_contains(usage, 'environment variable name "SOLVER_LIST"', 'generated: a list (F22)')
call assert(index(usage, 'SOLVER_HELP') == 0 .and. index(usage, 'SOLVER_VERSION') == 0, 'no name for the builtins')
! without a prefix nothing is generated
call define(prefix='')
call assert(index(cli%usage(g=0), 'SOLVER_') == 0, 'no prefix: no generated name')
call assert_contains(cli%usage(g=0), 'environment variable name "MY_OUT"', 'no prefix: explicit envvar kept')
call capture_close(lun)

! the generated variables are value sources
call reinvoke(1_I4P, exitstat, out, err, args='post-proc', env='SOLVER_MESH_FILE=wing.grd SOLVER_LEVEL=3 '// &
              'SOLVER_VERBOSE=yes SOLVER_POST_PROC_FORMAT=csv MY_OUT=o SOLVER_OUT=bad')
call assert_equal(exitstat, 0_I4P, 'values from generated variables: exit status (stderr: '//err//')')
call assert_contains(out, 'error=0 mesh=[wing.grd] level=[3] verbose=T out=[o] format=[csv]', &
                     'values from generated variables')

contains
  subroutine define(prefix)
  !< Define the CLI with a prefix.
  character(*), intent(in) :: prefix !< Prefix of the generated variables.

  if (prefix == '') then
    call cli%init(progname='solver', error_lun=lun, usage_lun=lun, error_hint=.false.)
  else
    call cli%init(progname='solver', auto_envvar_prefix=prefix, error_lun=lun, usage_lun=lun, error_hint=.false.)
  endif
  call cli%add(switch='--mesh-file', help='mesh', required=.true., act='store', error=error)
  call assert_equal(error, 0_I4P, 'add --mesh-file')
  call cli%add(switch='--level', help='level', required=.false., act='store', def='1', error=error)
  call cli%add(switch='--verbose', help='verbose', required=.false., act='store_true', def='.false.', error=error)
  call cli%add(switch_ab='-x', help='x', required=.false., act='store', def='0', error=error)
  call cli%add(switch='--out', help='out', required=.false., act='store', def='a.out', envvar='MY_OUT', error=error)
  call cli%add(positional=.true., position=1, help='input', required=.false., def='in', error=error)
  call assert_equal(error, 0_I4P, 'add a positional: no generated name, no error')
  call cli%add(switch='--star', help='star', required=.false., act='store*', def='s', error=error)
  call assert_equal(error, 0_I4P, 'add a store*: no generated name, no error')
  call cli%add(switch='--count', help='count', required=.false., act='count', error=error)
  call assert_equal(error, 0_I4P, 'add a count: no generated name, no error')
  call cli%add(switch='--app', help='append', required=.false., act='append', def='a', error=error)
  call assert_equal(error, 0_I4P, 'add an append: no generated name, no error')
  call cli%add(switch='--list', help='list', required=.false., act='store', nargs='+', def='1 2', error=error)
  call assert_equal(error, 0_I4P, 'add a list')
  call cli%add_group(group='post-proc', description='post processing')
  call cli%add(group='post-proc', switch='--format', help='format', required=.false., act='store', def='vtk', error=error)
  call assert_equal(error, 0_I4P, 'add post-proc --format')
  endsubroutine define

  subroutine child()
  !< Define the CLI with the prefix SOLVER, parse the real command line and print the values.
  character(99) :: mesh    !< Value of --mesh-file.
  character(99) :: level   !< Value of --level.
  character(99) :: outv    !< Value of --out.
  character(99) :: format  !< Value of post-proc --format.
  logical       :: verbose !< Value of --verbose.

  call capture_open(lun)
  call define(prefix='SOLVER')
  call cli%parse(error=error)
  mesh = '' ; level = '' ; outv = '' ; format = '' ; verbose = .false.
  if (error == 0) then
    call cli%get(switch='--mesh-file', val=mesh, error=error)
    call cli%get(switch='--level', val=level, error=error)
    call cli%get(switch='--verbose', val=verbose, error=error)
    call cli%get(switch='--out', val=outv, error=error)
    call cli%get(group='post-proc', switch='--format', val=format, error=error)
  endif
  call capture_close(lun)
  print '(A)', 'error='//trim(str(error, .true.))//' mesh=['//trim(mesh)//'] level=['//trim(level)//'] verbose='// &
               merge('T', 'F', verbose)//' out=['//trim(outv)//'] format=['//trim(format)//']'
  endsubroutine child
endprogram flap_test_auto_envvar

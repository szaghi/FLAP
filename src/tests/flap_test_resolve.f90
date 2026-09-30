!< The value-resolution chain: the source of every value and has_value (issue #125, step 2.1; #11 R.1-R.2, D2).
program flap_test_resolve
!< The value-resolution chain: the source of every value and has_value (issue #125, step 2.1; #11 R.1-R.2, D2).
!<
!< A CLA records where its value comes from: SOURCE_COMMANDLINE (passed), SOURCE_ENVIRONMENT (bare switch with envvar),
!< SOURCE_DEFAULT (not passed, with a default), SOURCE_NONE (nothing). The source of a parsed value is recorded while parsing,
!< so it survives a parse stopped by an error; resolve_values settles the others. The child (scenario 1) reads the envvar.
use flap, only : command_line_argument, command_line_arguments_group, ERROR_MISSING_REQUIRED, ERROR_UNKNOWN, &
                 SOURCE_COMMANDLINE, SOURCE_CONFIG, SOURCE_DEFAULT, SOURCE_ENVIRONMENT, SOURCE_NONE
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, reinvoke
use penf, only : I4P, str

implicit none
type(command_line_arguments_group) :: g        !< Group.
type(command_line_argument)        :: cla      !< Fresh CLA.
character(:), allocatable          :: out      !< Standard output of the child.
character(:), allocatable          :: err      !< Standard error of the child.
integer(I4P)                       :: lun      !< Capture unit.
integer(I4P)                       :: exitstat !< Exit status.
integer(I4P)                       :: error    !< Error trapping flag.

if (child_case() == 1) then
  call capture_open(lun)
  call parse([character(5) :: '--req', 'r', '--e'], error)
  print '(A)', 'error='//trim(str(error, .true.))//' source='//trim(str(source_of('--e'), .true.))//' val=['// &
               g%cla(index_of('--e'))%val//'] passed='//merge('T', 'F', g%cla(index_of('--e'))%is_passed)
  call capture_close(lun)
  stop
endif

call capture_open(lun)

! the explicit sources come first: source < SOURCE_DEFAULT means "given by the user"
call assert(SOURCE_COMMANDLINE < SOURCE_ENVIRONMENT .and. SOURCE_ENVIRONMENT < SOURCE_CONFIG .and. &
            SOURCE_CONFIG < SOURCE_DEFAULT .and. SOURCE_DEFAULT < SOURCE_NONE, 'sources ordered by explicitness')
call assert_equal(cla%source, SOURCE_NONE, 'a fresh CLA: no source')
call assert(.not.cla%has_value(), 'a fresh CLA: no value')

! passed values, defaults
call parse([character(5) :: '--a', '5', '--req', 'r', 'file'], error)
call assert_equal(error, 0_I4P, 'passed: parse')
call g%resolve_values
call assert_equal(source_of('--a'), SOURCE_COMMANDLINE, 'passed --a: command line')
call assert(g%cla(index_of('--a'))%has_value(), 'passed --a: has a value')
call assert_equal(source_of('--req'), SOURCE_COMMANDLINE, 'passed --req: command line')
call assert_equal(g%cla(g%positional_index(1_I4P))%source, SOURCE_COMMANDLINE, 'passed positional: command line')
call assert_equal(source_of('--flag'), SOURCE_DEFAULT, 'flag not passed: default')
call assert(.not.g%cla(index_of('--flag'))%has_value(), 'flag not passed: no explicit value')
call assert_equal(source_of('--e'), SOURCE_DEFAULT, 'envvar option not passed: default (the environment is not read)')

call parse([character(6) :: '--req', 'r', '--flag'], error)
call g%resolve_values
call assert_equal(source_of('--flag'), SOURCE_COMMANDLINE, 'passed flag: command line')
call assert(g%cla(index_of('--flag'))%has_value(), 'passed flag: has a value')
call assert_equal(source_of('--a'), SOURCE_DEFAULT, '--a not passed: default')
call assert_equal(g%cla(g%positional_index(1_I4P))%source, SOURCE_DEFAULT, 'positional not passed: default')

! nothing: a required option without default, not passed; the required check is unchanged
call parse([character(3) :: '--a', '5'], error)
call g%resolve_values
call assert_equal(source_of('--req'), SOURCE_NONE, 'required not passed: no source')
call g%is_required_passed
call assert_equal(g%error, ERROR_MISSING_REQUIRED, 'required not passed: missing required')

! a parse stopped by an error keeps the sources of the values parsed before it
call parse([character(7) :: '--a', '5', '--bogus'], error)
call assert_equal(error, ERROR_UNKNOWN, 'stopped parse: unknown switch')
call assert_equal(source_of('--a'), SOURCE_COMMANDLINE, 'stopped parse: --a keeps its source')

! reset_parse forgets the sources
call g%reset_parse
call assert_equal(source_of('--a'), SOURCE_NONE, 'reset_parse: no source')

call capture_close(lun)

! a bare switch with its environment variable set: the value comes from the environment
call reinvoke(1_I4P, exitstat, out, err, env='FLAP_TEST_RESOLVE=envv')
call assert_equal(exitstat, 0_I4P, 'bare --e with the variable set: exit status (stderr: '//err//')')
call assert_contains(out, 'error=0 source='//trim(str(SOURCE_ENVIRONMENT, .true.))//' val=[envv] passed=T', &
                     'bare --e with the variable set: environment source')

contains
  subroutine parse(args, error)
  !< Define the group (--a, --req, --flag, --e with envvar, a positional) and parse a command line.
  character(*), intent(in)  :: args(:) !< Command line arguments.
  integer(I4P), intent(out) :: error   !< Error of the parse.
  integer(I4P)              :: unknown !< Unknown argument error.

  call g%free
  g%progname = 'flap_test_resolve' ; g%group = '' ; g%error_lun = lun ; g%usage_lun = lun ; g%help = 'usage: '
  g%description = '' ; g%epilog = '' ; g%error_color = '' ; g%error_style = ''
  call add(switch='--a', act='STORE', def='1')
  call add(switch='--req', act='STORE', required=.true.)
  call add(switch='--flag', act='STORE_TRUE', def='.false.')
  call add(switch='--e', act='STORE', def='d', envvar='FLAP_TEST_RESOLVE')
  call add(act='STORE', def='p', position=1_I4P)
  g%is_called = .true.
  call g%parse(args=args, ignore_unknown_clas=.false., error_unknown_clas=unknown)
  error = g%error
  endsubroutine parse

  subroutine add(act, switch, def, required, envvar, position)
  !< Add a CLA to the group, as cli%add does.
  character(*), intent(in)           :: act      !< Action.
  character(*), intent(in), optional :: switch   !< Switch.
  character(*), intent(in), optional :: def      !< Default.
  logical,      intent(in), optional :: required !< Required.
  character(*), intent(in), optional :: envvar   !< Environment variable.
  integer(I4P), intent(in), optional :: position !< Position of a positional.
  type(command_line_argument)        :: c        !< CLA.

  call c%assign_object(g)
  c%help = 'help' ; c%help_color = '' ; c%help_style = '' ; c%help_markdown = '' ; c%m_exclude = '' ; c%act = act
  if (present(switch)) then
    c%switch = switch ; c%switch_ab = switch
  endif
  if (present(def)) then
    c%def = def ; c%val = def
  endif
  if (present(required)) c%is_required = required
  if (present(envvar)) c%envvar = envvar
  if (present(position)) then
    c%is_positional = .true. ; c%position = position
  endif
  call g%add(cla=c)
  call assert_equal(g%error, 0_I4P, 'add a CLA')
  endsubroutine add

  function index_of(switch) result(a)
  !< Index of the CLA with a switch.
  character(*), intent(in) :: switch !< Switch.
  integer(I4P)             :: a      !< Index.

  call assert(g%is_defined(switch=switch, pos=a), switch//' is defined')
  endfunction index_of

  function source_of(switch) result(source)
  !< Source of the value of the CLA with a switch.
  character(*), intent(in) :: switch !< Switch.
  integer(I4P)             :: source !< Source.

  source = g%cla(index_of(switch))%source
  endfunction source_of
endprogram flap_test_resolve

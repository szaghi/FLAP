!< Configuration-file values: set_config and the INI reader (issue #125, step 2.5; #11 4.1-4.2, T4.1-T4.7, T4.10-T4.12; D18).
program flap_test_config
!< Configuration-file values: set_config and the INI reader (issue #125, step 2.5; #11 4.1-4.2, T4.1-T4.7, T4.10-T4.12; D18).
!<
!< Precedence: command line > environment > configuration file > default. Keys are long switches without the dashes; a
!< section is a group (command); lists are blank separated, flags read yes/no, on/off, ... An unknown key is an error
!< (ERROR_CONFIG_UNKNOWN_KEY) unless ignore_unknown_clas; a missing file is an error only when required. The files are
!< written next to the executable. The child (case 1) parses with the file written by the parent and FLAP_TEST_CONFIG_E set.
!< Every get has its own variable and call site (nvfortran, B33).
use flap, only : command_line_interface, ERROR_CONFIG_NOT_FOUND, ERROR_CONFIG_UNKNOWN_KEY, ERROR_NOT_IN_CHOICES, &
                 STATUS_PRINT_H
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, delete_file, &
                            read_back, reinvoke, scratch_file, write_file
use penf, only : I4P, str

implicit none
character(*), parameter      :: NL = new_line('a') !< Line end.
type(command_line_interface) :: cli                !< Command Line Interface (CLI).
character(:), allocatable    :: ini                !< Path of the configuration file.
character(:), allocatable    :: out                !< Output of a child, or captured output.
character(:), allocatable    :: err                !< Standard error of a child.
integer(I4P)                 :: lun                !< Capture unit.
integer(I4P)                 :: exitstat           !< Exit status.
integer(I4P)                 :: error              !< Error trapping flag.

ini = scratch_file('ini')
if (child_case() == 1) then
  call capture_open(lun)
  call define
  call cli%parse(args='--mesh-file m', error=error)
  print '(A)', 'error='//trim(str(error, .true.))//' e=['//str_of('--e')//']'
  call capture_close(lun)
  stop
endif

call capture_open(lun)

! T4.1: values from the file; a required option is satisfied by it
call run('mesh-file = wing.grd'//NL//'cfl = 0.8'//NL, '')
call assert_equal(error, 0_I4P, 'config only: parse')
call assert_equal(str_of('--mesh-file'), 'wing.grd', 'config only: required --mesh-file')
call assert_equal(str_of('--cfl'), '0.8', 'config only: --cfl')
call assert_equal(str_of('--title'), 'none', 'config only: an absent key gives the default')
! T4.2: the command line wins over the file (the environment is checked by the child below)
call run('mesh-file = wing.grd'//NL//'cfl = 0.8'//NL, '--cfl 0.9')
call assert_equal(str_of('--cfl'), '0.9', 'command line over config')
! T4.3: a section is a group
call run('mesh-file = w'//NL//'[post]'//NL//'format = vtu'//NL, 'post')
call assert_equal(error, 0_I4P, 'section: parse')
call assert_equal(str_of('--format', group='post'), 'vtu', 'section [post]: post --format')
! T4.4: a list, blank separated
call run('mesh-file = w'//NL//'fields = rho  u v'//NL, '')
call assert_equal(list_of('--fields'), 'rho|u|v|', 'list value')
! T4.5: flags
call run('mesh-file = w'//NL//'verbose = yes'//NL, '')
call assert(flag_of('--verbose'), 'flag: yes')
call run('mesh-file = w'//NL//'verbose = Off'//NL, '')
call assert(.not.flag_of('--verbose'), 'flag: Off')
! T4.6, T4.7 (D18): unknown keys and sections
call run('mesh-file = w'//NL//'cfll = 1'//NL, '')
call assert_equal(error, ERROR_CONFIG_UNKNOWN_KEY, 'unknown key: error')
call assert_contains(out, '"cfll"', 'unknown key: named in the message')
call run('mesh-file = w'//NL//'[nope]'//NL//'format = x'//NL, '')
call assert_equal(error, ERROR_CONFIG_UNKNOWN_KEY, 'unknown section: error')
call run('mesh-file = w'//NL//'cfll = 1'//NL, '', ignore_unknown=.true.)
call assert_equal(error, 0_I4P, 'unknown key with ignore_unknown_clas: ignored')
call run('mesh-file = w'//NL//'n = 3'//NL, '')
call assert_equal(error, ERROR_CONFIG_UNKNOWN_KEY, 'a key naming a count: error (it takes no value)')
call run('mesh-file = w'//NL//'just words'//NL, '')
call assert_equal(error, ERROR_CONFIG_UNKNOWN_KEY, 'a line without "=": error')
! a broken file does not block the help
call run('cfll = 1'//NL, '--help')
call assert_equal(error, STATUS_PRINT_H, 'unknown key and --help: the help')
! T4.10: comments, blank lines, quotes, '=' in the value; the last of duplicated keys wins
call run('# comment'//NL//'; comment'//NL//NL//'  mesh-file=w  '//NL//'title = "a # b"  # comment'//NL, '')
call assert_equal(str_of('--title'), 'a # b', 'quoted value with #')
call run('mesh-file = w'//NL//'title = x # comment'//NL, '')
call assert_equal(str_of('--title'), 'x', 'inline comment after a blank')
call run('mesh-file = w'//NL//'title = x#y ;z'//NL, '')
call assert_equal(str_of('--title'), 'x#y', 'no blank before #: kept; blank before ;: comment')
call run('mesh-file = w'//NL//"title = 'q q'"//NL, '')
call assert_equal(str_of('--title'), 'q q', 'single quotes stripped')
call run('mesh-file = w'//NL//'title = a=b'//NL, '')
call assert_equal(str_of('--title'), 'a=b', '= inside the value')
call run('mesh-file = w'//NL//'cfl = 1'//NL//'cfl = 2'//NL, '')
call assert_equal(str_of('--cfl'), '2', 'duplicated key: the last wins')
! T4.11: a value from the file is checked against choices
call run('mesh-file = w'//NL//'level = 7'//NL, '')
call assert_equal(get_error('--level'), ERROR_NOT_IN_CHOICES, 'choices: violated by the file')
! T4.12: a line longer than 1000 characters
call run('mesh-file = w'//NL//'title = '//repeat('x', 1200)//NL, '')
call assert_equal(len(str_of('--title')), 1200, 'long line')
! the file: missing and required, missing and optional, without final line end
call delete_file(ini)
call run('', '--mesh-file w', required=.true., write=.false.)
call assert_equal(error, ERROR_CONFIG_NOT_FOUND, 'missing required file: error')
call assert_contains(out, ini, 'missing required file: named in the message')
call run('', '--mesh-file w', write=.false.)
call assert_equal(error, 0_I4P, 'missing optional file: skipped')
call run('mesh-file = w'//NL//'cfl = 3', '')
call assert_equal(str_of('--cfl'), '3', 'last line without line end')
call capture_close(lun)

! T4.2: the environment wins over the file, the file over the default
call write_file(ini, 'e = cfg'//NL)
call reinvoke(1_I4P, exitstat, out, err, env='FLAP_TEST_CONFIG_E=env')
call assert_equal(exitstat, 0_I4P, 'environment and config: exit status (stderr: '//err//')')
call assert_contains(out, 'error=0 e=[env]', 'environment over config')
call reinvoke(1_I4P, exitstat, out, err, env='-u FLAP_TEST_CONFIG_E')
call assert_contains(out, 'error=0 e=[cfg]', 'config over default')
call delete_file(ini)

contains
  subroutine define(ignore_unknown, required)
  !< Define the CLI reading the configuration file ini.
  logical, intent(in), optional :: ignore_unknown !< Ignore unknown arguments and keys.
  logical, intent(in), optional :: required       !< The file is required.

  call cli%init(progname='flap_test_config', standalone=.false., ignore_unknown_clas=ignore_unknown, error_lun=lun, &
                usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--mesh-file', help='mesh', required=.true., act='store', error=error)
  call cli%add(switch='--cfl', help='cfl', required=.false., act='store', def='0.5', error=error)
  call cli%add(switch='--level', help='level', required=.false., act='store', def='1', choices='1,2,3', error=error)
  call cli%add(switch='--fields', help='fields', required=.false., act='store', nargs='+', def='rho', error=error)
  call cli%add(switch='--verbose', help='verbose', required=.false., act='store_true', def='.false.', error=error)
  call cli%add(switch='--title', help='title', required=.false., act='store', def='none', error=error)
  call cli%add(switch='--e', help='e', required=.false., act='store', def='d', envvar='FLAP_TEST_CONFIG_E', error=error)
  call cli%add(switch='--n', help='count', required=.false., act='count', error=error)
  call cli%add_group(group='post', description='post processing')
  call cli%add(group='post', switch='--format', help='format', required=.false., act='store', def='vtk', error=error)
  call cli%set_config(file=ini, required=required, error=error)
  call assert_equal(error, 0_I4P, 'set_config')
  endsubroutine define

  subroutine run(text, args, ignore_unknown, required, write)
  !< Write the configuration file (unless write=.false.), define the CLI and parse a command line.
  character(*), intent(in)           :: text           !< Content of the file.
  character(*), intent(in)           :: args           !< Command line.
  logical,      intent(in), optional :: ignore_unknown !< Ignore unknown arguments and keys.
  logical,      intent(in), optional :: required       !< The file is required.
  logical,      intent(in), optional :: write          !< Write the file.
  logical                            :: write_         !< Write the file, local variable.

  write_ = .true. ; if (present(write)) write_ = write
  if (write_) call write_file(ini, text)
  call define(ignore_unknown=ignore_unknown, required=required)
  call cli%parse(args=args, error=error)
  out = read_back(lun)
  endsubroutine run

  function str_of(switch, group) result(val)
  !< Value of an option as a string.
  character(*), intent(in)           :: switch !< Switch.
  character(*), intent(in), optional :: group  !< Group.
  character(:), allocatable          :: val    !< Value.
  character(:), allocatable          :: g      !< Group, local variable.
  character(2000)                    :: buffer !< Buffer.
  integer(I4P)                       :: e      !< Error.

  g = '' ; if (present(group)) g = group
  buffer = ''
  call cli%get(group=g, switch=switch, val=buffer, error=e)
  val = trim(buffer)
  endfunction str_of

  function get_error(switch) result(e)
  !< Error of the get of an option as a string.
  character(*), intent(in) :: switch !< Switch.
  integer(I4P)             :: e      !< Error.
  character(99)            :: buffer !< Buffer.

  call cli%get(switch=switch, val=buffer, error=e)
  endfunction get_error

  function flag_of(switch) result(val)
  !< Value of a flag.
  character(*), intent(in) :: switch !< Switch.
  logical                  :: val    !< Value.
  integer(I4P)             :: e      !< Error.

  val = .false.
  call cli%get(switch=switch, val=val, error=e)
  endfunction flag_of

  function list_of(switch) result(joined)
  !< Values of a list, each followed by '|'.
  character(*), intent(in)   :: switch  !< Switch.
  character(:), allocatable  :: joined  !< Joined values.
  character(20), allocatable :: vals(:) !< Values.
  integer(I4P)               :: e       !< Error.
  integer                    :: v       !< Counter.

  joined = ''
  call cli%get_varying(switch=switch, val=vals, error=e)
  if (e /= 0 .or. .not.allocated(vals)) return
  do v=1, size(vals)
    joined = joined//trim(vals(v))//'|'
  enddo
  endfunction list_of
endprogram flap_test_config

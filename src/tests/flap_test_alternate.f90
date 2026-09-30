!< Alternate actions: act='alternate' bypasses the value validation (issue #125, step 2.10; #25 1.1-1.5, T1.1-T1.13; D3, D4).
program flap_test_alternate
!< Alternate actions: act='alternate' bypasses the value validation (issue #125, step 2.10; #25 1.1-1.5, T1.1-T1.13; D3, D4).
!<
!< A passed alternate (--list-models) makes parse return STATUS_ALTERNATE: the caller dispatches on is_passed. Bypassed
!< (D4): required options, exclusive sets, pairwise exclude, group exclusion, path checks, unknown configuration keys,
!< environment CSV errors. Not bypassed: syntax errors, and help/version/markdown, which come first (D3). Deprecation
!< warnings are still printed. The child (case 1) parses its real command line with an invalid list in FLAP_TEST_ALT_L.
use flap, only : command_line_interface, ERROR_ALTERNATE_INCONSISTENT, ERROR_DUPLICATED_CLAS, ERROR_M_EXCLUDE, &
                 ERROR_MISSING_REQUIRED, ERROR_UNKNOWN, STATUS_ALTERNATE, STATUS_PRINT_H
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, delete_file, &
                            read_back, reinvoke, scratch_file, write_file
use penf, only : I4P, str

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI).
character(:), allocatable    :: ini      !< Configuration file.
character(:), allocatable    :: out      !< Captured output.
character(:), allocatable    :: err      !< Standard error of the child.
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: exitstat !< Exit status.
integer(I4P)                 :: error    !< Error trapping flag.

ini = scratch_file('ini')
if (child_case() == 1) then
  call capture_open(lun)
  call define
  call cli%parse(error=error)
  call capture_close(lun)
  print '(A)', 'error='//trim(str(error, .true.))
  stop
endif

call capture_open(lun)
! T1.1-T1.3: the alternate bypasses the required option; without it, the usual validation
call run('--list-models')
call assert_equal(error, STATUS_ALTERNATE, 'alternate: status')
call assert(cli%is_passed(switch='--list-models'), 'alternate: is_passed')
call run('')
call assert_equal(error, ERROR_MISSING_REQUIRED, 'no alternate: missing required')
call run('--mesh m.grd')
call assert_equal(error, 0_I4P, 'no alternate, required given')
call assert(.not.cli%is_passed(switch='--list-models'), 'no alternate: not passed')
! T1.4, T1.5: syntax errors win
call run('--list-models --bogus')
call assert_equal(error, ERROR_UNKNOWN, 'alternate and an unknown switch: syntax error')
call run('--list-models --list-models')
call assert_equal(error, ERROR_DUPLICATED_CLAS, 'alternate twice: duplicated')
! T1.6: two alternates
call run('--list-models --dump-config')
call assert_equal(error, STATUS_ALTERNATE, 'two alternates: status')
call assert(cli%is_passed(switch='--list-models').and.cli%is_passed(switch='--dump-config'), 'two alternates: both passed')
! T1.7: pairwise exclude bypassed (and reported without the alternate)
call run('--list-models -a -b')
call assert_equal(error, STATUS_ALTERNATE, 'alternate: pairwise exclude bypassed')
call run('--mesh m -a -b')
call assert_equal(error, ERROR_M_EXCLUDE, 'no alternate: pairwise exclude reported')
! T1.8: choices are checked by get, as usual
call run('--list-models --n 3')
call assert_equal(error, STATUS_ALTERNATE, 'alternate with a value out of choices: status')
call assert(get_error('--n') /= 0, 'alternate: get still checks the choices')
! T1.9: an alternate of a command
call run('post --list-fields')
call assert_equal(error, STATUS_ALTERNATE, 'alternate of a command: status')
call assert(cli%run_command('post'), 'alternate of a command: command called')
! T1.10 (D3): help first
call run('--help --list-models')
call assert_equal(error, STATUS_PRINT_H, 'help and alternate: help')
! D4: exclusive sets, group exclusion, path checks, unknown configuration keys are bypassed; deprecation still warns
call run('--list-models --x 1 --y 2')
call assert_equal(error, STATUS_ALTERNATE, 'alternate: exclusive set bypassed')
call run('--list-models --table missing.table')
call assert_equal(error, STATUS_ALTERNATE, 'alternate: path check bypassed')
call run('--mesh m --x 1 --table missing.table')
call assert(error > 0, 'no alternate: path check reported')
call write_file(ini, 'bogus = 1'//new_line('a'))
call run('--list-models', config=.true.)
call assert_equal(error, STATUS_ALTERNATE, 'alternate: unknown configuration key bypassed')
call delete_file(ini)
call run('--list-models --old 1')
call assert_contains(out, 'warning: option "--old" is deprecated', 'alternate: deprecation still warns')
call run('--list-models first second')
call assert_equal(error, STATUS_ALTERNATE, 'alternate: group exclusion bypassed')
! T1.12: an alternate defined before a later add_group
call define
call cli%add_group(group='later', description='later')
call cli%parse(args='--list-models', error=error)
call assert_equal(error, STATUS_ALTERNATE, 'alternate, then add_group: status')
! T1.13: usage as a flag
call define
call assert_contains(cli%usage(g=0), ' [--list-models]', 'usage: [--list-models]')
call assert(index(cli%usage(g=0), '--list-models value') == 0, 'usage: no value placeholder')
! T1.11: definitions
call bad('nargs')
call bad('envvar')
call bad('positional')
call bad('required')
call bad('choices')
call bad('exclude')
call capture_close(lun)

! D4: an environment CSV error is bypassed
call reinvoke(1_I4P, exitstat, out, err, args='--list-models', env="'FLAP_TEST_ALT_L=1,""2'")
call assert_contains(out, 'error='//trim(str(STATUS_ALTERNATE, .true.)), 'alternate: environment CSV error bypassed')

contains
  subroutine define(config)
  !< Define the CLI.
  logical, intent(in), optional :: config !< Read the configuration file.

  call cli%init(progname='flap_test_alternate', standalone=.false., error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--mesh', help='mesh', required=.true., act='store', error=error)
  call cli%add(switch='--list-models', help='list the models', act='alternate', error=error)
  call assert_equal(error, 0_I4P, 'add an alternate')
  call cli%add(switch='--dump-config', help='dump the configuration', act='alternate', error=error)
  call cli%add(switch='-a', help='a', required=.false., act='store_true', def='.false.', exclude='-b', error=error)
  call cli%add(switch='-b', help='b', required=.false., act='store_true', def='.false.', error=error)
  call cli%add(switch='--n', help='n', required=.false., act='store', def='1', choices='1,2', error=error)
  call cli%add(switch='--x', help='x', required=.false., act='store', def='0', error=error)
  call cli%add(switch='--y', help='y', required=.false., act='store', def='0', error=error)
  call cli%set_mutually_exclusive_switches(switches='--x,--y', error=error)
  call cli%add(switch='--table', help='table', required=.false., act='store', def='', must_exist=.true., error=error)
  call cli%add(switch='--old', help='old', required=.false., act='store', def='0', deprecated='', error=error)
  call cli%add(switch='--l', help='list', required=.false., act='store', nargs='+', def='1', envvar='FLAP_TEST_ALT_L', &
               error=error)
  call cli%add_group(group='post', description='post processing')
  call cli%add(group='post', switch='--list-fields', help='list the fields', act='alternate', error=error)
  call cli%add_group(group='first', description='first')
  call cli%add_group(group='second', description='second')
  call cli%set_mutually_exclusive_groups(group1='first', group2='second')
  if (present(config)) then
    if (config) call cli%set_config(file=ini)
  endif
  endsubroutine define

  subroutine run(args, config)
  !< Define the CLI and parse a command line, capturing the output.
  character(*), intent(in)           :: args   !< Command line.
  logical,      intent(in), optional :: config !< Read the configuration file.

  call define(config=config)
  call cli%parse(args=args, error=error)
  out = read_back(lun)
  endsubroutine run

  function get_error(switch) result(e)
  !< Error of the get of an option.
  character(*), intent(in) :: switch !< Switch.
  integer(I4P)             :: e      !< Error.
  character(99)            :: buffer !< Buffer.

  call cli%get(switch=switch, val=buffer, error=e)
  endfunction get_error

  subroutine bad(what)
  !< An alternate with an attribute of a value: definition error.
  character(*), intent(in) :: what !< Attribute.

  call cli%init(progname='flap_test_alternate', error_lun=lun, usage_lun=lun)
  select case(what)
  case('nargs')
    call cli%add(switch='--z', help='z', act='alternate', nargs='2', error=error)
  case('envvar')
    call cli%add(switch='--z', help='z', act='alternate', envvar='Z', error=error)
  case('positional')
    call cli%add(positional=.true., position=1, help='z', act='alternate', error=error)
  case('required')
    call cli%add(switch='--z', help='z', required=.true., act='alternate', error=error)
  case('choices')
    call cli%add(switch='--z', help='z', act='alternate', choices='1,2', error=error)
  case('exclude')
    call cli%add(switch='--z', help='z', act='alternate', exclude='--w', error=error)
  endselect
  call assert_equal(error, ERROR_ALTERNATE_INCONSISTENT, 'alternate with '//what//': definition error')
  endsubroutine bad
endprogram flap_test_alternate

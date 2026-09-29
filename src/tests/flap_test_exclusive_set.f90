!< Mutually exclusive sets of switches, optionally required (issue #125, step 1.7; #1 C, D19, E4).
program flap_test_exclusive_set
!< Mutually exclusive sets of switches, optionally required (issue #125, step 1.7; #1 C, D19, E4).
!<
!< At most one member of a set may be passed, exactly one if the set is required. Only passed members count: a default neither
!< satisfies nor violates a set. The checks run after help/version (E4), like the required check. Every scenario uses a
!< fresh CLI (tests C-T1...C-T12 of #1).
use flap, only : command_line_interface, ERROR_M_EXCLUDE_SET, ERROR_M_EXCLUDE_SET_DEFINITION, ERROR_M_EXCLUDE_SET_REQUIRED, &
                 ERROR_MISSING_GROUP, STATUS_PRINT_H
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
character(:), allocatable    :: out   !< Captured output.
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.

call capture_open(lun)

! C-T1...C-T3, C-T5: required and optional sets
call check('--a 1',              0_I4P,                        'required set, one member', required=.true.)
call check('--b 2',              0_I4P,                        'required set, the other member', required=.true.)
call check('--a 1 --b 2',        ERROR_M_EXCLUDE_SET,          'required set, two members', required=.true.)
call assert_contains(out, '"--a", "--b"', 'required set, two members: the passed members are listed')
call check('',                   ERROR_M_EXCLUDE_SET_REQUIRED, 'required set, no member (defaults do not count)', &
           required=.true.)
call assert_contains(out, 'one of "--a", "--b" is required', 'required set, no member: the members are listed')
call check('',                   0_I4P,                        'optional set, no member')
call check('--a 1',              0_I4P,                        'optional set, one member')
call check('--a 1 --b 2',        ERROR_M_EXCLUDE_SET,          'optional set, two members')
call check('--a=1 --b=2',        ERROR_M_EXCLUDE_SET,          'optional set, two inline members')
! C-T4: the help is printed (the checks come after it), also over a violated set
call check('--help',             STATUS_PRINT_H,               'required set, --help', required=.true.)
call check('--help --a 1 --b 2', STATUS_PRINT_H,               'optional set, --help over two members')
! C-T6: a 3-member set
call check('--a 1 --c',          ERROR_M_EXCLUDE_SET,          '3-member set, --a --c', members='--a,--b,--c')
call assert_contains(out, '"--a", "--c"', '3-member set, --a --c: the passed members are listed')
call assert(index(out, '"--b"') == 0, '3-member set, --a --c: only the passed members are listed')
call check('--c',                0_I4P,                        '3-member set, --c', members='--a,--b,--c')
! C-T11: a member named by its abbreviation is the same member
call check('--a 1 --b',          ERROR_M_EXCLUDE_SET,          'set {--a,-B}, --a --b', members='--a,-B')
call check('-B --a 1',           ERROR_M_EXCLUDE_SET,          'set {--a,-B}, -B --a', members='--a,-B')
call assert_contains(out, '"--a", "--b"', 'set {--a,-B}: the members are named by their switch')
! the other options are not affected
call check('--a 1 --c',          0_I4P,                        'set {--a,--b}, --a --c')

! C-T7: a set defined before a later add_group is kept
call define(members='--a,--b')
call cli%add_group(group='x', description='a later command')
call cli%parse(args='--must m --a 1 --b 2', error=error)
call assert_equal(error, ERROR_M_EXCLUDE_SET, 'set, then add_group: still enforced')

! C-T8, C-T9: sets of a command
call define_run(required=.false.)
call cli%parse(args='run --a 1 --b 2', error=error)
call assert_equal(error, ERROR_M_EXCLUDE_SET, 'set of run, run --a --b')
call define_run(required=.false.)
call cli%parse(args='--a 1 --b 2', error=error)
call assert_equal(error, 0_I4P, 'set of run, top-level --a --b: the top level is not affected')
call define_run(required=.true.)
call cli%parse(args='other', error=error)
call assert_equal(error, 0_I4P, 'required set of run, run not called')
call define_run(required=.true.)
call cli%parse(args='run', error=error)
call assert_equal(error, ERROR_M_EXCLUDE_SET_REQUIRED, 'required set of run, run alone')

! C-T10: invalid definitions
call bad_definition('--a',        'one member')
call bad_definition('--a,-a',     'the same member twice')
call bad_definition('--a,-B,--b', 'the same member by switch and abbreviation')
call bad_definition('--a,--zzz',  'an undefined member')
call bad_definition('--a,--must', 'a required member')
call bad_definition('--a,--b,',   'an empty member')
call define(members='--a,--b')
call cli%set_mutually_exclusive_switches(switches='--b,--c', error=error)
call assert_equal(error, ERROR_M_EXCLUDE_SET_DEFINITION, 'a switch in two sets: definition error')
call cli%parse(args='--must m', error=error)
call assert_equal(error, ERROR_M_EXCLUDE_SET_DEFINITION, 'after an invalid set: parse fails')
out = read_back(lun)
call define(members='--a,--b')
call cli%set_mutually_exclusive_switches(switches='--a,--b', group='nope', error=error)
call assert_equal(error, ERROR_MISSING_GROUP, 'set of an undefined group: missing group error')

! C-T12: usage, docopt style; the members are not repeated
call define(members='--a,--b', required=.true.)
call assert_contains(cli%usage(g=0), ' (--a value | --b [value])', 'usage of a required set')
call assert(index(cli%usage(g=0), '[--a value]') == 0, 'usage of a required set: --a only in the set')
call define(members='--a,--c')
call assert_contains(cli%usage(g=0), ' [--a value | --c]', 'usage of an optional set')
call assert(index(cli%usage(g=0), '[--c]') == 0, 'usage of an optional set: --c only in the set')
call assert_contains(cli%usage(g=0), ' [--b [value]]', 'usage of an optional set: --b is not a member')

call capture_close(lun)

contains
  subroutine define(members, required, expected)
  !< Define a CLI with the options --a, --b (-B), --c, --must and a set of them.
  character(*), intent(in)           :: members   !< Members of the set.
  logical,      intent(in), optional :: required  !< The set is required.
  integer(I4P), intent(in), optional :: expected  !< Expected error of the set definition (default 0).
  integer(I4P)                       :: expected_ !< Expected error, local variable.

  expected_ = 0 ; if (present(expected)) expected_ = expected
  call cli%init(progname='flap_test_exclusive_set', standalone=.false., error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--a', help='a', required=.false., act='store', def='0', error=error)
  call cli%add(switch='--b', switch_ab='-B', help='b', required=.false., act='store', def='0', val_required=.false., &
               error=error)
  call cli%add(switch='--c', help='c', required=.false., act='store_true', def='.false.', error=error)
  call cli%add(switch='--must', help='required', required=.true., act='store', error=error)
  call cli%add_group(group='other', description='another command')
  call cli%set_mutually_exclusive_switches(switches=members, required=required, error=error)
  call assert_equal(error, expected_, 'define the set "'//members//'"')
  endsubroutine define

  subroutine check(args, expected, message, required, members)
  !< Define a set, parse a command line (the required --must is always passed) and check the error.
  character(*), intent(in)           :: args     !< Command line.
  integer(I4P), intent(in)           :: expected !< Expected error or status.
  character(*), intent(in)           :: message  !< Description of the check.
  logical,      intent(in), optional :: required !< The set is required.
  character(*), intent(in), optional :: members  !< Members of the set (default --a,--b).

  if (present(members)) then
    call define(members=members, required=required)
  else
    call define(members='--a,--b', required=required)
  endif
  call cli%parse(args='--must m '//args, error=error)
  call assert_equal(error, expected, message)
  out = read_back(lun)
  endsubroutine check

  subroutine define_run(required)
  !< Define a CLI with the options --a, --b at the top level and in the command run, and a set of run.
  logical, intent(in) :: required !< The set is required.

  call cli%init(progname='flap_test_exclusive_set', standalone=.false., error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--a', help='a', required=.false., act='store', def='0', error=error)
  call cli%add(switch='--b', help='b', required=.false., act='store', def='0', error=error)
  call cli%add_group(group='run', description='run')
  call cli%add(group='run', switch='--a', help='a', required=.false., act='store', def='0', error=error)
  call cli%add(group='run', switch='--b', help='b', required=.false., act='store', def='0', error=error)
  call cli%add_group(group='other', description='another command')
  call cli%set_mutually_exclusive_switches(switches='--a,--b', required=required, group='run', error=error)
  call assert_equal(error, 0_I4P, 'define the set of run')
  endsubroutine define_run

  subroutine bad_definition(members, what)
  !< Define a set with invalid members: the definition error is returned and reported.
  character(*), intent(in) :: members !< Members of the set.
  character(*), intent(in) :: what    !< Description of the invalid definition.

  call define(members=members, expected=ERROR_M_EXCLUDE_SET_DEFINITION)
  out = read_back(lun)
  call assert_contains(out, 'mutually exclusive set', 'set with '//what//': a message is printed')
  endsubroutine bad_definition
endprogram flap_test_exclusive_set

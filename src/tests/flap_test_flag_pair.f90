!< Boolean flag pairs --x/--no-x: switch_neg (issue #125, step 3.2; #11 8.1, T8.1-T8.10; D5).
program flap_test_flag_pair
!< Boolean flag pairs --x/--no-x: switch_neg (issue #125, step 3.2; #11 8.1, T8.1-T8.10; D5).
!<
!< A store_true (store_false) flag with switch_neg='--no-x' is .true. (.false.) by its switch and the opposite by the
!< negation. The last of the two wins (D5), so a preset can be overridden; the same spelling twice is a duplicate. Every get
!< has its own variable (nvfortran, B33).
use flap, only : command_line_interface, ERROR_DUPLICATED_CLAS, ERROR_GROUP_CONSISTENCY, ERROR_INLINE_VALUE_NOT_ALLOWED, &
                 ERROR_SWITCH_NEG_INCONSISTENT
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, delete_file, read_back, &
                            read_file, scratch_file, write_file
use penf, only : I4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
character(:), allocatable    :: out   !< Captured output.
character(:), allocatable    :: ini   !< Configuration file.
character(:), allocatable    :: bash  !< Bash completion file.
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.
logical                      :: v     !< Flag value (every get before its check: no side effect inside an expression).

ini = scratch_file('ini')
bash = scratch_file('bash')
call capture_open(lun)
! T8.1-T8.3: store_true
call run('--restart')
v = flag('--restart', error)
call assert(v .and. error == 0, 'switch: .true.')
call run('-r')
v = flag('--restart', error)
call assert(v .and. error == 0, 'abbreviation: .true.')
call run('--no-restart')
v = flag('--restart', error)
call assert(.not.v .and. error == 0, 'negation: .false.')
call assert(cli%is_passed(switch='--restart'), 'negation: the pair is passed')
call assert(cli%is_passed(switch='--no-restart'), 'negation: is_passed by the negation')
call run('')
v = flag('--restart', error)
call assert(.not.v .and. error == 0, 'absent: default .false.')
call run('--no-wait')
v = flag('--wait', error)
call assert(.not.v .and. error == 0, 'negation of a default .true.: .false.')
call run('')
v = flag('--wait', error)
call assert(v .and. error == 0, 'absent: default .true.')
! T8.4 (D5): the last one wins
call run('--restart --no-restart')
v = flag('--restart', error)
call assert(.not.v .and. error == 0, 'switch then negation: .false.')
call run('--no-restart --restart')
v = flag('--restart', error)
call assert(v .and. error == 0, 'negation then switch: .true.')
call run('-r --no-restart')
v = flag('--restart', error)
call assert(.not.v .and. error == 0, 'abbreviation then negation: .false.')
! T8.10: the same spelling twice is a duplicate
call define
call cli%parse(args='--restart --restart', error=error)
call assert_equal(error, ERROR_DUPLICATED_CLAS, 'switch twice: duplicate')
call define
call cli%parse(args='--no-restart --no-restart', error=error)
call assert_equal(error, ERROR_DUPLICATED_CLAS, 'negation twice: duplicate')
call define
call cli%parse(args='--restart --no-restart --restart', error=error)
call assert_equal(error, ERROR_DUPLICATED_CLAS, 'switch, negation, switch: duplicate')
call define
call cli%parse(args='--restart -r', error=error)
call assert_equal(error, ERROR_DUPLICATED_CLAS, 'switch and its abbreviation: duplicate')
! T8.5: store_false, the mirror image
call run('--no-color')
v = flag('--no-color', error)
call assert(.not.v .and. error == 0, 'store_false switch: .false.')
call run('--color')
v = flag('--no-color', error)
call assert(v .and. error == 0, 'store_false negation: .true.')
call run('--color --no-color')
v = flag('--no-color', error)
call assert(.not.v .and. error == 0, 'store_false: the last one wins')
! T8.8: the look-ahead of a preceding list stops at the negation
call run('--list 1 2 --no-restart')
call assert_equal(list_size('--list'), 2_I4P, 'list followed by the negation: 2 values')
v = flag('--restart', error)
call assert(.not.v .and. error == 0, 'list followed by the negation: .false.')
! an inline value is not allowed
call define
call cli%parse(args='--no-restart=1', error=error)
call assert_equal(error, ERROR_INLINE_VALUE_NOT_ALLOWED, 'negation with an inline value: error')
! provenance: the value of a negation
call run('--no-wait')
out = line_of(cli%provenance(), '--wait ')
call assert_contains(out, '= .false.', 'provenance of a negation: value')
call assert_contains(out, '[command line]', 'provenance of a negation: source')
! configuration file below the command line: the negation wins, else the file
call write_file(ini, 'restart = yes'//new_line('a'))
call run('', config=.true.)
v = flag('--restart', error)
call assert(v .and. error == 0, 'configuration: .true.')
call run('--no-restart', config=.true.)
v = flag('--restart', error)
call assert(.not.v .and. error == 0, 'configuration overridden by the negation')
call delete_file(ini)
! T8.9: help, usage, bash completion
call define
call assert_contains(cli%usage(g=0), ' [--restart/--no-restart]', 'usage: [--restart/--no-restart]')
call assert_contains(cli%usage(g=0), '   --restart/--no-restart, -r', 'help: --restart/--no-restart, -r')
call assert_contains(cli%usage(g=0), ' [--no-color/--color]', 'usage: store_false pair')
call cli%save_bash_completion(bash_file=bash, error=error)
call assert_equal(error, 0_I4P, 'bash completion saved')
out = read_file(bash)
call assert_contains(out, ' --no-restart', 'bash completion: the negation is a word')
call delete_file(bash)
! T8.6, T8.7: definitions
call bad('store')
call bad('positional')
call bad('nargs')
call bad('own switch')
call bad('own abbreviation')
call bad('blank')
call define
call cli%add(switch='--no-restart', help='clash', required=.false., act='store_true', def='.false.', error=error)
call assert_equal(error, ERROR_GROUP_CONSISTENCY, 'a switch equal to another negation: consistency error')
call define
call cli%add(switch='--other', switch_neg='--list', help='clash', required=.false., act='store_true', def='.false.', &
             error=error)
call assert_equal(error, ERROR_GROUP_CONSISTENCY, 'a negation equal to another switch: consistency error')
out = read_back(lun)
call capture_close(lun)

contains
  subroutine define(config)
  !< Define the CLI.
  logical, intent(in), optional :: config !< Read the configuration file.

  call cli%init(progname='flap_test_flag_pair', error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--restart', switch_ab='-r', switch_neg='--no-restart', help='restart', required=.false., &
               act='store_true', def='.false.', error=error)
  call assert_equal(error, 0_I4P, 'add --restart/--no-restart')
  call cli%add(switch='--wait', switch_neg='--no-wait', help='wait', required=.false., act='store_true', def='.true.', &
               error=error)
  call cli%add(switch='--no-color', switch_neg='--color', help='no color', required=.false., act='store_false', &
               def='.true.', error=error)
  call cli%add(switch='--list', help='list', required=.false., act='store', nargs='*', def='0', error=error)
  call assert_equal(error, 0_I4P, 'add the options')
  if (present(config)) then
    if (config) call cli%set_config(file=ini)
  endif
  endsubroutine define

  subroutine run(args, config)
  !< Define the CLI and parse a command line.
  character(*), intent(in)           :: args   !< Command line.
  logical,      intent(in), optional :: config !< Read the configuration file.

  call define(config=config)
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, 'parse "'//args//'"')
  endsubroutine run

  function flag(switch, e) result(val)
  !< Value of a flag.
  character(*), intent(in)  :: switch !< Switch.
  integer(I4P), intent(out) :: e      !< Error.
  logical                   :: val    !< Value.

  val = .false.
  call cli%get(switch=switch, val=val, error=e)
  endfunction flag

  function list_size(switch) result(n)
  !< Number of values of a varying integer list.
  character(*), intent(in)  :: switch  !< Switch.
  integer(I4P)              :: n       !< Number of values.
  integer(I4P), allocatable :: vals(:) !< Values.
  integer(I4P)              :: e       !< Error.

  n = -1
  call cli%get_varying(switch=switch, val=vals, error=e)
  if (e == 0) n = size(vals, dim=1)
  endfunction list_size

  function line_of(text, key) result(line)
  !< The first line of a text starting with a key ('' if none).
  character(*), intent(in)      :: text !< Text.
  character(*), intent(in)      :: key  !< Key.
  character(len=:), allocatable :: line !< Line.
  integer(I4P)                  :: b    !< Begin of the line.
  integer(I4P)                  :: e    !< End of the line.

  line = ''
  b = 1
  do while (b <= len(text))
    e = index(text(b:), new_line('a'))
    if (e == 0) then
      e = len(text)
    else
      e = b + e - 2
    endif
    if (index(text(b:e), key) == 1) then
      line = text(b:e)
      return
    endif
    b = e + 2
  enddo
  endfunction line_of

  subroutine bad(what)
  !< A flag pair with an invalid definition.
  character(*), intent(in) :: what !< Case.

  call cli%init(progname='flap_test_flag_pair', error_lun=lun, usage_lun=lun)
  select case(what)
  case('store')
    call cli%add(switch='--x', switch_neg='--no-x', help='x', required=.false., act='store', def='1', error=error)
  case('positional')
    call cli%add(positional=.true., position=1, switch_neg='--no-x', help='x', required=.false., act='store_true', &
                 def='.false.', error=error)
  case('nargs')
    call cli%add(switch='--x', switch_neg='--no-x', help='x', required=.false., act='store_true', nargs='2', &
                 def='.false. .false.', error=error)
  case('own switch')
    call cli%add(switch='--x', switch_neg='--x', help='x', required=.false., act='store_true', def='.false.', error=error)
  case('own abbreviation')
    call cli%add(switch='--x', switch_ab='-x', switch_neg='-x', help='x', required=.false., act='store_true', &
                 def='.false.', error=error)
  case('blank')
    call cli%add(switch='--x', switch_neg=' ', help='x', required=.false., act='store_true', def='.false.', error=error)
  endselect
  call assert_equal(error, ERROR_SWITCH_NEG_INCONSISTENT, 'switch_neg with '//what//': definition error')
  endsubroutine bad
endprogram flap_test_flag_pair

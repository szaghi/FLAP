!< Case-insensitive choices, switches and commands (issue #125, step 3.3; #11 11.1-11.2, T11.1-T11.6; D7).
program flap_test_case_insensitive
!< Case-insensitive choices, switches and commands (issue #125, step 3.3; #11 11.1-11.2, T11.1-T11.6; D7).
!<
!< add(case_sensitive=.false.) matches the character choices in any case and returns the declared spelling;
!< init(case_insensitive=.true.) matches switches (abbreviations and negations included) and command names in any case,
!< never the values. Both default to the case-sensitive behaviour. Every get has its own variable (nvfortran, B33).
use flap, only : command_line_interface, ERROR_GROUP_CONSISTENCY, ERROR_NOT_IN_CHOICES, ERROR_UNKNOWN, STATUS_PRINT_H
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
character(:), allocatable    :: out   !< Captured output.
character(99)                :: s     !< Character value (every get before its check).
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.
logical                      :: v     !< Flag value.

call capture_open(lun)
! T11.1: a choice in another case gives the declared spelling
call run('--scheme WENO5')
s = text_of('--scheme', error)
call assert(trim(s) == 'weno5' .and. error == 0, 'choice WENO5: declared spelling weno5')
call run('--scheme Muscl')
s = text_of('--scheme', error)
call assert(trim(s) == 'muscl' .and. error == 0, 'choice Muscl: declared spelling muscl')
call run('--schemes MUSCL Weno5')
call assert_equal(list_of('--schemes', error), 'muscl weno5', 'list of choices: declared spellings')
call assert_equal(error, 0_I4P, 'list of choices: no error')
call run('--pair MUSCL WENO5')
call assert_equal(pair_of('--pair', error), 'muscl weno5', 'fixed-size list of choices: declared spellings')
call assert_equal(error, 0_I4P, 'fixed-size list of choices: no error')
! T11.2: no match: the error lists the declared choices
call run('--scheme weno7')
s = text_of('--scheme', error)
call assert_equal(error, ERROR_NOT_IN_CHOICES, 'choice weno7: not in choices')
out = read_back(lun)
call assert_contains(out, 'weno5,muscl', 'not in choices: the declared choices are listed')
! T11.3: case-sensitive by default
call run('--mode FAST')
s = text_of('--mode', error)
call assert_equal(error, ERROR_NOT_IN_CHOICES, 'case-sensitive choice: FAST is not fast')
call define
call cli%parse(args='--MESH m.grd', error=error)
call assert_equal(error, ERROR_UNKNOWN, 'case-sensitive switch: --MESH is unknown')
call define
call cli%parse(args='COMPILE', error=error)
call assert(error /= 0, 'case-sensitive command: COMPILE is not compile')
! T11.4: switches in any case
call run('--MESH m.grd', nocase=.true.)
s = text_of('--mesh', error)
call assert(trim(s) == 'm.grd' .and. error == 0, '--MESH matches --mesh')
call run('--Mesh=ABC', nocase=.true.)
s = text_of('--MESH', error)
call assert(trim(s) == 'ABC' .and. error == 0, 'inline --Mesh=ABC: the value keeps its case; get by --MESH')
call run('-M x', nocase=.true.)
s = text_of('-m', error)
call assert(trim(s) == 'x' .and. error == 0, '-M matches -m')
call run('--NO-RESTART', nocase=.true.)
v = flag_of('--restart', error)
call assert(.not.v .and. error == 0, '--NO-RESTART matches the negation')
call assert(cli%is_passed(switch='--Restart'), 'is_passed in any case')
call run('--list 1 --MESH m', nocase=.true.)
s = text_of('--mesh', error)
call assert(trim(s) == 'm' .and. error == 0, 'the look-ahead of a list stops at --MESH')
call run('--mode FAST', nocase=.true.)
s = text_of('--mode', error)
call assert_equal(error, ERROR_NOT_IN_CHOICES, 'case_insensitive leaves the choices case-sensitive (D7)')
call define(nocase=.true., standalone=.false.)
call cli%parse(args='--HELP', error=error)
call assert_equal(error, STATUS_PRINT_H, '--HELP is the help')
out = read_back(lun)
! T11.5: commands in any case
call run('COMPILE --Opt 3', nocase=.true.)
call assert(cli%run_command('compile'), 'COMPILE runs compile')
call assert(cli%run_command('Compile'), 'run_command in any case')
s = text_of('--opt', error, group='COMPILE')
call assert(trim(s) == '3' .and. error == 0, 'the option of COMPILE')
! T11.6: switches differing only by case
call define(nocase=.true.)
call cli%add(switch='--Mesh', help='clash', required=.false., act='store', def='', error=error)
call assert_equal(error, ERROR_GROUP_CONSISTENCY, '--mesh and --Mesh: consistency error')
call define
call cli%add(switch='--Mesh', help='no clash', required=.false., act='store', def='', error=error)
call assert_equal(error, 0_I4P, '--mesh and --Mesh, case-sensitive: two options')
out = read_back(lun)
call capture_close(lun)

contains
  subroutine define(nocase, standalone)
  !< Define the CLI.
  logical, intent(in), optional :: nocase     !< Case-insensitive switches and commands.
  logical, intent(in), optional :: standalone !< Stop after help/version.

  call cli%init(progname='flap_test_case_insensitive', error_lun=lun, usage_lun=lun, error_hint=.false., &
                case_insensitive=nocase, standalone=standalone)
  call cli%add(switch='--scheme', help='scheme', required=.false., act='store', def='muscl', choices='weno5,muscl', &
               case_sensitive=.false., error=error)
  call assert_equal(error, 0_I4P, 'add --scheme')
  call cli%add(switch='--schemes', help='schemes', required=.false., act='store', nargs='+', def='muscl', &
               choices='weno5,muscl', case_sensitive=.false., error=error)
  call cli%add(switch='--pair', help='pair', required=.false., act='store', nargs='2', def='muscl muscl', &
               choices='weno5,muscl', case_sensitive=.false., error=error)
  call cli%add(switch='--mode', help='mode', required=.false., act='store', def='fast', choices='fast,slow', error=error)
  call cli%add(switch='--mesh', switch_ab='-m', help='mesh', required=.false., act='store', def='', error=error)
  call cli%add(switch='--restart', switch_neg='--no-restart', help='restart', required=.false., act='store_true', &
               def='.true.', error=error)
  call cli%add(switch='--list', help='list', required=.false., act='store', nargs='*', def='', error=error)
  call cli%add(group='compile', switch='--opt', help='optimization', required=.false., act='store', def='0', error=error)
  call assert_equal(error, 0_I4P, 'add the options')
  endsubroutine define

  subroutine run(args, nocase)
  !< Define the CLI and parse a command line.
  character(*), intent(in)           :: args   !< Command line.
  logical,      intent(in), optional :: nocase !< Case-insensitive switches and commands.

  call define(nocase=nocase)
  call cli%parse(args=args, error=error)
  call assert_equal(error, 0_I4P, 'parse "'//args//'"')
  endsubroutine run

  function text_of(switch, e, group) result(val)
  !< Value of a character option.
  character(*), intent(in)           :: switch !< Switch.
  integer(I4P), intent(out)          :: e      !< Error.
  character(*), intent(in), optional :: group  !< Group.
  character(99)                      :: val    !< Value.

  val = ''
  call cli%get(switch=switch, val=val, error=e, group=group)
  endfunction text_of

  function flag_of(switch, e) result(val)
  !< Value of a flag.
  character(*), intent(in)  :: switch !< Switch.
  integer(I4P), intent(out) :: e      !< Error.
  logical                   :: val    !< Value.

  val = .true.
  call cli%get(switch=switch, val=val, error=e)
  endfunction flag_of

  function list_of(switch, e) result(joined)
  !< Values of a varying character list, blank separated.
  character(*), intent(in)      :: switch  !< Switch.
  integer(I4P), intent(out)     :: e       !< Error.
  character(len=:), allocatable :: joined  !< Values.
  character(20), allocatable    :: vals(:) !< Values.
  integer(I4P)                  :: i       !< Counter.

  joined = ''
  call cli%get_varying(switch=switch, val=vals, error=e)
  if (e /= 0) return
  do i=1, size(vals, dim=1)
    joined = joined//trim(vals(i))
    if (i < size(vals, dim=1)) joined = joined//' '
  enddo
  endfunction list_of

  function pair_of(switch, e) result(joined)
  !< Values of a fixed-size character list of 2, blank separated.
  character(*), intent(in)      :: switch  !< Switch.
  integer(I4P), intent(out)     :: e       !< Error.
  character(len=:), allocatable :: joined  !< Values.
  character(20)                 :: vals(2) !< Values.

  joined = ''
  call cli%get(switch=switch, val=vals, error=e)
  if (e == 0) joined = trim(vals(1))//' '//trim(vals(2))
  endfunction pair_of
endprogram flap_test_case_insensitive

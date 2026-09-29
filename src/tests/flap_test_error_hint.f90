!< Error hint: a failed parse ends with "Try 'prog --help' for help." (issue #125, step 1.2; #113-3).
program flap_test_error_hint
!< Error hint: a failed parse ends with "Try 'prog --help' for help." (issue #125, step 1.2; #113-3).
!<
!< Every scenario uses a fresh CLI whose error output is captured.
use flap, only : command_line_interface, ERROR_MISSING_REQUIRED, ERROR_UNKNOWN, ERROR_UNKNOWN_CLAS_IGNORED, STATUS_PRINT_H, &
                 STATUS_PRINT_V
use flap_test_utils, only : assert, assert_equal, capture_close, capture_open, read_back
use flap_utils_m, only : count
use penf, only : I4P

implicit none
character(*), parameter   :: HINT = "Try 'prog --help' for help." !< Hint of the top level.
character(:), allocatable :: out                                  !< Captured output.
integer(I4P)              :: lun                                  !< Capture unit.

call capture_open(lun)

! T3.1 unknown switch: the hint is the last line
call check('--bogus', ERROR_UNKNOWN, out)
call assert_equal(last_line(out), HINT, 'unknown switch: last line is the hint')
! T3.2 missing required option: the hint is the last line
call check('', ERROR_MISSING_REQUIRED, out, required=.true.)
call assert_equal(last_line(out), HINT, 'missing required: last line is the hint')
! T3.3 error inside a command: the hint names it
call check('commit --bogus', ERROR_UNKNOWN, out)
call assert_equal(last_line(out), "Try 'prog commit --help' for help.", 'error in a command: the hint names it')
! T3.4 no help option: no hint
call check('--bogus', ERROR_UNKNOWN, out, disable_hv=.true.)
call assert(index(out, "Try '") == 0, 'disable_hv: no hint')
! T3.5 opt-out
call check('--bogus', ERROR_UNKNOWN, out, error_hint=.false.)
call assert(index(out, "Try '") == 0, 'error_hint=.false.: no hint')
! T3.6 successful parse: nothing is written
call check('-i 3', 0_I4P, out)
call assert_equal(int(len(out), I4P), 0_I4P, 'successful parse: nothing written')
! T3.7 unknown switch ignored: no hint
call check('--bogus', ERROR_UNKNOWN_CLAS_IGNORED, out, ignore_unknown_clas=.true.)
call assert(index(out, "Try '") == 0, 'ignored unknown switch: no hint')
! T3.8 statuses: no hint
call check('--help', STATUS_PRINT_H, out)
call assert(index(out, "Try '") == 0, '--help: no hint')
call check('--version', STATUS_PRINT_V, out)
call assert(index(out, "Try '") == 0, '--version: no hint')
! T3.9 a single hint, also when the usage is printed with the error
call check('', ERROR_MISSING_REQUIRED, out, required=.true.)
call assert_equal(count(out, "Try '"), 1_I4P, 'missing required: exactly one hint')

call capture_close(lun)

contains
  subroutine check(args, expected, out, required, disable_hv, error_hint, ignore_unknown_clas)
  !< Define a CLI with a command, parse a command line without stopping, check the error and return the output.
  character(*),              intent(in)           :: args                !< Command line.
  integer(I4P),              intent(in)           :: expected            !< Expected error or status.
  character(:), allocatable, intent(out)          :: out                 !< Captured output.
  logical,                   intent(in), optional :: required            !< Add a required option (not passed).
  logical,                   intent(in), optional :: disable_hv          !< No help/version options.
  logical,                   intent(in), optional :: error_hint          !< Print the hint.
  logical,                   intent(in), optional :: ignore_unknown_clas !< Ignore unknown arguments.
  type(command_line_interface)                    :: cli                 !< Command Line Interface (CLI).
  integer(I4P)                                    :: error               !< Error trapping flag.

  call cli%init(progname='prog', version='v1', standalone=.false., usage_lun=lun, version_lun=lun, error_lun=lun, &
                disable_hv=disable_hv, error_hint=error_hint, ignore_unknown_clas=ignore_unknown_clas)
  call cli%add(switch='--int', switch_ab='-i', help='an integer', required=.false., act='store', def='1', error=error)
  if (present(required)) then
    if (required) call cli%add(switch='--must', help='required', required=.true., act='store', error=error)
  endif
  call cli%add_group(group='commit', description='commit changes')
  call cli%add(group='commit', switch='--message', help='message', required=.false., act='store', def='m', error=error)
  out = read_back(lun) ! drop the output of the definitions
  call cli%parse(args=args, error=error)
  call assert_equal(error, expected, 'parse "'//args//'": error')
  out = read_back(lun)
  endsubroutine check

  function last_line(text) result(line)
  !< Return the last non-empty line of a text.
  character(*), intent(in)  :: text !< Text.
  character(:), allocatable :: line !< Last non-empty line.
  integer(I4P)              :: e    !< End of the line.
  integer(I4P)              :: b    !< Start of the line.

  e = len(text)
  do while (e > 0)
    if (text(e:e) /= new_line('a') .and. text(e:e) /= ' ') exit
    e = e - 1
  enddo
  b = index(text(1:e), new_line('a'), back=.true.) + 1
  line = text(b:e)
  endfunction last_line
endprogram flap_test_error_hint

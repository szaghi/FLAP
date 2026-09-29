!< A second parse is ignored; reset_parse allows parsing again without redefining the CLI (issue #125, B13).
program flap_test_reparse
!< A second parse is ignored; reset_parse allows parsing again without redefining the CLI (issue #125, B13).
use flap, only : command_line_interface, ERROR_UNKNOWN
use flap_test_utils, only : assert, assert_equal, capture_close, capture_open
use penf, only : I4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
character(99)                :: s     !< Value of --s.
integer(I4P)                 :: x     !< Value of --x.
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.

call capture_open(lun)
call cli%init(progname='flap_test_reparse', error_lun=lun, usage_lun=lun)
call cli%add(switch='--s', switch_ab='-s', help='a string', required=.true., act='store', error=error)
call cli%add(switch='--x', help='an integer', required=.false., act='store', def='7', error=error)
call cli%add_group(group='new', description='a command')

call cli%parse(args='-s a --x 1', error=error)
call assert_equal(error, 0_I4P, 'first parse')
call assert(cli%is_parsed(), 'is_parsed after parse')
call cli%parse(args='-s b', error=error)
call assert_equal(error, 0_I4P, 'second parse without reset: no error')
call cli%get(switch='-s', val=s, error=error)
call assert_equal(s, 'a', 'second parse without reset is ignored: values of the first one')

call cli%reset_parse
call assert(.not.cli%is_parsed(), 'is_parsed after reset_parse')
call cli%parse(args='-s b', error=error)
call assert_equal(error, 0_I4P, 'parse after reset_parse')
call cli%get(switch='-s', val=s, error=error)
call assert_equal(s, 'b', 'parse after reset_parse: new value')
call assert_equal(cli%is_passed(switch='--x'), .false., 'parse after reset_parse: --x no longer passed')
call cli%get(switch='--x', val=x, error=error)
call assert_equal(x, 7_I4P, 'parse after reset_parse: --x back to its default')

call cli%reset_parse
call cli%parse(args='-s c new', error=error)
call assert_equal(cli%run_command('new'), .true., 'command called')
call cli%reset_parse
call cli%parse(args='-s c', error=error)
call assert_equal(cli%run_command('new'), .false., 'command no longer called after reset_parse')

call cli%reset_parse
call cli%parse(args='-s d --bogus', error=error)
call assert_equal(error, ERROR_UNKNOWN, 'failing parse')
call cli%reset_parse
call cli%parse(args='-s e', error=error)
call assert_equal(error, 0_I4P, 'parse after a failed parse and reset_parse')
call cli%get(switch='-s', val=s, error=error)
call assert_equal(error, 0_I4P, 'get after a failed parse and reset_parse: no stale error')
call assert_equal(s, 'e', 'get after a failed parse and reset_parse: value')

call capture_close(lun)
endprogram flap_test_reparse

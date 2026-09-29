!< The base object: examples (issue #125, B15) and the error prefix shared by every error message (step 0.D.4).
program flap_test_object
!< The base object: examples (issue #125, B15) and the error prefix shared by every error message (step 0.D.4).
use flap, only : command_line_argument, command_line_interface, ERROR_GROUP_CONSISTENCY, ERROR_MISSING_CLA, &
                 ERROR_NOT_IN_CHOICES
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use penf, only : I4P

implicit none
type(command_line_argument)  :: a     !< Source object.
type(command_line_argument)  :: b     !< Copy.
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
integer(I4P)                 :: i     !< Value.
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.

call a%set_examples(['prog --one', 'prog --two'])
call assert(allocated(a%examples), 'set_examples: allocated')
call assert_equal(int(size(a%examples), I4P), 2_I4P, 'set_examples: size')

call a%set_examples(['prog --three'])
call assert_equal(int(size(a%examples), I4P), 1_I4P, 'set_examples called again: replaces the examples')
call assert_equal(a%examples(1), 'prog --three', 'set_examples called again: value')

call a%set_examples()
call assert(.not.allocated(a%examples), 'set_examples without examples: none')

call a%set_examples(['prog --four'])
call b%assign_object(a)
call assert(allocated(b%examples), 'assign_object: examples copied')
call assert_equal(b%examples(1), 'prog --four', 'assign_object: value')

call a%free_object
call assert(.not.allocated(a%examples), 'free_object: examples freed')

! the error prefix: pref, program name, 'error'
a%progname = 'prog'
a%error_color = ''
a%error_style = ''
call assert_equal(a%error_prefix(pref='PFX '), 'PFX prog: error', 'error_prefix with pref')
call assert_equal(a%error_prefix(), 'prog: error', 'error_prefix without pref')

! every level prefixes its messages the same way: argument, group, interface
call capture_open(lun)
call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
call cli%add(pref='PFX ', switch='--c', help='c', required=.false., act='store', def='1', choices='1,2', error=error)
call cli%add(pref='PFX ', switch='--d', switch_ab='--c', help='d', required=.false., act='store', def='1', error=error)
call assert_equal(error, ERROR_GROUP_CONSISTENCY, 'group error')
call assert_contains(read_back(lun), 'PFX prog: error: consistency error', 'group error: prefix')
call cli%free
call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
call cli%add(pref='PFX ', switch='--c', help='c', required=.false., act='store', def='1', choices='1,2', error=error)
call cli%parse(pref='PFX ', args='--c 3', error=error)
call cli%get(pref='PFX ', switch='--c', val=i, error=error)
call assert_equal(error, ERROR_NOT_IN_CHOICES, 'argument error')
call assert_contains(read_back(lun), 'PFX prog: error: value of named option "--c" must be chosen in', 'argument error: prefix')
call cli%get(pref='PFX ', switch='--nope', val=i, error=error)
call assert_equal(error, ERROR_MISSING_CLA, 'interface error')
call assert_contains(read_back(lun), 'PFX prog: error: there is no option "--nope"', 'interface error: prefix')
call capture_close(lun)
endprogram flap_test_object

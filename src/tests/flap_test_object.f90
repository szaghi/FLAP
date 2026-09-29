!< The base object handles its examples in free_object, assign_object and set_examples (issue #125, B15).
program flap_test_object
!< The base object handles its examples in free_object, assign_object and set_examples (issue #125, B15).
use flap, only : command_line_argument
use flap_test_utils, only : assert, assert_equal
use penf, only : I4P

implicit none
type(command_line_argument) :: a !< Source object.
type(command_line_argument) :: b !< Copy.

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
endprogram flap_test_object

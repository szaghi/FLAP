!< The renderers of an argument: usage text, completion words, completion values (issue #125, step 0.D.5).
program flap_test_signature
!< The renderers of an argument: usage text, completion words, completion values (issue #125, step 0.D.5).
!<
!< A rendering change of the usage text (metavar, ellipsis, negation) must never reach the bash word lists: each output has its
!< own renderer, and signature dispatches to them.
use flap, only : command_line_argument
use flap_test_utils, only : assert, assert_contains, assert_equal

implicit none
type(command_line_argument) :: opt  !< Option with choices.
type(command_line_argument) :: flag !< Flag.
type(command_line_argument) :: pos  !< Positional.
type(command_line_argument) :: hid  !< Hidden option.

opt%switch = '--out'
opt%switch_ab = '-o'
opt%act = 'STORE'
opt%def = 'a'
opt%choices = 'a,b'
call assert_equal(opt%signature_usage(), ' [--out value]', 'option: usage')
call assert_equal(opt%completion_words(), ' --out -o', 'option: completion words')
call assert_contains(opt%completion_values(), 'if [ "$prev" == "--out" ] || [ "$prev" == "-o" ] ; then', 'option: values test')
call assert_contains(opt%completion_values(), 'COMPREPLY=( $( compgen -W "a b" -- $cur ) )', 'option: values are the choices')
call assert_equal(opt%signature(), opt%signature_usage(), 'option: signature dispatches to the usage')
call assert_equal(opt%signature(bash_completion=.true., plain=.true.), opt%completion_words(), 'option: to the words')
call assert_equal(opt%signature(bash_completion=.true.), opt%completion_values(), 'option: to the values')

flag%switch = '--verbose'
flag%switch_ab = '--verbose'
flag%act = 'STORE_TRUE'
flag%def = '.false.'
call assert_equal(flag%signature_usage(), ' [--verbose]', 'flag: usage')
call assert_equal(flag%completion_words(), ' --verbose', 'flag: completion words, the switch once')

pos%is_positional = .true.
pos%position = 1
pos%act = 'STORE'
pos%is_required = .true.
call assert_equal(pos%signature_usage(), ' value', 'positional: usage')
call assert_equal(pos%completion_words(), '', 'positional: no completion words')
call assert_equal(pos%completion_values(), '', 'positional: no completion values')

hid = opt
hid%is_hidden = .true.
call assert_equal(hid%signature_usage(), '', 'hidden: no usage')
call assert_equal(hid%completion_words(), '', 'hidden: no completion words')
call assert_equal(hid%completion_values(), '', 'hidden: no completion values')
call assert(len(hid%signature()) == 0, 'hidden: empty signature')
endprogram flap_test_signature

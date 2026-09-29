!< One matcher for switch names: match_token of a CLA and is_switch_token of a group (issue #125, step 0.D.1, D1 rule 1).
program flap_test_match_token
!< One matcher for switch names: match_token of a CLA and is_switch_token of a group (issue #125, step 0.D.1, D1 rule 1).
!<
!< Rule 1 is an exact match of the switch or of its abbreviation; blanks around the token are not significant.
use flap, only : command_line_argument, command_line_arguments_group
use flap_test_utils, only : assert

implicit none
type(command_line_argument)        :: cla   !< Named CLA.
type(command_line_argument)        :: pos   !< Positional CLA.
type(command_line_argument)        :: bare  !< Named CLA without an abbreviation.
type(command_line_arguments_group) :: group !< Group.

cla%switch = '--verbose'
cla%switch_ab = '-v'
call assert(cla%match_token('--verbose'), 'switch matches')
call assert(cla%match_token('-v'), 'abbreviation matches')
call assert(cla%match_token('--verbose   '), 'trailing blanks are not significant')
call assert(cla%match_token('  -v'), 'leading blanks are not significant')
call assert(.not.cla%match_token('--verb'), 'a prefix does not match')
call assert(.not.cla%match_token('--verbose-more'), 'a longer name does not match')
call assert(.not.cla%match_token('--Verbose'), 'the match is case sensitive')
call assert(.not.cla%match_token('--verbose=1'), 'NAME=VALUE does not match (rule 2 is not implemented)')
call assert(.not.cla%match_token('-vv'), 'the compact count form does not match (rule 3 is not implemented)')
call assert(.not.cla%match_token(''), 'an empty token does not match')

bare%switch = '--bare'
call assert(bare%match_token('--bare'), 'switch without abbreviation matches')
call assert(.not.bare%match_token(''), 'switch without abbreviation: an empty token does not match')

pos%is_positional = .true.
pos%position = 1
call assert(.not.pos%match_token(''), 'a positional never matches: empty token')
call assert(.not.pos%match_token('1'), 'a positional never matches: its position')

group%cla = [cla, pos] ! set directly: add would run the consistency checks, not under test here
group%Na = 2
call assert(group%is_switch_token('--verbose'), 'group: switch is a switch token')
call assert(group%is_switch_token(' -v '), 'group: abbreviation with blanks is a switch token')
call assert(.not.group%is_switch_token('--other'), 'group: undefined switch is not a switch token')
call assert(.not.group%is_switch_token('value'), 'group: a value is not a switch token')
call assert(.not.group%is_switch_token(''), 'group: an empty argument is not a switch token')
endprogram flap_test_match_token

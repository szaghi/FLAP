!< "Did you mean ...?" suggestions for unknown switches and commands (issue #125, step 3.5; #11 7.1-7.2, T7.1-T7.6).
program flap_test_suggest
!< "Did you mean ...?" suggestions for unknown switches and commands (issue #125, step 3.5; #11 7.1-7.2, T7.1-T7.6).
!<
!< An unknown argument gets up to three suggestions, the names with similarity 1 - d/max(len) >= 0.6 (d the Levenshtein
!< distance), most similar first: the visible switches, abbreviations and negations of the group being parsed, plus the
!< command names and aliases at the top level. Hidden switches are never suggested.
use flap, only : command_line_interface, ERROR_UNKNOWN
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, read_back
use flap_utils_m, only : levenshtein
use penf, only : I4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
character(:), allocatable    :: out   !< Captured output.
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.

! levenshtein
call assert_equal(levenshtein('kitten', 'sitting'), 3_I4P, 'levenshtein kitten/sitting')
call assert_equal(levenshtein('', ''), 0_I4P, 'levenshtein of empty strings')
call assert_equal(levenshtein('', 'abc'), 3_I4P, 'levenshtein empty/abc')
call assert_equal(levenshtein('abc', ''), 3_I4P, 'levenshtein abc/empty')
call assert_equal(levenshtein('flap', 'flap'), 0_I4P, 'levenshtein of identical strings')
call assert_equal(levenshtein('--mas', '--mach'), 2_I4P, 'levenshtein --mas/--mach')

call capture_open(lun)
! T7.1, T7.6: one suggestion, the exact message
out = run('--verbse')
call assert_equal(error, ERROR_UNKNOWN, '--verbse: unknown')
call assert_equal(first_line(out), 'flap_test_suggest: error: switch "--verbse" is unknown! Did you mean "--verbose"?', &
                  '--verbse: message')
! T7.2: several, most similar first
out = run('--mas 3')
call assert_equal(first_line(out), &
                  'flap_test_suggest: error: switch "--mas" is unknown! (Did you mean one of: "--mass", "--mach"?)', &
                  '--mas: two suggestions, in order')
! T7.3: nothing close
out = run('--zzzzzzzz')
call assert_equal(first_line(out), 'flap_test_suggest: error: switch "--zzzzzzzz" is unknown!', 'nothing close')
! T7.4: a hidden switch is never suggested
out = run('--secre')
call assert(index(out, 'Did you mean') == 0, 'hidden --secret not suggested')
! T7.5: a command name, and an alias
out = run('comit')
call assert_contains(out, 'switch "comit" is unknown! Did you mean "commit"?', 'command suggestion')
out = run('chekout')
call assert_contains(out, 'Did you mean "checkout"?', 'command suggestion: checkout')
out = run('chx')
call assert_contains(out, 'Did you mean "chk"?', 'alias suggestion')
! the switches of the command being parsed, its negations included; an inline value is not part of the name
out = run('commit --mesage=x')
call assert_contains(out, 'switch "--mesage=x" is unknown! Did you mean "--message"?', 'switch of the command, inline')
out = run('commit --no-amnd')
call assert_contains(out, 'Did you mean "--no-amend"?', 'negation suggested')
! at most three, in declaration order among equals
out = run('--xyz')
call assert_contains(out, '(Did you mean one of: "--xyz1", "--xyz2", "--xyz3"?)', 'at most three')
call capture_close(lun)

contains
  function run(args) result(output)
  !< Define the CLI, parse a command line and return the captured output.
  character(*), intent(in)      :: args   !< Command line.
  character(len=:), allocatable :: output !< Captured output.

  call cli%init(progname='flap_test_suggest', error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--verbose', help='verbose', required=.false., act='store_true', def='.false.', error=error)
  call cli%add(switch='--mass', help='mass', required=.false., act='store', def='1', error=error)
  call cli%add(switch='--mach', help='mach', required=.false., act='store', def='1', error=error)
  call cli%add(switch='--secret', help='secret', required=.false., act='store', def='1', hidden=.true., error=error)
  call cli%add(switch='--xyz1', help='x', required=.false., act='store', def='1', error=error)
  call cli%add(switch='--xyz2', help='x', required=.false., act='store', def='1', error=error)
  call cli%add(switch='--xyz3', help='x', required=.false., act='store', def='1', error=error)
  call cli%add(switch='--xyz4', help='x', required=.false., act='store', def='1', error=error)
  call cli%add_group(group='commit', description='commit', error=error)
  call cli%add(group='commit', switch='--message', help='message', required=.false., act='store', def='', error=error)
  call cli%add(group='commit', switch='--amend', switch_neg='--no-amend', help='amend', required=.false., &
               act='store_true', def='.false.', error=error)
  call cli%add_group(group='checkout', aliases='chk', description='checkout', error=error)
  call assert_equal(error, 0_I4P, 'define')
  call cli%parse(args=args, error=error)
  output = read_back(lun)
  endfunction run

  function first_line(text) result(line)
  !< First line of a text.
  character(*), intent(in)      :: text !< Text.
  character(len=:), allocatable :: line !< First line.
  integer(I4P)                  :: e    !< End of the line.

  e = index(text, new_line('a'))
  if (e == 0) then
    line = text
  else
    line = text(:e-1)
  endif
  endfunction first_line
endprogram flap_test_suggest

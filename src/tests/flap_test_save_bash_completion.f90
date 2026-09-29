!< Test `save_bash_completion` method.
program flap_test_save_bash_completion
!< Test `save_bash_completion` method.
!<
!< Run with arguments it is the example program above; run without arguments it checks its own scenarios.

use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, delete_file, read_file, &
                            run_command, scratch_file, write_file
use penf

implicit none
integer(I4P) :: lun !< Capture unit for FLAP messages in self-test mode.

if (command_argument_count() > 0) then
  call example
else
  call self_test
endif

contains
  subroutine example()
  !< The example program: parse the real command line and save the completion script in the current directory.
  type(command_line_interface) :: cli                                             !< Command Line Interface (CLI).
  character(37)                :: bash_file='flap_test_save_bash_completion.bash' !< Bash script file name.

  call define_cli(cli)
  call cli%parse
  call cli%save_bash_completion(bash_file=trim(bash_file))
  endsubroutine example

  subroutine define_cli(cli)
  !< Define the example CLI.
  type(command_line_interface), intent(out) :: cli !< Command Line Interface (CLI).

  call cli%init(progname='flap_test_save_bash_completion')
  call cli%add(switch_ab='-b',  required=.false., act='store', def='no', choices='yes,no')
  call cli%add_group(group='compile', description='compile sources')
  call cli%add_group(group='clean',   description='clean compiled objects')
  call cli%add(group='compile', switch='--compiler', switch_ab='-c', required=.false., act='store', def='gnu')
  call cli%add(group='compile', switch='--flags', switch_ab='-f', required=.false., act='store', def='-O2')
  call cli%add(group='clean', switch='--clean', switch_ab='-c', required=.false., act='store_true', def='.false.')
  call cli%add(group='clean', switch='--clean-all', switch_ab='-ca', required=.false., act='store_true', def='.false.')
  call cli%add(group='compile', positional=.true., position=1, required=.false., def='1.0')
  call cli%add(group='compile', switch='--integer', switch_ab='-i', required=.false., act='store', def='1', choices='1,3,5')
  call cli%add(group='compile', switch='--real', required=.false., act='store', def='1.0', choices='1.,2.')
  endsubroutine define_cli

  subroutine self_test()
  !< The saved script is valid bash and completes switches, group names and choices.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  character(:), allocatable    :: script   !< Completion script path.
  character(:), allocatable    :: text     !< Completion script.
  character(:), allocatable    :: out      !< Command output.
  integer(I4P)                 :: exitstat !< Command exit status.
  integer(I4P)                 :: error    !< Error trapping flag.

  call capture_open(lun)
  call define_cli(cli)
  call cli%parse(args='', error=error)
  call assert_equal(error, 0_I4P, 'parse without arguments')
  script = scratch_file('bash')
  call cli%save_bash_completion(bash_file=script, error=error)
  call assert_equal(error, 0_I4P, 'save_bash_completion: error')
  text = read_file(script)
  call assert_contains(text, 'complete -F _completion flap_test_save_bash_completion', 'script registers the function')
  call assert_equal(text(1:19), '#!/usr/bin/env bash', 'shebang (B12)')

  call run_command("bash -n '"//script//"'", exitstat, out)
  call assert_equal(exitstat, 0_I4P, 'bash -n: '//out)

  out = complete(script, 'compile ""', 2_I4P)
  call assert_contains(out, '--compiler', 'compile <TAB>: offers --compiler')
  call assert_contains(out, '--integer', 'compile <TAB>: offers --integer')
  call assert(index(out, '--clean') == 0, 'compile <TAB>: does not offer the clean switches')
  ! B21 (#125): the group is detected only when the previous word is the group name, and kept in a global variable; so a
  ! group option value completes only after a TAB right after the group name, and a stale group leaks into the next command
  ! line. The first and the last assertions below pin the current behaviour and flip when B21 is fixed
  call assert(index(complete(script, 'compile --integer ""', 3_I4P), '1 3 5') == 0, &
              'compile --integer <TAB> in a fresh shell: choices not offered (B21, current behaviour)')
  call assert_equal(complete(script, 'compile --integer ""', 3_I4P, prime='compile ""', prime_cword=2_I4P), '1 3 5', &
                    'compile --integer <TAB> after compile <TAB>: choices')
  call assert_equal(complete(script, 'compile --real ""', 3_I4P, prime='compile ""', prime_cword=2_I4P), '1. 2.', &
                    'compile --real <TAB> after compile <TAB>: choices')
  call assert_equal(complete(script, 'compile --compiler ""', 3_I4P, prime='compile ""', prime_cword=2_I4P), '', &
                    'compile --compiler <TAB> after compile <TAB>: free value, no words')
  call assert_equal(complete(script, 'clean --clean --cl', 3_I4P, prime='compile ""', prime_cword=2_I4P), '', &
                    'clean --clean --cl<TAB> after compile <TAB>: stale group (B21, current behaviour)')
  call assert_contains(complete(script, 'clean --cl', 2_I4P), '--clean-all', 'clean --cl<TAB>: offers --clean-all')
  out = complete(script, '""', 1_I4P)
  call assert_contains(out, 'compile', '<TAB>: offers the compile group')
  call assert_contains(out, 'clean', '<TAB>: offers the clean group')
  ! B18 (#125): the top-level completion offers bogus words; this assertion flips when B18 is fixed
  call assert_contains(out, 'COMPREPLY=(', '<TAB>: bogus words (B18, current behaviour)')

  call delete_file(script)

  ! B12 (#125): an unwritable file is reported through error, not a crash
  call cli%save_bash_completion(bash_file=scratch_file('no-such-dir/x.bash'), error=error)
  call assert(error /= 0, 'unwritable file: error reported')
  call capture_close(lun)
  endsubroutine self_test

  function complete(script, words, cword, prime, prime_cword) result(reply)
  !< Source the completion script in bash and return the words offered for a command line.
  character(*), intent(in)           :: script      !< Completion script path.
  character(*), intent(in)           :: words       !< Words after the program name, as bash source ("" is an empty word).
  integer(I4P), intent(in)           :: cword       !< Index of the word being completed.
  character(*), intent(in), optional :: prime       !< Words of an earlier completion in the same shell session.
  integer(I4P), intent(in), optional :: prime_cword !< Index of the word completed by the earlier completion.
  character(:), allocatable          :: reply       !< Offered words separated by blanks, without the trailing newline.
  character(:), allocatable          :: driver      !< Driver script path.
  character(:), allocatable          :: session     !< Driver script.
  character(11)                      :: buffer      !< Conversion buffer.
  integer(I4P)                       :: exitstat    !< Driver exit status.

  session = "source '"//script//"'"//new_line('a')
  if (present(prime)) then
    write(buffer, '(I0)') prime_cword
    session = session//'COMP_WORDS=(flap_test_save_bash_completion '//prime//')'//new_line('a')// &
                       'COMP_CWORD='//trim(buffer)//new_line('a')//'_completion'//new_line('a')
  endif
  write(buffer, '(I0)') cword
  session = session//'COMP_WORDS=(flap_test_save_bash_completion '//words//')'//new_line('a')// &
                     'COMP_CWORD='//trim(buffer)//new_line('a')//'_completion'//new_line('a')//  &
                     'echo "${COMPREPLY[*]}"'//new_line('a')
  driver = scratch_file('driver.bash')
  call write_file(driver, session)
  call run_command("bash '"//driver//"'", exitstat, reply)
  call assert_equal(exitstat, 0_I4P, 'completion driver: '//reply)
  call delete_file(driver)
  if (len(reply) > 0) reply = reply(1:len(reply)-1)
  endfunction complete
endprogram flap_test_save_bash_completion

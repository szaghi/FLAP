!< Golden baselines of FLAP generated outputs: help/usage, man page, markdown and bash completion.
program flap_test_golden
!< Golden baselines of FLAP generated outputs: help/usage, man page, markdown and bash completion.
!<
!< Every output of the two reference CLIs (the ones of `flap_test_nested` and `flap_test_group_examples`) is compared with a
!< file in the golden directory (`FLAP_TEST_GOLDEN_DIR`, default `src/tests/golden`). Dates are masked. Outputs are taken
!< both before and after `parse`, because some of them depend on it (#125, B09), and the `<group> --help` path is run in a
!< child process because it ends the program.
!<
!< To regenerate the baselines after an intended output change, run with `FLAP_TEST_GOLDEN_UPDATE=1` and review the diff.
use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_equal, child_case, delete_file, read_file, reinvoke, scratch_file, write_file
use penf, only : I4P

implicit none
character(:), allocatable :: golden_dir !< Directory of the golden files.
logical                   :: update     !< Regenerate the golden files instead of comparing.
integer(I4P)              :: mismatches !< Number of outputs differing from their golden file.

select case(child_case())
case(0)
  call setup
  call check_cli('nested', ['main  ', 'init  ', 'commit', 'tag   '])
  call check_cli('group_examples', ['main', 'gwe ', 'gne '])
  call check_help('nested', ['--help       ', 'init --help  ', 'commit --help', 'tag --help   '])
  call check_help('group_examples', ['--help    ', 'gwe --help', 'gne --help'])
  call assert_equal(mismatches, 0_I4P, 'outputs differing from their golden file (see the messages above)')
case(1)
  call run_child('nested')
case(2)
  call run_child('group_examples')
endselect

contains
  subroutine setup()
  !< Read the configuration from the environment.
  character(4096) :: buffer !< Environment variable value.
  integer(I4P)    :: status !< Retrieval status.

  call get_environment_variable('FLAP_TEST_GOLDEN_DIR', value=buffer, status=status)
  golden_dir = 'src/tests/golden'
  if (status == 0) golden_dir = trim(buffer)
  call get_environment_variable('FLAP_TEST_GOLDEN_UPDATE', value=buffer, status=status)
  update = .false.
  if (status == 0) update = trim(buffer) == '1'
  mismatches = 0
  endsubroutine setup

  subroutine define_cli(cli, name)
  !< Define one of the reference CLIs.
  type(command_line_interface), intent(out) :: cli   !< Command line interface.
  character(*),                 intent(in)  :: name  !< CLI name: 'nested' or 'group_examples'.
  integer(I4P)                              :: error !< Error trapping flag.

  select case(name)
  case('nested') ! same definitions as flap_test_nested
    call cli%init(progname    = 'test_nested',                                       &
                  version     = 'v2.1.5',                                            &
                  authors     = 'Stefano Zaghi',                                     &
                  license     = 'MIT',                                               &
                  description = 'Toy program for testing FLAP with nested commands', &
                  examples    = ['test_nested                      ',                &
                                 'test_nested -h                   ',                &
                                 'test_nested init                 ',                &
                                 'test_nested commit -m "fix bug-1"',                &
                                 'test_nested tag -a "v2.1.5"      '])
    call cli%add(switch='--authors', switch_ab='-a', help='Print authors names', required=.false., act='store_true', &
                 def='.false.', error=error)
    call assert_equal(error, 0_I4P, 'nested: add --authors')
    call cli%add_group(group='init', description='fake init versioning')
    call cli%add_group(group='commit', description='fake commit changes to current branch')
    call cli%add_group(group='tag', description='fake tag current commit')
    call cli%set_mutually_exclusive_groups(group1='init', group2='commit')
    call cli%add(group='commit', switch='--message', switch_ab='-m', help='Commit message', required=.false., act='store', &
                 def='', error=error)
    call assert_equal(error, 0_I4P, 'nested: add commit --message')
    call cli%add(group='tag', switch='--annotate', switch_ab='-a', help='Tag annotation', required=.false., act='store', &
                 def='', error=error)
    call assert_equal(error, 0_I4P, 'nested: add tag --annotate')
  case('group_examples') ! same definitions as flap_test_group_examples, with an explicit progname
    call cli%init(progname    = 'flap_test_group_examples',                                  &
                  description = 'group examples usage FLAP example',                         &
                  examples    = ["flap_test_group_examples -s 'test string'      ",          &
                                 "flap_test_group_examples --string 'test string'"])
    call cli%add(switch='--string', switch_ab='-s', help='String input', required=.false., act='store', def='test', &
                 error=error)
    call assert_equal(error, 0_I4P, 'group_examples: add --string')
    call cli%add_group(group='gwe', description='Group with examples',                       &
                       examples=["flap_test_group_examples gwe --integer 32",                &
                                 "flap_test_group_examples gwe -i 12       "])
    call cli%add(group='gwe', switch='--integer', switch_ab='-i', help='Integer input', required=.false., act='store', &
                 def='-1', error=error)
    call assert_equal(error, 0_I4P, 'group_examples: add gwe --integer')
    call cli%add_group(group='gne', description='Group without examples')
    call cli%add(group='gne', switch='--float', switch_ab='-f', help='Float input', required=.false., act='store', &
                 def='-1.0', error=error)
    call assert_equal(error, 0_I4P, 'group_examples: add gne --float')
  case default
    call assert(.false., 'define_cli: unknown CLI "'//name//'"')
  endselect
  endsubroutine define_cli

  subroutine check_cli(name, groups)
  !< Compare usage, man page, markdown and bash completion of a CLI, before and after parse.
  character(*), intent(in)     :: name      !< CLI name.
  character(*), intent(in)     :: groups(:) !< Group labels in definition order: 'main' (group 0), then the group names.
  type(command_line_interface) :: cli       !< Command line interface.
  integer(I4P)                 :: error     !< Error trapping flag.

  call define_cli(cli, name)
  call check_outputs(cli, name//'.unparsed', groups)
  call cli%parse(args='', error=error)
  call assert_equal(error, 0_I4P, name//': parse without arguments')
  call check_outputs(cli, name//'.parsed', groups)
  endsubroutine check_cli

  subroutine check_outputs(cli, prefix, groups)
  !< Compare every generated output of a CLI with its golden file.
  type(command_line_interface), intent(in) :: cli       !< Command line interface.
  character(*),                 intent(in) :: prefix    !< Golden files prefix.
  character(*),                 intent(in) :: groups(:) !< Group labels in definition order.
  integer(I4P)                             :: g         !< Group counter.
  integer(I4P)                             :: error     !< Error trapping flag.

  do g = 0, size(groups, kind=I4P) - 1
    call compare(cli%usage(g=g)//new_line('a'), prefix//'.usage-'//trim(groups(g+1))//'.txt')
  enddo
  call cli%save_man_page(man_file=scratch_file(prefix//'.man'), error=error)
  call assert_equal(error, 0_I4P, prefix//': save_man_page')
  call compare_file(scratch_file(prefix//'.man'), prefix//'.man')
  call cli%save_usage_to_markdown(markdown_file=scratch_file(prefix//'.md'), error=error)
  call assert_equal(error, 0_I4P, prefix//': save_usage_to_markdown')
  call compare_file(scratch_file(prefix//'.md'), prefix//'.md')
  call cli%save_bash_completion(bash_file=scratch_file(prefix//'.bash'), error=error)
  call assert_equal(error, 0_I4P, prefix//': save_bash_completion')
  call compare_file(scratch_file(prefix//'.bash'), prefix//'.bash')
  endsubroutine check_outputs

  subroutine check_help(name, args)
  !< Compare the help printed by `prog [group] --help` (run in a child process, because it ends the program).
  character(*), intent(in)  :: name     !< CLI name.
  character(*), intent(in)  :: args(:)  !< Command lines to run.
  character(:), allocatable :: out      !< Child standard output.
  character(:), allocatable :: err      !< Child standard error.
  integer(I4P)              :: exitstat !< Child exit status.
  integer(I4P)              :: case     !< Child scenario.
  integer(I4P)              :: a        !< Counter.

  case = 1
  if (name == 'group_examples') case = 2
  do a = 1, size(args, kind=I4P)
    call reinvoke(case, exitstat, out, err, args=trim(args(a)))
    call assert_equal(exitstat, 0_I4P, name//' '//trim(args(a))//': exit status (stderr: '//err//')')
    call compare(out//err, name//'.cli.'//label(trim(args(a)))//'.txt')
  enddo
  endsubroutine check_help

  subroutine run_child(name)
  !< Child scenario: define a reference CLI and parse the real command line.
  character(*), intent(in)     :: name  !< CLI name.
  type(command_line_interface) :: cli   !< Command line interface.
  integer(I4P)                 :: error !< Error trapping flag.

  call define_cli(cli, name)
  call cli%parse(error=error)
  endsubroutine run_child

  subroutine compare_file(path, golden)
  !< Compare a generated file with its golden file, then delete it.
  character(*), intent(in)  :: path   !< Generated file.
  character(*), intent(in)  :: golden !< Golden file name.
  character(:), allocatable :: text   !< Generated text.

  text = read_file(path)
  call delete_file(path)
  call compare(text, golden)
  endsubroutine compare_file

  subroutine compare(actual, golden)
  !< Compare a text with its golden file (dates masked); in update mode, rewrite the golden file.
  character(*), intent(in)  :: actual   !< Actual text.
  character(*), intent(in)  :: golden   !< Golden file name.
  character(:), allocatable :: text     !< Actual text with dates masked.
  character(:), allocatable :: expected !< Golden text.
  character(:), allocatable :: path     !< Golden file path.
  logical                   :: differ   !< The texts differ.

  text = mask_dates(actual)
  path = golden_dir//'/'//golden
  if (update) then
    call write_file(path, text)
    return
  endif
  expected = read_file(path)
  differ = len(text) /= len(expected)
  if (.not.differ) differ = text /= expected
  if (differ) then
    mismatches = mismatches + 1
    call write_file(scratch_file(golden//'.actual'), text)
    print '(A)', 'MISMATCH '//path//': '//first_difference(text, expected)
    print '(A)', '  actual output saved as '//scratch_file(golden//'.actual')
  endif
  endsubroutine compare

  function mask_dates(text) result(masked)
  !< Replace every "Mon YYYY" date (as written by the man page and markdown generators) with "<DATE>".
  character(*), intent(in)  :: text   !< Text to mask.
  character(:), allocatable :: masked !< Masked text.
  character(3), parameter   :: MONTHS(12) = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', &
                                             'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  integer(I4P)              :: i      !< Position in the text.
  logical                   :: date   !< A date starts at position i.

  masked = ''
  i = 1
  do while (i <= len(text))
    date = .false.
    if (i + 7 <= len(text)) then
      if (any(text(i:i+2) == MONTHS)) then
        if (text(i+3:i+3) == ' ') date = verify(text(i+4:i+7), '0123456789') == 0
      endif
    endif
    if (date) then
      masked = masked//'<DATE>'
      i = i + 8
    else
      masked = masked//text(i:i)
      i = i + 1
    endif
  enddo
  endfunction mask_dates

  function first_difference(actual, expected) result(report)
  !< Describe the first line where two texts differ.
  character(*), intent(in)  :: actual   !< Actual text.
  character(*), intent(in)  :: expected !< Expected text.
  character(:), allocatable :: report   !< Description of the difference.
  integer(I4P)              :: i        !< Character counter.
  integer(I4P)              :: line     !< Line counter.

  line = 1
  do i = 1, int(min(len(actual), len(expected)), I4P)
    if (actual(i:i) /= expected(i:i)) exit
    if (actual(i:i) == new_line('a')) line = line + 1
  enddo
  report = 'first difference at line '//integer_label(line)//                            &
           ' (actual '//integer_label(int(len(actual), I4P))//' characters, expected '// &
           integer_label(int(len(expected), I4P))//')'
  endfunction first_difference

  pure function label(args) result(alabel)
  !< File-name label of a command line: blanks become '_', leading dashes of each word are dropped.
  character(*), intent(in)  :: args   !< Command line.
  character(:), allocatable :: alabel !< Label.
  integer(I4P)              :: i      !< Counter.

  alabel = ''
  do i = 1, len(args)
    select case(args(i:i))
    case(' ')
      alabel = alabel//'_'
    case('-')
      if (i == 1) cycle
      if (args(i-1:i-1) == '-' .or. args(i-1:i-1) == ' ') cycle
      alabel = alabel//'-'
    case default
      alabel = alabel//args(i:i)
    endselect
  enddo
  endfunction label

  pure function integer_label(n) result(string)
  !< Convert an integer to a string without blanks.
  integer(I4P), intent(in)  :: n      !< Integer to convert.
  character(:), allocatable :: string !< Converted integer.
  character(11)             :: buffer !< Conversion buffer.

  write(buffer, '(I0)') n
  string = trim(buffer)
  endfunction integer_label
endprogram flap_test_golden

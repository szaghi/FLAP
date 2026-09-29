!< Test `save_usage_to_markdown` method.
program flap_test_save_usage_to_markdown
!< Test `save_usage_to_markdown` method.
!<
!< Run with arguments it is the example program above; run without arguments it checks its own scenarios.

use flap, only : command_line_interface
use flap_test_utils, only : assert_contains, assert_equal, capture_close, capture_open, delete_file, read_file, scratch_file
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
  !< The example program: parse the real command line and save the markdown usage.
  type(command_line_interface) :: cli !< Command Line Interface (CLI).
  character(99)                :: md  !< Markdown file name.

  call define_cli(cli)
  call cli%get(switch='-m',    val=md)
  call cli%save_usage_to_markdown(markdown_file=trim(md))
  endsubroutine example

  subroutine define_cli(cli)
  !< Define the example CLI.
  type(command_line_interface), intent(out) :: cli !< Command Line Interface (CLI).

  call cli%init(progname='flap_save_usage_to_markdown',                 &
                version='1.1.2',                                        &
                authors='Batman and Robin',                             &
                license='GPL v3',                                       &
                description = 'FLAP test save man page',                &
                examples=['flap_save_usage_to_markdown                       ', &
                          'flap_save_usage_to_markdown -m test.md -i 4       ', &
                          'flap_save_usage_to_markdown 3.2 -m test.md        ', &
                          'flap_save_usage_to_markdown -1.5 -m test.md -i 102'])
  call cli%add(switch='--md',      switch_ab='-m', help='markdown file name', required=.false., act='store', def='test.md')
  call cli%add(switch='--integer', switch_ab='-i', help='a integer',          required=.false., act='store', def='2'      )
  call cli%add(positional=.true.,position=1,       help='a positional real',  required=.false.,              def='1.0'    )
  endsubroutine define_cli

  subroutine self_test()
  !< The markdown page has the title, the signature, the options as a list with hard line breaks, and the examples.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  character(:), allocatable    :: md    !< Markdown file path.
  character(:), allocatable    :: text  !< Markdown page.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call define_cli(cli)
  call cli%parse(args='', error=error)
  call assert_equal(error, 0_I4P, 'parse without arguments')
  md = scratch_file('md')
  call cli%save_usage_to_markdown(markdown_file=md, error=error)
  call assert_equal(error, 0_I4P, 'save_usage_to_markdown: error')
  text = read_file(md)
  call assert_contains(text, '# flap_save_usage_to_markdown'//new_line('a'), 'title')
  call assert_contains(text, 'Manual page for `flap_save_usage_to_markdown` version 1.1.2', 'subtitle')
  call assert_contains(text, '`flap_save_usage_to_markdown [value] [--md value] [--integer value] '// &
                       '[--help] [--markdown] [--version]`', 'signature')
  call assert_contains(text, '### Short description'//new_line('a')//new_line('a')//'FLAP test save man page', 'description')
  call assert_contains(text, '* `--integer value`, `-i value`    '//new_line('a')//'    default value 2  '//new_line('a')// &
                       '    a integer  ', 'option item with markdown hard line breaks')
  call assert_contains(text, '### Examples', 'examples section')
  call assert_contains(text, 'flap_save_usage_to_markdown -1.5 -m test.md -i 102', 'examples content')
  call delete_file(md)
  call capture_close(lun)
  endsubroutine self_test
endprogram flap_test_save_usage_to_markdown

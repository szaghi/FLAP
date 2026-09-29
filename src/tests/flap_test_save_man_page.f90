!< Test `save_man_page` method.
program flap_test_save_man_page
!< Test `save_man_page` method.
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
  !< The example program: parse the real command line and save the man page.
  type(command_line_interface) :: cli !< Command Line Interface (CLI).
  character(99)                :: man !< Man page file name.

  call define_cli(cli)
  call cli%get(switch='-m',    val=man)
  call cli%save_man_page(man_file=trim(man))
  endsubroutine example

  subroutine define_cli(cli)
  !< Define the example CLI.
  type(command_line_interface), intent(out) :: cli !< Command Line Interface (CLI).

  call cli%init(progname='flap_save_man_page',                          &
                version='1.1.2',                                        &
                authors='Batman and Robin',                             &
                license='GPL v3',                                       &
                description = 'FLAP test save man page',                &
                examples=['flap_save_man_page                        ', &
                          'flap_save_man_page -m test.man -i 4       ', &
                          'flap_save_man_page 3.2 -m test.man        ', &
                          'flap_save_man_page -1.5 -m test.man -i 102'])
  call cli%add(switch='--man',     switch_ab='-m', help='man page file name', required=.false., act='store', def='test.man')
  call cli%add(switch='--integer', switch_ab='-i', help='a integer',          required=.false., act='store', def='2'       )
  call cli%add(positional=.true.,position=1,       help='a positional real',  required=.false.,              def='1.0'     )
  endsubroutine define_cli

  subroutine self_test()
  !< The man page has the troff header and sections, the options with their defaults, the examples and the metadata.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  character(:), allocatable    :: man   !< Man page path.
  character(:), allocatable    :: text  !< Man page.
  integer(I4P)                 :: error !< Error trapping flag.

  call capture_open(lun)
  call define_cli(cli)
  call cli%parse(args='', error=error)
  call assert_equal(error, 0_I4P, 'parse without arguments')
  man = scratch_file('man')
  call cli%save_man_page(man_file=man, error=error)
  call assert_equal(error, 0_I4P, 'save_man_page: error')
  text = read_file(man)
  call assert_contains(text, '.TH flap_save_man_page "1"', 'title header')
  call assert_contains(text, '"version 1.1.2" "flap_save_man_page Manual"', 'title header version')
  call assert_contains(text, '.SH NAME'//new_line('a')//'flap_save_man_page - manual page for flap_save_man_page version 1.1.2', &
                       'NAME section')
  call assert_contains(text, '[value] [--man value] [--integer value]', 'SYNOPSIS')
  call assert_contains(text, '.SH DESCRIPTION'//new_line('a')//'FLAP test save man page', 'DESCRIPTION section')
  call assert_contains(text, '--integer value, -i value'//new_line('a')//'    default value 2'//new_line('a')//'    a integer', &
                       'OPTIONS: --integer with default and help')
  call assert_contains(text, 'a positional real', 'OPTIONS: positional')
  call assert_contains(text, '.SH EXAMPLES', 'EXAMPLES section')
  call assert_contains(text, 'flap_save_man_page -1.5 -m test.man -i 102', 'EXAMPLES content')
  call assert_contains(text, '.SH AUTHOR'//new_line('a')//'Batman and Robin', 'AUTHOR section')
  call assert_contains(text, '.SH COPYRIGHT'//new_line('a')//'GPL v3', 'COPYRIGHT section')
  call delete_file(man)
  call capture_close(lun)
  endsubroutine self_test
endprogram flap_test_save_man_page

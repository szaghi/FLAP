!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_save_usage_to_markdown
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).

use flap, only : command_line_interface
use penf

implicit none
type(command_line_interface) :: cli !< Command Line Interface (CLI).
character(99)                :: md  !< Markdown file name.
integer(I4P)                 :: i   !< Integer input.
real(R8P)                    :: r   !< Real input.

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
call cli%add(switch='--integer', switch_ab='-i', help='a integer',          required=.false., act='store', def='2'  )
call cli%add(positional=.true.,position=1,       help='a positional real',  required=.false.,              def='1.0')
call cli%get(switch='-m',    val=md)
call cli%get(switch='-i',    val=i )
call cli%get(position=1_I4P, val=r )
call cli%save_usage_to_markdown(markdown_file=trim(md))
endprogram flap_save_usage_to_markdown

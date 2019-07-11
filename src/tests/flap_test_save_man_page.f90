!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_save_man_page
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).

use flap, only : command_line_interface
use penf

implicit none
type(command_line_interface) :: cli !< Command Line Interface (CLI).
character(99)                :: man !< Man page file name.
integer(I4P)                 :: i   !< Integer input.
real(R8P)                    :: r   !< Real input.

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
call cli%add(switch='--integer', switch_ab='-i', help='a integer',          required=.false., act='store', def='2'  )
call cli%add(positional=.true.,position=1,       help='a positional real',  required=.false.,              def='1.0')
call cli%get(switch='-m',    val=man)
call cli%get(switch='-i',    val=i  )
call cli%get(position=1_I4P, val=r  )
call cli%save_man_page(man_file=trim(man))
endprogram flap_save_man_page

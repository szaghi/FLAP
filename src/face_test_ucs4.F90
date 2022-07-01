!< FACE test.
program face_test_ucs4
!< FACE test.
use face

implicit none
#ifdef UCS4_SUPPORTED
character(kind=UCS4, len=:), allocatable :: string_1 !< A string.
character(kind=UCS4, len=:), allocatable :: string_2 !< A string.
character(kind=UCS4, len=:), allocatable :: string_3 !< A string.

string_1 = colorize('Hello', color_fg='blue')
string_2 = colorize(UCS4_' ÜÇŞ4', color_fg='red')
string_3 = colorize(' World', color_fg='blue')
print '(A)', string_1//string_2//string_3
#endif
endprogram face_test_ucs4

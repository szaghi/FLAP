!< FACE test.
program face_test_styles
!< FACE test.
use face

implicit none

print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='blue', style='bold_on'         )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='blue', style='italics_on'      )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='blue', style='underline_on'    )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='blue', style='inverse_on'      )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='blue', style='strikethrough_on')
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='blue', style='framed_on'       )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='blue', style='encircled_on'    )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='blue', style='overlined_on'    )
endprogram face_test_styles

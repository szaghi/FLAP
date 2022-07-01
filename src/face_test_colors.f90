!< FACE test.
program face_test_colors
!< FACE test.
use face

implicit none

print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='black'          )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='red'            )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='green'          )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='yellow'         )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='blue'           )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='magenta'        )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='cyan'           )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='white'          )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='default'        )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='black_intense'  )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='red_intense'    )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='green_intense'  )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='yellow_intense' )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='blue_intense'   )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='magenta_intense')
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='cyan_intense'   )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_fg='white_intense'  )

print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='black'          )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='red'            )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='green'          )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='yellow'         )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='blue'           )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='magenta'        )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='cyan'           )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='white'          )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='default'        )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='black_intense'  )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='red_intense'    )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='green_intense'  )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='yellow_intense' )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='blue_intense'   )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='magenta_intense')
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='cyan_intense'   )
print '(A)', colorize('Hello', color_fg='red')//colorize(' World', color_bg='white_intense'  )
endprogram face_test_colors

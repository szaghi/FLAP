!< FACE, Fortran Ansi Colors Environment.
module face
!< FACE, Fortran Ansi Colors Environment.
use, intrinsic :: iso_fortran_env, only: int32

implicit none
private
public :: colorize
public :: colors_samples
public :: styles_samples
public :: ASCII
public :: UCS4

interface colorize
#if defined ASCII_SUPPORTED && defined ASCII_NEQ_DEFAULT
   module procedure colorize_ascii
   module procedure colorize_default
#else
   module procedure colorize_default
#endif
#ifdef UCS4_SUPPORTED
   module procedure colorize_ucs4
#endif
endinterface

! kind parameters
#ifdef ASCII_SUPPORTED
integer, parameter :: ASCII = selected_char_kind('ascii')     !< ASCII character set kind.
#else
integer, parameter :: ASCII = selected_char_kind('default')   !< ASCII character set kind.
#endif
#ifdef UCS4_SUPPORTED
integer, parameter :: UCS4  = selected_char_kind('iso_10646') !< Unicode character set kind.
#else
integer, parameter :: UCS4  = selected_char_kind('default')   !< Unicode character set kind.
#endif
! parameters
character(26), parameter :: UPPER_ALPHABET='ABCDEFGHIJKLMNOPQRSTUVWXYZ' !< Upper case alphabet.
character(26), parameter :: LOWER_ALPHABET='abcdefghijklmnopqrstuvwxyz' !< Lower case alphabet.
character(1),  parameter :: NL=new_line('a')                            !< New line character.
character(1),  parameter :: ESCAPE=achar(27)                            !< "\" character.
! codes
character(2), parameter :: CODE_START=ESCAPE//'['               !< Start ansi code, "\[".
character(1), parameter :: CODE_END='m'                         !< End ansi code, "m".
character(4), parameter :: CODE_CLEAR=CODE_START//'0'//CODE_END !< Clear all styles, "\[0m".
! styles codes
character(17), parameter :: STYLES(1:2,1:16)=reshape([&
             'BOLD_ON          ','1                ', &         !  Bold on.
             'ITALICS_ON       ','3                ', &         !  Italics on.
             'UNDERLINE_ON     ','4                ', &         !  Underline on.
             'INVERSE_ON       ','7                ', &         !  Inverse on: reverse foreground and background colors.
             'STRIKETHROUGH_ON ','9                ', &         !  Strikethrough on.
             'BOLD_OFF         ','22               ', &         !  Bold off.
             'ITALICS_OFF      ','23               ', &         !  Italics off.
             'UNDERLINE_OFF    ','24               ', &         !  Underline off.
             'INVERSE_OFF      ','27               ', &         !  Inverse off: reverse foreground and background colors.
             'STRIKETHROUGH_OFF','29               ', &         !  Strikethrough off.
             'FRAMED_ON        ','51               ', &         !  Framed on.
             'ENCIRCLED_ON     ','52               ', &         !  Encircled on.
             'OVERLINED_ON     ','53               ', &         !  Overlined on.
             'FRAMED_OFF       ','54               ', &         !  Framed off.
             'ENCIRCLED_OFF    ','54               ', &         !  Encircled off.
             'OVERLINED_OFF    ','55               '  &         !  Overlined off.
                                                     ], [2,16]) !< Styles.
! colors codes
character(15), parameter :: COLORS_FG(1:2,1:17)=reshape([&
                    'BLACK          ','30             ', &         !  Black.
                    'RED            ','31             ', &         !  Red.
                    'GREEN          ','32             ', &         !  Green.
                    'YELLOW         ','33             ', &         !  Yellow.
                    'BLUE           ','34             ', &         !  Blue.
                    'MAGENTA        ','35             ', &         !  Magenta.
                    'CYAN           ','36             ', &         !  Cyan.
                    'WHITE          ','37             ', &         !  White.
                    'DEFAULT        ','39             ', &         !  Default (white).
                    'BLACK_INTENSE  ','90             ', &         !  Black intense.
                    'RED_INTENSE    ','91             ', &         !  Red intense.
                    'GREEN_INTENSE  ','92             ', &         !  Green intense.
                    'YELLOW_INTENSE ','93             ', &         !  Yellow intense.
                    'BLUE_INTENSE   ','94             ', &         !  Blue intense.
                    'MAGENTA_INTENSE','95             ', &         !  Magenta intense.
                    'CYAN_INTENSE   ','96             ', &         !  Cyan intense.
                    'WHITE_INTENSE  ','97             '  &         !  White intense.
                                                        ], [2,17]) !< Foreground colors.
character(15), parameter :: COLORS_BG(1:2,1:17)=reshape([&
                    'BLACK          ','40             ', &         !  Black.
                    'RED            ','41             ', &         !  Red.
                    'GREEN          ','42             ', &         !  Green.
                    'YELLOW         ','43             ', &         !  Yellow.
                    'BLUE           ','44             ', &         !  Blue.
                    'MAGENTA        ','45             ', &         !  Magenta.
                    'CYAN           ','46             ', &         !  Cyan.
                    'WHITE          ','47             ', &         !  White.
                    'DEFAULT        ','49             ', &         !  Default (black).
                    'BLACK_INTENSE  ','100            ', &         !  Black intense.
                    'RED_INTENSE    ','101            ', &         !  Red intense.
                    'GREEN_INTENSE  ','102            ', &         !  Green intense.
                    'YELLOW_INTENSE ','103            ', &         !  Yellow intense.
                    'BLUE_INTENSE   ','104            ', &         !  Blue intense.
                    'MAGENTA_INTENSE','105            ', &         !  Magenta intense.
                    'CYAN_INTENSE   ','106            ', &         !  Cyan intense.
                    'WHITE_INTENSE  ','107            '  &         !  White intense.
                                                        ], [2,17]) !< Background colors.
contains
   ! public procedures
   subroutine colors_samples()
   !< Print to standard output all colors samples.
   integer(int32) :: c !< Counter.

   print '(A)', colorize('Foreground colors samples', color_fg='red_intense')
   do c=1, size(COLORS_FG, dim=2)
      print '(A)', '  colorize("'//COLORS_FG(1, c)//'", color_fg="'//COLORS_FG(1, c)//'") => '//&
         colorize(COLORS_FG(1, c), color_fg=COLORS_FG(1, c))//&
         ' code: '//colorize(trim(COLORS_FG(2, c)), color_fg=COLORS_FG(1, c), style='inverse_on')
   enddo
   print '(A)', colorize('Background colors samples', color_fg='red_intense')
   do c=1, size(COLORS_BG, dim=2)
      print '(A)', '  colorize("'//COLORS_BG(1, c)//'", color_bg="'//COLORS_BG(1, c)//'") => '//&
         colorize(COLORS_BG(1, c), color_bg=COLORS_BG(1, c))//&
         ' code: '//colorize(trim(COLORS_BG(2, c)), color_bg=COLORS_BG(1, c), style='inverse_on')
   enddo
   endsubroutine colors_samples

   subroutine styles_samples()
   !< Print to standard output all styles samples.
   integer(int32) :: s !< Counter.

   print '(A)', colorize('Styles samples', color_fg='red_intense')
   do s=1, size(STYLES, dim=2)
      print '(A)', '  colorize("'//STYLES(1, s)//'", style="'//STYLES(1, s)//'") => '//&
         colorize(STYLES(1, s), style=STYLES(1, s))//&
         ' code: '//colorize(trim(STYLES(2, s)), color_fg='magenta', style='inverse_on')
   enddo
   endsubroutine styles_samples

   ! private procedures
   pure function colorize_ascii(string, color_fg, color_bg, style) result(colorized)
   !< Colorize and stylize strings, ASCII kind.
   character(len=*, kind=ASCII), intent(in)           :: string    !< Input string.
   character(len=*),             intent(in), optional :: color_fg  !< Foreground color definition.
   character(len=*),             intent(in), optional :: color_bg  !< Background color definition.
   character(len=*),             intent(in), optional :: style     !< Style definition.
   character(len=:, kind=ASCII), allocatable          :: colorized !< Colorized string.
   character(len=:, kind=ASCII), allocatable          :: buffer    !< Temporary buffer.
   integer(int32)                                     :: i         !< Counter.

   colorized = string
   if (present(color_fg)) then
      i = color_index(upper(color_fg))
      if (i>0) then
         buffer = CODE_START//trim(COLORS_FG(2, i))//CODE_END
         colorized = buffer//colorized
         buffer = CODE_CLEAR
         colorized = colorized//buffer
      endif
   endif
   if (present(color_bg)) then
      i = color_index(upper(color_bg))
      if (i>0) then
         buffer = CODE_START//trim(COLORS_BG(2, i))//CODE_END
         colorized = buffer//colorized
         buffer = CODE_CLEAR
         colorized = colorized//buffer
      endif
   endif
   if (present(style)) then
      i = style_index(upper(style))
      if (i>0) then
         buffer = CODE_START//trim(STYLES(2, i))//CODE_END
         colorized = buffer//colorized
         buffer = CODE_CLEAR
         colorized = colorized//buffer
      endif
   endif
   endfunction colorize_ascii

   pure function colorize_default(string, color_fg, color_bg, style) result(colorized)
   !< Colorize and stylize strings, DEFAULT kind.
   character(len=*), intent(in)           :: string    !< Input string.
   character(len=*), intent(in), optional :: color_fg  !< Foreground color definition.
   character(len=*), intent(in), optional :: color_bg  !< Background color definition.
   character(len=*), intent(in), optional :: style     !< Style definition.
   character(len=:), allocatable          :: colorized !< Colorized string.
   integer(int32)                         :: i         !< Counter.

   colorized = string
   if (present(color_fg)) then
      i = color_index(upper(color_fg))
      if (i>0) colorized = CODE_START//trim(COLORS_FG(2, i))//CODE_END//colorized//CODE_CLEAR
   endif
   if (present(color_bg)) then
      i = color_index(upper(color_bg))
      if (i>0) colorized = CODE_START//trim(COLORS_BG(2, i))//CODE_END//colorized//CODE_CLEAR
   endif
   if (present(style)) then
      i = style_index(upper(style))
      if (i>0) colorized = CODE_START//trim(STYLES(2, i))//CODE_END//colorized//CODE_CLEAR
   endif
   endfunction colorize_default

   pure function colorize_ucs4(string, color_fg, color_bg, style) result(colorized)
   !< Colorize and stylize strings, UCS4 kind.
   character(len=*, kind=UCS4), intent(in)           :: string    !< Input string.
   character(len=*),            intent(in), optional :: color_fg  !< Foreground color definition.
   character(len=*),            intent(in), optional :: color_bg  !< Background color definition.
   character(len=*),            intent(in), optional :: style     !< Style definition.
   character(len=:, kind=UCS4), allocatable          :: colorized !< Colorized string.
   character(len=:, kind=UCS4), allocatable          :: buffer    !< Temporary buffer.
   integer(int32)                                    :: i         !< Counter.

   colorized = string
   if (present(color_fg)) then
      i = color_index(upper(color_fg))
      if (i>0) then
         buffer = CODE_START//trim(COLORS_FG(2, i))//CODE_END
         colorized = buffer//colorized
         buffer = CODE_CLEAR
         colorized = colorized//buffer
      endif
   endif
   if (present(color_bg)) then
      i = color_index(upper(color_bg))
      if (i>0) then
         buffer = CODE_START//trim(COLORS_BG(2, i))//CODE_END
         colorized = buffer//colorized
         buffer = CODE_CLEAR
         colorized = colorized//buffer
      endif
   endif
   if (present(style)) then
      i = style_index(upper(style))
      if (i>0) then
         buffer = CODE_START//trim(STYLES(2, i))//CODE_END
         colorized = buffer//colorized
         buffer = CODE_CLEAR
         colorized = colorized//buffer
      endif
   endif
   endfunction colorize_ucs4

   elemental function color_index(color)
   !< Return the array-index corresponding to the queried color.
   !<
   !< @note Because Foreground and backround colors lists share the same name, no matter what array is used to find the color index.
   !< Thus, the foreground array is used.
   character(len=*), intent(in) :: color       !< Color definition.
   integer(int32)               :: color_index !< Index into the colors arrays.
   integer(int32)               :: c           !< Counter.

   color_index = 0
   do c=1, size(COLORS_FG, dim=2)
      if (trim(COLORS_FG(1, c))==trim(adjustl(color))) then
         color_index = c
         exit
      endif
   enddo
   endfunction color_index

   elemental function style_index(style)
   !< Return the array-index corresponding to the queried style.
   character(len=*), intent(in) :: style       !< Style definition.
   integer(int32)               :: style_index !< Index into the styles array.
   integer(int32)               :: s           !< Counter.

   style_index = 0
   do s=1, size(STYLES, dim=2)
      if (trim(STYLES(1, s))==trim(adjustl(style))) then
         style_index = s
         exit
      endif
   enddo
   endfunction style_index

   elemental function upper(string)
   !< Return a string with all uppercase characters.
   character(len=*), intent(in) :: string !< Input string.
   character(len=len(string))   :: upper  !< Upper case string.
   integer                      :: n1     !< Characters counter.
   integer                      :: n2     !< Characters counter.

   upper = string
   do n1=1, len(string)
      n2 = index(LOWER_ALPHABET, string(n1:n1))
      if (n2>0) upper(n1:n1) = UPPER_ALPHABET(n2:n2)
   enddo
   endfunction upper
endmodule face

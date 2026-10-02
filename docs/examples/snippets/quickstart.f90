program greet
!< Quick start: a positional, a ranged integer, a choice read from the environment too, a flag.
use flap
implicit none
type(command_line_interface) :: cli
character(32)                :: name, lang, hello
integer                      :: times, i, error
logical                      :: shout

call cli%init(progname='greet', version='v1.0', description='Greet someone, in a few languages', &
              error_color='red', error_style='bold_on')
call cli%add(positional=.true., position=1, help='Who to greet', required=.true., metavar='NAME')
call cli%add(switch='--times', switch_ab='-t', help='How many times', def='1', min='1', max='5', metavar='N', &
             help_color='cyan', help_style='bold_on')
call cli%add(switch='--lang', help='Language', def='en', choices='en,it,fr', envvar='GREET_LANG', metavar='LANG', &
             help_color='cyan', help_style='bold_on')
call cli%add(switch='--shout', help='Say it louder', act='store_true', def='.false.', &
             help_color='cyan', help_style='bold_on')
call cli%parse(error=error)                 ! prints the help, the version or the error by itself
if (error /= 0) stop 1, quiet=.true.
call cli%get(position=1, val=name, error=error)       ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--times', val=times, error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--lang', val=lang, error=error)   ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--shout', val=shout, error=error) ; if (error /= 0) stop 1, quiet=.true.

select case(trim(lang))
case('it') ; hello = 'Ciao'
case('fr') ; hello = 'Salut'
case default ; hello = 'Hello'
endselect
do i = 1, times
  print '(A)', trim(hello)//' '//trim(name)//merge('!', '.', shout)
enddo
endprogram greet

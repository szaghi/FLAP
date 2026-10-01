!as heat
!run heat_9 printf '2\n' | heat --interactive
!run heat_9-given heat --scheme fe --interactive
!run -s heat_9-batch heat --interactive < /dev/null
program heat
!< Tutorial, chapter 9: asking the user, only when a value is missing.
use flap
use penf, only : I4P
implicit none
type(command_line_interface) :: cli
type(menu)                   :: m
character(2)                 :: scheme
logical                      :: interactive
integer(I4P)                 :: choice
integer(I4P)                 :: merror
integer                      :: error

call cli%init(progname='heat', version='v0.9', description='Solve the 2D heat equation on a square plate')
call cli%add(switch='--scheme', help='Time scheme', required=.false., act='store', def='fe', choices='fe,cn')
call cli%add(switch='--interactive', help='Ask for the missing values', required=.false., act='store_true', &
             def='.false.')
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--scheme', val=scheme, error=error)
call cli%get(switch='--interactive', val=interactive, error=error)
!region ask
if (interactive .and. .not.cli%is_passed(switch='--scheme')) then
  call m%init(question='Time scheme?')
  call m%add_option(text='fe: explicit Euler', is_default=.true.)
  call m%add_option(text='cn: Crank-Nicolson')
  call m%run(choice, merror)
  if (merror /= 0) stop 1, quiet=.true.   ! no answer (a batch job): stop rather than guess
  scheme = merge('fe', 'cn', choice == 1)
  write(*, '(A)')
endif
!endregion ask
print '(A)', 'heat: scheme '//scheme
endprogram heat

program menus
!< Interactive menus; the kind of menu is chosen by a positional argument (FLAP) and the answers come from stdin.
use flap
use penf, only : I4P
implicit none
type(command_line_interface) :: cli
type(menu)                   :: m
character(9)                 :: kind
integer(I4P)                 :: choice
integer(I4P), allocatable    :: choices(:)
logical                      :: answer
integer                      :: error
integer(I4P)                 :: merror

call cli%init(progname='menus')
call cli%add(positional=.true., position=1, help='Kind of menu', required=.true., act='store', &
             choices='single,default,multiple,yes_no,retry', metavar='KIND')
call cli%get(position=1, val=kind, error=error)
if (error /= 0) stop 1, quiet=.true.
select case(trim(kind))
case('single')
  call m%init(question='What is your favorite food?')
  call m%add_option(text='Pizza')
  call m%add_option(text='Ice Cream')
  call m%add_option(text='Tacos')
  call m%run(choice, merror)
case('default')
  call m%init(question='What is your favorite food?')
  call m%add_option(text='Pizza')
  call m%add_option(text='Ice Cream', is_default=.true.)
  call m%add_option(text='Tacos')
  call m%run(choice, merror) ! an empty answer: choice = 2
case('multiple')
  call m%init(question='Which toppings?', multiple=.true.)
  call m%add_option(text='Cheese', is_default=.true.)
  call m%add_option(text='Mushrooms')
  call m%add_option(text='Olives', is_default=.true.)
  call m%run(choices, merror) ! "3 1" gives [3, 1]; an empty answer the defaults, [1, 3]
  write(*, '(/,A,*(I0,:,","))') 'choices = ', choices
  stop
case('yes_no')
  call m%init(question='Overwrite the restart file?')
  call m%yes_no(answer, default='n', error=merror)
  write(*, '(/,A,L1)') 'answer = ', answer
  stop
case('retry')
  call m%init(question='What is your favorite food?', loop_on_invalid=.true., tries=3)
  call m%add_option(text='Pizza')
  call m%add_option(text='Ice Cream')
  call m%add_option(text='Tacos')
  call m%run(choice, merror)
endselect
if (merror /= 0) stop 1, quiet=.true.
write(*, '(/,A,I0)') 'choice = ', choice
endprogram menus

!run menus-single printf '2\n' | menus single
!run menus-default printf '\n' | menus default
!run menus-multiple printf '3 1\n' | menus multiple
!run menus-yes_no printf 'yes\n' | menus yes_no
!run menus-retry printf '7\n2\n' | menus retry
!run -s menus-eof menus single < /dev/null
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
  !region single
  call m%init(question='What is your favorite food?')
  call m%add_option(text='Pizza')
  call m%add_option(text='Ice Cream')
  call m%add_option(text='Tacos')
  call m%run(choice, merror)
  !endregion single
case('default')
  !region default
  call m%init(question='What is your favorite food?')
  call m%add_option(text='Pizza')
  call m%add_option(text='Ice Cream', is_default=.true.)
  call m%add_option(text='Tacos')
  call m%run(choice, merror) ! an empty answer: choice = 2
  !endregion default
case('multiple')
  !region multiple
  call m%init(question='Which toppings?', multiple=.true.)
  call m%add_option(text='Cheese', is_default=.true.)
  call m%add_option(text='Mushrooms')
  call m%add_option(text='Olives', is_default=.true.)
  call m%run(choices, merror) ! "3 1" gives [3, 1]; an empty answer the defaults, [1, 3]
  !endregion multiple
  write(*, '(/,A,*(I0,:,","))') 'choices = ', choices
  stop
case('yes_no')
  !region yes_no
  call m%init(question='Overwrite the restart file?')
  call m%yes_no(answer, default='n', error=merror)
  !endregion yes_no
  write(*, '(/,A,L1)') 'answer = ', answer
  stop
case('retry')
  !region retry
  call m%init(question='What is your favorite food?', loop_on_invalid=.true., tries=3)
  !endregion retry
  call m%add_option(text='Pizza')
  call m%add_option(text='Ice Cream')
  call m%add_option(text='Tacos')
  call m%run(choice, merror)
endselect
if (merror /= 0) stop 1, quiet=.true.
write(*, '(/,A,I0)') 'choice = ', choice
endprogram menus

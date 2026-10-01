program heat_test
!< Tutorial, chapter 8: testing the command line of heat, in-process, without touching the real command line.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: lun   ! a scratch unit catching FLAP's messages
integer                      :: nx
integer                      :: error

open(newunit=lun, status='scratch', action='readwrite')
call define(cli)

! a command line given as a string
call cli%parse(args='--nx 128', error=error)
call check(error == 0 .and. cli%get_source(switch='--nx') == SOURCE_COMMANDLINE, 'parse --nx 128')
call cli%get(switch='--nx', val=nx, error=error)
call check(nx == 128, 'get --nx')

! parse another command line with the same definitions
call cli%reset_parse
call cli%parse(args='', error=error)
call check(cli%get_source(switch='--nx') == SOURCE_DEFAULT, 'the default')

! errors and statuses are returned, never stop the program (standalone=.false.)
call cli%reset_parse
call cli%parse(args='--nx 1 --nx 2', error=error)
call check(error == ERROR_DUPLICATED_CLAS, 'a repeated switch')
call cli%reset_parse
call cli%parse(args='--help', error=error)
call check(error == STATUS_PRINT_H, '--help returns a status')
call check(caught('Optional switches:'), 'the help is written on the unit')
print '(A)', 'heat_test: all checks passed'

contains
  subroutine define(cli)
  !< The definitions of heat (in a real program, a module procedure shared by heat and its tests).
  type(command_line_interface), intent(inout) :: cli

  call cli%init(progname='heat', standalone=.false., usage_lun=lun, error_lun=lun)
  call cli%add(switch='--nx', help='Cells along each direction', required=.false., act='store', def='64')
  endsubroutine define

  subroutine check(condition, message)
  !< Stop with an error if a check fails.
  logical,      intent(in) :: condition
  character(*), intent(in) :: message

  if (.not.condition) then
    print '(A)', 'FAIL: '//message
    stop 1, quiet=.true.
  endif
  endsubroutine check

  function caught(text) result(found)
  !< Whether the messages written by FLAP on the scratch unit contain a text.
  character(*), intent(in) :: text
  logical                  :: found
  character(256)           :: line
  integer                  :: ios

  found = .false.
  rewind(lun)
  do
    read(lun, '(A)', iostat=ios) line
    if (ios /= 0) exit
    if (index(line, text) > 0) found = .true.
  enddo
  endfunction caught
endprogram heat_test

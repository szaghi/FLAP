!< Interactive menus for terminal programs (F23 of #125, the wmenu plan of #78): numbered options, one answer line.
module flap_menu_t
!< Interactive menus for terminal programs (F23 of #125, the wmenu plan of #78): numbered options, one answer line.
!<
!< Opt-in: the argument parser never uses this module, so parsing stays non-interactive and safe in batch and MPI jobs. A menu
!< prints its options numbered from 1, then the question, reads one answer line and returns the chosen index; the caller
!< dispatches with `select case`. The units are the caller's: the menu never opens nor closes them. At the end of the input
!< (standard input redirected from /dev/null or closed, as in a batch job) `run` returns `ERROR_MENU_EOF` at once: standard
!< Fortran cannot tell whether the input is a terminal, the end of file is the portable signal.
use, intrinsic :: iso_fortran_env, only : stdin => input_unit, stdout => output_unit, stderr => error_unit
use flap_utils_m, only : read_line
use penf

implicit none
private
save
public :: ERROR_MENU_INVALID
public :: ERROR_MENU_NO_RESPONSE
public :: ERROR_MENU_EOF
public :: ERROR_MENU_DEFINITION

! errors 2000-2099: menu
integer(I4P), parameter :: ERROR_MENU_INVALID     = 2001 !< Not a number, or out of range.
integer(I4P), parameter :: ERROR_MENU_NO_RESPONSE = 2004 !< Empty answer.
integer(I4P), parameter :: ERROR_MENU_EOF         = 2005 !< End of input: no answer can come.
integer(I4P), parameter :: ERROR_MENU_DEFINITION  = 2006 !< Invalid menu: no options, empty option text.

type :: menu_option
  !< An option of a menu.
  character(len=:), allocatable :: text !< Text shown.
endtype menu_option

type, public :: menu
  !< Interactive menu: numbered options, a question, one answer line.
  private
  character(len=:),  allocatable :: question           !< Question asked after the options.
  type(menu_option), allocatable :: options(:)         !< Options; the index is the number shown.
  integer(I4P)                   :: input_unit=stdin   !< Unit of the answers.
  integer(I4P)                   :: output_unit=stdout !< Unit of the options and the question.
  integer(I4P)                   :: error_unit=stderr  !< Unit of the error messages.
  contains
    ! public methods
    procedure, pass(self) :: add_option        !< Append an option.
    procedure, pass(self) :: free              !< Free dynamic memory.
    procedure, pass(self) :: init              !< Initialize the menu.
    generic               :: run => run_single !< Show the menu and read the answer.
    ! private methods
    procedure, pass(self), private :: run_single !< Show the menu and read one choice.
    procedure, pass(self), private :: raise      !< Write an error message and return its code.
    final                          :: finalize   !< Free dynamic memory when finalizing.
endtype menu

contains
  ! public methods
  subroutine init(self, question, input_unit, output_unit, error_unit)
  !< Initialize the menu: every previous setting and option is dropped.
  class(menu),  intent(inout)        :: self        !< Menu.
  character(*), intent(in)           :: question    !< Question asked after the options.
  integer(I4P), intent(in), optional :: input_unit  !< Unit of the answers (default: standard input).
  integer(I4P), intent(in), optional :: output_unit !< Unit of the options and the question (default: standard output).
  integer(I4P), intent(in), optional :: error_unit  !< Unit of the error messages (default: standard error).

  call self%free
  self%question = question
  if (present(input_unit))  self%input_unit  = input_unit
  if (present(output_unit)) self%output_unit = output_unit
  if (present(error_unit))  self%error_unit  = error_unit
  endsubroutine init

  subroutine add_option(self, text, error)
  !< Append an option: its index is the number shown. An empty (or blank) text is not added.
  class(menu),  intent(inout)         :: self     !< Menu.
  character(*), intent(in)            :: text     !< Text shown.
  integer(I4P), intent(out), optional :: error    !< Error trapping flag.
  type(menu_option), allocatable      :: grown(:) !< Options with the new one.
  integer(I4P)                        :: n        !< Number of options.
  integer(I4P)                        :: i        !< Counter.
  integer(I4P)                        :: error_   !< Error trapping flag, local variable.

  error_ = 0
  if (len_trim(text) == 0) then
    error_ = self%raise(ERROR_MENU_DEFINITION, 'empty option text')
  else
    n = 0 ; if (allocated(self%options)) n = size(self%options, dim=1)
    ! sized first, filled by element: an array constructor growing it is miscompiled by gfortran 16 trunk (see CLAUDE.md)
    allocate(grown(n + 1))
    do i=1, n
      grown(i) = self%options(i)
    enddo
    grown(n + 1)%text = text
    call move_alloc(grown, self%options)
  endif
  if (present(error)) error = error_
  endsubroutine add_option

  elemental subroutine free(self)
  !< Free dynamic memory and restore the default units.
  class(menu), intent(inout) :: self !< Menu.

  if (allocated(self%question)) deallocate(self%question)
  if (allocated(self%options)) deallocate(self%options)
  self%input_unit = stdin
  self%output_unit = stdout
  self%error_unit = stderr
  endsubroutine free

  ! private methods
  subroutine run_single(self, choice, error)
  !< Show the menu and read one choice: the index of the chosen option, 0 on error.
  class(menu),  intent(inout)         :: self   !< Menu.
  integer(I4P), intent(out)           :: choice !< Chosen index (0 on error).
  integer(I4P), intent(out), optional :: error  !< Error trapping flag.
  character(len=:), allocatable       :: answer !< Answer line.
  character(256)                      :: iomsg  !< I/O message.
  integer(I4P)                        :: iostat !< I/O status.
  integer(I4P)                        :: n      !< Number of options.
  integer(I4P)                        :: i      !< Counter.
  integer(I4P)                        :: error_ !< Error trapping flag, local variable.

  choice = 0
  n = 0 ; if (allocated(self%options)) n = size(self%options, dim=1)
  if (n == 0) then
    error_ = self%raise(ERROR_MENU_DEFINITION, 'the menu has no options')
  else
    do i=1, n
      write(self%output_unit, '(A)') trim(str(i, .true.))//') '//self%options(i)%text
    enddo
    ! the prompt must be visible before the read: no line end, then flush
    write(self%output_unit, '(A)', advance='no') self%question//' '
    flush(self%output_unit)
    call read_line(self%input_unit, answer, iostat, iomsg)
    if (is_iostat_end(iostat)) then
      error_ = self%raise(ERROR_MENU_EOF, 'end of input, no response')
    elseif (iostat /= 0) then
      error_ = self%raise(ERROR_MENU_INVALID, 'invalid response: '//trim(iomsg))
    else
      error_ = 0
      answer = trim(adjustl(answer))
      if (len(answer) == 0) then
        error_ = self%raise(ERROR_MENU_NO_RESPONSE, 'no response')
      else
        choice = option_index(answer, n)
        if (choice == 0) error_ = self%raise(ERROR_MENU_INVALID, 'invalid response: '//answer)
      endif
    endif
  endif
  if (present(error)) error = error_
  endsubroutine run_single

  function raise(self, code, message) result(error)
  !< Write an error message on the error unit and return its code.
  class(menu),  intent(in) :: self    !< Menu.
  integer(I4P), intent(in) :: code    !< Error code.
  character(*), intent(in) :: message !< Error message.
  integer(I4P)             :: error   !< Error code.

  write(self%error_unit, '(A)') 'error: '//message
  error = code
  endfunction raise

  elemental subroutine finalize(self)
  !< Free dynamic memory when finalizing.
  type(menu), intent(inout) :: self !< Menu.

  call self%free
  endsubroutine finalize

  ! non type-bound procedures
  pure function option_index(field, n) result(choice)
  !< The option number written in a field: digits only, in 1..n; 0 otherwise.
  character(*), intent(in) :: field  !< Field (no blanks around).
  integer(I4P), intent(in) :: n      !< Number of options.
  integer(I4P)             :: choice !< Option number, 0 if not valid.
  integer(I4P)             :: first  !< First significant digit.

  choice = 0
  if (len(field) == 0 .or. verify(field, '0123456789') /= 0) return
  first = verify(field, '0')
  if (first == 0) return                 ! all zeros
  if (len(field) - first + 1 > 9) return ! beyond any number of options, and beyond I4P
  read(field(first:), *) choice
  if (choice > n) choice = 0
  endfunction option_index
endmodule flap_menu_t

!< Interactive menus for terminal programs (F23 of #125, the wmenu plan of #78): numbered options, one answer line.
module flap_menu_t
!< Interactive menus for terminal programs (F23 of #125, the wmenu plan of #78): numbered options, one answer line.
!<
!< Opt-in: the argument parser never uses this module, so parsing stays non-interactive and safe in batch and MPI jobs. A menu
!< prints its options numbered from 1, then the question, reads one answer line and returns the chosen index (the indexes,
!< with multiple selection); the caller dispatches with `select case`. The units are the caller's: the menu never opens nor
!< closes them. At the end of the input (standard input redirected from /dev/null or closed, as in a batch job) `run`
!< returns `ERROR_MENU_EOF` at once: standard Fortran cannot tell whether the input is a terminal, the end of file is the
!< portable signal. `yes_no` asks the question alone (no options) and returns a logical. Colours and styles (FACE names,
!< none by default) apply to the option lines, the question and the word "error" of the messages.
use, intrinsic :: iso_fortran_env, only : stdin => input_unit, stdout => output_unit, stderr => error_unit
use face, only : colorize
use flap_utils_m, only : flap_string, read_line, upper_case
use penf

implicit none
private
save
public :: ERROR_MENU_INVALID
public :: ERROR_MENU_TOO_MANY
public :: ERROR_MENU_DUPLICATE
public :: ERROR_MENU_NO_RESPONSE
public :: ERROR_MENU_EOF
public :: ERROR_MENU_DEFINITION

! errors 2000-2099: menu
integer(I4P), parameter :: ERROR_MENU_INVALID     = 2001 !< Not a number, out of range, or an empty field.
integer(I4P), parameter :: ERROR_MENU_TOO_MANY    = 2002 !< Several answers to a single choice.
integer(I4P), parameter :: ERROR_MENU_DUPLICATE   = 2003 !< The same option chosen twice.
integer(I4P), parameter :: ERROR_MENU_NO_RESPONSE = 2004 !< Empty answer, and no default option.
integer(I4P), parameter :: ERROR_MENU_EOF         = 2005 !< End of input: no answer can come.
integer(I4P), parameter :: ERROR_MENU_DEFINITION  = 2006 !< Invalid menu or use (no options, empty text, ...).

type :: menu_option
  !< An option of a menu.
  character(len=:), allocatable :: text              !< Text shown.
  logical                       :: is_default=.false. !< Chosen by an empty answer.
endtype menu_option

type, public :: menu
  !< Interactive menu: numbered options, a question, one answer line.
  private
  character(len=:),  allocatable :: question           !< Question asked after the options.
  type(menu_option), allocatable :: options(:)         !< Options; the index is the number shown.
  character(len=:),  allocatable :: default_icon       !< Mark of the default options.
  integer(I4P)                   :: input_unit=stdin   !< Unit of the answers.
  integer(I4P)                   :: output_unit=stdout !< Unit of the options and the question.
  integer(I4P)                   :: error_unit=stderr  !< Unit of the error messages.
  logical                        :: loop_on_invalid=.false. !< Ask again after an invalid answer.
  integer(I4P)                   :: tries=3            !< Attempts in total with loop_on_invalid.
  logical                        :: multiple=.false.   !< Several options can be chosen.
  character(len=:),  allocatable :: separator          !< Separator of the answers (blank: runs of blanks).
  character(len=:),  allocatable :: option_color       !< ANSI colour of the option lines (FACE names).
  character(len=:),  allocatable :: option_style       !< ANSI style of the option lines.
  character(len=:),  allocatable :: question_color     !< ANSI colour of the question.
  character(len=:),  allocatable :: question_style     !< ANSI style of the question.
  character(len=:),  allocatable :: error_color        !< ANSI colour of the word "error" of the messages.
  character(len=:),  allocatable :: error_style        !< ANSI style of the word "error" of the messages.
  contains
    ! public methods
    procedure, pass(self) :: add_option        !< Append an option.
    procedure, pass(self) :: free              !< Free dynamic memory.
    procedure, pass(self) :: init              !< Initialize the menu.
    generic               :: run => run_single, run_multiple !< Show the menu and read the answer.
    procedure, pass(self) :: yes_no                          !< Ask the question as a yes/no one.
    ! private methods
    procedure, pass(self), private :: ask           !< Show the menu and read the chosen indexes.
    procedure, pass(self), private :: default_index !< Index of the (first) default option.
    procedure, pass(self), private :: evaluate      !< The indexes of an answer.
    procedure, pass(self), private :: raise         !< Write an error message and return its code.
    procedure, pass(self), private :: run_multiple  !< Show the menu and read the choices.
    procedure, pass(self), private :: run_single    !< Show the menu and read one choice.
    procedure, pass(self), private :: show          !< Write the options (unless yes/no) and the question.
    final                          :: finalize      !< Free dynamic memory when finalizing.
endtype menu

contains
  ! public methods
  subroutine init(self, question, multiple, separator, loop_on_invalid, tries, default_icon, input_unit, output_unit, &
                  error_unit, option_color, option_style, question_color, question_style, error_color, error_style, error)
  !< Initialize the menu: every previous setting and option is dropped.
  class(menu),  intent(inout)         :: self            !< Menu.
  character(*), intent(in)            :: question        !< Question asked after the options.
  logical,      intent(in),  optional :: multiple        !< Several options can be chosen (default: no).
  character(*), intent(in),  optional :: separator       !< Separator of the answers (default: blank, runs of blanks).
  logical,      intent(in),  optional :: loop_on_invalid !< Ask again after an invalid answer (default: no).
  integer(I4P), intent(in),  optional :: tries           !< Attempts in total with loop_on_invalid (default: 3).
  character(*), intent(in),  optional :: default_icon    !< Mark of the default options (default: '*').
  integer(I4P), intent(in),  optional :: input_unit      !< Unit of the answers (default: standard input).
  integer(I4P), intent(in),  optional :: output_unit     !< Unit of the options and the question (default: standard output).
  integer(I4P), intent(in),  optional :: error_unit      !< Unit of the error messages (default: standard error).
  character(*), intent(in),  optional :: option_color    !< ANSI colour of the option lines (FACE names; default: none).
  character(*), intent(in),  optional :: option_style    !< ANSI style of the option lines.
  character(*), intent(in),  optional :: question_color  !< ANSI colour of the question.
  character(*), intent(in),  optional :: question_style  !< ANSI style of the question.
  character(*), intent(in),  optional :: error_color     !< ANSI colour of the word "error" of the messages.
  character(*), intent(in),  optional :: error_style     !< ANSI style of the word "error" of the messages.
  integer(I4P), intent(out), optional :: error           !< Error trapping flag.
  integer(I4P)                        :: error_          !< Error trapping flag, local variable.

  call self%free
  error_ = 0
  self%question = question
  self%option_color   = '' ; if (present(option_color))   self%option_color   = option_color
  self%option_style   = '' ; if (present(option_style))   self%option_style   = option_style
  self%question_color = '' ; if (present(question_color)) self%question_color = question_color
  self%question_style = '' ; if (present(question_style)) self%question_style = question_style
  self%error_color    = '' ; if (present(error_color))    self%error_color    = error_color
  self%error_style    = '' ; if (present(error_style))    self%error_style    = error_style
  if (present(multiple)) self%multiple = multiple
  self%separator = ' '
  if (present(separator)) then
    if (len(separator) == 0) then
      error_ = self%raise(ERROR_MENU_DEFINITION, 'empty separator: the blank is used')
    else
      self%separator = separator
    endif
  endif
  if (present(loop_on_invalid)) self%loop_on_invalid = loop_on_invalid
  self%default_icon = '*' ; if (present(default_icon)) self%default_icon = default_icon
  if (present(input_unit))  self%input_unit  = input_unit
  if (present(output_unit)) self%output_unit = output_unit
  if (present(error_unit))  self%error_unit  = error_unit
  if (present(tries)) then
    if (tries < 1) then
      error_ = self%raise(ERROR_MENU_DEFINITION, 'tries must be at least 1, not '//trim(str(tries, .true.))// &
                                                 ': the default 3 is used')
    else
      self%tries = tries
    endif
  endif
  if (present(error)) error = error_
  endsubroutine init

  subroutine add_option(self, text, is_default, error)
  !< Append an option: its index is the number shown. An empty (or blank) text, or a second default, is not added.
  class(menu),  intent(inout)         :: self       !< Menu.
  character(*), intent(in)            :: text       !< Text shown.
  logical,      intent(in),  optional :: is_default !< Chosen by an empty answer (at most one option).
  integer(I4P), intent(out), optional :: error      !< Error trapping flag.
  type(menu_option), allocatable      :: grown(:)    !< Options with the new one.
  integer(I4P)                        :: n           !< Number of options.
  integer(I4P)                        :: i           !< Counter.
  integer(I4P)                        :: error_      !< Error trapping flag, local variable.
  logical                             :: is_default_ !< Chosen by an empty answer, local variable.

  error_ = 0
  is_default_ = .false. ; if (present(is_default)) is_default_ = is_default
  if (len_trim(text) == 0) then
    error_ = self%raise(ERROR_MENU_DEFINITION, 'empty option text')
  elseif (is_default_ .and. (.not.self%multiple) .and. self%default_index() > 0) then
    error_ = self%raise(ERROR_MENU_DEFINITION, 'a second default option "'//text//'": one choice has one default')
  else
    n = 0 ; if (allocated(self%options)) n = size(self%options, dim=1)
    ! sized first, filled by element: an array constructor growing it is miscompiled by gfortran 16 trunk (see CLAUDE.md)
    allocate(grown(n + 1))
    do i=1, n
      grown(i) = self%options(i)
    enddo
    grown(n + 1)%text = text
    grown(n + 1)%is_default = is_default_
    call move_alloc(grown, self%options)
  endif
  if (present(error)) error = error_
  endsubroutine add_option

  elemental subroutine free(self)
  !< Free dynamic memory and restore the default units.
  class(menu), intent(inout) :: self !< Menu.

  if (allocated(self%question)) deallocate(self%question)
  if (allocated(self%default_icon)) deallocate(self%default_icon)
  if (allocated(self%separator)) deallocate(self%separator)
  if (allocated(self%option_color)) deallocate(self%option_color)
  if (allocated(self%option_style)) deallocate(self%option_style)
  if (allocated(self%question_color)) deallocate(self%question_color)
  if (allocated(self%question_style)) deallocate(self%question_style)
  if (allocated(self%error_color)) deallocate(self%error_color)
  if (allocated(self%error_style)) deallocate(self%error_style)
  if (allocated(self%options)) deallocate(self%options)
  self%input_unit = stdin
  self%output_unit = stdout
  self%error_unit = stderr
  self%loop_on_invalid = .false.
  self%tries = 3
  self%multiple = .false.
  endsubroutine free

  ! private methods
  subroutine ask(self, choices, error, yes_no)
  !< Show the menu and read the chosen indexes (one without multiple selection); none on error.
  !<
  !< With loop_on_invalid an invalid (or empty) answer is reported with the tries left and the menu is asked again, up to
  !< `tries` attempts; the last error is returned. The end of the input and a read error are never retried. With yes_no
  !< (its default: 'Y', 'N', or ' ' for none) the question is asked alone and the index is 1 for yes, 2 for no.
  class(menu),               intent(inout)        :: self       !< Menu.
  integer(I4P), allocatable, intent(out)          :: choices(:) !< Chosen indexes (none on error).
  integer(I4P),              intent(out)          :: error      !< Error trapping flag.
  character(1),              intent(in), optional :: yes_no     !< Yes/no question, with its default.
  character(len=:), allocatable            :: answer     !< Answer line.
  character(len=:), allocatable            :: message    !< Error message.
  character(256)                           :: iomsg      !< I/O message.
  integer(I4P)                             :: iostat     !< I/O status.
  integer(I4P)                             :: attempts   !< Attempts allowed.
  integer(I4P)                             :: attempt    !< Current attempt.

  allocate(choices(0))
  ! a menu used without init: no question, the default icon and separator
  if (.not.allocated(self%question)) self%question = ''
  if (.not.allocated(self%default_icon)) self%default_icon = '*'
  if (.not.allocated(self%separator)) self%separator = ' '
  if (.not.allocated(self%option_color)) self%option_color = ''
  if (.not.allocated(self%option_style)) self%option_style = ''
  if (.not.allocated(self%question_color)) self%question_color = ''
  if (.not.allocated(self%question_style)) self%question_style = ''
  if (.not.present(yes_no)) then
    if (.not.allocated(self%options)) then
      error = self%raise(ERROR_MENU_DEFINITION, 'the menu has no options')
      return
    elseif (size(self%options, dim=1) == 0) then
      error = self%raise(ERROR_MENU_DEFINITION, 'the menu has no options')
      return
    endif
  endif
  attempts = 1 ; if (self%loop_on_invalid) attempts = self%tries
  do attempt=1, attempts
    if (present(yes_no)) then
      ! the suffix is built at each attempt, never appended to the question (wmenu repeats it)
      select case(yes_no)
      case('Y')
        call self%show(suffix='(Y/n)')
      case('N')
        call self%show(suffix='(y/N)')
      case default
        call self%show(suffix='(y/n)')
      endselect
    else
      call self%show
    endif
    call read_line(self%input_unit, answer, iostat, iomsg)
    if (is_iostat_end(iostat)) then
      error = self%raise(ERROR_MENU_EOF, 'end of input, no response')
      exit
    elseif (iostat /= 0) then
      error = self%raise(ERROR_MENU_INVALID, 'invalid response: '//trim(iomsg))
      exit
    endif
    if (present(yes_no)) then
      call evaluate_yes_no(trim(adjustl(answer)), yes_no, choices, error, message)
    else
      call self%evaluate(trim(adjustl(answer)), choices, error, message)
    endif
    if (error == 0) exit
    if (self%loop_on_invalid) message = message//' ('//trim(str(attempts - attempt, .true.))//' tries left)'
    error = self%raise(error, message)
  enddo
  endsubroutine ask

  subroutine run_multiple(self, choices, error)
  !< Show the menu and read the choices: the indexes of the chosen options in the order typed, none on error.
  !<
  !< On a single-choice menu it returns one index (several answers are `ERROR_MENU_TOO_MANY`).
  class(menu),               intent(inout)         :: self       !< Menu.
  integer(I4P), allocatable, intent(out)           :: choices(:) !< Chosen indexes (none on error).
  integer(I4P),              intent(out), optional :: error      !< Error trapping flag.
  integer(I4P)                                     :: error_     !< Error trapping flag, local variable.

  call self%ask(choices, error_)
  if (present(error)) error = error_
  endsubroutine run_multiple

  subroutine run_single(self, choice, error)
  !< Show the menu and read one choice: the index of the chosen option, 0 on error.
  class(menu),  intent(inout)         :: self       !< Menu.
  integer(I4P), intent(out)           :: choice     !< Chosen index (0 on error).
  integer(I4P), intent(out), optional :: error      !< Error trapping flag.
  integer(I4P), allocatable           :: choices(:) !< Chosen indexes.
  integer(I4P)                        :: error_     !< Error trapping flag, local variable.

  choice = 0
  if (self%multiple) then
    error_ = self%raise(ERROR_MENU_DEFINITION, 'run(choice) on a menu with multiple selection: use run(choices)')
  else
    call self%ask(choices, error_)
    if (error_ == 0) choice = choices(1)
  endif
  if (present(error)) error = error_
  endsubroutine run_single

  subroutine show(self, suffix)
  !< Write the numbered options, then the question on the line of the answer; with a suffix (yes/no), the question alone.
  class(menu),  intent(in)           :: self   !< Menu.
  character(*), intent(in), optional :: suffix !< Suffix of the question, the options not shown.
  integer(I4P)                       :: i      !< Counter.

  ! the prompt must be visible before the read: no line end, then flush
  if (present(suffix)) then
    write(self%output_unit, '(A)', advance='no') &
      colorize(self%question//' '//suffix, color_fg=self%question_color, style=self%question_style)//' '
    flush(self%output_unit)
    return
  endif
  do i=1, size(self%options, dim=1)
    if (self%options(i)%is_default) then
      write(self%output_unit, '(A)') colorize(trim(str(i, .true.))//') '//self%default_icon//self%options(i)%text, &
                                              color_fg=self%option_color, style=self%option_style)
    else
      write(self%output_unit, '(A)') colorize(trim(str(i, .true.))//') '//self%options(i)%text, &
                                              color_fg=self%option_color, style=self%option_style)
    endif
  enddo
  write(self%output_unit, '(A)', advance='no') &
    colorize(self%question, color_fg=self%question_color, style=self%question_style)//' '
  flush(self%output_unit)
  endsubroutine show

  subroutine yes_no(self, answer, default, error)
  !< Ask the question as a yes/no one, without the options: y, yes, n, no in any case; an empty answer is the default.
  !<
  !< The prompt ends with (Y/n), (y/N) or (y/n) (no default); retries and the end of the input as `run`.
  class(menu),  intent(inout)         :: self       !< Menu.
  logical,      intent(out)           :: answer     !< Answer (.false. on error).
  character(*), intent(in),  optional :: default    !< Default answer: 'y' or 'n' (any case); none if absent.
  integer(I4P), intent(out), optional :: error      !< Error trapping flag.
  integer(I4P), allocatable           :: choices(:) !< 1 for yes, 2 for no.
  character(1)                        :: default_   !< Default: 'Y', 'N' or ' ' (none).
  integer(I4P)                        :: error_     !< Error trapping flag, local variable.

  answer = .false.
  default_ = ' '
  error_ = 0
  if (present(default)) then
    if (upper_case(default) == 'Y' .or. upper_case(default) == 'N') then
      default_ = upper_case(default)
    else
      error_ = self%raise(ERROR_MENU_DEFINITION, 'the default of a yes/no question is y or n, not "'//default//'"')
    endif
  endif
  if (error_ == 0) then
    call self%ask(choices, error_, yes_no=default_)
    if (error_ == 0) answer = choices(1) == 1
  endif
  if (present(error)) error = error_
  endsubroutine yes_no

  pure subroutine evaluate(self, answer, choices, error, message)
  !< The indexes of an answer (no blanks around): the defaults for an empty one; none on error, with its message.
  !<
  !< Checked in order: several fields without multiple selection (too many), each field a number shown (invalid, also an
  !< empty field), an index repeated (duplicate).
  class(menu),                   intent(in)  :: self       !< Menu.
  character(*),                  intent(in)  :: answer     !< Answer.
  integer(I4P), allocatable,     intent(out) :: choices(:) !< Chosen indexes.
  integer(I4P),                  intent(out) :: error      !< Error code.
  character(len=:), allocatable, intent(out) :: message    !< Error message.
  type(flap_string), allocatable             :: fields(:)  !< Fields of the answer.
  integer(I4P)                               :: n          !< Number of options.
  integer(I4P)                               :: i          !< Counter.

  error = 0
  message = ''
  n = size(self%options, dim=1)
  if (len(answer) == 0) then
    allocate(choices(count(self%options(:)%is_default)))
    choices = pack([(i, i=1, n)], self%options(:)%is_default)
    if (size(choices, dim=1) == 0) then
      error = ERROR_MENU_NO_RESPONSE
      message = 'no response'
    endif
    return
  endif
  call split_fields(answer, self%separator, fields)
  allocate(choices(size(fields, dim=1)))
  if (size(fields, dim=1) > 1 .and. .not.self%multiple) then
    error = ERROR_MENU_TOO_MANY
    message = 'too many responses: '//answer
  else
    do i=1, size(fields, dim=1)
      choices(i) = option_index(fields(i)%s, n)
    enddo
    if (any(choices == 0)) then
      error = ERROR_MENU_INVALID
      message = 'invalid response: '//answer
    else
      do i=2, size(choices, dim=1)
        if (any(choices(:i-1) == choices(i))) then
          error = ERROR_MENU_DUPLICATE
          message = 'duplicate response: '//answer
          exit
        endif
      enddo
    endif
  endif
  if (error /= 0) then
    deallocate(choices)
    allocate(choices(0))
  endif
  endsubroutine evaluate

  pure function default_index(self) result(i)
  !< Index of the (first) default option, 0 if none.
  class(menu), intent(in) :: self !< Menu.
  integer(I4P)            :: i    !< Index.

  if (allocated(self%options)) then
    do i=1, size(self%options, dim=1)
      if (self%options(i)%is_default) return
    enddo
  endif
  i = 0
  endfunction default_index

  function raise(self, code, message) result(error)
  !< Write an error message on the error unit and return its code.
  class(menu),  intent(in) :: self    !< Menu.
  integer(I4P), intent(in) :: code    !< Error code.
  character(*), intent(in) :: message !< Error message.
  integer(I4P)             :: error   !< Error code.

  if (allocated(self%error_color) .and. allocated(self%error_style)) then
    write(self%error_unit, '(A)') colorize('error', color_fg=self%error_color, style=self%error_style)//': '//message
  else
    write(self%error_unit, '(A)') 'error: '//message
  endif
  error = code
  endfunction raise

  elemental subroutine finalize(self)
  !< Free dynamic memory when finalizing.
  type(menu), intent(inout) :: self !< Menu.

  call self%free
  endsubroutine finalize

  ! non type-bound procedures
  pure subroutine evaluate_yes_no(answer, default, choices, error, message)
  !< The index of a yes/no answer (no blanks around): 1 for y/yes, 2 for n/no (any case), the default if empty.
  character(*),                  intent(in)  :: answer     !< Answer.
  character(1),                  intent(in)  :: default    !< Default: 'Y', 'N' or ' ' (none).
  integer(I4P), allocatable,     intent(out) :: choices(:) !< [1] for yes, [2] for no; none on error.
  integer(I4P),                  intent(out) :: error      !< Error code.
  character(len=:), allocatable, intent(out) :: message    !< Error message.
  character(len=:), allocatable              :: word       !< Answer or default, upper case.

  error = 0
  message = ''
  word = upper_case(answer)
  if (len(word) == 0) word = trim(default)
  select case(word)
  case('Y', 'YES')
    choices = [1_I4P]
  case('N', 'NO')
    choices = [2_I4P]
  case('')
    allocate(choices(0))
    error = ERROR_MENU_NO_RESPONSE
    message = 'no response'
  case default
    allocate(choices(0))
    error = ERROR_MENU_INVALID
    message = 'invalid response: '//answer
  endselect
  endsubroutine evaluate_yes_no

  pure subroutine split_fields(answer, separator, fields)
  !< Split an answer into fields: a blank separator splits at runs of blanks; any other exactly, each field trimmed (so
  !< `1,,3` has an empty field). Not `tokenize`, whose trailing-token behaviour belongs to the parser.
  character(*),                   intent(in)  :: answer    !< Answer (no blanks around, not empty).
  character(*),                   intent(in)  :: separator !< Separator.
  type(flap_string), allocatable, intent(out) :: fields(:) !< Fields.
  integer(I4P)                                :: nf        !< Number of fields.
  integer(I4P)                                :: p         !< Position.
  integer(I4P)                                :: q         !< Position of the next separator.
  integer(I4P)                                :: i         !< Counter.
  integer(I4P)                                :: pass_     !< Pass: 1 counts, 2 fills (sized first, see add_option).

  do pass_=1, 2
    nf = 0
    if (len_trim(separator) == 0) then
      p = 1
      do while (p <= len(answer))
        if (answer(p:p) == ' ') then
          p = p + 1
          cycle
        endif
        q = scan(answer(p:), ' ')
        if (q == 0) then
          q = len(answer) + 1
        else
          q = p + q - 1
        endif
        nf = nf + 1
        if (pass_ == 2) fields(nf)%s = answer(p:q-1)
        p = q
      enddo
    else
      p = 1
      do
        q = index(answer(p:), separator)
        nf = nf + 1
        if (q == 0) then
          if (pass_ == 2) fields(nf)%s = trim(adjustl(answer(p:)))
          exit
        endif
        if (pass_ == 2) fields(nf)%s = trim(adjustl(answer(p:p+q-2)))
        p = p + q - 1 + len(separator)
      enddo
    endif
    if (pass_ == 1) allocate(fields(nf))
  enddo
  do i=1, nf
    if (.not.allocated(fields(i)%s)) fields(i)%s = ''
  enddo
  endsubroutine split_fields

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

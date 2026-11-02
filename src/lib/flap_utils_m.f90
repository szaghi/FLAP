!< FLAP utils.
module flap_utils_m
!< FLAP utils.
use penf

implicit none
private
public :: count
public :: csv_split
public :: skill_name
public :: error_class
public :: error_exit_status
public :: fish_escape
public :: ps_escape
public :: flap_string
public :: json_array
public :: json_string
public :: levenshtein
public :: to_characters
public :: LIST_SEP
public :: list_count
public :: list_items
public :: list_join
public :: list_push
public :: read_env
public :: read_line
public :: replace
public :: replace_all
public :: split_command_line
public :: suggestion_items
public :: suggestions
public :: tokenize
public :: unique
public :: upper_case
public :: wstrip
public :: write_text

character(len=*), parameter :: LIST_SEP = '||!||' !< Separator of the items of a stored list: v1||!||v2||!||.

type :: flap_string
  !< A string of any length. Arrays of it replace arrays of deferred-length strings in derived types: nvfortran 26.5
  !< corrupts the heap when copying a type with a `character(len=:), allocatable :: a(:)` component (B33 of #125).
  character(len=:), allocatable :: s !< The string.
endtype flap_string

interface count
  !< Overload intrinsic function count for counting substring occurences into strings.
  module procedure count_substring
endinterface
integer(I4P), parameter, public :: EXIT_APPLICATION = 1 !< Exit status of an application error.
integer(I4P), parameter, public :: EXIT_USAGE       = 2 !< Exit status of an error of the command line.
integer(I4P), parameter, public :: EXIT_ENVIRONMENT = 3 !< Exit status of an error of a file or a variable.
integer(I4P), parameter, public :: EXIT_DEFINITION  = 4 !< Exit status of an error of the program's definitions or calls.

contains
  pure function skill_name(progname) result(name)
  !< Return a name valid for an Agent Skill (#129) from a program name: the base name, lower case, any other character a hyphen,
  !< no leading, trailing or repeated hyphen, at most 64 characters; 'program' if nothing is left.
  character(*), intent(in)      :: progname !< Program name.
  character(len=:), allocatable :: name     !< Skill name.
  character(1)                  :: c        !< Character.
  integer(I4P)                  :: i        !< Counter.

  name = ''
  do i=index(progname, '/', back=.true.)+1, len_trim(progname)
    c = progname(i:i)
    if (c >= 'A' .and. c <= 'Z') c = achar(iachar(c) + 32)
    if ((c >= 'a' .and. c <= 'z') .or. (c >= '0' .and. c <= '9')) then
      if (len(name) < 64) name = name//c
    elseif (len(name) > 0 .and. len(name) < 64) then
      if (name(len(name):) /= '-') name = name//'-'
    endif
  enddo
  if (len(name) > 0) then
    if (name(len(name):) == '-') name = name(:len(name)-1)
  endif
  if (len(name) == 0) name = 'program'
  endfunction skill_name

  pure function error_class(code) result(class_name)
  !< Return the class of an error code (#129), as in the table of `docs/guide/errors.md`: what the caller must change.
  !< '' for a status, for no error and for an unknown code.
  integer(I4P), intent(in)      :: code       !< Error code.
  character(len=:), allocatable :: class_name !< Class.

  select case(code)
  case(7:10, 13:15, 23:26, 31, 38:41, 47, 50, 101:103, 1003, 1004, 1010, 1013, 2001:2004)
    class_name = 'usage'
  case(33:35, 43, 1006, 1007, 1011, 1012, 2005)
    class_name = 'environment'
  case(1:6, 11, 12, 16:22, 27:30, 32, 36, 37, 42, 44:46, 48, 49, 51, 52, 100, 104:106, 1000:1002, 1008, 1009, 1014, 1015, 2006)
    class_name = 'definition'
  case(1005)
    class_name = 'application'
  case default
    class_name = ''
  endselect
  endfunction error_class

  pure function error_exit_status(code) result(status)
  !< Return the exit status of an error code or a status (#129): 0 for success and for the statuses, 2 for STATUS_NO_ARGS and
  !< the `usage` class, 3 `environment`, 4 `definition`, 1 `application`. An unknown argument that the program asked to ignore
  !< (ERROR_UNKNOWN_CLAS_IGNORED) is a success.
  integer(I4P), intent(in) :: code   !< Error code or status.
  integer(I4P)             :: status !< Exit status.

  status = 0
  if (code == -5_I4P) status = EXIT_USAGE
  if (code <= 0 .or. code == 1004_I4P) return
  select case(error_class(code))
  case('usage')
    status = EXIT_USAGE
  case('environment')
    status = EXIT_ENVIRONMENT
  case('definition')
    status = EXIT_DEFINITION
  case default
    status = EXIT_APPLICATION
  endselect
  endfunction error_exit_status

  elemental function count_substring(string, substring) result(No)
  !< Count the number of (non-overlapping) occurences of a substring into a string.
  character(*), intent(in) :: string    !< String.
  character(*), intent(in) :: substring !< Substring.
  integer(I4P)             :: No        !< Number of occurrences.
  integer(I4P)             :: c1        !< Start of the part of the string still to be searched.
  integer(I4P)             :: c2        !< Position of the next occurrence, relative to c1.

  No = 0
  if (len(substring) == 0 .or. len(substring) > len(string)) return
  c1 = 1
  do
    c2 = index(string=string(c1:), substring=substring)
    if (c2 == 0) return
    No = No + 1
    c1 = c1 + c2 - 1 + len(substring)
  enddo
  endfunction count_substring

  pure function to_characters(strings) result(chars)
  !< Return an array of strings as a character array, each element as long as the longest string.
  type(flap_string), intent(in)            :: strings(:) !< Strings.
  character(len=:), allocatable            :: chars(:)   !< Characters.
  integer(I4P)                             :: l          !< Length of the longest string.
  integer(I4P)                             :: i          !< Counter.

  l = 0
  do i=1, size(strings, dim=1)
    if (allocated(strings(i)%s)) l = max(l, len(strings(i)%s))
  enddo
  allocate(character(len=l) :: chars(1:size(strings, dim=1)))
  do i=1, size(strings, dim=1)
    chars(i) = ''
    if (allocated(strings(i)%s)) chars(i) = strings(i)%s
  enddo
  endfunction to_characters

  pure function list_count(list) result(n)
  !< Return the number of items of a stored list; an empty (blank) list has none.
  character(*), intent(in) :: list !< Stored list.
  integer(I4P)             :: n    !< Number of items.

  n = 0
  if (len_trim(list) == 0) return
  n = count(list, LIST_SEP)
  if (len(list) < len(LIST_SEP)) then
    n = 1
  elseif (list(len(list)-len(LIST_SEP)+1:) /= LIST_SEP) then
    n = n + 1 ! last item without its trailing separator (as the defaults are stored)
  endif
  endfunction list_count

  pure subroutine list_items(list, items, n)
  !< Return the items of a stored list, each as long as the whole list; an empty (blank) list has none.
  character(*),              intent(in)  :: list     !< Stored list.
  character(:), allocatable, intent(out) :: items(:) !< Items.
  integer(I4P),              intent(out) :: n        !< Number of items.
  character(len(list)), allocatable      :: toks(:)  !< Tokens.

  n = list_count(list)
  allocate(character(len(list)) :: items(n))
  if (n == 0) return
  call tokenize(strin=list, delimiter=LIST_SEP, toks=toks)
  items = toks(1:n)
  endsubroutine list_items

  pure function list_join(list, sep) result(joined)
  !< Return the items of a stored list with a separator between them.
  character(*), intent(in)  :: list   !< Stored list.
  character(*), intent(in)  :: sep    !< Separator.
  character(:), allocatable :: joined !< Joined items.
  integer(I4P)              :: last   !< End of the last item.

  joined = ''
  if (len_trim(list) == 0) return
  last = len(list)
  if (last >= len(LIST_SEP)) then
    if (list(last-len(LIST_SEP)+1:) == LIST_SEP) last = last - len(LIST_SEP)
  endif
  joined = replace_all(string=list(1:last), substring=LIST_SEP, restring=sep)
  endfunction list_join

  pure subroutine list_push(list, item)
  !< Append an item to a stored list (an unallocated list is empty).
  character(:), allocatable, intent(inout) :: list !< Stored list.
  character(*),              intent(in)    :: item !< Item.

  if (.not.allocated(list)) list = ''
  list = list//item//LIST_SEP
  endsubroutine list_push

  subroutine read_env(name, value, found, ignore)
  !< Read an environment variable, whatever the length of its value: the only environment lookup of the library.
  !<
  !< Every lookup goes through here (step 0.D.2 of #125), so that `ignore_env` (F20) applies to all of them.
  character(*),              intent(in)  :: name   !< Name of the variable.
  character(:), allocatable, intent(out) :: value  !< Value; empty when the variable is not set.
  logical,                   intent(out) :: found  !< True if the variable is set (maybe to an empty value).
  logical, optional,         intent(in)  :: ignore !< Ignore the environment: never found (ignore_env).
  integer(I4P)                           :: length !< Length of the value.
  integer(I4P)                           :: status !< Retrieval status.

  value = ''
  found = .false.
  if (present(ignore)) then
    if (ignore) return
  endif
  call get_environment_variable(name=name, length=length, status=status)
  found = status == 0
  if (.not.found .or. length == 0) return
  deallocate(value)
  allocate(character(length) :: value)
  call get_environment_variable(name=name, value=value, status=status)
  found = status == 0
  if (.not.found) value = ''
  endsubroutine read_env

  subroutine read_line(lun, line, iostat, iomsg)
  !< Read a whole line of any length (non-advancing reads); a last line without line end is a line.
  !<
  !< `iostat` is 0 for a line, an end-of-file code (`is_iostat_end`) at the end of the input, positive for a read error.
  integer(I4P),                  intent(in)            :: lun    !< Unit.
  character(len=:), allocatable, intent(out)           :: line   !< Line.
  integer(I4P),                  intent(out)           :: iostat !< I/O status: 0, end of file, or an error.
  character(*),                  intent(out), optional :: iomsg  !< I/O message of an error.
  character(256)                                       :: chunk  !< Chunk.
  character(256)                                       :: msg    !< I/O message.
  integer(I4P)                                         :: size_  !< Characters read.

  line = ''
  msg = ''
  if (present(iomsg)) iomsg = ''
  do
    read(lun, '(A)', advance='no', iostat=iostat, iomsg=msg, size=size_) chunk
    line = line//chunk(1:size_)
    if (is_iostat_eor(iostat)) then
      iostat = 0
      return
    elseif (iostat /= 0) then
      if (is_iostat_end(iostat) .and. len(line) > 0) iostat = 0
      if (iostat > 0 .and. present(iomsg)) iomsg = trim(msg)
      return
    endif
  enddo
  endsubroutine read_line

  pure function replace(string, substring, restring) result(newstring)
  !< Replace substring (only first occurrence) into a string.
  character(len=*), intent(in)  :: string    !< String to be modified.
  character(len=*), intent(in)  :: substring !< Substring to be replaced.
  character(len=*), intent(in)  :: restring  !< String to be inserted.
  character(len=:), allocatable :: newstring !< New modified string.
  integer(I4P)                  :: pos       !< Position from which replace the substring.

  pos = index(string=string, substring=substring)
  newstring = string
  if (pos>0) then
    if (pos==1) then
      newstring = restring//string(len(substring)+1:)
    else
      newstring = string(1:pos-1)//restring//string(pos+len(substring):)
    endif
  endif
  endfunction replace

  pure function replace_all(string, substring, restring) result(newstring)
  !< Replace substring (all occurrences) into a string.
  !<
  !< The string is scanned once from left to right, so a replacement containing the substring is not replaced again.
  !< @note Leading and trailing white spaces are stripped out.
  character(len=*), intent(in)  :: string    !< String to be modified.
  character(len=*), intent(in)  :: substring !< Substring to be replaced.
  character(len=*), intent(in)  :: restring  !< String to be inserted.
  character(len=:), allocatable :: newstring !< New modified string.
  character(len=:), allocatable :: rest      !< Part of the string still to be scanned.
  integer(I4P)                  :: pos       !< Position of the next occurrence in rest.

  rest = wstrip(string)
  if (len(substring) == 0) then
    newstring = rest
    return
  endif
  newstring = ''
  do
    pos = index(rest, substring)
    if (pos == 0) exit
    newstring = newstring//rest(1:pos-1)//restring
    rest = rest(pos+len(substring):)
  enddo
  newstring = newstring//rest
  endfunction replace_all

  pure subroutine tokenize(strin, delimiter, toks, Nt)
  !< Tokenize a string in order to parse it.
  !<
  !< @note The dummy array containing tokens must allocatable and its character elements must have the same length of the input
  !< string. If the length of the delimiter is higher than the input string one then the output tokens array is allocated with
  !< only one element set to input string.
  character(len=*),          intent(in)               :: strin     !< String to be tokenized.
  character(len=*),          intent(in)               :: delimiter !< Delimiter of tokens.
  character(len=len(strin)), intent(out), allocatable :: toks(:)   !< Tokens.
  integer(I4P),              intent(out), optional    :: Nt        !< Number of tokens.
  character(len=len(strin))                           :: strsub    !< Temporary string.
  integer(I4P)                                        :: dlen      !< Delimiter length.
  integer(I4P)                                        :: c         !< Counter.
  integer(I4P)                                        :: n         !< Counter.
  integer(I4P)                                        :: t         !< Counter.

  ! initialization
  if (allocated(toks)) deallocate(toks)
  strsub = strin
  dlen = len(delimiter)
  if (dlen>len(strin)) then
    allocate(toks(1:1)) ; toks(1) = strin ; if (present(Nt)) Nt = 1 ; return
  endif
  ! compute the number of tokens
  n = 1
  do c=1,len(strsub)-dlen ! loop over string characters
    if (strsub(c:c+dlen-1)==delimiter) n = n + 1
  enddo
  allocate(toks(1:n))
  ! tokenization
  do t=1,n ! loop over tokens
    c = index(strsub, delimiter)
    if (c>0) then
      toks(t) = strsub(1:c-1)
      strsub = strsub(c+dlen:)
    else
      toks(t) = strsub
    endif
  enddo
  if (present(Nt)) Nt = n
  endsubroutine tokenize

  pure subroutine split_command_line(strin, toks, Nt)
  !< Split a command line string into arguments, in one pass, with shell-like quoting.
  !<
  !< Blanks and tabs separate arguments outside quotes. Text inside `'...'` or `"..."` is taken literally (both kinds, a quote
  !< of the other kind included); a quoted part is joined to the adjacent text (`ab"c d"e` is `abc de`), and a quoted empty
  !< string is an empty argument. An unterminated quote extends to the end of the string. There are no escape characters.
  character(len=*),          intent(in)               :: strin   !< Command line string.
  character(len=len(strin)), intent(out), allocatable :: toks(:) !< Arguments.
  integer(I4P),              intent(out)              :: Nt      !< Number of arguments.
  character(len=len(strin))                           :: tok     !< Argument being scanned.
  character(len=1)                                    :: quote   !< Open quote, blank when outside quotes.
  logical                                             :: in_tok  !< An argument is being scanned.
  logical                                             :: close_tok !< The argument being scanned ends here.
  integer(I4P)                                        :: l       !< Length of the argument being scanned.
  integer(I4P)                                        :: c       !< Character counter.
  integer(I4P)                                        :: pass    !< Pass: 1 counts the arguments, 2 stores them.

  do pass=1, 2
    Nt = 0
    l = 0
    in_tok = .false.
    quote = ' '
    do c=1, len(strin) + 1 ! the position after the last character acts as a final separator
      close_tok = .false.
      if (c > len(strin)) then
        close_tok = in_tok
      elseif (quote /= ' ') then
        if (strin(c:c) == quote) then
          quote = ' '
        else
          l = l + 1
          tok(l:l) = strin(c:c)
        endif
      elseif (strin(c:c) == "'" .or. strin(c:c) == '"') then
        quote = strin(c:c)
        in_tok = .true.
      elseif (strin(c:c) == ' ' .or. strin(c:c) == achar(9)) then
        close_tok = in_tok
      else
        l = l + 1
        tok(l:l) = strin(c:c)
        in_tok = .true.
      endif
      if (close_tok) then
        Nt = Nt + 1
        if (pass == 2) toks(Nt) = tok(1:l)
        l = 0
        in_tok = .false.
      endif
    enddo
    if (pass == 1) allocate(toks(1:Nt))
  enddo
  endsubroutine split_command_line

  pure function json_string(text) result(quoted)
  !< Return a text as a JSON string, quotes included (#128): control characters are escaped, and invalid UTF-8 is replaced by
  !< U+FFFD, since command lines and environment values are bytes while a JSON document must be valid UTF-8.
  character(*), intent(in)      :: text   !< Text.
  character(len=:), allocatable :: quoted !< JSON string.
  character(1), parameter       :: BS = achar(92) !< Backslash (a literal one is an escape for nvfortran, without -Mbackslash).
  character(len=6*len(text)+2)  :: buffer !< Escaped text; a byte takes 6 characters at most.
  character(16), parameter      :: HEXA = '0123456789abcdef' !< Hexadecimal digits.
  integer(I4P)                  :: i      !< Position in the text.
  integer(I4P)                  :: n      !< Position in the buffer.
  integer(I4P)                  :: code   !< Code of a byte.
  integer(I4P)                  :: seq    !< Length of a valid UTF-8 sequence.

  n = 1
  buffer(1:1) = '"'
  i = 1
  do while (i <= len(text))
    code = iachar(text(i:i))
    if (code < 0) code = code + 256
    if (text(i:i) == '"' .or. text(i:i) == BS) then
      buffer(n+1:n+2) = BS//text(i:i)
      n = n + 2
    elseif (code < 32) then
      select case(code)
      case(8)
        buffer(n+1:n+2) = BS//'b'
        n = n + 2
      case(9)
        buffer(n+1:n+2) = BS//'t'
        n = n + 2
      case(10)
        buffer(n+1:n+2) = BS//'n'
        n = n + 2
      case(12)
        buffer(n+1:n+2) = BS//'f'
        n = n + 2
      case(13)
        buffer(n+1:n+2) = BS//'r'
        n = n + 2
      case default
        buffer(n+1:n+6) = BS//'u00'//HEXA(code/16+1:code/16+1)//HEXA(mod(code,16)+1:mod(code,16)+1)
        n = n + 6
      endselect
    elseif (code < 128) then
      buffer(n+1:n+1) = text(i:i)
      n = n + 1
    else
      seq = utf8_sequence(text(i:))
      if (seq == 0) then
        buffer(n+1:n+6) = BS//'ufffd'
        n = n + 6
      else
        buffer(n+1:n+seq) = text(i:i+seq-1)
        n = n + seq
        i = i + seq - 1
      endif
    endif
    i = i + 1
  enddo
  n = n + 1
  buffer(n:n) = '"'
  quoted = buffer(1:n)
  endfunction json_string

  pure function utf8_sequence(text) result(seq)
  !< Return the length of the valid UTF-8 multi-byte sequence a text starts with, 0 if there is none (RFC 3629: no overlong
  !< form, no surrogate, nothing above U+10FFFF).
  character(*), intent(in) :: text !< Text, not empty, starting with a byte above 127.
  integer(I4P)             :: seq  !< Length of the sequence.
  integer(I4P)             :: b(4) !< Codes of the bytes, -1 if absent.
  integer(I4P)             :: i    !< Counter.

  b = -1
  do i=1, min(4, len(text))
    b(i) = iachar(text(i:i))
    if (b(i) < 0) b(i) = b(i) + 256
  enddo
  seq = 0
  if (b(1) >= 194 .and. b(1) <= 223) then
    if (is_continuation(b(2), 128, 191)) seq = 2
  elseif (b(1) == 224) then
    if (is_continuation(b(2), 160, 191) .and. is_continuation(b(3), 128, 191)) seq = 3
  elseif (b(1) == 237) then
    if (is_continuation(b(2), 128, 159) .and. is_continuation(b(3), 128, 191)) seq = 3
  elseif (b(1) >= 225 .and. b(1) <= 239) then
    if (is_continuation(b(2), 128, 191) .and. is_continuation(b(3), 128, 191)) seq = 3
  elseif (b(1) == 240) then
    if (is_continuation(b(2), 144, 191) .and. is_continuation(b(3), 128, 191) .and. is_continuation(b(4), 128, 191)) seq = 4
  elseif (b(1) >= 241 .and. b(1) <= 243) then
    if (is_continuation(b(2), 128, 191) .and. is_continuation(b(3), 128, 191) .and. is_continuation(b(4), 128, 191)) seq = 4
  elseif (b(1) == 244) then
    if (is_continuation(b(2), 128, 143) .and. is_continuation(b(3), 128, 191) .and. is_continuation(b(4), 128, 191)) seq = 4
  endif
  contains
    pure function is_continuation(byte, low, high) result(valid)
    !< Check a byte against its allowed interval.
    integer(I4P), intent(in) :: byte  !< Code of the byte.
    integer(I4P), intent(in) :: low   !< Lowest allowed.
    integer(I4P), intent(in) :: high  !< Highest allowed.
    logical                  :: valid !< Check result.

    valid = byte >= low .and. byte <= high
    endfunction is_continuation
  endfunction utf8_sequence

  pure function json_array(items) result(array)
  !< Return an array of strings as a JSON array, on one line.
  type(flap_string), intent(in) :: items(:) !< Items.
  character(len=:), allocatable :: array    !< JSON array.
  integer(I4P)                  :: i        !< Counter.

  array = '['
  do i=1, size(items, dim=1)
    if (i > 1) array = array//','
    array = array//json_string(items(i)%s)
  enddo
  array = array//']'
  endfunction json_array

  subroutine write_text(lun, text)
  !< Write a text on a unit. The text is an argument, so a function building it (usage, signature) is evaluated before the
  !< write starts: nvfortran 26.5 loses the output of a write whose output list calls a function that does I/O itself.
  integer(I4P), intent(in) :: lun  !< Unit.
  character(*), intent(in) :: text !< Text.

  write(lun, '(A)') text
  endsubroutine write_text

  pure subroutine csv_split(record, fields, nf, error)
  !< Split one CSV record (an RFC 4180 subset), the format of list values read from the environment (F22 of #125).
  !<
  !< The separator is ','; a field in "..." may hold commas, and "" in it is a literal "; blanks around an unquoted field
  !< are trimmed, those inside quotes kept; a quote inside an unquoted field is kept; an empty or blank record has no field.
  !< Not to be confused with tokenize, whose trailing-token behaviour the stored lists rely on.
  character(*),                   intent(in)  :: record    !< CSV record.
  type(flap_string), allocatable, intent(out) :: fields(:) !< Fields, with their exact length.
  integer(I4P),                   intent(out) :: nf        !< Number of fields.
  integer(I4P),                   intent(out) :: error     !< 0, or 1 for an unterminated quote.
  type(flap_string), allocatable              :: found(:)  !< Fields found (at most one more than the commas).
  character(len=:), allocatable               :: field     !< Current field.
  integer(I4P)                                :: n         !< Length of the record.
  integer(I4P)                                :: i         !< Cursor.
  integer(I4P)                                :: c         !< Position of the next comma, relative to the cursor.
  logical                                     :: closed    !< The quoted field is closed.

  nf = 0
  error = 0
  n = len(record)
  allocate(found(1:count(record, ',') + 1))
  if (len_trim(record) > 0) then
    i = 1
    do
      do while (i <= n)
        if (record(i:i) /= ' ') exit
        i = i + 1
      enddo
      field = ''
      if (i <= n .and. record(min(i, n):min(i, n)) == '"') then
        ! quoted: up to the closing quote, "" being a literal quote
        i = i + 1
        closed = .false.
        do while (i <= n)
          if (record(i:i) == '"') then
            if (i < n) then
              if (record(i+1:i+1) == '"') then
                field = field//'"'
                i = i + 2
                cycle
              endif
            endif
            closed = .true.
            i = i + 1
            exit
          endif
          field = field//record(i:i)
          i = i + 1
        enddo
        if (.not.closed) then
          error = 1
          nf = 0
          allocate(fields(0))
          return
        endif
        ! anything between the closing quote and the comma is kept, blanks trimmed
        c = index(record(i:), ',')
        if (c == 0) then
          field = field//trim(adjustl(record(i:)))
        else
          field = field//trim(adjustl(record(i:i+c-2)))
        endif
      else
        c = index(record(i:), ',')
        if (c == 0) then
          field = trim(record(i:))
        else
          field = trim(record(i:i+c-2))
        endif
      endif
      nf = nf + 1
      found(nf)%s = field
      if (c == 0) exit
      i = i + c
      if (i > n) then
        ! a trailing comma: an empty last field
        nf = nf + 1
        found(nf)%s = ''
        exit
      endif
    enddo
  endif
  allocate(fields(1:nf))
  do i=1, nf
    fields(i)%s = found(i)%s
  enddo
  endsubroutine csv_split

  elemental function unique(string, substring) result(uniq)
  !< Reduce to one (unique) multiple (sequential) occurrences of a characters substring into a string.
  !<
  !< For example the string ' ab-cre-cre-ab' is reduce to ' ab-cre-ab' if the substring is '-cre'. The result has the length
  !< of the input string, padded with trailing blanks.
  character(len=*), intent(in)  :: string    !< String to be parsed.
  character(len=*), intent(in)  :: substring !< Substring which multiple occurences must be reduced to one.
  character(len=len(string))    :: uniq      !< String parsed.
  character(len=:), allocatable :: reduced   !< Reduced string.
  logical                       :: previous  !< The previous piece was an occurrence of the substring.
  integer(I4P)                  :: Lsub      !< Lenght of substring.
  integer(I4P)                  :: c         !< Counter.

  uniq = string
  Lsub = len(substring)
  if (Lsub == 0 .or. Lsub > len(string)) return
  reduced = ''
  previous = .false.
  c = 1
  do while (c <= len(string))
    if (c + Lsub - 1 <= len(string)) then
      if (string(c:c+Lsub-1) == substring) then
        if (.not.previous) reduced = reduced//substring
        previous = .true.
        c = c + Lsub
        cycle
      endif
    endif
    reduced = reduced//string(c:c)
    previous = .false.
    c = c + 1
  enddo
  uniq = reduced
  endfunction unique

  elemental function upper_case(string)
  !< Convert the lower case characters of a string to upper case one.
  character(len=*), intent(in) :: string                                        !< String to be converted.
  character(len=len(string))   :: upper_case                                    !< Converted string.
  integer                      :: n1                                            !< Characters counter.
  integer                      :: n2                                            !< Characters counter.
  character(len=26), parameter :: upper_alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' !< Upper case alphabet.
  character(len=26), parameter :: lower_alphabet = 'abcdefghijklmnopqrstuvwxyz' !< Lower case alphabet.

  upper_case = string
  do n1=1, len(string)
    n2 = index(lower_alphabet, string(n1:n1))
    if (n2>0) upper_case(n1:n1) = upper_alphabet(n2:n2)
  enddo
  endfunction upper_case

  pure function fish_escape(text) result(escaped)
  !< Return a text for a fish single-quoted string (F15 of #125): a backslash and a quote are escaped, new lines become
  !< blanks.
  character(*), intent(in)      :: text    !< Text.
  character(len=:), allocatable :: escaped !< Escaped text.
  integer(I4P)                  :: c       !< Counter.

  escaped = ''
  do c=1, len(text)
    select case(text(c:c))
    case("'")
      escaped = escaped//achar(92)//"'" ! achar(92): a backslash (not a literal, which some compilers read as an escape)
    case(achar(92))
      escaped = escaped//achar(92)//achar(92)
    case(achar(10), achar(13))
      escaped = escaped//' '
    case default
      escaped = escaped//text(c:c)
    endselect
  enddo
  endfunction fish_escape

  pure function ps_escape(text) result(escaped)
  !< Return a text for a PowerShell single-quoted string (F15 of #125): a quote is doubled, new lines become blanks.
  character(*), intent(in)      :: text    !< Text.
  character(len=:), allocatable :: escaped !< Escaped text.
  integer(I4P)                  :: c       !< Counter.

  escaped = ''
  do c=1, len(text)
    select case(text(c:c))
    case("'")
      escaped = escaped//"''"
    case(achar(10), achar(13))
      escaped = escaped//' '
    case default
      escaped = escaped//text(c:c)
    endselect
  enddo
  endfunction ps_escape

  pure function levenshtein(a, b) result(d)
  !< Return the Levenshtein (edit) distance of two strings: insertions, deletions and substitutions, two-row dynamic
  !< programming, O(len(a) len(b)).
  character(*), intent(in)  :: a       !< First string.
  character(*), intent(in)  :: b       !< Second string.
  integer(I4P)              :: d       !< Distance.
  integer(I4P), allocatable :: prev(:) !< Distances of the previous row.
  integer(I4P), allocatable :: curr(:) !< Distances of the current row.
  integer(I4P)              :: i       !< Counter of a.
  integer(I4P)              :: j       !< Counter of b.

  allocate(prev(0:len(b)), curr(0:len(b)))
  prev = [(j, j=0, len(b))]
  do i=1, len(a)
    curr(0) = i
    do j=1, len(b)
      curr(j) = min(prev(j) + 1, curr(j-1) + 1, prev(j-1) + merge(0, 1, a(i:i) == b(j:j)))
    enddo
    prev = curr
  enddo
  d = prev(len(b))
  endfunction levenshtein

  pure function suggestions(token, candidates, case_insensitive) result(hint)
  !< Return the "Did you mean" hint of an unknown token (F10 of #125): up to three candidates with similarity
  !< 1 - d/max(len) >= 0.6 (d the Levenshtein distance), most similar first (declaration order among equals), with click's
  !< wording: ' Did you mean "x"?' or ' (Did you mean one of: "x", "y"?)'; '' for none. Case-folded with case_insensitive.
  character(*),      intent(in) :: token            !< Unknown token.
  type(flap_string), intent(in) :: candidates(:)    !< Candidate names.
  logical,           intent(in) :: case_insensitive !< Compare in any case.
  character(len=:), allocatable :: hint             !< Hint.
  type(flap_string), allocatable :: items(:)        !< Candidates chosen.
  integer(I4P)                  :: c                !< Counter.

  items = suggestion_items(token, candidates, case_insensitive)
  hint = ''
  if (size(items) == 1) then
    hint = ' Did you mean "'//items(1)%s//'"?'
  elseif (size(items) > 1) then
    hint = ' (Did you mean one of: "'//items(1)%s//'"'
    do c=2, size(items)
      hint = hint//', "'//items(c)%s//'"'
    enddo
    hint = hint//'?)'
  endif
  endfunction suggestions

  pure function suggestion_items(token, candidates, case_insensitive) result(items)
  !< Return the candidates of the "Did you mean" hint of an unknown token (F10 of #125): up to three with similarity
  !< 1 - d/max(len) >= 0.6 (d the Levenshtein distance), most similar first (declaration order among equals).
  character(*),      intent(in) :: token            !< Unknown token.
  type(flap_string), intent(in) :: candidates(:)    !< Candidate names.
  logical,           intent(in) :: case_insensitive !< Compare in any case.
  type(flap_string), allocatable :: items(:)        !< Candidates chosen.
  real(R8P),        allocatable :: score(:)         !< Similarity of each candidate.
  logical,          allocatable :: taken(:)         !< Candidate already chosen (or excluded).
  integer(I4P)                  :: pick(3)          !< Chosen candidates.
  integer(I4P)                  :: n                !< Number of chosen candidates.
  integer(I4P)                  :: c                !< Counter.
  integer(I4P)                  :: best             !< Best candidate left.
  integer(I4P)                  :: k                !< Counter.
  real(R8P), parameter          :: cutoff = 0.6_R8P !< Minimum similarity.

  allocate(score(size(candidates)), taken(size(candidates)))
  do c=1, size(candidates)
    score(c) = similarity(candidates(c)%s)
    ! a name listed twice (a switch equal to its abbreviation, say) is one candidate
    taken(c) = score(c) < cutoff .or. any([(candidates(c)%s == candidates(k)%s, k=1, c-1)])
  enddo
  n = 0
  do while (n < 3)
    best = 0
    do c=1, size(candidates)
      if (taken(c)) cycle
      if (best == 0) then
        best = c
      elseif (score(c) > score(best)) then
        best = c
      endif
    enddo
    if (best == 0) exit
    n = n + 1
    pick(n) = best
    taken(best) = .true.
  enddo
  allocate(items(n))
  do c=1, n
    items(c)%s = candidates(pick(c))%s
  enddo
  contains
    pure function similarity(name) result(sim)
    !< Similarity of a candidate to the token, 1 - d/max(len).
    character(*), intent(in) :: name !< Candidate.
    real(R8P)                :: sim  !< Similarity.
    integer(I4P)             :: l    !< Longest length.

    l = max(len(name), len(token))
    sim = 0._R8P
    if (l == 0 .or. len(name) == 0) return
    if (case_insensitive) then
      sim = 1._R8P - real(levenshtein(upper_case(name), upper_case(token)), R8P) / l
    else
      sim = 1._R8P - real(levenshtein(name, token), R8P) / l
    endif
    endfunction similarity
  endfunction suggestion_items

  pure function wstrip(string) result(newstring)
  !< Strip out leading and trailing white spaces from a string.
  character(len=*), intent(in)  :: string    !< String to be modified.
  character(len=:), allocatable :: newstring !< New modified string.

  newstring = trim(adjustl(string)) ! not allocate(source=...): nvfortran 26.5 crashes on it (B31 of #125)
  endfunction wstrip
endmodule flap_utils_m

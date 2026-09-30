!< FLAP utils.
module flap_utils_m
!< FLAP utils.
use penf

implicit none
private
public :: count
public :: csv_split
public :: flap_string
public :: to_characters
public :: LIST_SEP
public :: list_count
public :: list_items
public :: list_join
public :: list_push
public :: read_env
public :: replace
public :: replace_all
public :: split_command_line
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
contains
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

  pure function wstrip(string) result(newstring)
  !< Strip out leading and trailing white spaces from a string.
  character(len=*), intent(in)  :: string    !< String to be modified.
  character(len=:), allocatable :: newstring !< New modified string.

  newstring = trim(adjustl(string)) ! not allocate(source=...): nvfortran 26.5 crashes on it (B31 of #125)
  endfunction wstrip
endmodule flap_utils_m

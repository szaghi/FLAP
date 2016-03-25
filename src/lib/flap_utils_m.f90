!< FLAP utils.
module flap_utils_m
!-----------------------------------------------------------------------------------------------------------------------------------
!< FLAP utils.
!-----------------------------------------------------------------------------------------------------------------------------------
use penf
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
public :: count
public :: replace
public :: replace_all
public :: tokenize
public :: unique
public :: upper_case
public :: wstrip
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
interface count
  !< Overload intrinsic function count for counting substring occurences into strings.
  module procedure count_substring
endinterface
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  elemental function count_substring(string, substring) result(No)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Count the number of occurences of a substring into a string.
  !---------------------------------------------------------------------------------------------------------------------------------
  character(*), intent(in) :: string    !< String.
  character(*), intent(in) :: substring !< Substring.
  integer(I4P)             :: No        !< Number of occurrences.
  integer(I4P)             :: c1        !< Counters.
  integer(I4P)             :: c2        !< Counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  No = 0
  if (len(substring)>len(string)) return
  c1 = 1
  do
    c2 = index(string=string(c1:), substring=substring)
    if (c2==0) return
    No = No + 1
    c1 = c1 + c2 + len(substring)
  enddo
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction count_substring

  pure function replace(string, substring, restring) result(newstring)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Replace substring (only first occurrence) into a string.
  !---------------------------------------------------------------------------------------------------------------------------------
  character(len=*), intent(in)  :: string    !< String to be modified.
  character(len=*), intent(in)  :: substring !< Substring to be replaced.
  character(len=*), intent(in)  :: restring  !< String to be inserted.
  character(len=:), allocatable :: newstring !< New modified string.
  integer(I4P)                  :: pos       !< Position from which replace the substring.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  pos = index(string=string, substring=substring)
  newstring = string
  if (pos>0) then
    if (pos==1) then
      newstring = restring//string(len(substring)+1:)
    else
      newstring = string(1:pos-1)//restring//string(pos+len(substring):)
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction replace

  pure function replace_all(string, substring, restring) result(newstring)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Replace substring (all occurrences) into a string.
  !<
  !< @note Leading and trailing white spaces are stripped out.
  !---------------------------------------------------------------------------------------------------------------------------------
  character(len=*), intent(in)  :: string             !< String to be modified.
  character(len=*), intent(in)  :: substring          !< Substring to be replaced.
  character(len=*), intent(in)  :: restring           !< String to be inserted.
  character(len=:), allocatable :: newstring          !< New modified string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  newstring = wstrip(string)
  do
    if (index(newstring, substring)>0) then
      newstring = replace(string=newstring, substring=substring, restring=restring)
    else
      exit
    endif
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction replace_all

  pure subroutine tokenize(strin, delimiter, toks, Nt)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Tokenize a string in order to parse it.
  !<
  !< @note The dummy array containing tokens must allocatable and its character elements must have the same length of the input
  !< string. If the length of the delimiter is higher than the input string one then the output tokens array is allocated with
  !< only one element set to char(0).
  !---------------------------------------------------------------------------------------------------------------------------------
  character(len=*),          intent(in)               :: strin     !< String to be tokenized.
  character(len=*),          intent(in)               :: delimiter !< Delimiter of tokens.
  character(len=len(strin)), intent(out), allocatable :: toks(:)   !< Tokens.
  integer(I4P),              intent(out), optional    :: Nt        !< Number of tokens.
  character(len=len(strin))                           :: strsub    !< Temporary string.
  integer(I4P)                                        :: dlen      !< Delimiter length.
  integer(I4P)                                        :: c         !< Counter.
  integer(I4P)                                        :: n         !< Counter.
  integer(I4P)                                        :: t         !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! initialization
  if (allocated(toks)) deallocate(toks)
  strsub = strin
  dlen = len(delimiter)
  if (dlen>len(strin)) then
    allocate(toks(1:1)) ; toks(1) = char(0) ; if (present(Nt)) Nt = 1 ; return
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
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine tokenize

  pure function unique(string, substring) result(uniq)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Reduce to one (unique) multiple (sequential) occurrences of a characters substring into a string.
  !<
  !< For example the string ' ab-cre-cre-ab' is reduce to 'ab-cre-ab' if the substring is '-cre'.
  !< @note Eventual multiple trailing white space are not reduced to one occurrence.
  !---------------------------------------------------------------------------------------------------------------------------------
  character(len=*), intent(in) :: string    !< String to be parsed.
  character(len=*), intent(in) :: substring !< Substring which multiple occurences must be reduced to one.
  character(len=len(string))   :: uniq      !< String parsed.
  integer(I4P)                 :: Lsub      !< Lenght of substring.
  integer(I4P)                 :: c1        !< Counter.
  integer(I4P)                 :: c2        !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  uniq = string
  Lsub=len(substring)
  if (Lsub>len(string)) return
  c1 = 1
  Loop1: do
    if (c1>=len_trim(uniq)) exit Loop1
    if (uniq(c1:c1+Lsub-1)==substring.and.uniq(c1+Lsub:c1+2*Lsub-1)==substring) then
      c2 = c1 + Lsub
      Loop2: do
        if (c2>=len_trim(uniq)) exit Loop2
        if (uniq(c2:c2+Lsub-1)==substring) then
          c2 = c2 + Lsub
        else
          exit Loop2
        endif
      enddo Loop2
      uniq = uniq(1:c1)//uniq(c2:)
    else
      c1 = c1 + Lsub
    endif
  enddo Loop1
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction unique

  pure function upper_case(string)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Convert the lower case characters of a string to upper case one.
  !---------------------------------------------------------------------------------------------------------------------------------
  character(len=*), intent(in) :: string                                        !< String to be converted.
  character(len=len(string))   :: upper_case                                    !< Converted string.
  integer                      :: n1                                            !< Characters counter.
  integer                      :: n2                                            !< Characters counter.
  character(len=26), parameter :: upper_alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' !< Upper case alphabet.
  character(len=26), parameter :: lower_alphabet = 'abcdefghijklmnopqrstuvwxyz' !< Lower case alphabet.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  upper_case = string
  do n1=1, len(string)
    n2 = index(lower_alphabet, string(n1:n1))
    if (n2>0) upper_case(n1:n1) = upper_alphabet(n2:n2)
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction upper_case

  pure function wstrip(string) result(newstring)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Strip out leading and trailing white spaces from a string.
  !---------------------------------------------------------------------------------------------------------------------------------
  character(len=*), intent(in)  :: string    !< String to be modified.
  character(len=:), allocatable :: newstring !< New modified string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  allocate(newstring, source=trim(adjustl(string)))
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction wstrip
endmodule flap_utils_m

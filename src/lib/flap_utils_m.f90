!< FLAP utils.
module flap_utils_m
!-----------------------------------------------------------------------------------------------------------------------------------
!< FLAP utils.
!-----------------------------------------------------------------------------------------------------------------------------------
use IR_Precision
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
public :: upper_case
public :: tokenize
!-----------------------------------------------------------------------------------------------------------------------------------
contains
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
    c = index(strsub,delimiter)
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
endmodule flap_utils_m

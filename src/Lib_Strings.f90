!> @ingroup Library
!> @{
!> @defgroup Lib_StringsLibrary Lib_Strings
!> Library of miscellanea procedures for strings operations.
!> @}

!> @ingroup Interface
!> @{
!> @defgroup Lib_StringsInterface Lib_Strings
!> Library of miscellanea procedures for strings operations.
!> @}

!> @ingroup GlobalVarPar
!> @{
!> @defgroup Lib_StringsGlobalVarPar Lib_Strings
!> Library of miscellanea procedures for strings operations.
!> @}

!> @ingroup PublicProcedure
!> @{
!> @defgroup Lib_StringsPublicProcedure Lib_Strings
!> Library of miscellanea procedures for strings operations.
!> @}

!> @ingroup PrivateProcedure
!> @{
!> @defgroup Lib_StringsPrivateProcedure Lib_Strings
!> Library of miscellanea procedures for strings operations.
!> @}

!> Library of miscellanea procedures for strings operations.
!> This is a library module.
!> @ingroup Lib_StringsLibrary
module Lib_Strings
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision ! Integers and reals precision definition.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
save
private
public:: re_match
public:: Upper_Case
public:: Lower_Case
public:: delete
public:: insert
public:: replace
public:: tokenize
public:: tags_match
public:: unique
public:: count
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
!> @ingroup Lib_StringsGlobalVarPar
!> @{
character(len=26), parameter, private :: upper_alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
character(len=26), parameter, private :: lower_alphabet = 'abcdefghijklmnopqrstuvwxyz'
!> @}
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
!> Overloading intrinsic function count.
!> @ingroup Lib_StringsInterface
interface count
  module procedure count_substring
endinterface
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  !> @ingroup Lib_StringsPublicProcedure
  !> @{
  !> @brief Procedure for regular expression mathcing. Tries to match the given string with the pattern and give .true. if the
  !> entire string matches the pattern, .false. otherwise.
  !> @note Trailing blanks are ignored.
  recursive function re_match(string,pattern) result(match)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(in):: string  !< Input string.
  character(len=*), intent(in):: pattern !< Pattern to search for.
  logical::                      match   !< Match or not.
  character(len=len(pattern))::  literal
  integer::                      ptrim
  integer::                      p
  integer::                      k
  integer::                      ll
  integer::                      method
  integer::                      start
  integer::                      strim
  character(len=1), parameter::  backslash = '\\'
  character(len=1), parameter::  star      = '*'
  character(len=1), parameter::  question  = '?'
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  match  = .false.
  method = 0
  ptrim  = len_trim( pattern )
  strim  = len_trim( string )
  p      = 1
  ll     = 0
  start  = 1
  ! Split off a piece of the pattern
  do while (p <= ptrim)
    select case (pattern(p:p))
      case(star)
        if (ll.ne.0) exit
        method = 1
      case(question)
        if (ll.ne.0) exit
        method = 2
        start  = start + 1
      case(backslash)
        p  = p + 1
        ll = ll + 1
        literal(ll:ll) = pattern(p:p)
      case default
        ll = ll + 1
        literal(ll:ll) = pattern(p:p)
    endselect
    p = p + 1
  enddo
  ! Now look for the literal string (if any!)
  if (method==0) then
    ! We are at the end of the pattern, and of the string?
    if (strim==0.and.ptrim==0) then
      match = .true.
    else
      ! The string matches a literal part?
      if (ll>0) then
        if (string(start:min(strim,start+ll-1))==literal(1:ll)) then
          start = start + ll
          match = re_match(string(start:),pattern(p:))
        endif
      endif
    endif
  endif
  if (method==1) then
    ! Scan the whole of the remaining string ...
    if (ll==0) then
      match = .true.
    else
      do while (start <= strim)
        k = index(string(start:),literal(1:ll))
        if ( k > 0 ) then
          start = start + k + ll - 1
          match = re_match(string(start:),pattern(p:))
          if (match) then
            exit
          endif
        endif
        start = start + 1
      enddo
    endif
  endif
  if ( method == 2 .and. ll > 0 ) then
    ! Scan the whole of the remaining string ...
    if (string(start:min(strim,start+ll-1)) == literal(1:ll)) then
      match = re_match(string(start+ll:),pattern(p:))
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction re_match

  !> @brief Procedure for converting the lower case characters of a string to upper case one.
  !>@return \b Upper_Case character(len(string)) variable
  elemental function Upper_Case(string)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN):: string     !< String to be converted.
  character(len=len(string))::   Upper_Case !< Converted string.
  integer::                      n1,n2      !< Characters counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  Upper_Case = string
  do n1=1,len(string)
    n2 = index(lower_alphabet,string(n1:n1))
    if (n2>0) Upper_Case(n1:n1) = upper_alphabet(n2:n2)
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Upper_Case

  !> @brief Procedure for converting the upper case characters of a string to lower case one.
  !>@return \b Lower_Case character(len(string)) variable
  elemental function Lower_Case(string)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN):: string     !< String to be converted.
  character(len=len(string))::   Lower_Case !< Converted string.
  integer::                      n1,n2      !< Characters counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  Lower_Case = string
  do n1=1,len_trim(string)
    n2 = index(upper_alphabet,string(n1:n1))
    if (n2>0) Lower_Case(n1:n1) = lower_alphabet(n2:n2)
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Lower_Case

  !> @brief Procedure for deleting substring from a string.
  !>@return \b newstring character(len(string)-len(substring)) variable
  elemental function delete(string,substring) result(newstring)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN)::              string    !< String to be modified.
  character(len=*), intent(IN)::              substring !< Substring to be inserted.
  character(len=len(string)-len(substring)):: newstring !< New modified string.
  integer(I4P)::                              pos       !< Position from which delete the substring.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  pos = index(string=string,substring=string)
  if (pos>0) then
    if (pos==1) then
      newstring = string(len(substring)+1:)
    else
      newstring = string(1:pos-1)//string(pos+len(substring):)
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction delete

  !> @brief Procedure for inserting substring into a string from a certaing position.
  !>@return \b newstring character(len(string)+len(substring)) variable
  elemental function insert(string,substring,pos) result(newstring)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN)::              string    !< String to be modified.
  character(len=*), intent(IN)::              substring !< Substring to be inserted.
  integer(I4P),     intent(IN)::              pos       !< Position from which insert the substring.
  character(len=len(string)+len(substring)):: newstring !< New modified string.
  integer(I4P)::                              safepos   !< Safe position from which insert the substring.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  safepos = min(max(1,pos),len(string))
  newstring = string(1:safepos)//substring//string(safepos+1:)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction insert

  !> @brief Procedure for replacing substring into a string.
  !>@return \b newstring character(len(string)-len(substring)+len(restring)) variable
  elemental function replace(string,substring,restring) result(newstring)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN)::              string    !< String to be modified.
  character(len=*), intent(IN)::              substring !< Substring to be replaced.
  character(len=*), intent(IN)::              restring  !< String to be inserted.
  character(len=len(string)-len(substring)):: newstring !< New modified string.
  integer(I4P)::                              pos       !< Position from which replace the substring.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  pos = index(string=string,substring=string)
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

  !> @brief Subroutine for tokenizing a string in order to parse it.
  !> @note The dummy array containing tokens must allocatable and its character elements must have the same length of the input
  !> string. If the length of the delimiter is higher than the input string one then the output tokens array is allocated with
  !> only one element set to char(0).
  pure subroutine tokenize(strin,delimiter,Nt,toks)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*),          intent(IN)::               strin     !< String to be tokenized.
  character(len=*),          intent(IN)::               delimiter !< Delimiter of tokens.
  integer(I4P),              intent(OUT), optional::    Nt        !< Number of tokens.
  character(len=len(strin)), intent(OUT), allocatable:: toks(:)   !< Tokens.
  character(len=len(strin))::                           strsub    !< Temporary string.
  integer(I4P)::                                        dlen      !< Delimiter length.
  integer(I4P)::                                        c,n,t     !< Counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! initialization
  if (allocated(toks)) deallocate(toks)
  strsub = strin
  dlen = len(delimiter)
  if (dlen>len(strin)) then
    allocate(toks(1:1)) ; toks(1) = char(0) ; if (present(Nt)) Nt = 1 ; return
  endif
  ! computing the number of tokens
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

  !> @brief Subroutine for parsing a string providing the substrings matching an enclosing pairs tags.
  !> @note The dummy array containing matching substrings must allocatable and its character elements must have the same length of
  !> the input string. If the total length of the tags is higher than the input string one then the output substrings array is
  !> allocated with only one element set to char(0).
  !> @note Nested tags are not supported.
  pure subroutine tags_match(strin,tag_start,tag_stop,Ns,match)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*),                       intent(IN)::  strin                    !< String to be parsed.
  character(len=*),                       intent(IN)::  tag_start                !< Starting tag for delimiting matching substrings.
  character(len=*),                       intent(IN)::  tag_stop                 !< Starting tag for delimiting matching substrings.
  integer(I4P), optional,                 intent(OUT):: Ns                       !< Number of matching substrings.
  character(len=len(strin)), allocatable, intent(OUT):: match(:)                 !< Matching substrings.
  character(len=len(strin)), allocatable::              str_start(:),str_stop(:) !< Temporary strings.
  integer(I4P)::                                        tlen_start               !< Tag start length.
  integer(I4P)::                                        tlen_stop                !< Tag stop  length.
  integer(I4P)::                                        tlen                     !< Tags length.
  integer(I4P)::                                        n_start,n_stop,c,m       !< Counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! initialization
  if (allocated(match)) deallocate(match)
  tlen_start = len(tag_start)
  tlen_stop  = len(tag_stop )
  tlen       = tlen_start + tlen_stop
  if (tlen>len(strin)) then
    allocate(match(1:1)) ; match(1) = char(0) ; if (present(Ns)) Ns = 1 ; return
  endif
  ! computing the number of matching tags
  n_start = 0
  do c=1,len(strin)-tlen_start ! loop over string characters
    if (strin(c:c+tlen_start-1)==tag_start) n_start = n_start + 1
  enddo
  n_stop = 0
  do c=1,len(strin)-tlen_stop ! loop over string characters
    if (strin(c:c+tlen_stop-1)==tag_stop) n_stop = n_stop + 1
  enddo
  if (n_start/=n_stop) then
    allocate(match(1:1)) ; match(1) = char(0) ; if (present(Ns)) Ns = 1 ; return
  else
    allocate(match(1:n_start))
    call tokenize(strin=strin,delimiter=tag_start,toks=str_start)
    do m=1,n_start
      call tokenize(strin=str_start(m+1),delimiter=tag_stop,toks=str_stop)
      match(m) = str_stop(1)
    enddo
  endif
  if (present(Ns)) Ns = n_start
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine tags_match

  !> @brief Procedure for reducing to one (unique) multiple (sequential) occurrences of a characters substring into a string.
  !> For example the string ' ab-cre-cre-ab' is reduce to 'ab-cre-ab' if the substring is '-cre'.
  !> @note Eventual multiple trailing white space are not reduced to one occurrence.
  function unique(string,substring) result(uniq)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN):: string    !< String to be parsed.
  character(len=*), intent(IN):: substring !< Substring which multiple occurences must be reduced to one.
  character(len=len(string))::   uniq      !< String parsed.
  integer(I4P)::                 Lsub      !< Lenght of substring.
  integer(I4P)::                 c1,c2     !< Counters.
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
  !> @}

  !> @ingroup Lib_StringsPrivateProcedure
  !> @{
  !> @brief Procedure for counting the number of occurences of a substring into a string.
  elemental function count_substring(string,substring) result(No)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: string    !< String.
  character(*), intent(IN):: substring !< Substring.
  integer(I4P)::             No        !< Number of occurrences.
  integer(I4P)::             c1,c2     !< Counters.
  !---------------------------------------------------------------------------------------------------------------------------------

  No = 0
  if (len(substring)>len(string)) return
  c1 = 1
  do
    c2 = index(string=string(c1:),substring=substring)
    if (c2==0) return
    No = No + 1
    c1 = c1 + c2 + len(substring)
  enddo
endfunction count_substring
  !> @}
endmodule Lib_Strings

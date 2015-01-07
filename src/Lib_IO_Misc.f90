!> @ingroup Library
!> @{
!> @defgroup Lib_IO_MiscLibrary Lib_IO_Misc
!> @}

!> @ingroup Interface
!> @{
!> @defgroup Lib_IO_MiscInterface Lib_IO_Misc
!> @}

!> @ingroup GlobalVarPar
!> @{
!> @defgroup Lib_IO_MiscGlobalVarPar Lib_IO_Misc
!> @}

!> @ingroup PublicProcedure
!> @{
!> @defgroup Lib_IO_MiscPublicProcedure Lib_IO_Misc
!> @}

!> This module contains miscellanea procedures for input/output and strings operations.
!> This is a library module.
!> @ingroup Lib_IO_MiscLibrary
module Lib_IO_Misc
!-----------------------------------------------------------------------------------------------------------------------------------
USE IR_Precision                                                                  ! Integers and reals precision definition.
USE, intrinsic:: ISO_FORTRAN_ENV, only: stdout=>OUTPUT_UNIT, stderr=>ERROR_UNIT,& ! Standard output/error logical units.
                                        IOSTAT_END, IOSTAT_EOR                    ! Standard end-of-file/end-of record parameters.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
save
private
public:: stdout,stderr,iostat_end,iostat_eor
public:: Get_Unit
public:: get_extension,set_extension
public:: inquire_dir
public:: lc_file
public:: File_Not_Found
public:: Dir_Not_Found
public:: Upper_Case
public:: Lower_Case
public:: tokenize
public:: tags_match
public:: unique
public:: count
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
integer(I4P), public, parameter:: err_file_not_found = 10100 !< File not found error ID.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
!> Overloading intrinsic function count.
!> @ingroup Lib_IO_MiscInterface
interface count
  module procedure count_substring
endinterface
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  !> @ingroup Lib_IO_MiscPublicProcedure
  !> @{
  !> @brief The Get_Unit function returns a free logic unit for opening a file. The unit value is returned by the function, and also
  !> by the optional argument "Free_Unit". This allows the function to be used directly in an open statement like:
  !> open(unit=Get_Unit(myunit),...) ; read(myunit)...
  !> If no units are available, -1 is returned.
  integer function Get_Unit(Free_Unit)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer, intent(OUT), optional:: Free_Unit !< Free logic unit.
  integer::                        n1        !< Counter.
  integer::                        ios       !< Inquiring flag.
  logical::                        lopen     !< Inquiring flag.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  Get_Unit = -1
  n1=1
  do
    if ((n1/=stdout).AND.(n1/=stderr)) then
      inquire (unit=n1,opened=lopen,iostat=ios)
      if (ios==0) then
        if (.NOT.lopen) then
          Get_Unit = n1 ; if (present(Free_Unit)) Free_Unit = Get_Unit
          return
        endif
      endif
    endif
    n1=n1+1
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Get_Unit

  !> @brief Procedure for extracting the extension of a filename.
  !> @note The leading and trealing spaces are removed from the file name.
  elemental function get_extension(filename)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN):: filename      !< File name.
  character(len=len(filename)):: get_extension !< Extension of input file Name.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  get_extension = trim(adjustl(filename(index(filename,'.',back=.true.)+1:)))
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction get_extension

  !> @brief Procedure for setting the extension of a filename.
  !> @note The leading and trealing spaces are removed from the file name.
  elemental function set_extension(filename,extension) result(newfilename)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN)::  filename    !< File name.
  character(len=*), intent(IN)::  extension   !< Extension to be imposed.
  character(len=:), allocatable:: newfilename !< New file name.
  integer(I4P)::                  i           !< Counter.
  character(1)::                  dot         !< Doc caracter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  dot=''
  if (get_extension(trim(adjustl(filename)))/=trim(adjustl(extension))) then
    i = index(filename,'.',back=.true.)
    if (i==0) then
      i   = len(filename)
      dot = '.'
    endif
    newfilename = filename(:i)//trim(dot)//trim(adjustl(extension))
    newfilename = trim(adjustl(newfilename))
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction set_extension

  !> @brief Function for inquiring the presence of a directory.
  !> @return \b err integer(I_P) variable for error trapping.
  !> @note The leading and trealing spaces are removed from the directory name.
  function inquire_dir(myrank,errmsg,directory) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P), intent(IN),  optional:: myrank    !< Actual rank process necessary for concurrent multi-processes calls.
  character(*), intent(OUT), optional:: errmsg    !< Explanatory message if an I/O error occurs.
  character(*), intent(IN)::            directory !< Name of the directory that must be created.
  integer(I4P)::                        err       !< Error trapping flag: 0 no errors, >0 error occurs.
  integer(I4P)::                        UnitFree  !< Free logic unit.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! Creating a test file in the directory for inquiring its presence.
  if (present(myrank)) then
    if (present(errmsg)) then
      open(unit=Get_Unit(UnitFree),file=adjustl(trim(directory))//'ExiSt.p'//trim(strz(5,myrank)),iostat=err,iomsg=errmsg)
    else
      open(unit=Get_Unit(UnitFree),file=adjustl(trim(directory))//'ExiSt.p'//trim(strz(5,myrank)),iostat=err)
    endif
  else
    if (present(errmsg)) then
      open(unit=Get_Unit(UnitFree),file=adjustl(trim(directory))//'ExiSt.p'//trim(strz(5,0)),iostat=err,iomsg=errmsg)
    else
      open(unit=Get_Unit(UnitFree),file=adjustl(trim(directory))//'ExiSt.p'//trim(strz(5,0)),iostat=err)
    endif
  endif
  ! Deletig the test file if successfully created.
  if (err==0_I4P) then
    if (present(errmsg)) then
      close(UnitFree,status='DELETE',iomsg=errmsg)
    else
      close(UnitFree,status='DELETE')
    endif
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction inquire_dir

  !> @brief Function for calculating the number of lines (records) of a sequential file.
  !>@return \b n integer(I4P) variable
  function lc_file(filename) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: filename ! File name.
  integer(I4P)::             n        ! Number of lines (records).
  logical(4)::               is_file  ! Inquiring flag.
  character(11)::            fileform ! File format: FORMATTED or UNFORMATTED.
  integer(I4P)::             unitfile ! Logic unit.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  inquire(file=adjustl(trim(filename)),exist=is_file,form=fileform) ! Verifing the presence of the file.
  if (.NOT.is_file) then                                            ! File not found.
    n = -1_I4P                                                      ! Returning -1.
  else                                                              ! File found.
    n = 0_I4P                                                       ! Initializing number of records.
    open(unit   = Get_Unit(unitfile),      &
         file   = adjustl(trim(filename)), &
         action = 'READ',                  &
         form   = adjustl(trim(Upper_Case(fileform))))              ! Opening file.
    select case(adjustl(trim(Upper_Case(fileform))))
    case('FORMATTED')
      do
        read(unitfile,*,end=10)                                     ! Reading record.
        n = n + 1_I4P                                               ! Updating number of records.
      enddo
    case('UNFORMATTED')
      do
        read(unitfile,end=10)                                       ! Reading record.
        n = n + 1_I4P                                               ! Updating number of records.
      enddo
    endselect
    10 continue
    close(unitfile)                                                 ! Closing file.
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction lc_file

  !> @brief The Upper_Case function converts the lower case characters of a string to upper case one.
  !>@return \b Upper_Case character(*) variable
  elemental function Upper_Case(string)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN):: string     !< String to be converted.
  character(len=len(string))::   Upper_Case !< Converted string.
  integer::                      n1         !< Characters counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  Upper_Case = string
  do n1=1,len(string)
    select case(ichar(string(n1:n1)))
    case(97:122)
      Upper_Case(n1:n1)=char(ichar(string(n1:n1))-32) ! upper case conversion
    endselect
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Upper_Case

  !> @brief The Lower_Case function converts the upper case characters of a string to lower case one.
  !>@return \b Lower_Case character(*) variable
  elemental function Lower_Case(string)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(len=*), intent(IN):: string     !< String to be converted.
  character(len=len(string))::   Lower_Case !< Converted string.
  integer::                      n1         !< Characters counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  Lower_Case = string
  do n1=1,len_trim(string)
    select case(ichar(string(n1:n1)))
    case(65:90)
      Lower_Case(n1:n1)=char(ichar(string(n1:n1))+32) ! lower case conversion
    endselect
  enddo
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction Lower_Case

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

  !> @brief Procedure for printing to stderr a "file not found error".
  function File_Not_Found(stderrpref,filename,cpn) result(err)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN):: stderrpref !< Prefixing string for stderr outputs.
  character(*),           intent(IN):: filename   !< Name of file.
  character(*),           intent(IN):: cpn        !< Calling procedure name.
  integer(I4P)::                       err        !< Error trapping flag: 0 no errors, >0 error occurs.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(stderrpref)) then
    write(stderr,'(A)')stderrpref//' File '//adjustl(trim(filename))//' Not Found!'
    write(stderr,'(A)')stderrpref//' Calling procedure "'//adjustl(trim(cpn))//'"'
  else
    write(stderr,'(A)')            ' File '//adjustl(trim(filename))//' Not Found!'
    write(stderr,'(A)')            ' Calling procedure "'//adjustl(trim(cpn))//'"'
  endif
  err = err_file_not_found
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction File_Not_Found

  !> @brief Subroutine for printing to stderr a "directory not found error".
  subroutine Dir_Not_Found(myrank,Nproc,dirname,cpn)
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P), intent(IN), optional:: myrank      !< Actual rank process.
  integer(I4P), intent(IN), optional:: Nproc       !< Number of MPI processes used.
  character(*), intent(IN)::           dirname     !< Name of directory.
  character(*), intent(IN)::           cpn         !< Calling procedure name.
  character(DI4P)::                    rks         !< String containing myrank.
  integer(I4P)::                       rank=0,Np=1 !< Dummy temporary variables.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(myrank)) rank = myrank ; if (present(Nproc)) Np = Nproc ; rks = 'rank'//trim(strz(Np,rank))
  write(stderr,'(A)')trim(rks)//' Directory '//adjustl(trim(dirname))//' Not Found!'
  write(stderr,'(A)')trim(rks)//' Calling procedure "'//adjustl(trim(cpn))//'"'
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine Dir_Not_Found
  !> @}
endmodule Lib_IO_Misc

!< Configuration file reader: a small INI subset, the value source below the environment (F08 of #125).
module flap_config_m
!< Configuration file reader: a small INI subset, the value source below the environment (F08 of #125).
!<
!< Format: `key = value` lines; `[section]` starts a section (a group, i.e. a command; the keys before any section belong to
!< the top level, section ''); blank lines and lines starting with '#' or ';' are comments; an inline comment starts at a
!< '#' or ';' preceded by a blank; one pair of quotes (' or ") around a value is stripped, and a quoted value keeps its '#'
!< and ';'. Lines have any length. Any other line is malformed: its number is recorded.
use flap_utils_m, only : flap_string
use penf

implicit none
private
save

type, public :: config_file
  !< Entries of a configuration file.
  type(flap_string), allocatable :: section(:)     !< Section of each entry ('' for the top level).
  type(flap_string), allocatable :: key(:)         !< Key of each entry.
  type(flap_string), allocatable :: value(:)       !< Value of each entry.
  integer(I4P),      allocatable :: line(:)        !< Line number of each entry.
  integer(I4P)                   :: n=0_I4P        !< Number of entries.
  integer(I4P)                   :: bad_line=0_I4P !< Line number of the first malformed line, 0 if none.
  contains
    procedure, pass(self) :: load   !< Load a file.
    procedure, pass(self) :: lookup !< Look up the value of a key.
endtype config_file

contains
  subroutine load(self, file, found, iostat, iomsg)
  !< Load a configuration file; found is false (and nothing is loaded) when the file does not exist.
  class(config_file),            intent(inout) :: self    !< Configuration.
  character(*),                  intent(in)    :: file    !< File name.
  logical,                       intent(out)   :: found   !< The file exists.
  integer(I4P),                  intent(out)   :: iostat  !< I/O status (0 when read, or not found).
  character(len=:), allocatable, intent(out)   :: iomsg   !< I/O message.
  character(len=:), allocatable                :: line    !< Line.
  character(len=:), allocatable                :: section !< Current section.
  character(256)                               :: msg     !< I/O message buffer.
  integer(I4P)                                 :: lun     !< Unit.
  integer(I4P)                                 :: nl      !< Line number.

  self%n = 0
  self%bad_line = 0
  iostat = 0
  iomsg = ''
  inquire(file=file, exist=found)
  if (.not.found) return
  msg = ''
  open(newunit=lun, file=file, status='old', action='read', form='formatted', access='sequential', iostat=iostat, iomsg=msg)
  if (iostat /= 0) then
    iomsg = trim(msg)
    return
  endif
  section = ''
  nl = 0
  do
    call read_line(lun, line, iostat)
    if (iostat /= 0) exit
    nl = nl + 1
    call parse_line(line)
  enddo
  if (is_iostat_end(iostat)) iostat = 0
  close(lun)
  contains
    subroutine parse_line(raw)
    !< Parse a line: comment, section or key = value.
    character(*), intent(in)      :: raw !< Line.
    character(len=:), allocatable :: t   !< Line without tabs and blanks around.
    character(len=:), allocatable :: v   !< Value.
    integer(I4P)                  :: e   !< Position of '=' or ']'.
    integer(I4P)                  :: c   !< Position of the closing quote or of an inline comment.

    t = trim(adjustl(tabs_to_blanks(raw)))
    if (len(t) == 0) return
    if (t(1:1) == '#' .or. t(1:1) == ';') return
    if (t(1:1) == '[') then
      e = index(t, ']')
      if (e == 0) then
        call malformed
      else
        section = trim(adjustl(t(2:e-1)))
      endif
      return
    endif
    e = index(t, '=')
    if (e <= 1) then
      call malformed
      return
    endif
    v = trim(adjustl(t(e+1:)))
    if (len(v) > 0) then
      if (v(1:1) == '"' .or. v(1:1) == "'") then
        c = index(v(2:), v(1:1))
        if (c > 0) v = v(2:c)
      else
        do c=1, len(v)
          if (v(c:c) == '#' .or. v(c:c) == ';') then
            if (c == 1) then
              v = ''
              exit
            elseif (v(c-1:c-1) == ' ') then
              v = trim(v(1:c-1))
              exit
            endif
          endif
        enddo
      endif
    endif
    call add_entry(key=trim(t(1:e-1)), value=v)
    endsubroutine parse_line

    subroutine malformed
    !< Record the first malformed line.
    if (self%bad_line == 0) self%bad_line = nl
    endsubroutine malformed

    subroutine add_entry(key, value)
    !< Append an entry.
    character(*), intent(in)       :: key   !< Key.
    character(*), intent(in)       :: value !< Value.
    type(flap_string), allocatable :: s(:)  !< Grown sections.
    type(flap_string), allocatable :: k(:)  !< Grown keys.
    type(flap_string), allocatable :: v(:)  !< Grown values.
    integer(I4P),      allocatable :: l(:)  !< Grown line numbers.
    integer(I4P)                   :: i     !< Counter.

    if (.not.allocated(self%key)) then
      allocate(self%section(1:8), self%key(1:8), self%value(1:8), self%line(1:8))
    elseif (self%n == size(self%key, dim=1)) then
      allocate(s(1:2*self%n), k(1:2*self%n), v(1:2*self%n), l(1:2*self%n))
      do i=1, self%n
        s(i)%s = self%section(i)%s ; k(i)%s = self%key(i)%s ; v(i)%s = self%value(i)%s ; l(i) = self%line(i)
      enddo
      call move_alloc(from=s, to=self%section)
      call move_alloc(from=k, to=self%key)
      call move_alloc(from=v, to=self%value)
      call move_alloc(from=l, to=self%line)
    endif
    self%n = self%n + 1
    self%section(self%n)%s = section
    self%key(self%n)%s = key
    self%value(self%n)%s = value
    self%line(self%n) = nl
    endsubroutine add_entry
  endsubroutine load

  pure subroutine lookup(self, section, key, value, found)
  !< Look up the value of a key in a section: the last entry wins.
  class(config_file),            intent(in)  :: self    !< Configuration.
  character(*),                  intent(in)  :: section !< Section ('' for the top level).
  character(*),                  intent(in)  :: key     !< Key.
  character(len=:), allocatable, intent(out) :: value   !< Value ('' if not found).
  logical,                       intent(out) :: found   !< The key is in the section.
  integer(I4P)                               :: i       !< Counter.

  value = ''
  found = .false.
  do i=self%n, 1, -1
    if (self%section(i)%s == section .and. self%key(i)%s == key) then
      value = self%value(i)%s
      found = .true.
      return
    endif
  enddo
  endsubroutine lookup

  subroutine read_line(lun, line, iostat)
  !< Read a whole line of any length (non-advancing reads); a last line without line end is a line.
  integer(I4P),                  intent(in)  :: lun    !< Unit.
  character(len=:), allocatable, intent(out) :: line   !< Line.
  integer(I4P),                  intent(out) :: iostat !< I/O status: 0, or end of file.
  character(256)                             :: chunk  !< Chunk.
  integer(I4P)                               :: size_  !< Characters read.

  line = ''
  do
    read(lun, '(A)', advance='no', iostat=iostat, size=size_) chunk
    line = line//chunk(1:size_)
    if (is_iostat_eor(iostat)) then
      iostat = 0
      return
    elseif (iostat /= 0) then
      if (is_iostat_end(iostat) .and. len(line) > 0) iostat = 0
      return
    endif
  enddo
  endsubroutine read_line

  pure function tabs_to_blanks(string) result(blanked)
  !< Return a string with its tabs replaced by blanks.
  character(*), intent(in) :: string  !< String.
  character(len(string))   :: blanked !< String without tabs.
  integer(I4P)             :: c       !< Counter.

  blanked = string
  do c=1, len(blanked)
    if (blanked(c:c) == achar(9)) blanked(c:c) = ' '
  enddo
  endfunction tabs_to_blanks
endmodule flap_config_m

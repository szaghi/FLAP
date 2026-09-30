!< Unit tests of csv_split, the splitter of list values read from the environment (issue #125, step 2.4; #77 5.1, T5.1-T5.10).
program flap_test_csv_split
!< Unit tests of csv_split, the splitter of list values read from the environment (issue #125, step 2.4; #77 5.1, T5.1-T5.10).
!<
!< One CSV record, an RFC 4180 subset: ',' separates; a field in "..." may hold commas and "" is a literal "; blanks around
!< unquoted fields are trimmed; a quote inside an unquoted field is kept; an unterminated quote is an error.
use flap_utils_m, only : csv_split, flap_string
use flap_test_utils, only : assert, assert_equal
use penf, only : I4P

implicit none

call check('a,b,c',             [character(8) :: 'a', 'b', 'c'],     [1, 1, 1], 'T5.1 plain fields')
call check('1, 2 , 3',          [character(8) :: '1', '2', '3'],     [1, 1, 1], 'T5.2 unquoted blanks trimmed')
call check('"a,b",c',           [character(8) :: 'a,b', 'c'],        [3, 1],    'T5.3 quoted comma')
call check('"say ""hi""",x',    [character(8) :: 'say "hi"', 'x'],   [8, 1],    'T5.4 doubled quote')
call check('" padded "',        [character(8) :: ' padded '],        [8],       'T5.5 blanks inside quotes kept')
call check('a,,b',              [character(8) :: 'a', '', 'b'],      [1, 0, 1], 'T5.6 empty middle field')
call check('a,',                [character(8) :: 'a', ''],           [1, 0],    'T5.7 empty last field')
call check('a"b,c',             [character(8) :: 'a"b', 'c'],        [3, 1],    'T5.10 quote inside an unquoted field')
call check(' "my file", x.h5 ', [character(8) :: 'my file', 'x.h5'], [7, 4],    'blanks around a quoted field')
call check_empty('',    'T5.8 empty record')
call check_empty('   ', 'T5.8 blank record')
call check_error('"abc',  'T5.9 unterminated quote')
call check_error('1,"99', 'T5.9 unterminated quote in the last field')

contains
  subroutine check(record, expected, lengths, message)
  !< Split a record and check the fields, with their exact lengths (blanks are significant).
  character(*), intent(in)       :: record      !< CSV record.
  character(*), intent(in)       :: expected(:) !< Expected fields.
  integer,      intent(in)       :: lengths(:)  !< Expected lengths of the fields.
  character(*), intent(in)       :: message     !< Description of the check.
  type(flap_string), allocatable :: fields(:)   !< Fields.
  integer(I4P)                   :: nf          !< Number of fields.
  integer(I4P)                   :: error       !< Error flag.
  integer                        :: f           !< Counter.

  call csv_split(record=record, fields=fields, nf=nf, error=error)
  call assert_equal(error, 0_I4P, message//': no error')
  call assert_equal(nf, int(size(expected), I4P), message//': number of fields')
  do f=1, size(expected)
    call assert_equal(int(len(fields(f)%s), I4P), int(lengths(f), I4P), message//': length of a field')
    call assert(fields(f)%s == expected(f)(1:lengths(f)), message//': field ['//fields(f)%s//']')
  enddo
  endsubroutine check

  subroutine check_empty(record, message)
  !< An empty or blank record has no field.
  character(*), intent(in)       :: record    !< CSV record.
  character(*), intent(in)       :: message   !< Description of the check.
  type(flap_string), allocatable :: fields(:) !< Fields.
  integer(I4P)                   :: nf        !< Number of fields.
  integer(I4P)                   :: error     !< Error flag.

  call csv_split(record=record, fields=fields, nf=nf, error=error)
  call assert(error == 0 .and. nf == 0, message//': no field')
  endsubroutine check_empty

  subroutine check_error(record, message)
  !< An unterminated quote is an error.
  character(*), intent(in)       :: record    !< CSV record.
  character(*), intent(in)       :: message   !< Description of the check.
  type(flap_string), allocatable :: fields(:) !< Fields.
  integer(I4P)                   :: nf        !< Number of fields.
  integer(I4P)                   :: error     !< Error flag.

  call csv_split(record=record, fields=fields, nf=nf, error=error)
  call assert(error /= 0, message//': error')
  endsubroutine check_error
endprogram flap_test_csv_split

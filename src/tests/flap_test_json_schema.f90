!< JSON description of a CLI: save_json_schema and --schema (issue #128).
program flap_test_json_schema
!< JSON description of a CLI: save_json_schema and --schema (issue #128).
!<
!< The whole document of a CLI using every feature is pinned by `flap_test_golden`; this test checks the single behaviours.
use flap, only : command_line_interface, error_description, STATUS_SCHEMA
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, delete_file, &
                            read_back, read_file, reinvoke, run_command, scratch_file, write_file
use penf, only : I4P

implicit none
character(1), parameter   :: BS = achar(92) !< Backslash.
integer(I4P)              :: lun      !< Capture unit.
character(:), allocatable :: out      !< Output of a child.
character(:), allocatable :: err      !< Errors of a child.
character(:), allocatable :: json     !< Document.
integer(I4P)              :: exitstat !< Exit status of a child.

select case(child_case())
case(1)
  call child_schema
  stop
endselect

call capture_open(lun)
call check_contents
call check_before_after
call check_hidden_builtins
call check_escaping
call check_ranges
call check_not_standalone
call check_save
call check_errors_table
call capture_close(lun)

! T2.6 printed by a child, with a required option missing, exit 0; T2.8 unknown when not enabled
call reinvoke(1_I4P, exitstat, out, err, args='--schema')
call assert_equal(exitstat, 0_I4P, 'T2.6 exit status')
call assert_contains(out, '"schema_version": 1', 'T2.6 printed')
call assert_contains(out, '"switch": "--need"', 'T2.6 the option')
call reinvoke(1_I4P, exitstat, out, err, args='--need 1 --bogus --schema')
call assert_contains(err, '--bogus', 'T2.6 a syntax error comes first')
call reinvoke(1_I4P, exitstat, out, err, args='--need 1')
call assert_contains(out, 'status=0', 'no --schema, the program runs')

contains
  subroutine define(cli)
  !< A CLI using the features of the description.
  type(command_line_interface), intent(out) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                              :: error !< Error trapping flag.

  call cli%init(progname='prog', version='1.2.0', description='A program', error_lun=lun, usage_lun=lun, version_lun=lun, &
                standalone=.false., schema_option=.true.)
  call cli%add(switch='--steps', switch_ab='-s', help='Steps', required=.true., val_type='I4P', error=error)
  call assert_equal(error, 0_I4P, 'add --steps')
  call cli%add(switch='--cfl', help='CFL', required=.false., def='0.5', val_type='R8P', min='0', max='1', max_open=.true., &
               error=error)
  call assert_equal(error, 0_I4P, 'add --cfl')
  call cli%add(switch='--scheme', help='Scheme', required=.false., def='a', choices='a,b', error=error)
  call assert_equal(error, 0_I4P, 'add --scheme')
  call cli%add(switch='--ijk', help='Sizes', required=.false., def='1 2 3', nargs='3', val_type='I4P', error=error)
  call assert_equal(error, 0_I4P, 'add --ijk')
  call cli%add(switch='--v', help='Verbose', required=.false., act='count', error=error)
  call cli%add(switch='--color', switch_neg='--no-color', help='Color', required=.false., act='store_true', def='.false.', &
               error=error)
  call cli%add(switch='--x', help='x', required=.false., def='1', exclude='--y', error=error)
  call cli%add(switch='--y', help='y', required=.false., def='2', error=error)
  call cli%add(switch='--a', help='a', required=.false., act='store_true', def='.false.', error=error)
  call cli%add(switch='--b', help='b', required=.false., act='store_true', def='.false.', error=error)
  call cli%set_mutually_exclusive_switches(switches='--a,--b', required=.true., error=error)
  call assert_equal(error, 0_I4P, 'exclusive set')
  call cli%add(switch='--old', help='old', required=.false., def='1', deprecated='use --new', envvar='PROG_OLD', error=error)
  call cli%add(switch='--secret', help='hidden', required=.false., def='1', hidden=.true., error=error)
  call cli%add(positional=.true., position=1, help='Input', required=.true., val_type='character', error=error)
  call assert_equal(error, 0_I4P, 'add positional')
  call cli%add_group(group='run', help='Run it', description='Runs', aliases='r')
  call cli%add_group(group='stop', help='Stop it', exclude='run')
  call cli%add(group='run', switch='--np', help='Ranks', required=.false., def='1', val_type='I4P', error=error)
  call assert_equal(error, 0_I4P, 'add --np')
  endsubroutine define

  subroutine check_contents
  !< T2.1 what the description says.
  type(command_line_interface) :: cli !< Command Line Interface (CLI).

  call define(cli)
  json = cli%json_schema()
  call assert_contains(json, '"program": {"name": "prog", "version": "1.2.0", "description": "A program"}', 'program')
  call assert_contains(json, '"switch": "--steps", "abbreviation": "-s"', 'abbreviation')
  call assert_contains(json, '"value": {"type": "integer", "minimum": -2147483648, "maximum": 2147483647, "x-flap-kind": "I4P"}', &
                       'kind limits')
  call assert_contains(json, '"typed": true', 'typed')
  call assert_contains(json, '"value": {"type": "string", "enum": ["a", "b"]}, "typed": false', 'untyped, choices')
  call assert_contains(json, '"type": "array", "items": {"type": "integer"', 'a list')
  call assert_contains(json, '"minItems": 3, "maxItems": 3', 'a fixed size')
  call assert_contains(json, '"default": ["1", "2", "3"]', 'a list default')
  call assert_contains(json, '"negation": "--no-color"', 'a negation')
  call assert_contains(json, '"value": {"type": "boolean"}', 'a flag')
  call assert_contains(json, '"action": "count", "value": {"type": "integer", "minimum": 0}', 'a count')
  call assert_contains(json, '{"members": ["--a","--b"], "required": true}', 'an exclusive set')
  call assert_contains(json, '"deprecated": "use --new"', 'deprecated')
  call assert_contains(json, '"envvar": "PROG_OLD"', 'an envvar')
  call assert_contains(json, '"position": 1', 'a positional')
  call assert_contains(json, '{"name": "run", "aliases": ["r"], "help": "Run it", "description": "Runs"', 'a command')
  call assert_contains(json, '"exclusive_with": ["run"]', 'exclusive commands')
  call assert_contains(json, '"switch": "--np"', 'an option of a command')
  endsubroutine check_contents

  subroutine check_before_after
  !< T2.2 the same output before and after parse, the symmetric exclusion and the sanitized defaults included.
  type(command_line_interface)  :: cli    !< Command Line Interface (CLI).
  character(len=:), allocatable :: before !< Before parse.
  integer(I4P)                  :: error  !< Error trapping flag.

  call define(cli)
  before = cli%json_schema()
  call cli%parse(args='--steps 1 --a in', error=error)
  call assert_equal(error, 0_I4P, 'T2.2 parse')
  call assert_equal(cli%json_schema(), before, 'T2.2 before and after')
  call assert_contains(before, '"switch": "--y", "help": "y", "required": false, "action": "store", '//&
                       '"value": {"type": "string"}, "typed": false, "default": "2", "exclude": "--x"', 'T2.2 exclude both ways')
  endsubroutine check_before_after

  subroutine check_hidden_builtins
  !< T2.3 hidden options and builtins are left out.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call define(cli)
  call cli%parse(args='--steps 1 --a in', error=error)
  json = cli%json_schema()
  call assert(index(json, '--secret') == 0, 'T2.3 hidden')
  call assert(index(json, '"--help"') == 0, 'T2.3 --help')
  call assert(index(json, '"--schema"') == 0, 'T2.3 --schema')
  call assert(index(json, '"switch": "--"') == 0, 'T2.3 --')
  endsubroutine check_hidden_builtins

  subroutine check_escaping
  !< T2.4 and T2.5 text needing escapes; the document is valid JSON for python3, when there is one.
  type(command_line_interface)  :: cli   !< Command Line Interface (CLI).
  character(len=:), allocatable :: file  !< Document.
  character(len=:), allocatable :: text  !< Output of python3.
  integer(I4P)                  :: error !< Error trapping flag.
  integer(I4P)                  :: stat  !< Exit status.

  call define(cli)
  call cli%add(switch='--q', help='a "quote" '//BS//' '//new_line('a')//achar(9)//char(255), required=.false., def='x', error=error)
  json = cli%json_schema()
  call assert_contains(json, '"a '//BS//'"quote'//BS//'" '//BS//BS//' '//BS//'n'//BS//'t'//BS//'ufffd"', 'T2.4 escaped')
  file = scratch_file('schema.json')
  call cli%save_json_schema(file, error=error)
  call assert_equal(error, 0_I4P, 'T2.5 saved')
  call run_command('command -v python3 >/dev/null', stat, text)
  if (stat == 0) then
    call run_command('python3 -I -m json.tool "'//file//'" >/dev/null', stat, text)
    call assert_equal(stat, 0_I4P, 'T2.5 valid JSON: '//text)
  endif
  call delete_file(file)
  endsubroutine check_escaping

  subroutine check_ranges
  !< T2.9 open, closed and kind-derived bounds, numbers rewritten for JSON.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--a', help='a', required=.false., def='1', val_type='I1P', min='0', error=error)
  call cli%add(switch='--b', help='b', required=.false., def='.5', val_type='R8P', min='.5', max='1.', min_open=.false., &
               error=error)
  call cli%add(switch='--c', help='c', required=.false., def='2', val_type='R4P', min='+1d0', min_open=.true., error=error)
  call cli%add(switch='--d', help='d', required=.false., def='2', min='1', error=error)
  call cli%add(switch='--e', help='e', required=.false., def='2', val_type='I4P', choices='1,2', error=error)
  call assert_equal(error, 0_I4P, 'T2.9 definitions')
  json = cli%json_schema()
  call assert_contains(json, '{"type": "integer", "minimum": 0, "maximum": 127, "x-flap-kind": "I1P"}', 'T2.9 one kind bound')
  call assert_contains(json, '{"type": "number", "minimum": 0.5, "maximum": 1.0, "x-flap-kind": "R8P"}', 'T2.9 rewritten')
  call assert_contains(json, '{"type": "number", "exclusiveMinimum": 1e0, "x-flap-kind": "R4P"}', 'T2.9 open')
  call assert_contains(json, '"value": {"type": "number", "minimum": 1}, "typed": false', 'T2.9 untyped with a range')
  call assert_contains(json, '"enum": [1, 2]', 'T2.9 numeric choices')
  call check_review
  endsubroutine check_ranges

  subroutine check_review
  !< No key twice, a range and choices that agree, no hidden member of an exclusive set.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
  call cli%add(switch='-v', help='v', required=.false., act='count', min='1', error=error)
  call cli%add(switch='-w', help='w', required=.false., act='count', error=error)
  call cli%add(switch='--r', help='r', required=.false., def='1', min='0', choices='1,2', error=error)
  call cli%add(switch='--a', help='a', required=.false., act='store_true', def='.false.', error=error)
  call cli%add(switch='--hide', help='h', required=.false., act='store_true', def='.false.', hidden=.true., error=error)
  call cli%set_mutually_exclusive_switches(switches='--a,--hide', error=error)
  call assert_equal(error, 0_I4P, 'review: definitions')
  json = cli%json_schema()
  call assert_contains(json, '"action": "count", "value": {"type": "integer", "minimum": 1}', 'a count with a minimum')
  call assert_contains(json, '"action": "count", "value": {"type": "integer", "minimum": 0}', 'a count without')
  call assert_contains(json, '{"type": "number", "minimum": 0, "enum": [1, 2]}', 'a range and choices')
  call assert_contains(json, '{"members": ["--a"], "required": false}', 'a hidden member')
  call assert(index(json, '--hide') == 0, 'a hidden member: left out')
  endsubroutine check_review

  subroutine check_not_standalone
  !< T2.7 the status with standalone=.false.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call define(cli)
  call cli%parse(args='--schema', error=error)
  call assert_equal(error, STATUS_SCHEMA, 'T2.7 status')
  call assert_contains(read_back(lun), '"schema_version": 1', 'T2.7 printed')
  endsubroutine check_not_standalone

  subroutine check_save
  !< save_json_schema writes the same document; a file that cannot be written is an I/O status.
  type(command_line_interface)  :: cli   !< Command Line Interface (CLI).
  character(len=:), allocatable :: file  !< Document.
  integer(I4P)                  :: error !< Error trapping flag.

  call define(cli)
  file = scratch_file('saved.json')
  call cli%save_json_schema(file, error=error)
  call assert_equal(error, 0_I4P, 'saved')
  call assert_contains(read_file(file), '"switch": "--steps"', 'saved document')
  call delete_file(file)
  call cli%save_json_schema('/nonexistent-dir/x.json', error=error)
  call assert(error /= 0, 'a file that cannot be written')
  endsubroutine check_save

  subroutine check_errors_table
  !< The published meanings; every code of docs/guide/errors.md has its own, when the page is there (from the repo root).
  character(len=:), allocatable :: page   !< The page.
  character(len=:), allocatable :: row    !< A row.
  type(command_line_interface)  :: cli    !< Command Line Interface (CLI).
  integer(I4P)                  :: code   !< Code.
  integer(I4P)                  :: ios    !< I/O status.
  integer(I4P)                  :: n      !< Rows compared.
  integer(I4P)                  :: start  !< Start of a row.
  integer(I4P)                  :: finish !< End of a row.
  integer(I4P)                  :: a      !< Start of the code.
  integer(I4P)                  :: b      !< End of the code.
  integer(I4P)                  :: c      !< Start of the meaning.
  integer(I4P)                  :: d      !< End of the meaning.
  logical                       :: exists !< The page is there.

  call assert_equal(error_description(50_I4P), 'Value is not a number', 'a meaning')
  call assert_equal(error_description(99999_I4P), '', 'an unknown code')
  call define(cli)
  call assert_contains(cli%json_schema(), '"50": "Value is not a number"', 'published')
  inquire(file='docs/guide/errors.md', exist=exists)
  if (.not.exists) return
  page = read_file('docs/guide/errors.md')
  n = 0
  start = 1
  do while (start <= len(page))
    finish = index(page(start:), new_line('a'))
    if (finish == 0) exit
    row = page(start:start+finish-2)
    start = start + finish
    if (len(row) < 4) cycle
    if (row(1:3) /= '| `') cycle
    a = 4
    b = a + index(row(a:), '`') - 2
    read(row(a:b), *, iostat=ios) code
    if (ios /= 0) cycle
    if (code < 1 .or. code >= 2000) cycle
    c = a + index(row(a:), '|') ! after the second bar
    c = c + index(row(c:), '|') ! after the third bar
    d = c + index(row(c:), '|') - 2
    call assert_equal(error_description(code), trim(adjustl(row(c:d))), 'the page and the table, code '//row(a:b))
    n = n + 1
  enddo
  call assert(n > 50, 'the rows of the page have been read')
  endsubroutine check_errors_table

  subroutine child_schema
  !< --schema with a required option and standalone.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', schema_option=.true., version='1')
  call cli%add(switch='--need', help='needed', required=.true., error=error)
  call cli%parse(error=error)
  print '(A,I0)', 'status=', error
  endsubroutine child_schema
endprogram flap_test_json_schema

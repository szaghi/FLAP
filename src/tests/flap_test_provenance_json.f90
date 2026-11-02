!< JSON provenance, the run manifest, and sensitive values (issue #128).
program flap_test_provenance_json
!< JSON provenance, the run manifest, and sensitive values (issue #128).
use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, delete_file, &
                            read_back, read_file, reinvoke, run_command, scratch_file, write_file
use penf, only : I4P

implicit none
character(1), parameter   :: BS = achar(92) !< Backslash.
integer(I4P)              :: lun      !< Capture unit.
character(:), allocatable :: out      !< Output of a child.
character(:), allocatable :: err      !< Errors of a child.
character(:), allocatable :: file     !< Configuration file.
integer(I4P)              :: exitstat !< Exit status of a child.

if (child_case() == 1) then
  call child
  stop
endif

call capture_open(lun)
call check_lists
call check_default_format
call check_command
call check_failed
call check_repeatable
call check_escaping
call check_sensitive
call check_sensitive_positional
call check_sensitive_outputs
call check_sensitive_lists
call check_failed_args
call check_save
call capture_close(lun)

! T5.1 one value of each source
file = scratch_file('prov.ini')
call write_file(file, 'conf = from-file')
call reinvoke(1_I4P, exitstat, out, err, args='--cmd from-line "--conf-file='//file//'"', env='FLAP_TEST_PJ=from-env')
call assert_equal(exitstat, 0_I4P, 'T5.1 child: '//err)
call assert_contains(out, '{"command": "", "name": "--cmd", "value": "from-line", "source": "command line"}', 'T5.1 command line')
call assert_contains(out, '{"command": "", "name": "--env", "value": "from-env", "source": "environment", '//&
                     '"variable": "FLAP_TEST_PJ"}', 'T5.1 environment')
call assert_contains(out, '"name": "--conf", "value": "from-file", "source": "config", "file": ', 'T5.1 configuration file')
call assert_contains(out, '{"command": "", "name": "--def", "value": "d", "source": "default"}', 'T5.1 default')
call delete_file(file)

contains
  subroutine child
  !< A value of each source.
  type(command_line_interface)  :: cli    !< Command Line Interface (CLI).
  character(len=:), allocatable :: report !< Report.
  integer(I4P)                  :: error  !< Error trapping flag.

  call cli%init(progname='prog', version='1.2.0')
  call cli%add(switch='--cmd', help='c', required=.false., def='x', error=error)
  call cli%add(switch='--env', help='e', required=.false., def='x', envvar='FLAP_TEST_PJ', error=error)
  call cli%add(switch='--conf', help='c', required=.false., def='x', error=error)
  call cli%add(switch='--def', help='d', required=.false., def='d', error=error)
  call cli%add(switch='--conf-file', help='f', required=.false., def='', act='config', error=error)
  call cli%parse(error=error)
  report = cli%provenance(format='json')
  print '(A)', report
  endsubroutine child

  subroutine check_lists
  !< T5.2 lists, maps, a negated flag.
  type(command_line_interface)  :: cli    !< Command Line Interface (CLI).
  character(len=:), allocatable :: report !< Report.
  integer(I4P)                  :: error  !< Error trapping flag.

  call cli%init(progname='prog', version='1', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--l', help='l', required=.false., def='1', nargs='+', error=error)
  call cli%add(switch='--e', help='e', required=.false., def='', nargs='*', error=error)
  call cli%add(switch='--m', help='m', required=.false., def='', nargs='*', map=.true., error=error)
  call cli%add(switch='--c', switch_neg='--no-c', help='c', required=.false., act='store_true', def='.true.', error=error)
  call cli%add(switch='--a', help='a', required=.false., act='append', def='', error=error)
  call cli%parse(args='--l 1 2 --m a=1 b=2 --no-c --a x --a y', error=error)
  call assert_equal(error, 0_I4P, 'T5.2 parse')
  report = cli%provenance(format='json')
  call assert_contains(report, '"name": "--l", "value": ["1", "2"], "source": "command line"', 'T5.2 a list')
  call assert_contains(report, '"name": "--e", "value": [], "source": "default"', 'T5.2 an empty list')
  call assert_contains(report, '"name": "--m", "value": ["a=1", "b=2"]', 'T5.2 a map')
  call assert_contains(report, '"name": "--c", "value": ".false."', 'T5.2 a negation')
  call assert_contains(report, '"name": "--a", "value": ["x", "y"]', 'T5.2 an append')
  call assert_contains(report, '"arguments": ["--l","1","2","--m","a=1","b=2","--no-c","--a","x","--a","y"]', 'arguments')
  call assert_contains(report, '"status": 0', 'status')
  call assert_contains(report, '"program": {"name": "prog", "version": "1"}', 'program')
  call assert(index(report, '"--help"') == 0, 'no builtin')
  endsubroutine check_lists

  subroutine check_default_format
  !< T5.3 the text report: without format and with format='text', as it was.
  type(command_line_interface)  :: cli   !< Command Line Interface (CLI).
  character(len=:), allocatable :: one   !< Report.
  character(len=:), allocatable :: other !< Report.
  integer(I4P)                  :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--nx', help='n', required=.false., def='1', error=error)
  call cli%add(switch='--longer', help='l', required=.false., def='22', error=error)
  call cli%parse(args='--nx 5', error=error)
  one = cli%provenance()
  other = cli%provenance(format='text')
  call assert_equal(one, '--nx     = 5  [command line]'//new_line('a')//'--longer = 22 [default]', 'T5.3 text')
  call assert_equal(other, one, 'T5.3 format=text')
  endsubroutine check_default_format

  subroutine check_command
  !< T5.4 a called command against one not called.
  type(command_line_interface)  :: cli    !< Command Line Interface (CLI).
  character(len=:), allocatable :: report !< Report.
  integer(I4P)                  :: error  !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
  call cli%add_group(group='run', help='r')
  call cli%add_group(group='stop', help='s')
  call cli%add(group='run', switch='--np', help='n', required=.false., def='1', error=error)
  call cli%add(group='stop', switch='--now', help='n', required=.false., def='1', error=error)
  call cli%parse(args='run --np 4', error=error)
  report = cli%provenance(format='json')
  call assert_contains(report, '{"command": "run", "name": "--np", "value": "4", "source": "command line"}', 'T5.4 called')
  call assert(index(report, '--now') == 0, 'T5.4 not called')
  endsubroutine check_command

  subroutine check_failed
  !< T5.5 a failed parse: the status is the error, the document valid.
  type(command_line_interface)  :: cli    !< Command Line Interface (CLI).
  character(len=:), allocatable :: report !< Report.
  integer(I4P)                  :: error  !< Error trapping flag.
  character(len=:), allocatable :: path   !< Document.
  character(len=:), allocatable :: text   !< Output of python3.
  integer(I4P)                  :: stat   !< Exit status.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--n', help='n', required=.false., def='1', error=error)
  call cli%parse(args='--bogus', error=error)
  report = cli%provenance(format='json')
  call assert_contains(report, '"status": 15', 'T5.5 status')
  path = scratch_file('failed.json')
  call write_file(path, report)
  call run_command('command -v python3 >/dev/null', stat, text)
  if (stat == 0) then
    call run_command('python3 -I -m json.tool "'//path//'" >/dev/null', stat, text)
    call assert_equal(stat, 0_I4P, 'T5.5 valid JSON: '//text)
  endif
  call delete_file(path)
  text = read_back(lun)
  endsubroutine check_failed

  subroutine check_repeatable
  !< T5.6 the same inputs, the same bytes.
  type(command_line_interface)  :: a     !< Command Line Interface (CLI).
  type(command_line_interface)  :: b     !< Command Line Interface (CLI).
  integer(I4P)                  :: error !< Error trapping flag.
  character(len=:), allocatable :: one   !< Report.

  call a%init(progname='prog', error_lun=lun, usage_lun=lun)
  call a%add(switch='--n', help='n', required=.false., def='1', error=error)
  call a%parse(args='--n 2', error=error)
  one = a%provenance(format='json')
  call b%init(progname='prog', error_lun=lun, usage_lun=lun)
  call b%add(switch='--n', help='n', required=.false., def='1', error=error)
  call b%parse(args='--n 2', error=error)
  call assert_equal(b%provenance(format='json'), one, 'T5.6 repeatable')
  call assert_equal(a%provenance(format='json'), one, 'T5.6 called twice')
  endsubroutine check_repeatable

  subroutine check_escaping
  !< T5.7 a value needing escapes.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--n', help='n', required=.false., def='a"'//char(255), error=error)
  call cli%parse(args='', error=error)
  call assert_contains(cli%provenance(format='json'), '"value": "a'//BS//'"'//BS//'ufffd"', 'T5.7 escaped')
  endsubroutine check_escaping

  subroutine check_sensitive
  !< A sensitive value never reaches a report, as a separate token, inline, in a command or from the default.
  type(command_line_interface)  :: cli    !< Command Line Interface (CLI).
  character(len=:), allocatable :: report !< Report.
  integer(I4P)                  :: error  !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--token', help='t', required=.false., def='DEFSECRET', sensitive=.true., error=error)
  call cli%add(switch='--pass', help='p', required=.false., def='', sensitive=.true., error=error)
  call cli%add(switch='--open', help='o', required=.false., def='', error=error)
  call cli%add_group(group='run', help='r')
  call cli%add(group='run', switch='--key', help='k', required=.false., def='', sensitive=.true., error=error)
  call cli%parse(args='--pass=SECRET1 --open visible run --key SECRET2', error=error)
  call assert_equal(error, 0_I4P, 'sensitive: parse')
  report = cli%provenance(format='json')
  call assert(index(report, 'SECRET') == 0, 'sensitive: manifest, not '//report)
  call assert_contains(report, '"name": "--pass", "value": "***"', 'sensitive: value')
  call assert_contains(report, '"--pass=***"', 'sensitive: inline argument')
  call assert_contains(report, '"--key","***"', 'sensitive: separate argument')
  call assert_contains(report, '"--open","visible"', 'sensitive: others stay')
  report = cli%provenance()
  call assert(index(report, 'SECRET') == 0, 'sensitive: text report')
  call assert_contains(report, '***', 'sensitive: text report, masked')
  endsubroutine check_sensitive

  subroutine check_sensitive_positional
  !< A sensitive positional: no command line in the manifest.
  type(command_line_interface)  :: cli    !< Command Line Interface (CLI).
  character(len=:), allocatable :: report !< Report.
  integer(I4P)                  :: error  !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
  call cli%add(positional=.true., position=1, help='p', required=.true., sensitive=.true., error=error)
  call cli%parse(args='SECRET3', error=error)
  call assert_equal(error, 0_I4P, 'sensitive positional: parse')
  report = cli%provenance(format='json')
  call assert(index(report, 'SECRET') == 0, 'sensitive positional: manifest')
  call assert_contains(report, '"arguments": null', 'sensitive positional: no arguments')
  endsubroutine check_sensitive_positional

  subroutine check_sensitive_outputs
  !< The default of a sensitive option is left out of the help and of the JSON description.
  type(command_line_interface) :: cli   !< Command Line Interface (CLI).
  integer(I4P)                 :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--token', help='t', required=.false., def='DEFSECRET', sensitive=.true., error=error)
  call assert(index(cli%usage(g=0_I4P), 'DEFSECRET') == 0, 'sensitive: help')
  call assert(index(cli%json_schema(), 'DEFSECRET') == 0, 'sensitive: description')
  call assert_contains(cli%json_schema(), '"sensitive": true', 'sensitive: described')
  endsubroutine check_sensitive_outputs

  subroutine check_sensitive_lists
  !< All the tokens of a sensitive value, and none after them; a sensitive flag has none.
  type(command_line_interface)  :: cli    !< Command Line Interface (CLI).
  character(len=:), allocatable :: report !< Report.
  integer(I4P)                  :: error  !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--s', help='s', required=.false., def='', nargs='+', sensitive=.true., error=error)
  call cli%add(switch='--pair', help='p', required=.false., def='x y', nargs='2', sensitive=.true., error=error)
  call cli%add(switch='--ff', help='f', required=.false., act='store_true', def='.false.', sensitive=.true., error=error)
  call cli%add(switch='--o', help='o', required=.false., def='', error=error)
  call cli%parse(args='--s aa bb cc --pair dd ee --ff --o visible', error=error)
  call assert_equal(error, 0_I4P, 'sensitive lists: parse')
  report = cli%provenance(format='json')
  call assert_contains(report, '"arguments": ["--s","***","***","***","--pair","***","***","--ff","--o","visible"]', &
                       'sensitive lists: arguments')
  endsubroutine check_sensitive_lists

  subroutine check_failed_args
  !< A failed parse(args=): the report is about that command line, and parse does not run again.
  type(command_line_interface)  :: cli    !< Command Line Interface (CLI).
  character(len=:), allocatable :: report !< Report.
  integer(I4P)                  :: error  !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun, standalone=.false., error_hint=.false.)
  call cli%add(switch='--x', help='x', required=.false., def='1', val_type='I4P', error=error)
  call cli%parse(args='--x abc', error=error)
  report = read_back(lun)
  report = cli%provenance(format='json')
  call assert_contains(report, '"arguments": ["--x","abc"]', 'failed: arguments')
  call assert_contains(report, '"status": 50', 'failed: status')
  call assert_equal(read_back(lun), '', 'failed: nothing printed again')
  endsubroutine check_failed_args

  subroutine check_save
  !< save_provenance writes the manifest; it parses first, as get does.
  type(command_line_interface)  :: cli   !< Command Line Interface (CLI).
  character(len=:), allocatable :: path  !< Manifest.
  integer(I4P)                  :: error !< Error trapping flag.

  call cli%init(progname='prog', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--n', help='n', required=.false., def='1', error=error)
  path = scratch_file('manifest.json')
  call cli%save_provenance(path, error=error)
  call assert_equal(error, 0_I4P, 'saved')
  call assert_contains(read_file(path), '"name": "--n"', 'saved document')
  call delete_file(path)
  call cli%save_provenance('/nonexistent-dir/x.json', error=error)
  call assert(error /= 0, 'a file that cannot be written')
  endsubroutine check_save
endprogram flap_test_provenance_json

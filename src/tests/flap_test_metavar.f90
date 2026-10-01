!< Metavar: the placeholder of a value in the usage, help, man page and markdown (issue #125, step 4.1; #11 9.1, T9.1-T9.4).
program flap_test_metavar
!< Metavar: the placeholder of a value in the usage, help, man page and markdown (issue #125, step 4.1; #11 9.1, T9.1-T9.4).
!<
!< add(metavar='FILE') replaces the generic "value" (and the KEY=VALUE of a map) wherever a value is shown; lists number it,
!< FILE#1 [FILE#2 FILE#3...]. Without metavar the outputs are unchanged (T9.4, and flap_test_golden). The bash completion
!< never shows placeholders (flap_test_signature).
use flap, only : command_line_interface
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, delete_file, read_back, &
                            read_file, scratch_file
use penf, only : I4P

implicit none
type(command_line_interface) :: cli   !< Command Line Interface (CLI).
character(:), allocatable    :: out   !< Output.
character(:), allocatable    :: file  !< Scratch file.
integer(I4P)                 :: lun   !< Capture unit.
integer(I4P)                 :: error !< Error trapping flag.

file = scratch_file('out')
call capture_open(lun)
call define
call cli%parse(args='in.dat --mesh m.grd', error=error)
call assert_equal(error, 0_I4P, 'parse')
! T9.1: the usage line
out = cli%usage(g=0)
call assert_contains(out, ' --mesh FILE ', 'usage: required option')
call assert_contains(out, ' [--cfl CFL]', 'usage: optional option')
! T9.2: lists and the other placeholders
call assert_contains(out, ' [--fields NAME#1 [NAME#2 NAME#3...]]', 'usage: nargs=+')
call assert_contains(out, ' [--probes [P#1 P#2 P#3...]]', 'usage: nargs=*')
call assert_contains(out, ' [--box X#1 X#2 X#3 ]', 'usage: nargs=3')
call assert_contains(out, ' [--inc DIR]...', 'usage: append')
call assert_contains(out, ' [--set PARAM=VAL [PARAM=VAL...]]', 'usage: a map with a metavar')
call assert_contains(out, ' [--level [LVL]]', 'usage: optional value (store*)')
! T9.3: a positional
call assert_contains(out, ' INPUT', 'usage: positional')
! the help lines
call assert_contains(out, '   --mesh FILE, -m FILE', 'help: option with abbreviation')
call assert_contains(out, '   --cfl CFL', 'help: option')
call assert_contains(out, '   --fields NAME#1 [NAME#2...]', 'help: list')
call assert_contains(out, '  INPUT', 'help: positional')
call assert(index(out, '--mesh value') == 0, 'no generic placeholder left for --mesh')
! T9.4: without metavar, the generic placeholders
call assert_contains(out, ' [--other value]', 'usage: no metavar, value')
call assert_contains(out, ' [--keys KEY=VALUE [KEY=VALUE...]]', 'usage: map without metavar, KEY=VALUE')
! man page and markdown
call cli%save_man_page(man_file=file, error=error)
call assert_equal(error, 0_I4P, 'man page saved')
out = read_file(file)
call assert_contains(out, '--mesh FILE', 'man page: metavar')
call cli%save_usage_to_markdown(markdown_file=file, error=error)
call assert_equal(error, 0_I4P, 'markdown saved')
out = read_file(file)
call assert_contains(out, '`--mesh FILE`', 'markdown: metavar')
call delete_file(file)
! a flag takes no value: its metavar is ignored
call cli%init(progname='flap_test_metavar', error_lun=lun, usage_lun=lun)
call cli%add(switch='--v', help='v', required=.false., act='store_true', def='.false.', metavar='X', error=error)
call assert_equal(error, 0_I4P, 'metavar on a flag: ignored')
call assert(index(cli%usage(g=0), '--v X') == 0, 'flag: no placeholder')
out = read_back(lun)
call capture_close(lun)

contains
  subroutine define()
  !< Define the CLI.

  call cli%init(progname='flap_test_metavar', error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--mesh', switch_ab='-m', help='mesh', required=.true., act='store', metavar='FILE', error=error)
  call cli%add(switch='--cfl', help='cfl', required=.false., act='store', def='0.5', metavar='CFL', error=error)
  call cli%add(switch='--fields', help='fields', required=.false., act='store', nargs='+', def='u', metavar='NAME', &
               error=error)
  call cli%add(switch='--probes', help='probes', required=.false., act='store', nargs='*', def='', metavar='P', error=error)
  call cli%add(switch='--box', help='box', required=.false., act='store', nargs='3', def='0 0 0', metavar='X', error=error)
  call cli%add(switch='--inc', help='include', required=.false., act='append', def='', metavar='DIR', error=error)
  call cli%add(switch='--set', help='set', required=.false., act='store', nargs='+', map=.true., def='a=1', &
               metavar='PARAM=VAL', error=error)
  call cli%add(switch='--keys', help='keys', required=.false., act='store', nargs='+', map=.true., def='a=1', error=error)
  call cli%add(switch='--level', help='level', required=.false., act='store*', def='1', metavar='LVL', error=error)
  call cli%add(switch='--other', help='other', required=.false., act='store', def='0', error=error)
  call cli%add(positional=.true., position=1, help='input', required=.true., act='store', metavar='INPUT', error=error)
  call assert_equal(error, 0_I4P, 'add the options')
  endsubroutine define
endprogram flap_test_metavar

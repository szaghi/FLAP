!< The --man builtin and the file names of --man and --markdown (issue #125, F29, step 6.5; issue #99).
program flap_test_man_option
!< The --man builtin and the file names of --man and --markdown (issue #125, F29, step 6.5; issue #99).
!<
!< With init(man_option=.true.) the top level gets --man, which saves the man page like --markdown saves the Markdown:
!< STATUS_PRINT_MAN (-8), or exit 0 in standalone mode, before any value check. The files are <progname>.1 and
!< <progname>.md unless init(man_file=, markdown_file=) name them. Builtins (these, and the completion ones) are neither
!< reported by provenance nor copied by copy_options.
use flap, only : command_line_interface, ERROR_UNKNOWN, STATUS_PRINT_H, STATUS_PRINT_M, STATUS_PRINT_MAN
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, child_case, delete_file, &
                            read_back, read_file, reinvoke, scratch_file
use penf, only : I4P

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI).
character(:), allocatable    :: out      !< Captured output, or output of a child.
character(:), allocatable    :: err      !< Errors of a child.
character(:), allocatable    :: man      !< Man page file.
character(:), allocatable    :: ref      !< Reference man page file.
character(:), allocatable    :: md       !< Markdown file.
character(:), allocatable    :: prog     !< Program name with a scratch path: its default files are scratch files.
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: error    !< Error trapping flag.
integer(I4P)                 :: exitstat !< Exit status of a child.
logical                      :: exist    !< A file exists.

man = scratch_file('man.1')
ref = scratch_file('ref.1')
md = scratch_file('custom.md')
prog = scratch_file('prog')
if (child_case() == 1) then
  ! standalone: --man saves the page and ends the program with exit status 0
  call cli%init(progname='flapman', man_option=.true., man_file=man)
  call cli%add(switch='--mesh', help='mesh file', required=.true., act='store')
  call cli%parse(error=error)
  print '(A)', 'not stopped'
  stop
endif
call capture_open(lun)

! off by default: an unknown switch, not in the help
call define(man_option=.false.)
call assert(index(cli%usage(g=0), '--man') == 0, 'off: not in the help')
call cli%parse(args='--man', error=error)
call assert_equal(error, ERROR_UNKNOWN, 'off: unknown')
out = read_back(lun)

! on: in the help; --man saves the man page, before the required check
call delete_file(man)
call define(man_option=.true., man_file=man)
call assert_contains(cli%usage(g=0), ' [--man]', 'on: usage line')
call assert_contains(cli%usage(g=0), '   --man', 'on: help line')
call cli%save_man_page(man_file=ref, error=error)
call assert_equal(error, 0_I4P, 'reference man page')
call cli%parse(args='--man', error=error)
call assert_equal(error, STATUS_PRINT_MAN, 'on: status')
call assert_equal(read_file(man), read_file(ref), 'on: the man page, as save_man_page writes it')
call assert_equal(read_back(lun), '', 'on: nothing printed')
call delete_file(man)
call delete_file(ref)
! the help comes first (D3)
call define(man_option=.true., man_file=man)
call cli%parse(args='--man --help', error=error)
call assert_equal(error, STATUS_PRINT_H, 'the help first')
inquire(file=man, exist=exist)
call assert(.not.exist, 'the help first: no man page')
out = read_back(lun)
! the default name: <progname>.1
call delete_file(prog//'.1')
call define(man_option=.true., progname=prog)
call cli%parse(args='--man', error=error)
call assert_equal(error, STATUS_PRINT_MAN, 'default name: status')
inquire(file=prog//'.1', exist=exist)
call assert(exist, 'default name: <progname>.1')
call delete_file(prog//'.1')
out = read_back(lun)

! --markdown: markdown_file names its file (default <progname>.md, unchanged)
call delete_file(md)
call define(man_option=.false., markdown_file=md)
call cli%parse(args='--markdown', error=error)
call assert_equal(error, STATUS_PRINT_M, 'markdown_file: status')
call assert_contains(read_file(md), '--mesh', 'markdown_file: the Markdown')
call delete_file(md)
call delete_file(prog//'.md')
call define(man_option=.false., progname=prog)
call cli%parse(args='--markdown', error=error)
inquire(file=prog//'.md', exist=exist)
call assert(exist, 'markdown default name: <progname>.md')
call delete_file(prog//'.md')
out = read_back(lun)

! builtins are not reported by provenance, nor copied by copy_options (the completion ones included)
call define(man_option=.true., man_file=man, completion_options=.true.)
call cli%parse(args='--mesh m', error=error)
call assert_equal(error, 0_I4P, 'provenance: parse')
out = cli%provenance()
call assert_contains(out, 'mesh', 'provenance: an option')
call assert(index(out, 'man ') == 0 .and. index(out, 'completion') == 0 .and. index(out, 'markdown') == 0, &
            'provenance: no builtin')
call cli%copy_options(to_group='run', from_group='', error=error)
call assert_equal(error, 0_I4P, 'copy_options')
call assert(cli%is_defined(group='run', switch='--mesh'), 'copy_options: an option copied')
call assert(.not.cli%is_defined(group='run', switch='--man'), 'copy_options: --man not copied')
call assert(.not.cli%is_defined(group='run', switch='--show-completion'), 'copy_options: completion not copied')
out = read_back(lun)

! standalone: exit status 0, the page saved, nothing printed
call delete_file(man)
call reinvoke(1_I4P, exitstat, out, err, args='--man')
call assert_equal(exitstat, 0_I4P, 'standalone: exit status')
call assert(index(out, 'not stopped') == 0, 'standalone: stopped')
inquire(file=man, exist=exist)
call assert(exist, 'standalone: the man page')
call delete_file(man)
call capture_close(lun)

contains
  subroutine define(man_option, man_file, markdown_file, progname, completion_options)
  !< A CLI with a required option and a command.
  logical,      intent(in)           :: man_option         !< Add --man.
  character(*), intent(in), optional :: man_file           !< Man page file.
  character(*), intent(in), optional :: markdown_file      !< Markdown file.
  character(*), intent(in), optional :: progname           !< Program name.
  logical,      intent(in), optional :: completion_options !< Add the completion builtins.
  integer(I4P)                       :: e                  !< Error trapping flag.
  character(:), allocatable          :: p                  !< Program name, local variable.

  p = 'flapman' ; if (present(progname)) p = progname
  call cli%init(progname=p, man_option=man_option, man_file=man_file, markdown_file=markdown_file, &
                completion_options=completion_options, standalone=.false., error_lun=lun, usage_lun=lun, version_lun=lun)
  call cli%add(switch='--mesh', help='mesh file', required=.true., act='store', error=e)
  call cli%add_group(group='run', description='run')
  call assert_equal(e, 0_I4P, 'define')
  endsubroutine define
endprogram flap_test_man_option

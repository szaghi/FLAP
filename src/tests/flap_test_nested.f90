!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_nested
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).
!<
!< Run with arguments it is the example program above; run without arguments it checks its own scenarios.

use, intrinsic :: iso_fortran_env, only : error_unit
use flap, only : command_line_interface, ERROR_GROUP_M_EXCLUDE, ERROR_UNKNOWN, ERROR_VALUE_MISSING
use flap_test_utils, only : assert_equal, capture_close, capture_open
use penf

implicit none
integer(I4P) :: lun !< Capture unit for FLAP messages in self-test mode.

if (command_argument_count() > 0) then
  call example
else
  call self_test
endif

contains
  subroutine example()
  !< The example program: parse the real command line and run the fake command.
  type(command_line_interface) :: cli           !< Command Line Interface (CLI).
  logical                      :: authors_print !< Boolean value.
  character(500)               :: message       !< Message value.
  integer(I4P)                 :: error         !< Error trapping flag.

  call define_cli(cli, error_unit)

  authors_print = .false.

  ! parse Command Line Interface
  call cli%parse(error=error)
  if (error/=0) then
    print '(A)', 'Error code: '//trim(str(n=error))
    stop
  endif

  ! use Command Line Interface data to trigger program behaviour
  call cli%get(switch='-a',val=authors_print,error=error) ; if (error/=0) stop
  if (authors_print) then
    print '(A)','Authors: '//cli%authors
  elseif (cli%run_command('init')) then
    print '(A)','init (fake) versioning'
  elseif (cli%run_command('commit')) then
    call cli%get(group='commit',switch='-m',val=message,error=error) ; if (error/=0) stop
    print '(A)','commit changes to current branch with message "'//trim(message)//'"'
  elseif (cli%run_command('tag')) then
    call cli%get(group='tag',switch='-a',val=message,error=error) ; if (error/=0) stop
    print '(A)','tag current branch with message "'//trim(message)//'"'
  else
    print '(A)','cowardly you are doing nothing... try at least "-h" option!'
  endif
  endsubroutine example

  subroutine define_cli(cli, lun)
  !< Define the example CLI.
  type(command_line_interface), intent(out) :: cli !< Command Line Interface (CLI).
  integer(I4P),                 intent(in)  :: lun !< Unit for usage and error messages.

  ! initialize Command Line Interface
  call cli%init(error_lun=lun, usage_lun=lun,                                        &
                progname    = 'test_nested',                                       &
                version     = 'v2.1.5',                                            &
                authors     = 'Stefano Zaghi',                                     &
                license     = 'MIT',                                               &
                description = 'Toy program for testing FLAP with nested commands', &
                examples    = ['test_nested                      ',                &
                               'test_nested -h                   ',                &
                               'test_nested init                 ',                &
                               'test_nested commit -m "fix bug-1"',                &
                               'test_nested tag -a "v2.1.5"      '])

  ! set a Command Line Argument without a group to trigger authors names printing
  call cli%add(switch='--authors',switch_ab='-a',help='Print authors names',required=.false.,act='store_true',def='.false.')

  ! set Command Line Arguments Groups, i.e. commands
  call cli%add_group(group='init',description='fake init versioning')
  call cli%add_group(group='commit',description='fake commit changes to current branch')
  call cli%add_group(group='tag',description='fake tag current commit')
  call cli%set_mutually_exclusive_groups(group1='init',group2='commit')

  ! set Command Line Arguments of commit command
  call cli%add(group='commit',switch='--message',switch_ab='-m',help='Commit message',required=.false.,act='store',def='')

  ! set Command Line Arguments of commit command
  call cli%add(group='tag',switch='--annotate',switch_ab='-a',help='Tag annotation',required=.false.,act='store',def='')
  endsubroutine define_cli

  subroutine self_test()
  !< Subcommands: selection, their own options, a top-level flag, mutual exclusion and a value equal to a command name.
  type(command_line_interface) :: cli     !< Command Line Interface (CLI).
  logical                      :: authors !< Authors flag.
  character(99)                :: message !< Commit message.
  character(99)                :: annot   !< Tag annotation.
  integer(I4P)                 :: error   !< Error trapping flag.

  call capture_open(lun)

  call parse('', cli, error)
  call assert_equal(error, 0_I4P, 'no arguments: error')
  call called(cli, '', [.false., .false., .false.])
  call cli%get(switch='-a', val=authors, error=error)
  call assert_equal(authors, .false., 'no arguments: --authors')

  call parse('-a', cli, error)
  call cli%get(switch='-a', val=authors, error=error)
  call assert_equal(authors, .true., '-a: --authors')

  call parse('init', cli, error)
  call assert_equal(error, 0_I4P, 'init: error')
  call called(cli, 'init', [.true., .false., .false.])

  call parse('commit -m "fix bug-1"', cli, error)
  call assert_equal(error, 0_I4P, 'commit -m: error')
  call called(cli, 'commit -m', [.false., .true., .false.])
  call cli%get(group='commit', switch='-m', val=message, error=error)
  call assert_equal(message, 'fix bug-1', 'commit -m: message')

  call parse('tag -a v2.1.5', cli, error)
  call called(cli, 'tag -a', [.false., .false., .true.])
  call cli%get(group='tag', switch='-a', val=annot, error=error)
  call assert_equal(annot, 'v2.1.5', 'tag -a: annotation (same short switch as the top-level --authors)')

  call parse('init commit', cli, error)
  call assert_equal(error, ERROR_GROUP_M_EXCLUDE, 'init commit: mutually exclusive commands')

  call parse('commit tag', cli, error)
  call assert_equal(error, 0_I4P, 'commit tag: commands not declared exclusive can be combined')
  call called(cli, 'commit tag', [.false., .true., .true.])

  call parse('commit -x', cli, error)
  call assert_equal(error, ERROR_UNKNOWN, 'commit -x: unknown switch in the command')

  ! B04 (#125): an option value equal to a command name is taken as that command; these assertions pin the current
  ! behaviour and flip when B04 is fixed
  call parse('commit -m tag', cli, error)
  call assert_equal(error, ERROR_VALUE_MISSING, 'commit -m tag: value taken as the tag command (B04, current behaviour)')
  call called(cli, 'commit -m tag (B04, current behaviour)', [.false., .true., .true.])

  call capture_close(lun)
  endsubroutine self_test

  subroutine parse(args, cli, error)
  !< Define the example CLI (messages captured) and parse a command line.
  character(*),                 intent(in)  :: args  !< Command line.
  type(command_line_interface), intent(out) :: cli   !< Command Line Interface (CLI).
  integer(I4P),                 intent(out) :: error !< Error trapping flag of parse.

  call define_cli(cli, lun)
  call cli%parse(args=args, error=error)
  endsubroutine parse

  subroutine called(cli, label, expected)
  !< Check which commands have been called.
  type(command_line_interface), intent(in) :: cli         !< Command Line Interface (CLI).
  character(*),                 intent(in) :: label       !< Scenario label.
  logical,                      intent(in) :: expected(3) !< Expected init, commit, tag.

  call assert_equal(cli%run_command('init'),   expected(1), label//': init called')
  call assert_equal(cli%run_command('commit'), expected(2), label//': commit called')
  call assert_equal(cli%run_command('tag'),    expected(3), label//': tag called')
  endsubroutine called
endprogram flap_test_nested

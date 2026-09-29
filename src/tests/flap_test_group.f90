!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_group
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).

use flap, only : command_line_interface, ERROR_MISSING_GROUP, ERROR_UNKNOWN
use flap_test_utils, only : assert_equal, capture_close, capture_open
use penf

implicit none
logical      :: spectrum !< Spectrum value.
logical      :: domain   !< Domain value.
logical      :: grid     !< Grid value.
logical      :: called   !< The group "new" has been called.
integer(I4P) :: error    !< Error trapping flag.
integer(I4P) :: lun      !< Capture unit for FLAP messages.

call capture_open(lun)

call fake_call('', spectrum, domain, grid, called, error)
call assert_equal(error, 0_I4P, 'no arguments: error')
call assert_equal(called, .false., 'no arguments: group not called')
call check('no arguments', [.false., .false., .false.])

call fake_call('new -s', spectrum, domain, grid, called, error)
call assert_equal(error, 0_I4P, 'new -s: error')
call assert_equal(called, .true., 'new -s: group called')
call check('new -s', [.true., .false., .false.])

call fake_call('new -d', spectrum, domain, grid, called, error)
call check('new -d', [.false., .true., .false.])

call fake_call('new -g', spectrum, domain, grid, called, error)
call check('new -g', [.false., .false., .true.])

call fake_call('new --spectrum -g', spectrum, domain, grid, called, error)
call check('new --spectrum -g', [.true., .false., .true.])

call fake_call('new', spectrum, domain, grid, called, error)
call assert_equal(called, .true., 'new alone: group called')
call check('new alone', [.false., .false., .false.])

call fake_call('new -x', spectrum, domain, grid, called, error)
call assert_equal(error, ERROR_UNKNOWN, 'new -x: unknown switch in the group')

call check_values_named_as_commands
call check_unknown_group

call capture_close(lun)

contains
  subroutine check_unknown_group()
  !< B24 (#125): get with an unknown group reports ERROR_MISSING_GROUP and returns, for every getter kind.
  type(command_line_interface) :: cli       !< Command Line Interface (CLI).
  character(99)                :: name      !< Scalar value.
  character(99)                :: pair(2)   !< Fixed-size list value.
  character(99), allocatable   :: list(:)   !< Varying-size list value.
  integer(I4P),  allocatable   :: ilist(:)  !< Varying-size integer list value.
  integer(I4P)                 :: err       !< Error trapping flag.

  call define_values(cli, '')
  call cli%get(group='nope', switch='--name', val=name, error=err)
  call assert_equal(err, ERROR_MISSING_GROUP, 'get, unknown group')
  call cli%get(group='nope', switch='--pair', val=pair, error=err)
  call assert_equal(err, ERROR_MISSING_GROUP, 'get into a fixed-size list, unknown group')
  call cli%get_varying(group='nope', switch='--list', val=list, error=err)
  call assert_equal(err, ERROR_MISSING_GROUP, 'get_varying (character), unknown group')
  call cli%get_varying(group='nope', switch='--list', val=ilist, error=err)
  call assert_equal(err, ERROR_MISSING_GROUP, 'get_varying (integer), unknown group')
  endsubroutine check_unknown_group

  subroutine check_values_named_as_commands()
  !< B04 (#125): a value equal to a command name is the value when the option takes a fixed number of values; a variadic
  !< list is ended by a command name.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  character(99)                :: name     !< Value of --name.
  character(99)                :: target   !< Value of new --target.
  character(99)                :: pair(2)  !< Values of --pair.
  character(99), allocatable   :: list(:)  !< Values of --list.
  integer(I4P)                 :: err      !< Error trapping flag.

  call define_values(cli, '--name new new --target del')
  call assert_equal(cli%run_command('new'), .true., '--name new new ...: new called')
  call assert_equal(cli%run_command('del'), .false., '--name new new ...: del not called')
  call cli%get(switch='--name', val=name, error=err)
  call assert_equal(name, 'new', '--name new: value equal to a command name')
  call cli%get(group='new', switch='--target', val=target, error=err)
  call assert_equal(target, 'del', 'new --target del: value equal to another command name')

  call define_values(cli, '--pair new del del')
  call assert_equal(cli%run_command('new'), .false., '--pair new del del: new not called')
  call assert_equal(cli%run_command('del'), .true., '--pair new del del: del called')
  call cli%get(switch='--pair', val=pair, error=err)
  call assert_equal(pair(1), 'new', "--pair new del: nargs='2' value 1")
  call assert_equal(pair(2), 'del', "--pair new del: nargs='2' value 2")

  call define_values(cli, '--list a b new')
  call assert_equal(cli%run_command('new'), .true., "--list a b new: a command name ends a nargs='*' list")
  call cli%get_varying(switch='--list', val=list, error=err)
  call assert_equal(int(size(list), I4P), 2_I4P, "--list a b new: list size")
  endsubroutine check_values_named_as_commands

  subroutine define_values(cli, args)
  !< Define a CLI whose options take values that may equal command names, and parse a command line (it must succeed).
  type(command_line_interface), intent(out) :: cli  !< Command Line Interface (CLI).
  character(*),                 intent(in)  :: args !< Command line.
  integer(I4P)                              :: err  !< Error trapping flag.

  call cli%init(progname='flap_test_group', error_lun=lun, usage_lun=lun)
  call cli%add(switch='--name', help='a value', required=.false., act='store', def='x', error=err)
  call assert_equal(err, 0_I4P, 'add --name')
  call cli%add(switch='--pair', help='two values', required=.false., act='store', nargs='2', def='x y', error=err)
  call assert_equal(err, 0_I4P, 'add --pair')
  call cli%add(switch='--list', help='values', required=.false., act='store', nargs='*', def='x', error=err)
  call assert_equal(err, 0_I4P, 'add --list')
  call cli%add_group(group='new', description='create')
  call cli%add(group='new', switch='--target', help='a value', required=.false., act='store', def='x', error=err)
  call assert_equal(err, 0_I4P, 'add new --target')
  call cli%add_group(group='del', description='delete')
  call cli%parse(args=args, error=err)
  call assert_equal(err, 0_I4P, 'parse "'//args//'"')
  endsubroutine define_values

  subroutine check(label, expected)
  !< Check the three flags.
  character(*), intent(in) :: label       !< Scenario label.
  logical,      intent(in) :: expected(3) !< Expected spectrum, domain, grid.

  call assert_equal(spectrum, expected(1), label//': spectrum')
  call assert_equal(domain,   expected(2), label//': domain')
  call assert_equal(grid,     expected(3), label//': grid')
  endsubroutine check

  subroutine fake_call(args, spectrum, domain, grid, called, error)
  !< Define a CLI with one group of three flags, parse a fake command line and get the flags.
  character(*), intent(in)     :: args     !< Fake arguments.
  logical,      intent(out)    :: spectrum !< Spectrum value.
  logical,      intent(out)    :: domain   !< Domain value.
  logical,      intent(out)    :: grid     !< Grid value.
  logical,      intent(out)    :: called   !< The group "new" has been called.
  integer(I4P), intent(out)    :: error    !< Error trapping flag of parse.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  integer(I4P)                 :: err      !< Error trapping flag.

  spectrum = .false.
  domain   = .false.
  grid     = .false.
  called   = .false.
  call cli%init(progname='flap_test_group', error_lun=lun, usage_lun=lun)
  call cli%add_group(group='new', description='create new instance')
  call cli%add(group='new', switch='--spectrum', switch_ab='-s',            &
               help='Create new spectrum', required=.false., def='.false.', &
               act='store_true', error=err)
  call assert_equal(err, 0_I4P, 'add --spectrum')
  call cli%add(group='new', switch='--domain', switch_ab='-d',            &
               help='Create new domain', required=.false., def='.false.', &
               act='store_true', error=err)
  call assert_equal(err, 0_I4P, 'add --domain')
  call cli%add(group='new', switch='--grid', switch_ab='-g',            &
               help='Create new grid', required=.false., def='.false.', &
               act='store_true', error=err)
  call assert_equal(err, 0_I4P, 'add --grid')
  call cli%parse(args=args, error=error)
  if (error /= 0) return
  called = cli%run_command('new')
  call cli%get(group='new', switch='--spectrum', val=spectrum, error=err)
  call assert_equal(err, 0_I4P, args//': get --spectrum')
  call cli%get(group='new', switch='--domain', val=domain, error=err)
  call assert_equal(err, 0_I4P, args//': get --domain')
  call cli%get(group='new', switch='--grid', val=grid, error=err)
  call assert_equal(err, 0_I4P, args//': get --grid')
  endsubroutine fake_call
endprogram flap_test_group

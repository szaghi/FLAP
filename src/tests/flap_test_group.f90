!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_group
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).

use flap, only : command_line_interface, ERROR_UNKNOWN
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

call capture_close(lun)

contains
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

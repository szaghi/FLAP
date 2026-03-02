!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
program flap_test_group
!< A testing program for FLAP, Fortran command Line Arguments Parser for poor people
!<
!<### Compile
!< See [compile instructions](https://github.com/szaghi/FLAP/wiki/Download-compile).
!<
!<###Usage Compile
!< See [usage instructions](https://github.com/szaghi/FLAP/wiki/Testing-Programs).

use flap, only : command_line_interface
use penf

implicit none
logical :: switch_value_domain   !< Switch sentinel.
logical :: switch_value_grid     !< Switch sentinel.
logical :: switch_value_spectrum !< Switch sentinel.

call fake_call(args='', spectrum=switch_value_spectrum, domain=switch_value_domain, grid=switch_value_grid)
print*, 'test_group'
print*, 'spectrum = ', switch_value_spectrum
print*, 'domain   = ', switch_value_domain
print*, 'grid     = ', switch_value_grid
if (switch_value_spectrum .neqv. .false.) error stop 'test_group: spectrum should be .false.'
if (switch_value_domain   .neqv. .false.) error stop 'test_group: domain should be .false.'
if (switch_value_grid     .neqv. .false.) error stop 'test_group: grid should be .false.'

call fake_call(args='new -s', spectrum=switch_value_spectrum, domain=switch_value_domain, grid=switch_value_grid)
print*, 'test_group new -s'
print*, 'spectrum = ', switch_value_spectrum
print*, 'domain   = ', switch_value_domain
print*, 'grid     = ', switch_value_grid
if (switch_value_spectrum .neqv. .true. ) error stop 'test_group new -s: spectrum should be .true.'
if (switch_value_domain   .neqv. .false.) error stop 'test_group new -s: domain should be .false.'
if (switch_value_grid     .neqv. .false.) error stop 'test_group new -s: grid should be .false.'

call fake_call(args='new -d', spectrum=switch_value_spectrum, domain=switch_value_domain, grid=switch_value_grid)
print*, 'test_group new -d'
print*, 'spectrum = ', switch_value_spectrum
print*, 'domain   = ', switch_value_domain
print*, 'grid     = ', switch_value_grid
if (switch_value_spectrum .neqv. .false.) error stop 'test_group new -d: spectrum should be .false.'
if (switch_value_domain   .neqv. .true. ) error stop 'test_group new -d: domain should be .true.'
if (switch_value_grid     .neqv. .false.) error stop 'test_group new -d: grid should be .false.'

call fake_call(args='new -g', spectrum=switch_value_spectrum, domain=switch_value_domain, grid=switch_value_grid)
print*, 'test_group new -g'
print*, 'spectrum = ', switch_value_spectrum
print*, 'domain   = ', switch_value_domain
print*, 'grid     = ', switch_value_grid
if (switch_value_spectrum .neqv. .false.) error stop 'test_group new -g: spectrum should be .false.'
if (switch_value_domain   .neqv. .false.) error stop 'test_group new -g: domain should be .false.'
if (switch_value_grid     .neqv. .true. ) error stop 'test_group new -g: grid should be .true.'
contains
  subroutine fake_call(args, spectrum, domain, grid)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Wrapper for fake calls.
  !---------------------------------------------------------------------------------------------------------------------------------
  character(*), intent(in)     :: args     !< Fake arguments.
  logical,      intent(out)    :: spectrum !< Spectrum value.
  logical,      intent(out)    :: domain   !< Domain value.
  logical,      intent(out)    :: grid     !< Grid value.
  type(command_line_interface) :: cli      !< Command Line Interface (CLI).
  integer(I4P)                 :: error    !< Error trapping flag.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  call cli%init
  call cli%add_group(group='new', description='create new instance')
  call cli%add(group='new', switch='--spectrum', switch_ab='-s',            &
               help='Create new spectrum', required=.false., def='.false.', &
               act='store_true', error=error)
  if (error/=0) stop
  call cli%add(group='new', switch='--domain', switch_ab='-d',            &
               help='Create new domain', required=.false., def='.false.', &
               act='store_true', error=error)
  if (error/=0) stop
  call cli%add(group='new', switch='--grid', switch_ab='-g',            &
               help='Create new grid', required=.false., def='.false.', &
               act='store_true', error=error)
  if (error/=0) stop
  call cli%parse(args=args, error=error)
  if (error/=0) stop
  call cli%get(group='new', switch='--spectrum', val=spectrum, error=error)
  if (error/=0) stop
  call cli%get(group='new', switch='--domain', val=domain, error=error)
  if (error/=0) stop
  call cli%get(group='new', switch='--grid', val=grid, error=error)
  if (error/=0) stop
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine fake_call
endprogram flap_test_group

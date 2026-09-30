!< Path checks of option values: must_exist, readable, writable, allow_dash (issue #125, step 2.7; #11 5.1, T5.1-T5.11).
program flap_test_path
!< Path checks of option values: must_exist, readable, writable, allow_dash (issue #125, step 2.7; #11 5.1, T5.1-T5.11).
!<
!< The resolved value is checked at parse, whatever its source (the default included; an empty value is not checked), with
!< standard Fortran only: inquire for existence, an open for reading or appending (nothing written) for the permissions.
!< Directories are not told apart (#11 5: a directory exists and opens for reading). The fixtures are created next to the
!< executable; the permission cases use chmod and are skipped when running as root.
use flap, only : command_line_interface, ERROR_PATH_INCONSISTENT, ERROR_PATH_NOT_FOUND, ERROR_PATH_NOT_READABLE, &
                 ERROR_PATH_NOT_WRITABLE
use flap_test_utils, only : assert, assert_contains, assert_equal, capture_close, capture_open, delete_file, read_back, &
                            read_file, run_command, scratch_file, write_file
use penf, only : I4P
use, intrinsic :: iso_fortran_env, only : compiler_version

implicit none
type(command_line_interface) :: cli      !< Command Line Interface (CLI).
character(:), allocatable    :: fin      !< Existing readable file.
character(:), allocatable    :: fro      !< Read-only file.
character(:), allocatable    :: fsecret  !< Unreadable file.
character(:), allocatable    :: fout     !< Output file, not existing.
character(:), allocatable    :: out      !< Captured output.
logical                      :: root     !< Running as root (or without chmod): permissions are not enforced.
logical                      :: exists   !< File existence.
integer(I4P)                 :: lun      !< Capture unit.
integer(I4P)                 :: exitstat !< Exit status.
integer(I4P)                 :: error    !< Error trapping flag.

fin = scratch_file('in') ; fro = scratch_file('ro') ; fsecret = scratch_file('secret') ; fout = scratch_file('out')
call write_file(fin, 'data')
call write_file(fro, 'read only')
call write_file(fsecret, 'secret')
call delete_file(fout)
call run_command('id -u', exitstat, out)
root = index(out, '0') == 1 .and. len_trim(out) <= 2
call run_command("chmod 444 '"//fro//"' && chmod 000 '"//fsecret//"'", exitstat, out)
if (exitstat /= 0) root = .true.

call capture_open(lun)
! T5.1, T5.2: existence
call check('--in '//fin, 0_I4P, 'existing file')
call check('--in '//fin//'.missing', ERROR_PATH_NOT_FOUND, 'missing file')
call assert_contains(out, fin//'.missing', 'missing file: named in the message')
! T5.3: unreadable, with the reason of the processor; T5.4: read-only file for writing
if (root) then
  print '(A)', 'SKIP: permission cases (root, or no chmod)'
else
  call check('--in '//fsecret, ERROR_PATH_NOT_READABLE, 'unreadable file')
  call assert_contains(out, fsecret, 'unreadable file: named in the message')
  if (index(compiler_version(), 'nvfortran') > 0) then
    ! nvfortran 26.5: open(action='write') of a read-only file succeeds (the error comes at the first write), so a
    ! read-only file passes writable; documented limitation, pinned here
    call check('--in '//fin//' --out '//fro, 0_I4P, 'read-only file for writing (nvfortran: not detected)')
  else
    call check('--in '//fin//' --out '//fro, ERROR_PATH_NOT_WRITABLE, 'read-only file for writing')
  endif
endif
! T5.5: a missing output file passes and is not created
call check('--in '//fin//' --out '//fout, 0_I4P, 'missing output file')
inquire(file=fout, exist=exists)
call assert(.not.exists, 'missing output file: not created')
! T5.6: an existing writable file passes, untouched
call check('--in '//fin//' --out '//fin, 0_I4P, 'existing writable file')
call assert_equal(read_file(fin), 'data'//new_line('a'), 'existing writable file: content unchanged')
! T5.7, T5.8: '-' with and without allow_dash
call check('--in '//fin//' --log -', 0_I4P, '- with allow_dash')
call check('--in -', ERROR_PATH_NOT_FOUND, '- without allow_dash: a file name')
! T5.9: a missing default is an error at parse time; an empty value is not checked
call check('--in '//fin, ERROR_PATH_NOT_FOUND, 'missing default', def=fin//'.nodef')
call check('--in '//fin, 0_I4P, 'empty default: not checked', def='')
! T5.10: a directory exists (the known limitation: directories are not told apart)
call check('--in .', 0_I4P, 'directory with readable: accepted')
! T5.11: a list, one bad element
call check('--in '//fin//' --inputs '//fin//' '//fin//'.missing', ERROR_PATH_NOT_FOUND, 'list with a missing element')
call check('--in '//fin//' --inputs '//fin//' '//fin, 0_I4P, 'list of existing files')
! a command not called is not checked
call check('--in '//fin, 0_I4P, 'command not called: its default is not checked')
call check('--in '//fin//' run', ERROR_PATH_NOT_FOUND, 'command called: its default is checked')
! definitions: the path keywords need a value (store, store*, append)
call cli%init(progname='flap_test_path', error_lun=lun, usage_lun=lun)
call cli%add(switch='--flag', help='flag', required=.false., act='store_true', def='.false.', must_exist=.true., error=error)
call assert_equal(error, ERROR_PATH_INCONSISTENT, 'must_exist on a flag: definition error')
call cli%init(progname='flap_test_path', error_lun=lun, usage_lun=lun)
call cli%add(switch='--app', help='append', required=.false., act='append', def='.', must_exist=.true., error=error)
call assert_equal(error, 0_I4P, 'must_exist on an append: allowed')
call capture_close(lun)

call run_command("chmod 644 '"//fro//"' '"//fsecret//"'", exitstat, out)
call delete_file(fin) ; call delete_file(fro) ; call delete_file(fsecret) ; call delete_file(fout)

contains
  subroutine check(args, expected, message, def)
  !< Define the CLI, parse a command line and check the error.
  character(*), intent(in)           :: args     !< Command line.
  integer(I4P), intent(in)           :: expected !< Expected error.
  character(*), intent(in)           :: message  !< Description of the check.
  character(*), intent(in), optional :: def      !< Default of --cfg.

  call cli%init(progname='flap_test_path', error_lun=lun, usage_lun=lun, error_hint=.false.)
  call cli%add(switch='--in', help='input', required=.true., act='store', readable=.true., error=error)
  call cli%add(switch='--out', help='output', required=.false., act='store', def='', writable=.true., error=error)
  call cli%add(switch='--log', help='log', required=.false., act='store', def='-', writable=.true., allow_dash=.true., &
               error=error)
  call cli%add(switch='--inputs', help='inputs', required=.false., act='store', nargs='+', def='', must_exist=.true., &
               error=error)
  if (present(def)) then
    call cli%add(switch='--cfg', help='configuration', required=.false., act='store', def=def, must_exist=.true., &
                 error=error)
  endif
  call cli%add_group(group='run', description='run')
  call cli%add(group='run', switch='--table', help='table', required=.false., act='store', def='missing.table', &
               must_exist=.true., error=error)
  call assert_equal(error, 0_I4P, message//': definitions')
  call cli%parse(args=args, error=error)
  out = read_back(lun)
  call assert_equal(error, expected, message)
  endsubroutine check
endprogram flap_test_path

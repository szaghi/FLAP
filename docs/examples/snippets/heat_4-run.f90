subroutine run
!< The run command.
integer :: nx, verbose, e
real(8) :: cfl

call cli%get(group='run', switch='--nx', val=nx, error=e)
call cli%get(group='run', switch='--cfl', val=cfl, error=e)
call cli%get(group='run', switch='--verbose', val=verbose, error=e)
print '(A,I0,A,F4.2,A,I0)', 'run: nx ', nx, ', cfl ', cfl, ', verbosity ', verbose
endsubroutine run

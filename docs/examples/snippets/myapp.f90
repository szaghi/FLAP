program myapp
!< Options of every basic kind: parse, then get each value into a variable of its type.
use flap
implicit none
type(command_line_interface) :: cli
character(256)               :: input
character(256)               :: output
integer                      :: n
real(8)                      :: tol
logical                      :: verbose
integer                      :: error

call cli%init(progname    = 'myapp',                         &
              version     = 'v1.0',                          &
              description = 'Demonstration program',         &
              examples    = ['myapp -i a.dat -o b.dat      ', &
                             'myapp -i a.dat -n 100 --tol 1'])
call cli%add(switch='--input',   switch_ab='-i', help='Input file',     required=.true.,  act='store', error=error)
call cli%add(switch='--output',  switch_ab='-o', help='Output file',    required=.false., act='store', def='out.dat', &
             error=error)
call cli%add(switch='--niter',   switch_ab='-n', help='Iterations',     required=.false., act='store', def='100', &
             error=error)
call cli%add(switch='--tol',     switch_ab='-t', help='Tolerance',      required=.false., act='store', def='1.0e-6', &
             error=error)
call cli%add(switch='--verbose',                 help='Verbose output', required=.false., act='store_true', &
             def='.false.', error=error)
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.

call cli%get(switch='-i',        val=input,   error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='-o',        val=output,  error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='-n',        val=n,       error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='-t',        val=tol,     error=error) ; if (error /= 0) stop 1, quiet=.true.
call cli%get(switch='--verbose', val=verbose, error=error) ; if (error /= 0) stop 1, quiet=.true.

print '(A)',       'input   = '//trim(input)
print '(A)',       'output  = '//trim(output)
print '(A,I0)',    'niter   = ', n
print '(A,ES8.1)', 'tol     = ', tol
print '(A,L1)',    'verbose = ', verbose
endprogram myapp

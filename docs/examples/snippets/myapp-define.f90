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

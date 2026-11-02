if (cli%is_dry_run()) then
  print '(A,I0,A)', 'would run ', steps, ' steps'
  stop
endif

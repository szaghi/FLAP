call cli%parse(error=error)
if (error == STATUS_ALTERNATE) then
  if (cli%is_passed(switch='--list-models')) print '(A)', 'spalart-allmaras, k-omega-sst'
  stop
elseif (error /= 0) then
  stop 1, quiet=.true.
endif

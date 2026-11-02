if (trim(input) == '-') then
  read(*, '(A)') line
else
  open(newunit=unit, file=trim(input), action='read')
  read(unit, '(A)') line
  close(unit)
endif

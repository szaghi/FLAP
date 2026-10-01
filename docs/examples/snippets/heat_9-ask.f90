if (interactive .and. .not.cli%is_passed(switch='--scheme')) then
  call m%init(question='Time scheme?')
  call m%add_option(text='fe: explicit Euler', is_default=.true.)
  call m%add_option(text='cn: Crank-Nicolson')
  call m%run(choice, merror)
  if (merror /= 0) stop 1, quiet=.true.   ! no answer (a batch job): stop rather than guess
  scheme = merge('fe', 'cn', choice == 1)
  write(*, '(A)')
endif

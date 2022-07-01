! This file is part of fortran_tester
! Copyright 2015 Pierre de Buyl
! License: BSD

program test_tester_7
  use tester
  implicit none

  type(tester_t) :: test

  call test%init()

  call test%assert_equal([1, 2, huge(1)], [0, 2, huge(1)])

  call test%print()

end program test_tester_7

! This file is part of fortran_tester
! Copyright 2015 Pierre de Buyl
! License: BSD

program test_tester_8
  use tester
  implicit none

  type(tester_t) :: test
  integer, parameter :: long_k = selected_int_kind(18)

  call test%init()

  call test%assert_equal([1_long_k, 2_long_k, huge(1_long_k)], [0_long_k, 2_long_k, huge(1_long_k)])

  call test%print()

end program test_tester_8

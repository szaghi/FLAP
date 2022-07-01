! This file is part of fortran_tester
! Copyright 2015 Pierre de Buyl
! License: BSD

program test_tester_4
  use tester
  implicit none

  type(tester_t) :: test

  call test%init()

  call test%assert_equal(.true., 1>2)

  call test%print()

end program test_tester_4

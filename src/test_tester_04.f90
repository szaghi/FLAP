! This file is part of fortran_tester
! Copyright 2018 Pierre de Buyl
! License: BSD

program test_tester_6
  use tester
  implicit none

  integer, parameter :: rk = selected_real_kind(15)
  real(kind=rk), parameter :: pi = 4*atan(1._rk)
  type(tester_t) :: test

  call test%init()

  call test%assert_close(sin(2*pi), 0._rk)

  call test%assert_close(sin(2*3.1415927), 0.)

  call test%print()

end program test_tester_6

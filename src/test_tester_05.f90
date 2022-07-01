! This file is part of fortran_tester
! Copyright 2015 Pierre de Buyl
! License: BSD

program test_tester_05
  use tester
  implicit none

  integer, parameter :: i_k1 = selected_int_kind(3)

  type(tester_t) :: test

  call test% init()

  call test% assert_equal(8765_i_k1, 8765_i_k1)

  call test% assert_equal( &
       [-3261_i_k1, -1169_i_k1, 2967_i_k1, -3736_i_k1, 3504_i_k1], &
       [-3261_i_k1, -1169_i_k1, 2967_i_k1, -3736_i_k1, 3504_i_k1])

  call test% assert_positive(1982_i_k1)

  call test% assert_positive([6987_i_k1, 0_i_k1])

  call test% print()

end program test_tester_05

! This file is part of fortran_tester
! Copyright 2015 Pierre de Buyl
! License: BSD

program test_tester_1
  use tester
  implicit none

  integer, parameter :: long_k = selected_int_kind(18)
  double precision :: pi = 4*atan(1.d0)

  type(tester_t) :: test

  call test% init()

  call test% assert_equal(-121, -11**2)

  call test% assert_equal([1, -10, 1899010], [1, -10, 1899010])

  call test% assert_equal([0.2420243742417814d0, 0.4924788296716989d0, &
       0.8541147722227219d0, 0.267520651034313d0 , 0.6948550035165076d0], &
       [0.2420243742417814d0, 0.4924788296716989d0, &
       0.8541147722227219d0, 0.267520651034313d0 , 0.6948550035165076d0])

  call test% assert_close(0.d0, sin(pi))

  call test% assert_equal(0.d0, 0*1.d0)

  call test% assert_equal(.true., 2 > 1)

  call test% assert_equal(1.0, 1.0)

  call test% assert_equal( &
       [7.2936402920067644, 3.0975232096437191, 9.2077205929200456, &
       9.0014871205366358], &
       [7.2936402920067644, 3.0975232096437191, 9.2077205929200456, &
       9.0014871205366358])

  call test% assert_close(1.d0, (1.d0+1.d-16))

  call test% assert_close(1., (1.+1.e-7))

  call test% assert_close([ 0.58557761, 0.04035789, 0.30463428, &
       0.57437861, 0.4879709 , 0.00986957], &
       [ 0.58557761+epsilon(1.0), 0.04035789, 0.30463428+2*epsilon(1.0), &
       0.57437861, 0.4879709 , 0.00986957-epsilon(1.0)])

  call test% assert_close([1.d0, 2.d0], [1.d0, 2.d0])

  call test% assert_positive(epsilon(1.))
  call test% assert_positive(0.1)
  call test% assert_positive(0.1d0)

  call test% assert_positive([1., 2., 0.])
  call test% assert_positive([1.d0, huge(1.d0)])

  call test% assert_equal(1, 1)
  call test% assert_equal(1_long_k, 1_long_k)
  call test% assert_equal([1, -huge(1), huge(1), 0], [1, -huge(1), huge(1), 0])
  call test% assert_equal([1_long_k, -huge(1_long_k), huge(1_long_k), 0_long_k], &
       [1_long_k, -huge(1_long_k), huge(1_long_k), 0_long_k])

  call test% assert_positive(2**30)
  call test% assert_positive(2_long_k**62)
  call test% assert_positive([2**30, 1, 0])
  call test% assert_positive([2_long_k**62, 1_long_k, 0_long_k])

  call test% print()

end program test_tester_1

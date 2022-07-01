! This file is part of fortran_tester
! Copyright 2015 2018 Pierre de Buyl
! License: BSD

program test_tester_1
  use tester
  implicit none

  integer, parameter :: rk = selected_real_kind(15)
  complex(kind=rk) :: x, y
  complex(kind=rk) :: a(5), b(5)
  complex :: c(3), d(3)
  type(tester_t) :: test

  call test% init()

  call test% assert_equal((1234, -1234), (1234, -1234))

  call test% assert_close((1._rk, 0._rk), (1._rk, 0._rk))

  call test% assert_close(cmplx(1., epsilon(0.)), (1., 0.))

  x = (0._rk, 1._rk)
  y = cmplx(epsilon(0._rk), 1._rk, kind=rk)
  call test% assert_close(x, y)

  x = cmplx(-1158.1181871905803291, 779.0494065373754893)
  y = cmplx(-1158.1181871905803291, 779.0494065373754893)

  call test% assert_equal(x, y)

  c = 1
  d = 1
  d = d + cmplx(0, epsilon(0.))

  call test% assert_close(c, d)

  c = cmplx(1154274.4026509234681726, -461087.8365501734078862)
  d = cmplx(1154274.4026509234681726, -461087.8365501734078862)

  call test% assert_equal(c, d)

  a = -10
  b = -10

  call test% assert_equal(a, b)

  a = 0
  b = epsilon(0._rk)

  call test% assert_close(a, b)

  b(1) = b(1) + cmplx(0._rk, epsilon(real(b(1))), kind=rk)

  call test% assert_close(a, b)

  call test% print()

end program test_tester_1

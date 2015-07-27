!< Pure Fortran (2003+) library for ensuring codes portability
module IR_Precision
!-----------------------------------------------------------------------------------------------------------------------------------
!< Pure Fortran (2003+) library for ensuring codes portability
!<{!README-IR_Precision.md!}
!-----------------------------------------------------------------------------------------------------------------------------------
USE, intrinsic:: ISO_FORTRAN_ENV, only: stdout => OUTPUT_UNIT, stderr => ERROR_UNIT ! Standard output/error logical units.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
public:: endianL,endianB,endian
public:: R16P, FR16P, DR16P, MinR16P, MaxR16P, BIR16P, BYR16P, smallR16P, ZeroR16
public:: R8P,  FR8P,  DR8P,  MinR8P,  MaxR8P,  BIR8P,  BYR8P,  smallR8P,  ZeroR8
public:: R4P,  FR4P,  DR4P,  MinR4P,  MaxR4P,  BIR4P,  BYR4P,  smallR4P,  ZeroR4
public:: R_P,  FR_P,  DR_P,  MinR_P,  MaxR_P,  BIR_P,  BYR_P,  smallR_P,  Zero
public:: I8P,  FI8P,  DI8P,  MinI8P,  MaxI8P,  BII8P,  BYI8P
public:: I4P,  FI4P,  DI4P,  MinI4P,  MaxI4P,  BII4P,  BYI4P
public:: I2P,  FI2P,  DI2P,  MinI2P,  MaxI2P,  BII2P,  BYI2P
public:: I1P,  FI1P,  DI1P,  MinI1P,  MaxI1P,  BII1P,  BYI1P
public:: I_P,  FI_P,  DI_P,  MinI_P,  MaxI_P,  BII_P,  BYI_P
public:: NRknd, RPl, FRl
public:: NIknd, RIl, FIl
public:: check_endian
public:: bit_size,byte_size
public:: str, strz, cton, bstr, bcton
public:: digit
public:: ir_initialized,IR_Init
public:: IR_Print
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
logical::            ir_initialized = .false. !< Flag for chcecking the initialization of some variables that must be initialized.
integer, parameter:: endianL        = 1       !< Little endian parameter.
integer, parameter:: endianB        = 0       !< Big endian parameter.
integer::            endian         = endianL !< Bit ordering: Little endian (endianL), or Big endian (endianB).

! The following are the portable kind parameters available.
! Real precision definitions:
#ifdef r16p
integer, parameter:: R16P = selected_real_kind(33,4931) !< 33  digits, range \([10^{-4931}, 10^{+4931} - 1]\); 128 bits.
#else
integer, parameter:: R16P = selected_real_kind(15,307)  !< Defined as R8P; 64 bits.
#endif
integer, parameter:: R8P  = selected_real_kind(15,307)  !< 15  digits, range \([10^{-307} , 10^{+307}  - 1]\); 64 bits.
integer, parameter:: R4P  = selected_real_kind(6,37)    !< 6   digits, range \([10^{-37}  , 10^{+37}   - 1]\); 32 bits.
integer, parameter:: R_P  = R8P                         !< Default real precision.
! Integer precision definitions:
integer, parameter:: I8P  = selected_int_kind(18) !< Range \([-2^{63},+2^{63} - 1]\), 19 digits plus sign; 64 bits.
integer, parameter:: I4P  = selected_int_kind(9)  !< Range \([-2^{31},+2^{31} - 1]\), 10 digits plus sign; 32 bits.
integer, parameter:: I2P  = selected_int_kind(4)  !< Range \([-2^{15},+2^{15} - 1]\), 5  digits plus sign; 16 bits.
integer, parameter:: I1P  = selected_int_kind(2)  !< Range \([-2^{7} ,+2^{7}  - 1]\), 3  digits plus sign; 8  bits.
integer, parameter:: I_P  = I4P                   !< Default integer precision.

! Format parameters useful for writing in a well-ascii-format numeric variables.
! Real output formats:
character(10), parameter:: FR16P = '(E42.33E4)' !< Output format for kind=R16P variable.
character(10), parameter:: FR8P  = '(E23.15E3)' !< Output format for kind=R8P variable.
character(9),  parameter:: FR4P  = '(E13.6E2)'  !< Output format for kind=R4P variable.
character(10), parameter:: FR_P  = FR8P         !< Output format for kind=R_P variable.
! Real number of digits of output formats:
integer, parameter:: DR16P = 42   !< Number of digits of output format FR16P.
integer, parameter:: DR8P  = 23   !< Number of digits of output format FR8P.
integer, parameter:: DR4P  = 13   !< Number of digits of output format FR4P.
integer, parameter:: DR_P  = DR8P !< Number of digits of output format FR_P.
! Integer output formats:
character(5), parameter:: FI8P   = '(I20)'    !< Output format                     for kind=I8P variable.
character(8), parameter:: FI8PZP = '(I20.19)' !< Output format with zero prefixing for kind=I8P variable.
character(5), parameter:: FI4P   = '(I11)'    !< Output format                     for kind=I4P variable.
character(8), parameter:: FI4PZP = '(I11.10)' !< Output format with zero prefixing for kind=I4P variable.
character(4), parameter:: FI2P   = '(I6)'     !< Output format                     for kind=I2P variable.
character(6), parameter:: FI2PZP = '(I6.5)'   !< Output format with zero prefixing for kind=I2P variable.
character(4), parameter:: FI1P   = '(I4)'     !< Output format                     for kind=I1P variable.
character(6), parameter:: FI1PZP = '(I4.3)'   !< Output format with zero prefixing for kind=I1P variable.
character(5), parameter:: FI_P   = FI4P       !< Output format                     for kind=I_P variable.
character(8), parameter:: FI_PZP = FI4PZP     !< Output format with zero prefixing for kind=I_P variable.
! Integer number of digits of output formats:
integer, parameter:: DI8P = 20   !< Number of digits of output format I8P.
integer, parameter:: DI4P = 11   !< Number of digits of output format I4P.
integer, parameter:: DI2P = 6    !< Number of digits of output format I2P.
integer, parameter:: DI1P = 4    !< Number of digits of output format I1P.
integer, parameter:: DI_P = DI4P !< Number of digits of output format I_P.
! List of kinds
integer,       parameter:: NRknd=4                                           !< Number of defined real kinds.
integer,       parameter:: RPl(1:NRknd)=[R16P,R8P,R4P,R_P]                   !< List of defined real kinds.
character(10), parameter:: FRl(1:NRknd)=[FR16P,FR8P,FR4P//' ',FR_P]          !< List of defined real kinds output format.
integer,       parameter:: NIknd=5                                           !< Number of defined integer kinds.
integer,       parameter:: RIl(1:NIknd)=[I8P,I4P,I2P,I1P,I_P]                !< List of defined integer kinds.
character(5),  parameter:: FIl(1:NIknd)=[FI8P,FI4P,FI2P//' ',FI1P//' ',FI_P] !< List of defined integer kinds output format.

! Useful parameters for handling numbers ranges.
! Real min and max values:
real(R16P), parameter:: MinR16P = -huge(1._R16P) !< Minimum value of kind=R16P variable.
real(R16P), parameter:: MaxR16P =  huge(1._R16P) !< Maximum value of kind=R16P variable.
real(R8P),  parameter:: MinR8P  = -huge(1._R8P ) !< Minimum value of kind=R8P variable.
real(R8P),  parameter:: MaxR8P  =  huge(1._R8P ) !< Maximum value of kind=R8P variable.
real(R4P),  parameter:: MinR4P  = -huge(1._R4P ) !< Minimum value of kind=R4P variable.
real(R4P),  parameter:: MaxR4P  =  huge(1._R4P ) !< Maximum value of kind=R4P variable.
real(R_P),  parameter:: MinR_P  = MinR8P         !< Minimum value of kind=R_P variable.
real(R_P),  parameter:: MaxR_P  = MaxR8P         !< Maximum value of kind=R_P variable.
! Real number of bits/bytes
integer(I2P):: BIR16P !< Number of bits of kind=R16P variable.
integer(I1P):: BIR8P  !< Number of bits of kind=R8P variable.
integer(I1P):: BIR4P  !< Number of bits of kind=R4P variable.
integer(I1P):: BIR_P  !< Number of bits of kind=R_P variable.
integer(I2P):: BYR16P !< Number of bytes of kind=R16P variable.
integer(I1P):: BYR8P  !< Number of bytes of kind=R8P variable.
integer(I1P):: BYR4P  !< Number of bytes of kind=R4P variable.
integer(I1P):: BYR_P  !< Number of bytes of kind=R_P variable.
! Real smallest values:
real(R16P), parameter:: smallR16P = tiny(1._R16P) !< Smallest (module) representable value of kind=R16P variable.
real(R8P),  parameter:: smallR8P  = tiny(1._R8P ) !< Smallest (module) representable value of kind=R8P variable.
real(R4P),  parameter:: smallR4P  = tiny(1._R4P ) !< Smallest (module) representable value of kind=R4P variable.
real(R_P),  parameter:: smallR_P  = smallR8P      !< Smallest (module) representable value of kind=R_P variable.
! Integer min and max values:
integer(I8P), parameter:: MinI8P = -huge(1_I8P) !< Minimum value of kind=I8P variable.
integer(I4P), parameter:: MinI4P = -huge(1_I4P) !< Minimum value of kind=I4P variable.
integer(I2P), parameter:: MinI2P = -huge(1_I2P) !< Minimum value of kind=I2P variable.
integer(I1P), parameter:: MinI1P = -huge(1_I1P) !< Minimum value of kind=I1P variable.
integer(I_P), parameter:: MinI_P = MinI4P       !< Minimum value of kind=I_P variable.
integer(I8P), parameter:: MaxI8P =  huge(1_I8P) !< Maximum value of kind=I8P variable.
integer(I4P), parameter:: MaxI4P =  huge(1_I4P) !< Maximum value of kind=I4P variable.
integer(I2P), parameter:: MaxI2P =  huge(1_I2P) !< Maximum value of kind=I2P variable.
integer(I1P), parameter:: MaxI1P =  huge(1_I1P) !< Maximum value of kind=I1P variable.
integer(I_P), parameter:: MaxI_P =  MaxI4P      !< Maximum value of kind=I_P variable.
! Integer number of bits/bytes:
integer(I8P), parameter:: BII8P = bit_size(MaxI8P)       !< Number of bits of kind=I8P variable.
integer(I4P), parameter:: BII4P = bit_size(MaxI4P)       !< Number of bits of kind=I4P variable.
integer(I2P), parameter:: BII2P = bit_size(MaxI2P)       !< Number of bits of kind=I2P variable.
integer(I1P), parameter:: BII1P = bit_size(MaxI1P)       !< Number of bits of kind=I1P variable.
integer(I_P), parameter:: BII_P = bit_size(MaxI_P)       !< Number of bits of kind=I_P variable.
integer(I8P), parameter:: BYI8P = bit_size(MaxI8P)/8_I8P !< Number of bytes of kind=I8P variable.
integer(I4P), parameter:: BYI4P = bit_size(MaxI4P)/8_I4P !< Number of bytes of kind=I4P variable.
integer(I2P), parameter:: BYI2P = bit_size(MaxI2P)/8_I2P !< Number of bytes of kind=I2P variable.
integer(I1P), parameter:: BYI1P = bit_size(MaxI1P)/8_I1P !< Number of bytes of kind=I1P variable.
integer(I_P), parameter:: BYI_P = bit_size(MaxI_P)/8_I_P !< Number of bytes of kind=I_P variable.
! Smallest real representable difference by the running calculator.
real(R16P), parameter:: ZeroR16 = nearest(1._R16P, 1._R16P) - &
                                  nearest(1._R16P,-1._R16P) !< Smallest representable difference of kind=R16P variable.
real(R8P),  parameter:: ZeroR8  = nearest(1._R8P, 1._R8P) - &
                                  nearest(1._R8P,-1._R8P)   !< Smallest representable difference of kind=R8P variable.
real(R4P),  parameter:: ZeroR4  = nearest(1._R4P, 1._R4P) - &
                                  nearest(1._R4P,-1._R4P)   !< Smallest representable difference of kind=R4P variable.
real(R_P),  parameter:: Zero    = ZeroR8                    !< Smallest representable difference of kind=R_P variable.
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
interface bit_size
  !< Overloading of the intrinsic *bit_size* function for computing the number of bits of (also) real and character variables.
  module procedure                &
#ifdef r16p
                   bit_size_R16p, &
#endif
                   bit_size_R8P,  &
                   bit_size_R4P,  &
                   bit_size_chr
endinterface
interface byte_size
  !< Overloading of the *byte_size* function for computing the number of bytes.
  module procedure                 &
                   byte_size_I8P,  &
                   byte_size_I4P,  &
                   byte_size_I2P,  &
                   byte_size_I1P,  &
#ifdef r16p
                   byte_size_R16p, &
#endif
                   byte_size_R8P,  &
                   byte_size_R4P,  &
                   byte_size_chr
endinterface
interface str
  !< Procedure for converting number, real and integer, to string (number to string type casting).
  module procedure                    &
#ifdef r16p
                   strf_R16P,str_R16P,&
#endif
                   strf_R8P ,str_R8P, &
                   strf_R4P ,str_R4P, &
                   strf_I8P ,str_I8P, &
                   strf_I4P ,str_I4P, &
                   strf_I2P ,str_I2P, &
                   strf_I1P ,str_I1P, &
                             str_bol, &
#ifdef r16p
                             str_a_R16P,&
#endif
                             str_a_R8P, &
                             str_a_R4P, &
                             str_a_I8P, &
                             str_a_I4P, &
                             str_a_I2P, &
                             str_a_I1P
endinterface
interface strz
  !< Procedure for converting number, integer, to string, prefixing with the right number of zeros (number to string type
  !< casting with zero padding).
  module procedure strz_I8P,  &
                   strz_I4P,  &
                   strz_I2P,  &
                   strz_I1P
endinterface
interface cton
  !< Procedure for converting string to number, real or initeger, (string to number type casting).
  module procedure            &
#ifdef r16p
                   ctor_R16P, &
#endif
                   ctor_R8P,  &
                   ctor_R4P,  &
                   ctoi_I8P,  &
                   ctoi_I4P,  &
                   ctoi_I2P,  &
                   ctoi_I1P
endinterface
interface bstr
  !< Procedure for converting number, real and integer, to bit-string (number to bit-string type casting).
  module procedure           &
#ifdef r16p
                   bstr_R16P,&
#endif
                   bstr_R8P, &
                   bstr_R4P, &
                   bstr_I8P, &
                   bstr_I4P, &
                   bstr_I2P, &
                   bstr_I1P
endinterface
interface bcton
  !< Procedure for converting bit-string to number, real or initeger, (bit-string to number type casting).
  module procedure            &
#ifdef r16p
                   bctor_R16P, &
#endif
                   bctor_R8P,  &
                   bctor_R4P,  &
                   bctoi_I8P,  &
                   bctoi_I4P,  &
                   bctoi_I2P,  &
                   bctoi_I1P
endinterface
interface digit
  !< Procedure for computing the number of digits in decimal base of the input integer.
  module procedure digit_I8,digit_I4,digit_I2,digit_I1
endinterface
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  pure function is_little_endian() result(is_little)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for checking if the type of the bit ordering of the running architecture is little endian.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical::      is_little !< Logical output: true is the running architecture uses little endian ordering, false otherwise.
  integer(I1P):: int1(1:4) !< One byte integer array for casting 4 bytes integer.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  int1 = transfer(1_I4P,int1)
  is_little = (int1(1)==1_I1P)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction is_little_endian

  subroutine check_endian()
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Subroutine for checking the type of bit ordering (big or little endian) of the running architecture.
  !<
  !> @note The result is stored into the *endian* global variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (is_little_endian()) then
    endian = endianL
  else
    endian = endianB
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine check_endian

  elemental function bit_size_R16P(r) result(bits)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of bits of a real variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R16P), intent(IN):: r       !< Real variable whose number of bits must be computed.
  integer(I2P)::           bits    !< Number of bits of r.
  integer(I1P)::           mold(1) !< "Molding" dummy variable for bits counting.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  bits = size(transfer(r,mold),dim=1,kind=I2P)*8_I2P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bit_size_R16P

  elemental function bit_size_R8P(r) result(bits)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of bits of a real variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R8P), intent(IN):: r       !< Real variable whose number of bits must be computed.
  integer(I1P)::          bits    !< Number of bits of r.
  integer(I1P)::          mold(1) !< "Molding" dummy variable for bits counting.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  bits = size(transfer(r,mold),dim=1,kind=I1P)*8_I1P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bit_size_R8P

  elemental function bit_size_R4P(r) result(bits)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of bits of a real variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R4P), intent(IN):: r       !< Real variable whose number of bits must be computed.
  integer(I1P)::          bits    !< Number of bits of r.
  integer(I1P)::          mold(1) !< "Molding" dummy variable for bits counting.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  bits = size(transfer(r,mold),dim=1,kind=I1P)*8_I1P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bit_size_R4P

  elemental function bit_size_chr(c) result(bits)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of bits of a character variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: c       !< Character variable whose number of bits must be computed.
  integer(I4P)::             bits    !< Number of bits of c.
  integer(I1P)::             mold(1) !< "Molding" dummy variable for bits counting.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  bits = size(transfer(c,mold),dim=1,kind=I4P)*8_I4P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bit_size_chr

  elemental function byte_size_I8P(i) result(bytes)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of bytes of an integer variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I8P), intent(IN):: i     !< Integer variable whose number of bytes must be computed.
  integer(I1P)::             bytes !< Number of bytes of i.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  bytes = bit_size(i)/8_I1P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction byte_size_I8P

  elemental function byte_size_I4P(i) result(bytes)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of bytes of an integer variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P), intent(IN):: i     !< Integer variable whose number of bytes must be computed.
  integer(I1P)::             bytes !< Number of bytes of i.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  bytes = bit_size(i)/8_I1P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction byte_size_I4P

  elemental function byte_size_I2P(i) result(bytes)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of bytes of an integer variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I2P), intent(IN):: i     !< Integer variable whose number of bytes must be computed.
  integer(I1P)::             bytes !< Number of bytes of i.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  bytes = bit_size(i)/8_I1P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction byte_size_I2P

  elemental function byte_size_I1P(i) result(bytes)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of bytes of an integer variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I1P), intent(IN):: i     !< Integer variable whose number of bytes must be computed.
  integer(I1P)::             bytes !< Number of bytes of i.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  bytes = bit_size(i)/8_I1P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction byte_size_I1P

  elemental function byte_size_R16P(r) result(bytes)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of bytes of a real variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R16P), intent(IN):: r     !< Real variable whose number of bytes must be computed.
  integer(I1P)::           bytes !< Number of bytes of r.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  bytes = bit_size(r)/8_I1P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction byte_size_R16P

  elemental function byte_size_R8P(r) result(bytes)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of bytes of a real variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R8P), intent(IN):: r     !< Real variable whose number of bytes must be computed.
  integer(I1P)::          bytes !< Number of bytes of r.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  bytes = bit_size(r)/8_I1P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction byte_size_R8P

  elemental function byte_size_R4P(r) result(bytes)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of bytes of a real variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R4P), intent(IN):: r     !< Real variable whose number of bytes must be computed.
  integer(I1P)::          bytes !< Number of bytes of r.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  bytes = bit_size(r)/8_I1P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction byte_size_R4P

  elemental function byte_size_chr(c) result(bytes)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of bytes of a character variable.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: c     !< Character variable whose number of bytes must be computed.
  integer(I4P)::             bytes !< Number of bytes of c.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  bytes = bit_size(c)/8_I4P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction byte_size_chr

  elemental function strf_R16P(fm,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting real to string. This function achieves casting of real to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: fm  !< Format different from the standard for the kind.
  real(R16P),   intent(IN):: n   !< Real to be converted.
  character(DR16P)::         str !< Returned string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,trim(fm)) n ! Casting of n to string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction strf_R16P

  elemental function strf_R8P(fm,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting real to string. This function achieves casting of real to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: fm  !< Format different from the standard for the kind.
  real(R8P),    intent(IN):: n   !< Real to be converted.
  character(DR8P)::          str !< Returned string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,trim(fm)) n ! Casting of n to string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction strf_R8P

  elemental function strf_R4P(fm,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting real to string. This function achieves casting of real to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: fm  !< Format different from the standard for the kind.
  real(R4P),    intent(IN):: n   !< Real to be converted.
  character(DR4P)::          str !< Returned string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,trim(fm)) n ! Casting of n to string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction strf_R4P

  elemental function strf_I8P(fm,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string. This function achieves casting of integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: fm  !< Format different from the standard for the kind.
  integer(I8P), intent(IN):: n   !< Integer to be converted.
  character(DI8P)::          str !< Returned string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,trim(fm)) n ! Casting of n to string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction strf_I8P

  elemental function strf_I4P(fm,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string. This function achieves casting of integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: fm  !< Format different from the standard for the kind.
  integer(I4P), intent(IN):: n   !< Integer to be converted.
  character(DI4P)::          str !< Returned string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,trim(fm)) n ! Casting of n to string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction strf_I4P

  elemental function strf_I2P(fm,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string. This function achieves casting of integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: fm  !< Format different from the standard for the kind.
  integer(I2P), intent(IN):: n   !< Integer to be converted.
  character(DI2P)::          str !< Returned string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,trim(fm)) n ! Casting of n to string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction strf_I2P

  elemental function strf_I1P(fm,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string. This function achieves casting of integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: fm  !< Format different from the standard for the kind.
  integer(I1P), intent(IN):: n   !< Integer to be converted.
  character(DI1P)::          str !< Returned string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,trim(fm)) n ! Casting of n to string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction strf_I1P

  elemental function str_R16P(no_sign,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting real to string. This function achieves casting of real to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,    intent(IN), optional:: no_sign !< Flag for leaving out the sign.
  real(R16P), intent(IN)::           n       !< Real to be converted.
  character(DR16P)::                 str     !< Returned string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FR16P) n                ! Casting of n to string.
  if (n>0._R16P) str(1:1)='+'       ! Prefixing plus if n>0.
  if (present(no_sign)) str=str(2:) ! Leaving out the sign.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_R16P

  elemental function str_R8P(no_sign,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting real to string. This function achieves casting of real to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,      intent(IN), optional:: no_sign !< Flag for leaving out the sign.
  real(R8P),    intent(IN)::           n       !< Real to be converted.
  character(DR8P)::                    str     !< Returned string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FR8P) n                 ! Casting of n to string.
  if (n>0._R8P) str(1:1)='+'        ! Prefixing plus if n>0.
  if (present(no_sign)) str=str(2:) ! Leaving out the sign.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_R8P

  elemental function str_R4P(no_sign,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting real to string. This function achieves casting of real to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,   intent(IN), optional:: no_sign !< Flag for leaving out the sign.
  real(R4P), intent(IN)::           n       !< Real to be converted.
  character(DR4P)::                 str     !< Returned string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FR4P) n                 ! Casting of n to string.
  if (n>0._R4P) str(1:1)='+'        ! Prefixing plus if n>0.
  if (present(no_sign)) str=str(2:) ! Leaving out the sign.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_R4P

  elemental function str_I8P(no_sign,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string. This function achieves casting of integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,      intent(IN), optional:: no_sign !< Flag for leaving out the sign.
  integer(I8P), intent(IN)::           n       !< Integer to be converted.
  character(DI8P)::                    str     !< Returned string containing input number plus padding zeros.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FI8P) n                 ! Casting of n to string.
  str = adjustl(trim(str))          ! Removing white spaces.
  if (n>=0_I8P) str='+'//trim(str)  ! Prefixing plus if n>0.
  if (present(no_sign)) str=str(2:) ! Leaving out the sign.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_I8P

  elemental function str_I4P(no_sign,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string. This function achieves casting of integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,      intent(IN), optional:: no_sign !< Flag for leaving out the sign.
  integer(I4P), intent(IN)::           n       !< Integer to be converted.
  character(DI4P)::                    str     !< Returned string containing input number plus padding zeros.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FI4P) n                 ! Casting of n to string.
  str = adjustl(trim(str))          ! Removing white spaces.
  if (n>=0_I4P) str='+'//trim(str)  ! Prefixing plus if n>0.
  if (present(no_sign)) str=str(2:) ! Leaving out the sign.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_I4P

  elemental function str_I2P(no_sign,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string. This function achieves casting of integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,      intent(IN), optional:: no_sign !< Flag for leaving out the sign.
  integer(I2P), intent(IN)::           n       !< Integer to be converted.
  character(DI2P)::                    str     !< Returned string containing input number plus padding zeros.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FI2P) n                 ! Casting of n to string.
  str = adjustl(trim(str))          ! Removing white spaces.
  if (n>=0_I2P) str='+'//trim(str)  ! Prefixing plus if n>0.
  if (present(no_sign)) str=str(2:) ! Leaving out the sign.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_I2P

  elemental function str_I1P(no_sign,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string. This function achieves casting of integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,      intent(IN), optional:: no_sign !< Flag for leaving out the sign.
  integer(I1P), intent(IN)::           n       !< Integer to be converted.
  character(DI1P)::                    str     !< Returned string containing input number plus padding zeros.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FI1P) n                 ! Casting of n to string.
  str = adjustl(trim(str))          ! Removing white spaces.
  if (n>=0_I1P) str='+'//trim(str)  ! Prefixing plus if n>0.
  if (present(no_sign)) str=str(2:) ! Leaving out the sign.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_I1P

  elemental function str_bol(n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting logical to string. This function achieves casting of logical to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical, intent(IN):: n   !< Logical to be converted.
  character(1)::        str !< Returned string containing input number plus padding zeros.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,'(L1)') n
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_bol

  pure function str_a_R16P(no_sign,delimiters,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting real (array) to string. This function achieves casting of real to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,      intent(IN), optional:: no_sign         !< Flag for leaving out the sign.
  character(*), intent(IN), optional:: delimiters(1:2) !< Eventual delimiters of array values.
  real(R16P),   intent(IN)::           n(:)            !< Real array to be converted.
  character(len=:), allocatable::      str             !< Returned string containing input number.
  character(DR16P)::                   strn            !< String containing of element of input array number.
  integer::                            i               !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(no_sign)) then
    str = ''
    do i=1,size(n)
      strn = str_R16P(no_sign=no_sign, n=n(i))
      str = str//','//trim(strn)
    enddo
  else
    str = ''
    do i=1,size(n)
      strn = str_R16P(n=n(i))
      str = str//','//trim(strn)
    enddo
  endif
  str = trim(str(2:))
  if (present(delimiters)) str = delimiters(1)//str//delimiters(2)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_a_R16P

  pure function str_a_R8P(no_sign,delimiters,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting real (array) to string. This function achieves casting of real to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,      intent(IN), optional:: no_sign         !< Flag for leaving out the sign.
  character(*), intent(IN), optional:: delimiters(1:2) !< Eventual delimiters of array values.
  real(R8P),    intent(IN)::           n(:)            !< Real array to be converted.
  character(len=:), allocatable::      str             !< Returned string containing input number.
  character(DR8P)::                    strn            !< String containing of element of input array number.
  integer::                            i               !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(no_sign)) then
    str = ''
    do i=1,size(n)
      strn = str_R8P(no_sign=no_sign, n=n(i))
      str = str//','//trim(strn)
    enddo
  else
    str = ''
    do i=1,size(n)
      strn = str_R8P(n=n(i))
      str = str//','//trim(strn)
    enddo
  endif
  str = trim(str(2:))
  if (present(delimiters)) str = delimiters(1)//str//delimiters(2)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_a_R8P

  pure function str_a_R4P(no_sign,delimiters,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting real (array) to string. This function achieves casting of real to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,      intent(IN), optional:: no_sign         !< Flag for leaving out the sign.
  character(*), intent(IN), optional:: delimiters(1:2) !< Eventual delimiters of array values.
  real(R4P),    intent(IN)::           n(:)            !< Real array to be converted.
  character(len=:), allocatable::      str             !< Returned string containing input number.
  character(DR4P)::                    strn            !< String containing of element of input array number.
  integer::                            i               !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(no_sign)) then
    str = ''
    do i=1,size(n)
      strn = str_R4P(no_sign=no_sign, n=n(i))
      str = str//','//trim(strn)
    enddo
  else
    str = ''
    do i=1,size(n)
      strn = str_R4P(n=n(i))
      str = str//','//trim(strn)
    enddo
  endif
  str = trim(str(2:))
  if (present(delimiters)) str = delimiters(1)//str//delimiters(2)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_a_R4P

  pure function str_a_I8P(no_sign,delimiters,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer (array) to string. This function achieves casting of integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,      intent(IN), optional:: no_sign         !< Flag for leaving out the sign.
  character(*), intent(IN), optional:: delimiters(1:2) !< Eventual delimiters of array values.
  integer(I8P), intent(IN)::           n(:)            !< Integer array to be converted.
  character(len=:), allocatable::      str             !< Returned string containing input number.
  character(DI8P)::                    strn            !< String containing of element of input array number.
  integer::                            i               !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(no_sign)) then
    str = ''
    do i=1,size(n)
      strn = str_I8P(no_sign=no_sign, n=n(i))
      str = str//','//trim(strn)
    enddo
  else
    str = ''
    do i=1,size(n)
      strn = str_I8P(n=n(i))
      str = str//','//trim(strn)
    enddo
  endif
  str = trim(str(2:))
  if (present(delimiters)) str = delimiters(1)//str//delimiters(2)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_a_I8P

  pure function str_a_I4P(no_sign,delimiters,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer (array) to string. This function achieves casting of integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,      intent(IN), optional:: no_sign         !< Flag for leaving out the sign.
  character(*), intent(IN), optional:: delimiters(1:2) !< Eventual delimiters of array values.
  integer(I4P), intent(IN)::           n(:)            !< Integer array to be converted.
  character(len=:), allocatable::      str             !< Returned string containing input number.
  character(DI4P)::                    strn            !< String containing of element of input array number.
  integer::                            i               !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(no_sign)) then
    str = ''
    do i=1,size(n)
      strn = str_I4P(no_sign=no_sign, n=n(i))
      str = str//','//trim(strn)
    enddo
  else
    str = ''
    do i=1,size(n)
      strn = str_I4P(n=n(i))
      str = str//','//trim(strn)
    enddo
  endif
  str = trim(str(2:))
  if (present(delimiters)) str = delimiters(1)//str//delimiters(2)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_a_I4P

  pure function str_a_I2P(no_sign,delimiters,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer (array) to string. This function achieves casting of integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,      intent(IN), optional:: no_sign         !< Flag for leaving out the sign.
  character(*), intent(IN), optional:: delimiters(1:2) !< Eventual delimiters of array values.
  integer(I2P), intent(IN)::           n(:)            !< Integer array to be converted.
  character(len=:), allocatable::      str             !< Returned string containing input number.
  character(DI2P)::                    strn            !< String containing of element of input array number.
  integer::                            i               !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(no_sign)) then
    str = ''
    do i=1,size(n)
      strn = str_I2P(no_sign=no_sign, n=n(i))
      str = str//','//trim(strn)
    enddo
  else
    str = ''
    do i=1,size(n)
      strn = str_I2P(n=n(i))
      str = str//','//trim(strn)
    enddo
  endif
  str = trim(str(2:))
  if (present(delimiters)) str = delimiters(1)//str//delimiters(2)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_a_I2P

  pure function str_a_I1P(no_sign,delimiters,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer (array) to string. This function achieves casting of integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  logical,      intent(IN), optional:: no_sign         !< Flag for leaving out the sign.
  character(*), intent(IN), optional:: delimiters(1:2) !< Eventual delimiters of array values.
  integer(I1P), intent(IN)::           n(:)            !< Integer array to be converted.
  character(len=:), allocatable::      str             !< Returned string containing input number.
  character(DI1P)::                    strn            !< String containing of element of input array number.
  integer::                            i               !< Counter.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (present(no_sign)) then
    str = ''
    do i=1,size(n)
      strn = str_I1P(no_sign=no_sign, n=n(i))
      str = str//','//trim(strn)
    enddo
  else
    str = ''
    do i=1,size(n)
      strn = str_I1P(n=n(i))
      str = str//','//trim(strn)
    enddo
  endif
  str = trim(str(2:))
  if (present(delimiters)) str = delimiters(1)//str//delimiters(2)
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction str_a_I1P

  elemental function strz_I8P(nz_pad,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string, prefixing with the right number of zeros. This function achieves casting of
  !< integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P), intent(IN), optional:: nz_pad !< Number of zeros padding.
  integer(I8P), intent(IN)::           n      !< Integer to be converted.
  character(DI8P)::                    str    !< Returned string containing input number plus padding zeros.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FI8PZP) n                              ! Casting of n to string.
  str=str(2:)                                      ! Leaving out the sign.
  if (present(nz_pad)) str=str(DI8P-nz_pad:DI8P-1) ! Leaving out the extra zeros padding
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction strz_I8P

  elemental function strz_I4P(nz_pad,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string, prefixing with the right number of zeros. This function achieves casting of
  !< integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P), intent(IN), optional:: nz_pad !< Number of zeros padding.
  integer(I4P), intent(IN)::           n      !< Integer to be converted.
  character(DI4P)::                    str    !< Returned string containing input number plus padding zeros.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FI4PZP) n                              ! Casting of n to string.
  str=str(2:)                                      ! Leaving out the sign.
  if (present(nz_pad)) str=str(DI4P-nz_pad:DI4P-1) ! Leaving out the extra zeros padding
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction strz_I4P

  elemental function strz_I2P(nz_pad,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string, prefixing with the right number of zeros. This function achieves casting of
  !< integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P), intent(IN), optional:: nz_pad !< Number of zeros padding.
  integer(I2P), intent(IN)::           n      !< Integer to be converted.
  character(DI2P)::                    str    !< Returned string containing input number plus padding zeros.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FI2PZP) n                              ! Casting of n to string.
  str=str(2:)                                      ! Leaving out the sign.
  if (present(nz_pad)) str=str(DI2P-nz_pad:DI2P-1) ! Leaving out the extra zeros padding
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction strz_I2P

  elemental function strz_I1P(nz_pad,n) result(str)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string, prefixing with the right number of zeros. This function achieves casting of
  !< integer to string.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P), intent(IN), optional:: nz_pad !< Number of zeros padding.
  integer(I1P), intent(IN)::           n      !< Integer to be converted.
  character(DI1P)::                    str    !< Returned string containing input number plus padding zeros.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FI1PZP) n                              ! Casting of n to string.
  str=str(2:)                                      ! Leaving out the sign.
  if (present(nz_pad)) str=str(DI1P-nz_pad:DI1P-1) ! Leaving out the extra zeros padding
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction strz_I1P

  function ctor_R16P(pref,error,str,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting string to real. This function achieves casting of string to real.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN)::  pref  !< Prefixing string.
  integer(I4P), optional, intent(OUT):: error !< Error trapping flag: 0 no errors, >0 error occurs.
  character(*),           intent(IN)::  str   !< String containing input number.
  real(R16P),             intent(IN)::  knd   !< Number kind.
  real(R16P)::                          n     !< Number returned.
  integer(I4P)::                        err   !< Error trapping flag: 0 no errors, >0 error occurs.
  character(len=:), allocatable::       prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(str,*,iostat=err) n ! Casting of str to n.
  if (err/=0) then
    prefd = '' ; if (present(pref)) prefd = pref
    write(stderr,'(A,I1,A)') prefd//' Error: conversion of string "'//str//'" to real failed! real(',kind(knd),')'
  endif
  if (present(error)) error = err
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ctor_R16P

  function ctor_R8P(pref,error,str,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting string to real. This function achieves casting of string to real.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN)::  pref  !< Prefixing string.
  integer(I4P), optional, intent(OUT):: error !< Error trapping flag: 0 no errors, >0 error occurs.
  character(*),           intent(IN)::  str   !< String containing input number.
  real(R8P),              intent(IN)::  knd   !< Number kind.
  real(R8P)::                           n     !< Number returned.
  integer(I4P)::                        err   !< Error trapping flag: 0 no errors, >0 error occurs.
  character(len=:), allocatable::       prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(str,*,iostat=err) n ! Casting of str to n.
  if (err/=0) then
    prefd = '' ; if (present(pref)) prefd = pref
    write(stderr,'(A,I1,A)') prefd//' Error: conversion of string "'//str//'" to real failed! real(',kind(knd),')'
  endif
  if (present(error)) error = err
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ctor_R8P

  function ctor_R4P(pref,error,str,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting string to real. This function achieves casting of string to real.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN)::  pref  !< Prefixing string.
  integer(I4P), optional, intent(OUT):: error !< Error trapping flag: 0 no errors, >0 error occurs.
  character(*),           intent(IN)::  str   !< String containing input number.
  real(R4P),              intent(IN)::  knd   !< Number kind.
  real(R4P)::                           n     !< Number returned.
  integer(I4P)::                        err   !< Error trapping flag: 0 no errors, >0 error occurs.
  character(len=:), allocatable::       prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(str,*,iostat=err) n ! Casting of str to n.
  if (err/=0) then
    prefd = '' ; if (present(pref)) prefd = pref
    write(stderr,'(A,I1,A)') prefd//' Error: conversion of string "'//str//'" to real failed! real(',kind(knd),')'
  endif
  if (present(error)) error = err
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ctor_R4P

  function ctoi_I8P(pref,error,str,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting string to integer. This function achieves casting of string to integer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN)::  pref  !< Prefixing string.
  integer(I4P), optional, intent(OUT):: error !< Error trapping flag: 0 no errors, >0 error occurs.
  character(*),           intent(IN)::  str   !< String containing input number.
  integer(I8P),           intent(IN)::  knd   !< Number kind.
  integer(I8P)::                        n     !< Number returned.
  integer(I4P)::                        err   !< Error trapping flag: 0 no errors, >0 error occurs.
  character(len=:), allocatable::       prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(str,*,iostat=err) n ! Casting of str to n.
  if (err/=0) then
    prefd = '' ; if (present(pref)) prefd = pref
    write(stderr,'(A,I1,A)') prefd//' Error: conversion of string "'//str//'" to integer failed! integer(',kind(knd),')'
  endif
  if (present(error)) error = err
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ctoi_I8P

  function ctoi_I4P(pref,error,str,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting string to integer. This function achieves casting of string to integer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN)::  pref  !< Prefixing string.
  integer(I4P), optional, intent(OUT):: error !< Error trapping flag: 0 no errors, >0 error occurs.
  character(*),           intent(IN)::  str   !< String containing input number.
  integer(I4P),           intent(IN)::  knd   !< Number kind.
  integer(I4P)::                        n     !< Number returned.
  integer(I4P)::                        err   !< Error trapping flag: 0 no errors, >0 error occurs.
  character(len=:), allocatable::       prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(str,*,iostat=err) n ! Casting of str to n.
  if (err/=0) then
    prefd = '' ; if (present(pref)) prefd = pref
    write(stderr,'(A,I1,A)') prefd//' Error: conversion of string "'//str//'" to integer failed! integer(',kind(knd),')'
  endif
  if (present(error)) error = err
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ctoi_I4P

  function ctoi_I2P(pref,error,str,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting string to integer. This function achieves casting of string to integer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN)::  pref  !< Prefixing string.
  integer(I4P), optional, intent(OUT):: error !< Error trapping flag: 0 no errors, >0 error occurs.
  character(*),           intent(IN)::  str   !< String containing input number.
  integer(I2P),           intent(IN)::  knd   !< Number kind.
  integer(I2P)::                        n     !< Number returned.
  integer(I4P)::                        err   !< Error trapping flag: 0 no errors, >0 error occurs.
  character(len=:), allocatable::       prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(str,*,iostat=err) n ! Casting of str to n.
  if (err/=0) then
    prefd = '' ; if (present(pref)) prefd = pref
    write(stderr,'(A,I1,A)') prefd//' Error: conversion of string "'//str//'" to integer failed! integer(',kind(knd),')'
  endif
  if (present(error)) error = err
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ctoi_I2P

  function ctoi_I1P(pref,error,str,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting string to integer. This function achieves casting of string to integer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN)::  pref  !< Prefixing string.
  integer(I4P), optional, intent(OUT):: error !< Error trapping flag: 0 no errors, >0 error occurs.
  character(*),           intent(IN)::  str   !< String containing input number.
  integer(I1P),           intent(IN)::  knd   !< Number kind.
  integer(I1P)::                        n     !< Number returned.
  integer(I4P)::                        err   !< Error trapping flag: 0 no errors, >0 error occurs.
  character(len=:), allocatable::       prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(str,*,iostat=err) n ! Casting of str to n.
  if (err/=0) then
    prefd = '' ; if (present(pref)) prefd = pref
    write(stderr,'(A,I1,A)') prefd//' Error: conversion of string "'//str//'" to integer failed! integer(',kind(knd),')'
  endif
  if (present(error)) error = err
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction ctoi_I1P

  elemental function bstr_R16P(n) result(bstr)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting real to string of bits. This function achieves casting of real to bit-string.
  !<
  !< @note It is assumed that R16P is represented by means of 128 bits, but this is not ensured in all architectures.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R8P), intent(IN):: n    !< Real to be converted.
  character(128)::        bstr !< Returned bit-string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(bstr,'(B128.128)')n ! Casting of n to bit-string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bstr_R16P

  elemental function bstr_R8P(n) result(bstr)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting real to string of bits. This function achieves casting of real to bit-string.
  !<
  !< @note It is assumed that R8P is represented by means of 64 bits, but this is not ensured in all architectures.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R8P), intent(IN):: n    !< Real to be converted.
  character(64)::         bstr !< Returned bit-string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(bstr,'(B64.64)')n ! Casting of n to bit-string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bstr_R8P

  elemental function bstr_R4P(n) result(bstr)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting real to string of bits. This function achieves casting of real to bit-string.
  !<
  !< @note It is assumed that R4P is represented by means of 32 bits, but this is not ensured in all architectures.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  real(R4P), intent(IN):: n    !< Real to be converted.
  character(32)::         bstr !< Returned bit-string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(bstr,'(B32.32)')n ! Casting of n to bit-string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bstr_R4P

  elemental function bstr_I8P(n) result(bstr)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string of bits. This function achieves casting of integer to bit-string.
  !<
  !< @note It is assumed that I8P is represented by means of 64 bits, but this is not ensured in all architectures.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I8P), intent(IN):: n    !< Real to be converted.
  character(64)::            bstr !< Returned bit-string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(bstr,'(B64.64)')n ! Casting of n to bit-string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bstr_I8P

  elemental function bstr_I4P(n) result(bstr)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string of bits. This function achieves casting of integer to bit-string.
  !<
  !< @note It is assumed that I4P is represented by means of 32 bits, but this is not ensured in all architectures.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P), intent(IN):: n    !< Real to be converted.
  character(32)::            bstr !< Returned bit-string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(bstr,'(B32.32)')n ! Casting of n to bit-string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bstr_I4P

  elemental function bstr_I2P(n) result(bstr)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string of bits. This function achieves casting of integer to bit-string.
  !<
  !< @note It is assumed that I2P is represented by means of 16 bits, but this is not ensured in all architectures.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I2P), intent(IN):: n    !< Real to be converted.
  character(16)::            bstr !< Returned bit-string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(bstr,'(B16.16)')n ! Casting of n to bit-string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bstr_I2P

  elemental function bstr_I1P(n) result(bstr)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting integer to string of bits. This function achieves casting of integer to bit-string.
  !<
  !< @note It is assumed that I1P is represented by means of 8 bits, but this is not ensured in all architectures.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I1P), intent(IN):: n    !< Real to be converted.
  character(8)::             bstr !< Returned bit-string containing input number.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(bstr,'(B8.8)')n ! Casting of n to bit-string.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bstr_I1P

  elemental function bctor_R8P(bstr,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting bit-string to real. This function achieves casting of bit-string to real.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: bstr !< String containing input number.
  real(R8P),    intent(IN):: knd  !< Number kind.
  real(R8P)::                n    !< Number returned.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(bstr,'(B'//trim(str(.true.,bit_size(knd)))//'.'//trim(str(.true.,bit_size(knd)))//')')n ! Casting of bstr to n.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bctor_R8P

  elemental function bctor_R4P(bstr,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting bit-string to real. This function achieves casting of bit-string to real.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: bstr !< String containing input number.
  real(R4P),    intent(IN):: knd  !< Number kind.
  real(R4P)::                n    !< Number returned.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(bstr,'(B'//trim(str(.true.,bit_size(knd)))//'.'//trim(str(.true.,bit_size(knd)))//')')n ! Casting of bstr to n.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bctor_R4P

  elemental function bctoi_I8P(bstr,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting bit-string to integer. This function achieves casting of bit-string to integer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: bstr !< String containing input number.
  integer(I8P), intent(IN):: knd  !< Number kind.
  integer(I8P)::             n    !< Number returned.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(bstr,'(B'//trim(str(.true.,bit_size(knd)))//'.'//trim(str(.true.,bit_size(knd)))//')')n ! Casting of bstr to n.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bctoi_I8P

  elemental function bctoi_I4P(bstr,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting bit-string to integer. This function achieves casting of bit-string to integer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: bstr !< String containing input number.
  integer(I4P), intent(IN):: knd  !< Number kind.
  integer(I4P)::             n    !< Number returned.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(bstr,'(B'//trim(str(.true.,bit_size(knd)))//'.'//trim(str(.true.,bit_size(knd)))//')')n ! Casting of bstr to n.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bctoi_I4P

  elemental function bctoi_I2P(bstr,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting bit-string to integer. This function achieves casting of bit-string to integer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: bstr !< String containing input number.
  integer(I2P), intent(IN):: knd  !< Number kind.
  integer(I2P)::             n    !< Number returned.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(bstr,'(B'//trim(str(.true.,bit_size(knd)))//'.'//trim(str(.true.,bit_size(knd)))//')')n ! Casting of bstr to n.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bctoi_I2P

  elemental function bctoi_I1P(bstr,knd) result(n)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for converting bit-string to integer. This function achieves casting of bit-string to integer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), intent(IN):: bstr !< String containing input number.
  integer(I1P), intent(IN):: knd  !< Number kind.
  integer(I1P)::             n    !< Number returned.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  read(bstr,'(B'//trim(str(.true.,bit_size(knd)))//'.'//trim(str(.true.,bit_size(knd)))//')')n ! Casting of bstr to n.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction bctoi_I1P

  elemental function digit_I8(n) result(digit)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of digits in decimal base of the input integer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I8P), intent(IN):: n     !< Input integer.
  character(DI8P)::          str   !< Returned string containing input number plus padding zeros.
  integer(I4P)::             digit !< Number of digits.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FI8P) abs(n)         ! Casting of n to string.
  digit = len_trim(adjustl(str)) ! Calculating the digits number of n.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction digit_I8

  elemental function digit_I4(n) result(digit)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of digits in decimal base of the input integer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I4P), intent(IN):: n     !< Input integer.
  character(DI4P)::          str   !< Returned string containing input number plus padding zeros.
  integer(I4P)::             digit !< Number of digits.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FI4P) abs(n)         ! Casting of n to string.
  digit = len_trim(adjustl(str)) ! Calculating the digits number of n.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction digit_I4

  elemental function digit_I2(n) result(digit)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of digits in decimal base of the input integer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I2P), intent(IN):: n     !< Input integer.
  character(DI2P)::          str   !< Returned string containing input number plus padding zeros.
  integer(I4P)::             digit !< Number of digits.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FI2P) abs(n)         ! Casting of n to string.
  digit = len_trim(adjustl(str)) ! Calculating the digits number of n.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction digit_I2

  elemental function digit_I1(n) result(digit)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for computing the number of digits in decimal base of the input integer.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  integer(I1P), intent(IN):: n     !< Input integer.
  character(DI1P)::          str   !< Returned string containing input number plus padding zeros.
  integer(I4P)::             digit !< Number of digits.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(str,FI1P) abs(n)         ! Casting of n to string.
  digit = len_trim(adjustl(str)) ! Calculating the digits number of n.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endfunction digit_I1

  subroutine IR_init()
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for initilizing module's variables that are not initialized into the definition specification.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  ! checking the bit ordering architecture
  call check_endian
  ! computing the bits/bytes sizes of real variables
  BIR8P  = bit_size(r=MaxR8P)  ; BYR8P  = BIR8P/8_I1P
  BIR4P  = bit_size(r=MaxR4P)  ; BYR4P  = BIR4P/8_I1P
  BIR_P  = bit_size(r=MaxR_P)  ; BYR_P  = BIR_P/8_I1P
#ifdef r16p
  BIR16P = bit_size(r=MaxR16P) ; BYR16P = BIR16P/8_I2P
#else
  BIR16P = int(BIR8P,kind=I2P) ; BYR16P = BIR16P/8_I2P
#endif
  ir_initialized = .true.
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine IR_init

  subroutine IR_Print(pref,iostat,iomsg,unit)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Procedure for printing to the standard output the kind definition of reals and integers and the utility variables.
  !---------------------------------------------------------------------------------------------------------------------------------
  implicit none
  character(*), optional, intent(IN)::  pref    !< Prefixing string.
  integer(I4P), optional, intent(OUT):: iostat  !< IO error.
  character(*), optional, intent(OUT):: iomsg   !< IO error message.
  integer(I4P),           intent(IN)::  unit    !< Logic unit.
  character(len=:), allocatable::       prefd   !< Prefixing string.
  integer(I4P)::                        iostatd !< IO error.
  character(500)::                      iomsgd  !< Temporary variable for IO error message.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (.not.ir_initialized) call IR_init
  prefd = '' ; if (present(pref)) prefd = pref
  ! printing informations
  if (endian==endianL) then
    write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)prefd//' This architecture has LITTLE Endian bit ordering'
  else
    write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)prefd//' This architecture has BIG Endian bit ordering'
  endif
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//' Reals kind, format and characters number:'
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   R16P: '//str(n=R16P)//','//FR16P//','//str(n=DR16P)
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   R8P:  '//str(n=R8P )//','//FR8P //','//str(n=DR8P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   R4P:  '//str(n=R4P )//','//FR4P //','//str(n=DR4P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//' Integers kind, format and characters number:'
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   I8P:  '//str(n=I8P )//','//FI8P //','//str(n=DI8P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   I4P:  '//str(n=I4P )//','//FI4P //','//str(n=DI4P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   I2P:  '//str(n=I2P )//','//FI2P //','//str(n=DI2P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   I1P:  '//str(n=I1P )//','//FI1P //','//str(n=DI1P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//' Reals minimum and maximum values:'
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   R16P: '//str(n=MinR16P)//','//str(n=MaxR16P)
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   R8P:  '//str(n=MinR8P )//','//str(n=MaxR8P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   R4P:  '//str(n=MinR4P )//','//str(n=MaxR4P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//' Integergs minimum and maximum values:'
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   I8P:  '//str(n=MinI8P )//','//str(n=MaxI8P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   I4P:  '//str(n=MinI4P )//','//str(n=MaxI4P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   I2P:  '//str(n=MinI2P )//','//str(n=MaxI2P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   I1P:  '//str(n=MinI1P )//','//str(n=MaxI1P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//' Reals bits/bytes sizes:'
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   R16P: '//str(n=BIR16P)//'/'//str(n=BYR16P)
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   R8P:  '//str(n=BIR8P )//'/'//str(n=BYR8P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   R4P:  '//str(n=BIR4P )//'/'//str(n=BYR4P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//' Integers bits/bytes sizes:'
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   I8P:  '//str(n=BII8P )//'/'//str(n=BYI8P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   I4P:  '//str(n=BII4P )//'/'//str(n=BYI4P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   I2P:  '//str(n=BII2P )//'/'//str(n=BYI2P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   I1P:  '//str(n=BII1P )//'/'//str(n=BYI1P )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//' Machine precisions'
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   ZeroR16: '//str(.true.,ZeroR16)
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   ZeroR8:  '//str(.true.,ZeroR8 )
  write(unit=unit,fmt='(A)',iostat=iostatd,iomsg=iomsgd)  prefd//'   ZeroR4:  '//str(.true.,ZeroR4 )
  if (present(iostat)) iostat = iostatd
  if (present(iomsg))  iomsg  = iomsgd
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine IR_Print
endmodule IR_Precision

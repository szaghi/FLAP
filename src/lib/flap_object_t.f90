!< Base (abstract) class upon which FLAP's concrete classes are built.
module flap_object_t
!-----------------------------------------------------------------------------------------------------------------------------------
!< Base (abstract) class upon which FLAP's concrete classes are built.
!-----------------------------------------------------------------------------------------------------------------------------------
use, intrinsic:: ISO_FORTRAN_ENV, only: stdout=>OUTPUT_UNIT, stderr=>ERROR_UNIT
use penf
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
implicit none
private
save
!-----------------------------------------------------------------------------------------------------------------------------------

!-----------------------------------------------------------------------------------------------------------------------------------
type, abstract, public :: object
  !< Base (abstract) class upon which FLAP's concrete classes are built.
  private
  character(len=:), public, allocatable :: progname      !< Program name.
  character(len=:), public, allocatable :: version       !< Program version.
  character(len=:), public, allocatable :: help          !< Help message.
  character(len=:), public, allocatable :: description   !< Detailed description.
  character(len=:), public, allocatable :: license       !< License description.
  character(len=:), public, allocatable :: authors       !< Authors list.
  character(len=:), public, allocatable :: epilog        !< Epilogue message.
  character(len=:), public, allocatable :: m_exclude     !< Mutually exclude other CLA(s group).
  character(len=:), public, allocatable :: error_message !< Meaningful error message to standard-error.
  integer(I4P),     public              :: error=0_I4P   !< Error trapping flag.
  contains
    procedure :: free_object         !< Free dynamic memory.
    procedure :: print_version       !< Print version.
    procedure :: print_error_message !< Print meaningful error message.
    procedure :: assign_object       !< Assignment overloading.
endtype object
!-----------------------------------------------------------------------------------------------------------------------------------
contains
  elemental subroutine free_object(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Free dynamic memory.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(object), intent(inout) :: self !< Object data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(self%progname     )) deallocate(self%progname     )
  if (allocated(self%version      )) deallocate(self%version      )
  if (allocated(self%help         )) deallocate(self%help         )
  if (allocated(self%description  )) deallocate(self%description  )
  if (allocated(self%license      )) deallocate(self%license      )
  if (allocated(self%authors      )) deallocate(self%authors      )
  if (allocated(self%epilog       )) deallocate(self%epilog       )
  if (allocated(self%m_exclude    )) deallocate(self%m_exclude    )
  if (allocated(self%error_message)) deallocate(self%error_message)
  self%error = 0_I4P
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine free_object

  subroutine print_version(self, pref)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Print version.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(object),          intent(in) :: self  !< Object data.
  character(*), optional, intent(in) :: pref  !< Prefixing string.
  character(len=:), allocatable      :: prefd !< Prefixing string.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  prefd = '' ; if (present(pref)) prefd = pref
  write(stdout,'(A)')prefd//self%progname//' version '//self%version
  if (self%license /= '') then
    write(stdout,'(A)')prefd//self%license
  endif
  if (self%authors /= '') then
    write(stdout,'(A)')prefd//self%authors
  endif
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine print_version

  subroutine print_error_message(self)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Print meaningful error message to standard-error.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(object), intent(in) :: self !< Object data.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  write(stderr, '(A)') self%error_message
  write(stderr, '(A)')
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine print_error_message

  elemental subroutine assign_object(lhs, rhs)
  !---------------------------------------------------------------------------------------------------------------------------------
  !< Assign two abstract objects.
  !---------------------------------------------------------------------------------------------------------------------------------
  class(object), intent(inout) :: lhs !< Left hand side.
  class(object), intent(in)    :: rhs !< Rigth hand side.
  !---------------------------------------------------------------------------------------------------------------------------------

  !---------------------------------------------------------------------------------------------------------------------------------
  if (allocated(rhs%progname   )) lhs%progname    = rhs%progname
  if (allocated(rhs%version    )) lhs%version     = rhs%version
  if (allocated(rhs%help       )) lhs%help        = rhs%help
  if (allocated(rhs%description)) lhs%description = rhs%description
  if (allocated(rhs%license    )) lhs%license     = rhs%license
  if (allocated(rhs%authors    )) lhs%authors     = rhs%authors
  if (allocated(rhs%epilog     )) lhs%epilog      = rhs%epilog
  if (allocated(rhs%m_exclude  )) lhs%m_exclude   = rhs%m_exclude
  return
  !---------------------------------------------------------------------------------------------------------------------------------
  endsubroutine assign_object
endmodule flap_object_t

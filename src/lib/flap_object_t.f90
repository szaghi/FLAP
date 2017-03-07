!< Base (abstract) class upon which FLAP's concrete classes are built.
module flap_object_t
!< Base (abstract) class upon which FLAP's concrete classes are built.

use, intrinsic :: iso_fortran_env, only : stdout=>output_unit, stderr=>error_unit
use penf

implicit none
private
save

type, abstract, public :: object
  !< Base (abstract) class upon which FLAP's concrete classes are built.
  character(len=:), allocatable :: progname           !< Program name.
  character(len=:), allocatable :: version            !< Program version.
  character(len=:), allocatable :: help               !< Help message.
  character(len=:), allocatable :: help_color         !< ANSI color of help messages.
  character(len=:), allocatable :: help_style         !< ANSI style of help messages.
  character(len=:), allocatable :: help_markdown      !< Longer help message, markdown formatted.
  character(len=:), allocatable :: description        !< Detailed description.
  character(len=:), allocatable :: license            !< License description.
  character(len=:), allocatable :: authors            !< Authors list.
  character(len=:), allocatable :: epilog             !< Epilogue message.
  character(len=:), allocatable :: m_exclude          !< Mutually exclude other CLA(s group).
  character(len=:), allocatable :: error_message      !< Meaningful error message to standard-error.
  character(len=:), allocatable :: error_color        !< ANSI color of error messages.
  character(len=:), allocatable :: error_style        !< ANSI style of error messages.
  integer(I4P)                  :: error=0_I4P        !< Error trapping flag.
  integer(I4P)                  :: usage_lun=stderr   !< Output unit to print help/usage messages
  integer(I4P)                  :: version_lun=stdout !< Output unit to print version message
  integer(I4P)                  :: error_lun=stderr   !< Error unit to print error messages
  contains
    ! public methods
    procedure, pass(self) :: free_object         !< Free dynamic memory.
    procedure, pass(self) :: print_version       !< Print version.
    procedure, pass(self) :: print_error_message !< Print meaningful error message.
    procedure, pass(lhs ) :: assign_object       !< Assignment overloading.
endtype object

contains
  ! public methods
  elemental subroutine free_object(self)
  !< Free dynamic memory.
  class(object), intent(inout) :: self !< Object data.

  if (allocated(self%progname     )) deallocate(self%progname     )
  if (allocated(self%version      )) deallocate(self%version      )
  if (allocated(self%help         )) deallocate(self%help         )
  if (allocated(self%help_color  ))  deallocate(self%help_color   )
  if (allocated(self%help_style  ))  deallocate(self%help_style   )
  if (allocated(self%help_markdown)) deallocate(self%help_markdown)
  if (allocated(self%description  )) deallocate(self%description  )
  if (allocated(self%license      )) deallocate(self%license      )
  if (allocated(self%authors      )) deallocate(self%authors      )
  if (allocated(self%epilog       )) deallocate(self%epilog       )
  if (allocated(self%m_exclude    )) deallocate(self%m_exclude    )
  if (allocated(self%error_message)) deallocate(self%error_message)
  if (allocated(self%error_color  )) deallocate(self%error_color  )
  if (allocated(self%error_style  )) deallocate(self%error_style  )
  self%error = 0_I4P
  self%usage_lun = stderr
  self%version_lun = stdout
  self%error_lun = stderr
  endsubroutine free_object

  subroutine print_version(self, pref)
  !< Print version.
  class(object), intent(in)           :: self  !< Object data.
  character(*),  intent(in), optional :: pref  !< Prefixing string.
  character(len=:), allocatable       :: prefd !< Prefixing string.

  prefd = '' ; if (present(pref)) prefd = pref
  write(self%version_lun,'(A)')prefd//self%progname//' version '//self%version
  if (self%license /= '') then
    write(self%version_lun,'(A)')prefd//self%license
  endif
  if (self%authors /= '') then
    write(self%version_lun,'(A)')prefd//self%authors
  endif
  endsubroutine print_version

  subroutine print_error_message(self)
  !< Print meaningful error message to standard-error.
  class(object), intent(in) :: self !< Object data.

  write(self%error_lun, '(A)') self%error_message
  write(self%error_lun, '(A)')
  endsubroutine print_error_message

  elemental subroutine assign_object(lhs, rhs)
  !< Assign two abstract objects.
  class(object), intent(inout) :: lhs !< Left hand side.
  class(object), intent(in)    :: rhs !< Rigth hand side.

  if (allocated(rhs%progname     )) lhs%progname      = rhs%progname
  if (allocated(rhs%version      )) lhs%version       = rhs%version
  if (allocated(rhs%help         )) lhs%help          = rhs%help
  if (allocated(rhs%help_color   )) lhs%help_color    = rhs%help_color
  if (allocated(rhs%help_style   )) lhs%help_style    = rhs%help_style
  if (allocated(rhs%help_markdown)) lhs%help_markdown = rhs%help_markdown
  if (allocated(rhs%description  )) lhs%description   = rhs%description
  if (allocated(rhs%license      )) lhs%license       = rhs%license
  if (allocated(rhs%authors      )) lhs%authors       = rhs%authors
  if (allocated(rhs%epilog       )) lhs%epilog        = rhs%epilog
  if (allocated(rhs%m_exclude    )) lhs%m_exclude     = rhs%m_exclude
  if (allocated(rhs%error_message)) lhs%error_message = rhs%error_message
  if (allocated(rhs%error_color  )) lhs%error_color   = rhs%error_color
  if (allocated(rhs%error_style  )) lhs%error_style   = rhs%error_style
                                    lhs%error         = rhs%error
                                    lhs%usage_lun     = rhs%usage_lun
                                    lhs%version_lun   = rhs%version_lun
                                    lhs%error_lun     = rhs%error_lun
  endsubroutine assign_object
endmodule flap_object_t

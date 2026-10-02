!run actions-help actions --help
!run actions actions -vv -I src --include=lib --format --no-restart
!run actions-defaults actions
!run actions-count actions -vvv
!run actions-append actions -I src --include=lib
!run actions-pair actions --no-restart
!run actions-value actions --format=json -v --verbose
!run -s actions-typo actions --verbse
program actions
!< The actions: count, append, store*, a flag pair, a hidden flag.
use flap
implicit none
type(command_line_interface) :: cli
integer                      :: verbosity
character(99), allocatable   :: include(:)
character(99)                :: format
logical                      :: restart
integer                      :: error
integer                      :: i

call cli%init(progname='actions', description='The actions of FLAP')
!region define
!region count
! count: -v -v, -vv or --verbose --verbose give 2
call cli%add(switch='--verbose', switch_ab='-v', help='Verbosity (repeatable)', required=.false., act='count')
!endregion count
!region append
! append: one value per occurrence
call cli%add(switch='--include', switch_ab='-I', help='Include directory (repeatable)', required=.false., &
             act='append', def='.')
!endregion append
!region optional
! store*: the value is optional, the switch alone gives the default
call cli%add(switch='--format', help='Output format', required=.false., act='store*', def='text')
!endregion optional
!region pair
! a flag with its negation: the last one passed wins
call cli%add(switch='--restart', switch_neg='--no-restart', help='Restart from the checkpoint', required=.false., &
             act='store_true', def='.true.')
!endregion pair
!region hidden
! a hidden flag: parsed, but not shown in the help
call cli%add(switch='--debug-internal', help='Internal debug flag', required=.false., act='store_true', def='.false.', &
             hidden=.true.)
!endregion hidden
!endregion define
call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
!region get
call cli%get(switch='--verbose', val=verbosity, error=error)
call cli%get_varying(switch='--include', val=include, error=error)
call cli%get(switch='--format', val=format, error=error)
call cli%get(switch='--restart', val=restart, error=error)
!endregion get
print '(A,I0)', 'verbosity = ', verbosity
print '(A,*(A,:,", "))', 'include   = ', (trim(include(i)), i=1, size(include))
print '(A)',    'format    = '//trim(format)
print '(A,L1)', 'restart   = ', restart
endprogram actions

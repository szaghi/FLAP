call cli%init(progname='ignore_unknown', ignore_unknown_clas=.true.) ! unknown arguments are reported, not fatal
call cli%add(switch='--nx', help='Cells', required=.false., act='store', def='64')
call cli%parse(error=error)
if (error /= 0 .and. error /= ERROR_UNKNOWN_CLAS_IGNORED) stop 1, quiet=.true.

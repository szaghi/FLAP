call cli%parse(error=error)
if (error /= 0) stop cli%exit_status(), quiet=.true.

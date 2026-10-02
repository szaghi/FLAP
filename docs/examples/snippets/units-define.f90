open(newunit=log, file='flap.log', action='write')
call cli%init(progname='units', usage_lun=log, error_lun=log) ! the help and the errors go to the log

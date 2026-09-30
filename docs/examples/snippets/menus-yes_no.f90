call m%init(question='Overwrite the restart file?')
call m%yes_no(answer, default='n', error=merror)

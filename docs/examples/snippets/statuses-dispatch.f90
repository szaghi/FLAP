call cli%parse(error=error)
select case(error)
case(0)
  print '(A)', 'running'
case(STATUS_PRINT_H, STATUS_PRINT_V, STATUS_PRINT_M)
  print '(A)', 'help, version or Markdown printed: cleaning up, then exit status 0'
case(STATUS_NO_ARGS)
  stop 2, quiet=.true.
case default
  stop 1, quiet=.true.
endselect

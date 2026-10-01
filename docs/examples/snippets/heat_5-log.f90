call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
! the header of the run log: every value and where it comes from
print '(A)', '# heat v0.5, parameters:'
print '(A)', cli%provenance()

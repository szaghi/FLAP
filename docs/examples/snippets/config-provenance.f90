call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.
print '(A)', cli%provenance()

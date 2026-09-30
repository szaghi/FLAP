call cli%parse(error=error)
if (error /= 0) stop 1, quiet=.true.

call cli%get(switch='-a', val=authors, error=error)
if (authors) print '(A)', 'Authors: '//cli%authors
if (cli%run_command('init')) print '(A)', 'Initialising versioning'
if (cli%run_command('commit')) then
  call cli%get(group='commit', switch='-m', val=message, error=error)
  print '(A)', 'Committing with message: "'//trim(message)//'"'
endif
if (cli%run_command('tag')) then
  call cli%get(group='tag', switch='-a', val=annotation, error=error)
  print '(A)', 'Tagging with annotation: "'//trim(annotation)//'"'
endif

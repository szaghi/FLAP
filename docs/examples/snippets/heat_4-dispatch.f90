! several commands can be called on one command line: one block each
if (cli%run_command('run')) call run
if (cli%run_command('post')) call post
if (cli%run_command('info')) print '(A)', 'heat v0.4, built with FLAP'

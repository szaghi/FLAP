call m%init(question='What is your favorite food?')
call m%add_option(text='Pizza')
call m%add_option(text='Ice Cream', is_default=.true.)
call m%add_option(text='Tacos')
call m%run(choice, merror) ! an empty answer: choice = 2

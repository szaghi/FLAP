call m%init(question='Which toppings?', multiple=.true.)
call m%add_option(text='Cheese', is_default=.true.)
call m%add_option(text='Mushrooms')
call m%add_option(text='Olives', is_default=.true.)
call m%run(choices, merror) ! "3 1" gives [3, 1]; an empty answer the defaults, [1, 3]

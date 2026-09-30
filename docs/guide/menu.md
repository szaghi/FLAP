# Interactive Menus

FLAP ships an optional module for simple interactive menus, in the spirit of Go's
[wmenu](https://github.com/dixonwille/wmenu): the program prints numbered options, reads the user's answer and gets back
the index of the chosen option.

The menu is **separate from the argument parser**. The parser never calls it, so parsing stays non-interactive and safe in
batch and MPI jobs. Use a menu only where your program really asks the user something.

## A single choice

```fortran
use flap, only : menu
use penf, only : I4P

type(menu)   :: m
integer(I4P) :: choice
integer(I4P) :: error

call m%init(question='What is your favorite food?')
call m%add_option(text='Pizza')
call m%add_option(text='Ice Cream')
call m%add_option(text='Tacos')
call m%run(choice, error)
if (error /= 0) stop 'no valid answer'
select case(choice)
case(1) ! Pizza
case(2) ! Ice Cream
case(3) ! Tacos
endselect
```

```text
1) Pizza
2) Ice Cream
3) Tacos
What is your favorite food? 2
```

`run` prints the options numbered from 1, then the question on the line where the answer is typed, and reads one line.
The answer must be one of the numbers shown; blanks around it are ignored. On any error `choice` is 0, the error code is
returned in `error` and a message such as `error: invalid response: 7` is written to the error unit.

| Procedure | Purpose |
|---|---|
| `init(question, multiple, separator, loop_on_invalid, tries, default_icon, input_unit, output_unit, error_unit, option_color, option_style, question_color, question_style, error_color, error_style, error)` | Start a new menu: drops the options and settings of a previous one. Every argument except `question` is optional. |
| `add_option(text, is_default, error)` | Append an option; its number is its position. An empty text, or a second default, is an error and is not added. |
| `run(choice, error)` | Show the menu and read one answer; `choice` is the index of the chosen option. A menu can be run several times. |
| `run(choices, error)` | The same, `choices` an allocatable array: the chosen indexes (see [Multiple selection](#multiple-selection)). |
| `yes_no(answer, default, error)` | Ask the question as a yes/no one, without the options; `answer` is a logical (see [Yes/no questions](#yes-no-questions)). |
| `free` | Release the memory (also done automatically). |

## A default option

`add_option(..., is_default=.true.)` makes an option the answer to an empty (or blank) line. It is marked with the default
icon, `*` unless `init(default_icon=...)` sets another one (`''` for none):

```fortran
call m%init(question='What is your favorite food?')
call m%add_option(text='Pizza')
call m%add_option(text='Ice Cream', is_default=.true.)
call m%add_option(text='Tacos')
call m%run(choice, error) ! Enter alone: choice = 2
```

```text
1) Pizza
2) *Ice Cream
3) Tacos
What is your favorite food?
```

A single-choice menu has at most one default: a second one is `ERROR_MENU_DEFINITION` and is not added (a menu with
multiple selection can have several). Without a
default, an empty answer is `ERROR_MENU_NO_RESPONSE`. An invalid answer is an error even when there is a default.

## Multiple selection

With `init(multiple=.true.)` the user can choose several options in one answer, and `run` fills an allocatable array
with their indexes, in the order typed:

```fortran
integer(I4P), allocatable :: choices(:)

call m%init(question='Which toppings?', multiple=.true.)
call m%add_option(text='Cheese', is_default=.true.)
call m%add_option(text='Mushrooms')
call m%add_option(text='Olives', is_default=.true.)
call m%run(choices, error) ! "3 1" gives [3, 1]; an empty answer the defaults, [1, 3]
```

- By default the answers are separated by blanks, and several blanks count as one (`1   3`).
- `init(separator=',')` sets another separator: the answer is split at each one and the blanks around each field are
  ignored (`1, 3`); an empty field (`1,,3`) is invalid. An empty separator is `ERROR_MENU_DEFINITION` (the blank is kept).
- The same option twice (`2 2`) is `ERROR_MENU_DUPLICATE`.
- An empty answer gives all the default options.

On any error `choices` is allocated with no elements. `run(choices)` also works on a single-choice menu (one element);
there, and with the scalar `run(choice)`, several answers are `ERROR_MENU_TOO_MANY`. The scalar `run(choice)` on a menu
with multiple selection is `ERROR_MENU_DEFINITION`: use the array.

## Yes/no questions

`yes_no` asks the menu's question alone, without listing the options, and returns a logical:

```fortran
logical :: overwrite

call m%init(question='Overwrite the restart file?')
call m%yes_no(overwrite, default='n', error=error)
```

```text
Overwrite the restart file? (y/N) yes
```

- `y`, `yes`, `n`, `no` are accepted in any case (`yEs` too).
- `default='y'` or `'n'` (any case) answers an empty line and sets the suffix: `(Y/n)`, `(y/N)`, or `(y/n)` without a
  default, when an empty answer is `ERROR_MENU_NO_RESPONSE`. Any other default is `ERROR_MENU_DEFINITION`.
- Anything else is `ERROR_MENU_INVALID`; retries and the end of the input work as for `run`, and the suffix is never
  repeated on a retry. On any error `answer` is `.false.`.

## Asking again

By default the first invalid answer is returned as an error. With `init(loop_on_invalid=.true.)` the menu reports it
with the tries left and asks again, up to `tries` attempts in total (3 by default); when they are exhausted `run`
returns the last error. An empty answer without a default counts as an invalid one.

```fortran
call m%init(question='What is your favorite food?', loop_on_invalid=.true., tries=3)
```

```text
1) Pizza
2) Ice Cream
3) Tacos
What is your favorite food? 7
error: invalid response: 7 (2 tries left)
1) Pizza
2) Ice Cream
3) Tacos
What is your favorite food? 2
```

Every error kind is retried except the end of the input (see below). `tries` below 1 is `ERROR_MENU_DEFINITION` (returned by `init`,
which keeps the default 3).

## Colours

`init` takes a colour and a style for the option lines, the question and the word `error` of the messages, with the
names of FLAP's other colour settings (FACE: `red`, `blue`, ..., `bold_on`, `italics_on`, ...):

```fortran
call m%init(question='What is your favorite food?', option_color='blue', question_style='bold_on', error_color='red')
```

Without them the output has no escape sequences. The user's answer is echoed by the terminal, not by the program, so it
has no colour of its own.

## Units

By default the menu reads standard input and writes to standard output and standard error. `init(input_unit=,
output_unit=, error_unit=)` selects other units, already opened by the caller: the menu never opens nor closes a unit.
This is also how a menu is tested without a terminal: write the answers to a file, open it, and pass its unit as
`input_unit`.

## Batch and MPI jobs

When there is no more input (standard input redirected from `/dev/null` or closed, as in most batch jobs) `run` returns
`ERROR_MENU_EOF` at once instead of waiting, even with `loop_on_invalid`. Standard Fortran cannot tell whether the input is a terminal, so the end of
the input is the signal: check `error` and fall back to a default or stop.

<<< @/examples/output/menus-eof.ansi{ansi}

In an MPI program, run the menu on one rank only and broadcast the chosen index; the module performs no MPI calls and
never stops the program.

## Errors

| Code | Name | Cause |
|---|---|---|
| `2001` | `ERROR_MENU_INVALID` | The answer is not one of the numbers shown (not a number, out of range, an empty field), or it could not be read |
| `2002` | `ERROR_MENU_TOO_MANY` | Several answers to a single choice |
| `2003` | `ERROR_MENU_DUPLICATE` | The same option chosen twice |
| `2004` | `ERROR_MENU_NO_RESPONSE` | Empty answer, and no default option |
| `2005` | `ERROR_MENU_EOF` | End of the input: no answer can come |
| `2006` | `ERROR_MENU_DEFINITION` | `run` on a menu without options, `add_option` with an empty text or a second default (single choice), `init` with `tries` below 1 or an empty separator, the scalar `run(choice)` with multiple selection, `yes_no` with a default other than y or n |

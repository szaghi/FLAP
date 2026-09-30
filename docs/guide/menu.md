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
| `init(question, default_icon, input_unit, output_unit, error_unit)` | Start a new menu: drops the options and settings of a previous one. Every argument except `question` is optional. |
| `add_option(text, is_default, error)` | Append an option; its number is its position. An empty text, or a second default, is an error and is not added. |
| `run(choice, error)` | Show the menu and read one answer; `choice` is the index of the chosen option. A menu can be run several times. |
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

A single-choice menu has at most one default: a second one is `ERROR_MENU_DEFINITION` and is not added. Without a
default, an empty answer is `ERROR_MENU_NO_RESPONSE`. An invalid answer is an error even when there is a default.

## Units

By default the menu reads standard input and writes to standard output and standard error. `init(input_unit=,
output_unit=, error_unit=)` selects other units, already opened by the caller: the menu never opens nor closes a unit.
This is also how a menu is tested without a terminal: write the answers to a file, open it, and pass its unit as
`input_unit`.

## Batch and MPI jobs

When there is no more input (standard input redirected from `/dev/null` or closed, as in most batch jobs) `run` returns
`ERROR_MENU_EOF` at once instead of waiting. Standard Fortran cannot tell whether the input is a terminal, so the end of
the input is the signal: check `error` and fall back to a default or stop.

In an MPI program, run the menu on one rank only and broadcast the chosen index; the module performs no MPI calls and
never stops the program.

## Errors

| Code | Name | Cause |
|---|---|---|
| `2001` | `ERROR_MENU_INVALID` | The answer is not one of the numbers shown (not a number, out of range, several numbers), or it could not be read |
| `2004` | `ERROR_MENU_NO_RESPONSE` | Empty answer, and no default option |
| `2005` | `ERROR_MENU_EOF` | End of the input: no answer can come |
| `2006` | `ERROR_MENU_DEFINITION` | `run` on a menu without options, `add_option` with an empty text or a second default |

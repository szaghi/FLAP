# 9. Asking the user

Sometimes a program should ask rather than fail: a user at a terminal may not know the schemes `heat` offers. FLAP's
optional `menu` type asks a numbered question; `heat` uses it only with `--interactive`, and only when `--scheme` is
missing:

<<< @/examples/snippets/heat_9-ask.f90

<<< @/examples/output/heat_9.ansi{ansi}

<<< @/examples/output/heat_9-given.ansi{ansi}

(In a terminal the answer `2` is echoed after the question; here it comes from `printf`.)

In a batch job there is nobody to answer: the menu sees the end of its input at once and returns an error, and `heat`
stops instead of guessing:

<<< @/examples/output/heat_9-batch.ansi{ansi}

The parser never asks anything: menus are a separate module, used only where the program decides to.

::: tip What you learned
`menu`: options, a default, an answer from standard input, safe behaviour in batch jobs.
Reference: [Interactive Menus](/guide/menu).
:::

That is the whole tour. For quick answers, see the [cookbook](../cookbook).

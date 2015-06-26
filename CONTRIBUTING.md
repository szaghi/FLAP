# How to contribute

This project is FOSS (free and open source software), therefore, anyone is interest to use, to develop or to contribute to it is welcome.

This project must remain KISS (Keep It Simple and Stupid), thus a few guidelines for contributing are provided.

## Issues Handling

If you find issues (bugs or new features requests) you are kindly requested to highlight them on the GitHub repository.

+ Make sure you have a [GitHub account](https://github.com/signup/free);
+ submit a ticket for your issue, assuming one does not already exist;
  + clearly describe the issue including steps to reproduce when it is a bug;
  + make sure you fill in the earliest version that you know has the issue.

## Collaborative Development

If you like to directly contribute to the project you are welcome. To improve the collaborative development of the project you are kindly requested to respect the following guidelines.

+ Fork the repository on GitHub;
+ make sure you have a modern Fortran compiler having extensive support for 2003+ standards for safely testing the project;
+ create a topic branch from where you want to base your work;
  + this is usually the master branch:
  + only target release branches if you are certain your fix must be on that branch;
  + to quickly create a topic branch based on master; `git branch fix/master/my_contribution master` then checkout the new branch with `git checkout fix/master/my_contribution`; please avoid working directly on the `master` branch;
+ check for unnecessary whitespace with `git diff --check` [before committing](#gitws);
+ make sure your commit messages are clear;
+ make sure you have properly tested for your changes;
+ as long as possible, try to follow our [coding style](#fstyle);

### <a name="gitws"></a> Make git to get the rid of unnecessary white-spaces

It is suggested to allow git to get the rid of unnecessary white-spaces eventually introduced into the sources. To this aim check that your git configuration (global or repository-specific) contains the following settings:

```dosini
[color]
  ui = true
[color "diff"]
  whitespace = red reverse
[core]
  whitespace=fix,-indent-with-non-tab,trailing-space,cr-at-eol
```

### <a name="fstyle"></a> Fortran Coding Style

As long as possible, contributors are kindly requested to follow the current coding style:

+ write code that comments itself, e.g. clearness naming (even if lengthy) is better than conciseness one which often means obscure:
  + human readable variables names are better than obscure acronyms, e.g. `real :: gas_ideal_air` is better than `real :: gia`;
  + variables name of one character should be avoided; they should be used only for counters, e.g. `do i=1, Number_iterations ; ! loop statements ; enddo`
+ name all constants;
+ minimize global data:
  + use global types parameters, i.e. kinds and precisions of numbers, especially;
+ use pervasive explicit typing, i.e. add `implicit none` to all modules and programs:
  + declare intent for all procedures arguments;
  + consistently place procedure arguments in the following order:
    + the pass argument;
    + intent(in out) arguments;
    + intent(in) arguments;
    + intent(out) arguments;
    + optional arguments
+ avoid side effects, as much as possible;
+ indent blocks of statements being inside loops, select case, if, etc...:
  + indent with two white spaces instead of tabs;
+ avoid trailing white spaces;
+ blank lines should not have any space;
+ prefer `>,<,==...` instead of `.gt.,.lt.,.eq....`;

In general, it is strongly recommended to avoid Microsoft-Windows-like carriage-return symbols in order to not pollute the source files with unnecessary symbols.

# How to contribute

This project is open source, therefore, anyone is interest to use, to develop or to contribute to it is welcome.

The project must remain KISS (Keep It Simple and Stupid) thus a few guidelines for contributing are provided.

## Issues Handling

If you find issues (bugs or new features requests) you are kindly requested to highlight them on the GitHub repository.

+ Make sure you have a [GitHub account](https://github.com/signup/free);
+ submit a ticket for your issue, assuming one does not already exist;
  + clearly describe the issue including steps to reproduce when it is a bug;
  + make sure you fill in the earliest version that you know has the issue.

Alternatively, you can signal issues directly to the main developer at stefano.zaghi@gmail.com.

## Collaborative Development

If you like to directly contribute to the project you are welcome. To improve the collaborative development of the project you are kindly requested to respect the following guidelines.

+ Fork the repository on GitHub;
+ make sure you have a modern Fortran compiler having extensive support for 2003+ standards for safely testing the project;
+ create a topic branch from where you want to base your work;
  + this is usually the master branch:
  + only target release branches if you are certain your fix must be on that branch;
  + to quickly create a topic branch based on master; `git branch fix/master/my_contribution master` then checkout the new branch with `git checkout fix/master/my_contribution`; please avoid working directly on the `master` branch;
+ check for unnecessary whitespace with `git diff --check` before committing;
+ make sure your commit messages are clear;
+ make sure you have properly tested for your changes.

As long as possible, contributors are kindly requested to follow the current coding style of the project (two white spaces instead of tabs, no trailing white spaces, blank lines should not have any space, prefer `>,<,==...` instead of `.gt.,.lt.,.eq....`, etc...). In particular, avoid _implicit_ typing and prefer verbose comments. In general, it is strongly recommended to avoid Microsoft-Windows-like carriage-return symbols in order to not pollute the source files with unnecessary symbols.

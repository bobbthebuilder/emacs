# C/C++11 Development Environment for Emacs 

![Screenshot](screenshot.png?raw=true)

## Description

Slim, easy customizable, expandable, works-out-of-the-box configuration 
which turns emacs into a complete __C/C++11 Development Environment__ with

* C/C++-specific code completion: `irony-mode` with `company-mode`'s backend: `company-irony`
* General code completion: `semantic`
* Syntax checking and diagnostic report: `flycheck` and `flycheck-irony` 
* Abbreviations which automatically expand into function templates: `yasnippet` 

__New__: C++17 support

## Dependencies

The following packages __must__ be installed: [Emacs](https://www.gnu.org/software/emacs/) (version >= 24), 
[CMake](https://cmake.org/) (version >= 2.8.3), [libclang](http://clang.llvm.org/doxygen/group__CINDEX.html)

Optional are: [GDB](https://www.gnu.org/software/gdb/), [git](http://git-scm.com/), [gcc](https://gcc.gnu.org/)

## Installation

__Important__: Backup your emacs configuration in `~/.emacs.d` 
(for example by `cp -R ~./emacs.d ~/emacs_backup`)

1. `git clone git@github.com:bobbthebuilder/emacs.git ~/.emacs.d` 
2. Start emacs (Note: all packages needed are downloaded automatically, just wait a few seconds)
3. On the first run, `irony-mode` will ask you to build and install `irony-server`: `M-x irony-install-server RET`

That's all. 

## Custom shortcuts 

| Key         | Action                                                | 
| ------------|:-----------------------------------------------------:|
| F2          | `M-x eshell` to lauch shell inside emacs              |
| F5	      | `M-x compile` with gcc call if there is no makefile   | 
| Tab         | indent or complete with yasnippet		      |
| M-g _line_  | jump to line _line_                                   | 

Feel free to send me push requests, bug reports and remarks.

# C/C++11 Development Environment for Emacs 

![Screenshot](screenshot.png?raw=true)

## Description

Slim, easy customizable, expandable, works-out-of-the-box configuration which turns emacs into a complete
C/C++11 Development Environment with

* Code completition: `irony-mode` with `company-mode`'s backend: `company-irony`
* Syntax Checking: `flycheck`
* Abbreviations which automatically expand into function templates: `yasnippet`

## Dependencies

The following packages __must__ be installed:

| Package                                                      | Version       | 
| -------------------------------------------------------------|:-------------:|
| [Emacs](https://www.gnu.org/software/emacs/)                 | >= 24         | 
| [CMake](https://cmake.org/)                                  | >= 2.8.3      | 
| [libclang](http://clang.llvm.org/doxygen/group__CINDEX.html) |               | 

Optional are:

* [GDB](https://www.gnu.org/software/gdb/)
* [git](http://git-scm.com/)
* [gcc](

## Installation

__Important__: Backup your emacs configuration in `~/.emacs.d` 
(for example by `cp -R ~./emacs.d ~/emacs_backup`)

1. `git clone git@github.com:bobbthebuilder/emacs.git ~/.emacs.d` 
2. Start emacs (Note: all packages needed are automatically downloaded, just wait a few seconds)
3. On the first run, `irony-mode` will ask you to build and install `irony-server`: `M-x irony-install-server RET`
 
That's all. 

## Shortcuts 

Feel free to send me push requests, bug reports and remarks.

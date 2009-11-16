MouseTerm
=========

Fork Notes
----------

This is a development fork of brodie/mouseterm, in which I hope to add a few
more features.  So far it supports setting of tab titles via the standard
Xterm escape code ("\e]2;<TITLE STRING>\007"), and incorporates a Ragel[12]-based
parser for extending the escape sequence parsing.

Note that this is a massively unstable work in progress, caveat user, etc.

Please submit any bug reports / feature suggestions into the GitHub Issues
tracker, although I can't commit to making things work on Snow Leopard until
I get round to upgrading.

[12]: http://www.complang.org/ragel/


See the TODO file for current plans.

Original Readme follows:
------------------------

MouseTerm is a [SIMBL][1]/[PlugSuit][2] plugin for Mac OS X's
[Terminal.app][3] that passes mouse events to the terminal, allowing you to
use mouse shortcuts within applications that support them.

No configuration is necessary, just open the `.dmg` file, run `Install`, and
restart Terminal.app. To uninstall, simply run `Uninstall` from the `.dmg`.

[1]: http://www.culater.net/software/SIMBL/SIMBL.php
[2]: http://infinite-labs.net/PlugSuit/
[3]: http://www.apple.com/macosx/technology/unix.html


Download
--------

[MouseTerm-leopard.dmg][4] (82 KB)

[4]: http://bitheap.org/mouseterm/MouseTerm-leopard.dmg


Status
------

MouseTerm is currently alpha quality software. Some features have not yet
been implemented, and there may be bugs in the current implementation.

What works:

* Mouse scroll wheel reporting.
* Simulated mouse wheel scrolling for programs like `less` (i.e. any
  fullscreen program that uses [application cursor key mode][5]).

What's being worked on:

* Reporting for other mouse buttons.
* `xterm` "hilite" mouse tracking mode.
* A preferences dialog and terminal profile integration.

[5]: http://the.earth.li/~sgtatham/putty/0.60/htmldoc/Chapter4.html#config-appcursor


Frequently Asked Questions
--------------------------

> What programs can I use the mouse in?

This varies widely and depends on the specific program. `less`, [Emacs][6],
and [Vim][7] are good places to test out mouse reporting.

> How do I enable mouse reporting in Vim?

To enable the mouse for all modes add the following to your `~/.vimrc` file:

    if has("mouse")
        set mouse=a
    endif

Run `:help mouse` for more information and other possible values.

> What about enabling it in Emacs?

By default MouseTerm will use simulated mouse wheel scrolling in Emacs. To
enable terminal mouse support, add this to your `~/.emacs` file:

    (xterm-mouse-mode 1)
    (mouse-wheel-mode 1)
    (global-set-key [mouse-4] '(lambda ()
                                 (interactive)
                                 (scroll-down 1)))

    (global-set-key [mouse-5] '(lambda ()
                                 (interactive)
                                 (scroll-up 1)))

[6]: http://www.gnu.org/software/emacs/
[7]: http://www.vim.org/


Development
-----------

Download the official development repository using [Mercurial][8]:

    hg clone http://bitheap.org/hg/mouseterm/

Run `make` to compile the plugin, and `make install` to install it into
your home directory's SIMBL plugins folder. Run `make` and `make builddmg`
to create a disk image of the application.

[JRSwizzle][9] and some mouse reporting code from [iTerm][10] are used in
MouseTerm.

[8]: http://www.selenic.com/mercurial/
[9]: http://rentzsch.com/trac/wiki/JRSwizzle
[10]: http://iterm.sourceforge.net/


Contact
-------

Contact information can be found on my site, [brodierao.com][11].

[11]: http://brodierao.com/

MouseTerm
=========

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

[MouseTerm.dmg][4] (82 KB, for Snow Leopard users)
[MouseTerm-leopard.dmg][5] (82 KB, for Leopard users)

[4]: http://bitheap.org/mouseterm/MouseTerm.dmg
[5]: http://bitheap.org/mouseterm/MouseTerm-leopard.dmg


Status
------

MouseTerm is currently alpha quality software. Some features have not yet
been implemented, and there may be bugs in the current implementation.

What works:

* Mouse scroll wheel reporting.
* Simulated mouse wheel scrolling for programs like `less` (i.e. any
  fullscreen program that uses [application cursor key mode][6]).

What's being worked on:

* Reporting for other mouse buttons.
* `xterm` "hilite" mouse tracking mode.
* A preferences dialog and terminal profile integration.

[6]: http://the.earth.li/~sgtatham/putty/0.60/htmldoc/Chapter4.html#config-appcursor


Frequently Asked Questions
--------------------------

> What programs can I use the mouse in?

This varies widely and depends on the specific program. `less`, [Emacs][7],
and [Vim][8] are good places to test out mouse reporting.

> How do I enable mouse reporting in Vim?

To enable the mouse for all modes add the following to your `~/.vimrc` file:

    if has("mouse")
        set mouse=a
    endif

Run `:help mouse` for more information and other possible values.

> What about enabling it in Emacs?

By default MouseTerm will use simulated mouse wheel scrolling in Emacs. To
enable terminal mouse support, add this to your `~/.emacs` file:

    (unless window-system
      (xterm-mouse-mode 1)
      (mouse-wheel-mode 1)
      (global-set-key [mouse-4] '(lambda ()
                                   (interactive)
                                   (scroll-down 1)))
      (global-set-key [mouse-5] '(lambda ()
                                   (interactive)
                                   (scroll-up 1))))

[7]: http://www.gnu.org/software/emacs/
[8]: http://www.vim.org/


Development
-----------

Download the official development repository using [Git][9]:

    git clone git://github.com/brodie/mouseterm.git

Run `make` to compile the plugin, and `make install` to install it into
your home directory's SIMBL plugins folder. Run `make` and `make builddmg`
to create a disk image of the application.

Visit [GitHub][10] if you'd like to fork the project, watch for new changes,
or report issues.

[JRSwizzle][11] and some mouse reporting code from [iTerm][12] are used in
MouseTerm.

[9]: http://git-scm.org/
[10]: http://github.com/brodie/mouseterm
[11]: http://rentzsch.com/trac/wiki/JRSwizzle
[12]: http://iterm.sourceforge.net/


Contact
-------

Contact information can be found on my site, [brodierao.com][13].

[13]: http://brodierao.com/

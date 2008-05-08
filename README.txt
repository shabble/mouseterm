MouseTerm
=========

MouseTerm is a [SIMBL][1] plugin for Mac OS X's [Terminal.app][2] that
passes mouse events to the terminal, allowing you to use mouse shortcuts
within applications that support them.

No configuration is necessary, just install SIMBL and move
`MouseTerm.bundle` to `Library/Application Support/SIMBL/Plugins` in
your home folder and restart Terminal.app. To uninstall the plugin, simply
delete the plugin's folder.

[1]: http://www.culater.net/software/SIMBL/SIMBL.php
[2]: http://www.apple.com/macosx/technology/unix.html


Download
--------

[MouseTerm.zip][3] (? KB)

[3]: http://bitheap.org/mouseterm/MouseTerm.zip


Status
------

MouseTerm is currently alpha quality software. Some features have not yet
been implemented, and there may be bugs in the current implementation.

What works:

* Mouse scroll wheel reporting.
* Simulated mouse wheel scrolling for programs like `less` (i.e. any
  fullscreen program that uses [application cursor key mode][4]).

What's being worked on:

* Reporting for other mouse buttons.
* `xterm` "hilite" mouse tracking mode.
* A preferences dialog and terminal profile integration.

[4]: http://the.earth.li/~sgtatham/putty/0.60/htmldoc/Chapter4.html#config-appcursor


Development
-----------

Download the official development repository using [Mercurial][5]:

    hg clone http://bitheap.org/hg/mouseterm/

Run `make` to compile the plugin, and `make install` to install it into
your home directory's SIMBL plugins folder.

[JRSwizzle][6] and mouse reporting code from [iTerm][7] are used in
MouseTerm.

[5]: http://www.selenic.com/mercurial/
[6]: http://rentzsch.com/trac/wiki/JRSwizzle
[7]: http://iterm.sourceforge.net/

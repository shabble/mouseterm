MouseTerm
==========

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


Development
-----------

Download the official development repository using [Mercurial][4]:

    hg clone http://bitheap.org/hg/mouseterm/

Run `make` to compile the plugin, and `make install` to install it into
your home directory's SIMBL plugins folder.

[JRSwizzle][5] and mouse reporting code from [iTerm][6] are used in
MouseTerm.

[4]: http://www.selenic.com/mercurial/
[5]: http://rentzsch.com/trac/wiki/JRSwizzle
[6]: http://iterm.sourceforge.net/

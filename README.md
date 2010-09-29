TermWeaver (TERMinal anyWherE And eVerywhERe)
=============================================

TermWeaver is just a very simple application (a preference pane
really) which allows one to launch a new terminal window or a new
terminal tab using a global hot key. Additionally to that it will try
to get the current directory of the application that had a focus when
the hot key was pressed. It works with applications like Finder.app,
Aquamacs.app, iWorks, ... Actually it works with Terminal.app itself
so one can hit the new tab hot key while in terminal and the new tab
will be open with the same current directory as the other one - kind
of a gnome-terminal behavior.

![TermWeaver preference pane screenshot version 1.0][1]

Features
--------

* Hot Key for new Terminal.app window
* Hot Key for new Terminal.app tab
* Automatically gets the current directory of the focused application (if it is possible)
* UI setting for hot keys
* Auto-Update (thanks to Sparky framework)

Related Work
------------

I use Terminal.app a lot so for me particularly it is very handy. I
tried to use [dterm][2], but I don't like that it does kind of its own
terminal emulation. The only think I need is a quick way how to get a
new terminal window or tab with the current directory (especially from
Finder.app or Terminal.app). Anyway for others [dterm][3] might be a
good option. Another similar thing is [visor][4] - quake like terminal
window ([SIMBL][5] plugin). I also meant this to be for me kind of a
introduction to objective-c / cocoa development.

Further Work
------------

What I'd like to do next (when I have a bit of a time) is to mix this
with [visor][4] - to add a new setting that would allow to have new
tab in the ad hoc terminal window with the current path.

Acknowledgement
---------------

As a objective-c / cocoa beginner I found Pierre Chatelier's *From C++
to Objective-C* book very useful. It's available [here][7]. For some
parts I got inspired by the [Growl][8] project and [Google Toolbox for
Mac][9].


  [1]: http://github.com/fikovnik/TermWeaver/tree/master/wiki/images/sshot-prefpane-1.0.png
  [2]: http://www.decimus.net/dterm.php
  [3]: http://www.decimus.net/dterm.php
  [4]: http://github.com/darwin/visor
  [5]: http://www.culater.net/software/SIMBL/SIMBL.php
  [6]: http://github.com/darwin/visor
  [7]: http://www.chachatelier.fr/programmation/fichiers/cpp-objc-en.pdf
  [8]: http://growl.info/source.php
  [9]: http://code.google.com/p/google-toolbox-for-mac/
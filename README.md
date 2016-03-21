new-firefox
===========

Create temporary Firefox sessions.

To log into any site while surfing, you might want to use a different
Firefox session to prevent tracking. Firefox does have an option to open
one or more private windows, but different private windows share the same
set of cookies, they all represent one private session.
Also, all Firefox windows belong to the same process.
If this process is already using 1 GB of your RAM,
a new process would be a lot faster than the old memory hog.

This script starts a new Firefox process with a temporary profile,
which is automatically deleted afterwards.
When a temporary profile is deleted, the cookies from that session
are gone as well, just like those from a private session
when the last private window is closed.
For example, it could be used to start 3 temporary Firefox sessions
to log into one site with 3 different names.

This tool starts Firefox in safe mode, with all addons disabled.
This is done because the temporary profile is not a perfect copy
of the default profile, therefore some addons might cause trouble.
It was observed that a bookmark sync addon failed to load the bookmarks
in a temporary profile and then started a sync,
deleting all of them on the server.

Please note that this is just a cheap script, with minimal error handling.
Don't expect the temporary Firefox sessions to work perfectly.



Installation
------------

Just copy this thing into your local ~/bin directory
and drop the suffix.
Then, when starting Firefox (hit Alt + F2 or whatever), enter "new-firefox".

Firefox will show a dialog informing you that it's being started in safe mode.
So it'll be obvious that this is a separate Firefox session.



Cleanup
-------

Normally, this tool will create a temporary profile
and delete that profile when Firefox is closed.
However, this tool might fail to do so due to a bug or a crash.
In such a case, the temporary profile should be deleted manually.

Navigate to $HOME/.mozilla/firefox/.
Look for directories named "tempX.profile", where X is a number.
These are temporary profile directories.
You can safely delete those, once all Firefox sessions are closed.
Don't delete any other files or directories.

Then, open the file called profiles.ini and look for config sections
that have a "Path" key which points to a "tempX.profile" directory.
Remove these sections. Keep the other sections as they are.



Gory details
------------

This tool creates a temporary profile directory in $HOME/.mozilla/firefox/.
The directory is always named "tempX.profile", where X is a positive integer.
X is the directory number, which isn't really an index but rather a number
used to form a unique directory name.
Also, a profile section for this temporary profile is added to the config file
called profiles.ini.
Each section name contains a number, which is the section index.
When one or more temporary sessions are created, their section indexes
and directory numbers usually match.
As soon as a session is closed while sessions with higher indexes
are still running, their section indexes will be decreased.
Failure to do so would lead to a gap in the profile section array,
which in turn would cause Firefox to show the profile chooser dialog.
When closed, this profile chooser may reset the config file
by removing all temporary profile sections.



Author
------

Philip Seeger (philip@philip-seeger.de)



License
-------

Please see the file called LICENSE.




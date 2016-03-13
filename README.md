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



Author
------

Philip Seeger (philip@philip-seeger.de)



License
-------

Please see the file called LICENSE.




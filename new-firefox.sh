#!/bin/bash

# Firefox location
FIREFOX=${FIREFOX:-/usr/bin/firefox}
if [ ! -x "$FIREFOX" ]; then
    echo "Firefox not found: $FIREFOX" >&2
    exit 1
fi
DIR="$HOME/.mozilla/firefox/"
if [ ! -d "$DIR" ]; then
    echo "Profile directory not found: $DIR" >&2
    exit 1
fi

# Profile file
profilefile="$DIR/profiles.ini"
if [ ! -f "$profilefile" ]; then
    echo "Profile file not found: $profilefile" >&2
    exit 1
fi
profiledata=$(cat $profilefile)
if [ -z "$profiledata" ]; then
    echo "Could not read profile file: $profilefile" >&2
    exit 1
fi

# Default profile
default=$(echo "$profiledata" | grep Path= | head -n 1 | cut -f2 -d'=')
if [ -z "$default" ]; then
    echo "Default profile name not found: $default" >&2
    exit 1
fi
defaultdir="$DIR/$default"
if [ ! -d "$defaultdir" ]; then
    echo "Default profile directory not found: $defaultdir" >&2
    exit 1
fi

# Last profile
latestnum=$(echo "$profiledata" | \
grep '\[Profile' | grep -Eo '[0-9]+' | tail -n 1)
if [ -z "$latestnum" ]; then
    echo "Unable to determine last index" >&2
    exit 1
fi

# New profile index
newnum=$(($latestnum+1))
if [ $newnum -lt 1 ]; then
    echo "Invalid new profile index: $newnum" >&2
    exit 1
fi
newname="temp$newnum"

# New profile directory with old config
newdir="$DIR$newname.profile"
echo "Creating new profile directory $newname.profile..."
mkdir "$newdir"
if [ ! -d "$newdir" ]; then
    echo "Error creating new profile directory: $newdir" >&2
    exit 1
fi
echo "Copying default config..."
cp -v "$defaultdir/prefs.js" "$newdir/" >/dev/null

# Copy additional data
echo "Copying default extensions..."
cp -vR "$defaultdir/extensions"* "$newdir/" >/dev/null

# New profile config section
newsection="[Profile$newnum]
Name=$newname
IsRelative=1
Path=$newname.profile
"
echo "Adding new profile config section..."
echo "$newsection" >>$profilefile

# Start Firefox with new profile and wait
# Safe mode used to prevent issues with addons
# A bookmark sync addon might otherwise delete all bookmarks
echo "Starting Firefox with new profile..."
$FIREFOX -P "$newname" --new-instance --safe-mode
echo "Firefox closed"

# Delete profile config section
echo "Deleting profile config section..."
sed -i '/Profile'$newnum'/,/^\s*$/{d}' $profilefile

# Delete profile directory
if [ ! -f "$newdir/prefs.js" ]; then
    echo "Not deleting, dir doesn't look right, no prefs.js" >&2
    exit 1
fi
echo "Deleting profile directory..."
echo "$newdir"
rm -rfv "$newdir" >/dev/null

# Done
echo "Done"


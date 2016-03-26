#!/bin/bash

# Firefox executable
FIREFOX=${FIREFOX:-/usr/bin/firefox}
if [ ! -x "$FIREFOX" ]; then
    echo "Firefox not found: $FIREFOX" >&2
    exit 1
fi

# Firefox profile directory
DIR="$HOME/.mozilla/firefox/"
if [ ! -d "$DIR" ]; then
    echo "Profile directory not found: $DIR" >&2
    exit 1
fi

# Profile file
profile_file="$DIR/profiles.ini"
if [ ! -f "$profile_file" ]; then
    echo "Profile file not found: $profile_file" >&2
    exit 1
fi
profile_data=$(cat "$profile_file")
if [ -z "$profile_data" ]; then
    echo "Could not read profile file: $profile_file" >&2
    exit 1
fi

# Default profile
default_name=$(echo "$profile_data" | grep Path= | head -n 1 | cut -f2 -d'=')
if [ -z "$default_name" ]; then
    echo "Default profile name not found: $default_name" >&2
    exit 1
fi
default_dir="$DIR/$default_name"
if [ ! -d "$default_dir" ]; then
    echo "Default profile directory not found: $default_dir" >&2
    exit 1
fi

# Determine new profile index for config file (section name)
# Index 0 is that of default profile
# Profile index must be highest + 1 or else config is considered invalid
# Profile chooser shows up if config invalid (and config restored on close)
new_profile_index=0
profile_indexes=$(echo "$profile_data" | grep '\[Profile')
for i in $profile_indexes; do
    current_index=${i//[!0-9]/}
    if [ $current_index -ge $new_profile_index ]; then
        new_profile_index=$current_index
    fi
    unset -v current_index
done
((new_profile_index++))

# Determine index for new profile directory name (usually profile index)
# Increment index if old profile dir found not in profile.ini anymore
# Such an old profile directory should probably be deleted
# Directory index might be > profile index if old directory found
# Firefox would not run in new session if new profile pointed at old dir
# Simply incrementing profile index would break config:
#   Section index 0 is default, 1 missing in config, 2 is new section index
#   Profile directory #1 still exists
#   Creating section #2 (dir #2) in config would break it, section #1 missing
#   Adding section #1 pointing to dir #1 would not be a new session (old dir)
#   So: New profile section #1 in config pointing to new profile directory #2
new_dir_index=$new_profile_index
while [ -d "${DIR}temp${new_dir_index}.profile" ]; do
    str_date=$(date -r "${DIR}temp${new_dir_index}.profile" +%Y-%m-%d-%H-%M-%S)
    [ -n "$str_date" ] && str_date=" ($str_date)"
    echo "Old profile directory$str_date found: temp${new_dir_index}.profile"
    unset -v str_date
    ((new_dir_index++))
done

# New profile dir
new_name="temp${new_dir_index}"
new_dir="${DIR}${new_name}.profile"

# New profile directory with old config
echo "Creating new profile \"$new_name\" (#$new_profile_index)..."
mkdir "$new_dir"
if [[ $? -ne 0 || ! -d "$new_dir" ]]; then
    echo "Error creating new profile directory: $new_dir" >&2
    exit 1
fi

# Store section index in profile directory
# Section index might change
# Change into and stay in profile directory
cd "$new_dir"
if [ $? -ne 0 ]; then
    echo "Error changing into profile directory: $new_dir" >&2
    exit 1
fi
index_file_name="._TEMP_PROFILE_"
echo -n $new_profile_index >"$index_file_name"
if [ $? -ne 0 ]; then
    echo "Error saving temporary index in profile directory: $new_dir" >&2
    exit 1
fi

# Copy default config
echo "Copying default config..."
cp -v "$default_dir/prefs.js" "$new_dir/" >/dev/null

# Copy additional data
echo "Copying default extensions..."
cp -vR "$default_dir/extensions"* "$new_dir/" >/dev/null

# New profile config section
new_section="[Profile$new_profile_index]
Name=$new_name
IsRelative=1
Path=${new_name}.profile
"
echo "Adding new profile to config..."
echo "$new_section" >>"$profile_file"

# Start Firefox with new profile and wait
# Safe mode used to prevent issues with addons
# A bookmark sync addon might otherwise delete all bookmarks
echo "Starting Firefox with temporary profile (#$new_profile_index)..."
$FIREFOX -P "$new_name" --new-instance --safe-mode
echo "Firefox closed"

# Get section index which may have been moved
if [ -e "$index_file_name" ]; then
    new_profile_index=$(cat "$index_file_name")
fi

# Remove profile section from config
# May fail if config reverted in the meantime (Firefox profile chooser)
echo "Deleting profile config section (#$new_profile_index)..."
sed -i '/Profile'$new_profile_index'/,/^\s*$/{d}' "$profile_file"

# Decrement following section indexes to not break config
# Config might be invalid at this point (section #1 removed, #2 still there)
next_index=$((new_profile_index+1))
while grep -q '\[Profile'$((next_index))'\]' "$profile_file"; do
    current_path=$(grep -A 3 '\[Profile'$next_index'\]' "$profile_file" | \
        grep Path)
    current_path="${current_path#*=}"
    next_index_new=$((next_index-1))
    echo "Moving section #$next_index -> #$next_index_new..."
    sed -i 's/\[Profile'$next_index'\]/\[Profile'$next_index_new'\]/' \
        "$profile_file"
    if [ -n "$current_path" ]; then
        current_info_file="${DIR}${current_path}/$index_file_name"
        echo -n $next_index_new >"$current_info_file"
    fi
    ((next_index++))
done

# Delete profile directory
if [ ! -f "$new_dir/prefs.js" ]; then
    # Don't delete it if it doesn't look like a profile directory
    echo "Not deleting, dir doesn't look right, no prefs.js" >&2
    exit 1
fi
echo "Deleting profile directory ($new_name)..."
rm -rfv "$new_dir" >/dev/null

# Done
echo "Done"


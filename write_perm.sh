#!/usr/bin/sudo sh

for entry in level1 level2 level3 out dump; do
    if [ -d $entry ]; then
        sudo chmod -R ugo+rwx $entry
    fi
done

#!/usr/bin/sudo sh

if [ ! -d level2 ]; then
    echo "Unpack level 2 first"
    exit 0
fi

for part in system system_ext vendor product odm oem
do
    if [ -d level2/$part ]; then
    size=$(cat level2/${part}_size.txt)
    fs=level2/${part}_fs_config
    fc=level2/${part}_file_contexts
    bin/linux/make_ext4fs -s -J -L $part -T -1 -S $fc -C $fs -l $size -a $part level1/$part.PARTITION level2/$part/
    echo "Done."
    fi
done

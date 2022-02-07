#!/bin/sh

if [ -d level1 ]
then
    echo "Deleting existing $level_dir"
    rm -rf level1
fi

count_file=`ls -1 in/*.img 2>/dev/null | wc -l`
if [ $count_file = 0 ]; then
    echo "No files found in /in"
elif [ $count_file -ne 1 ]; then
    echo "Too many files found"
fi

bin/linux/AmlImagePack -d in/*.img level1
echo "Done."

#!/bin/sh

if [ ! -d level1 ]
then
    echo "Can't find level1 folder"
fi

count_file=`ls -1 level1/image.cfg 2>/dev/null | wc -l`
if [ $count_file = 0 ]; then
    echo "Can't find image.cfg"
fi

file_name=$(basename in/*.img)
bin/linux/AmlImagePack -r level1/image.cfg level1 out/$file_name
echo "Done."

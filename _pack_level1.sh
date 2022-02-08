#!/bin/sh

if [ ! -d level1 ]; then
    echo "Can't find level1 folder"
elif [ ! -d out ]; then
    echo "Can't find out folder"
    mkdir out
elif [ "$(ls -1 level1/image.cfg 2>/dev/null | wc -l)" = 0 ]; then
    echo "Can't find image.cfg"
else
    file_name=$(basename in/*.img)
	bin/linux/AmlImagePack -r level1/image.cfg level1 out/"$file_name"
	echo "Done."
fi

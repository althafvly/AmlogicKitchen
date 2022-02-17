#!/usr/bin/sudo sh

if [ ! -d level1 ]; then
    echo "Can't find level1 folder"
elif [ "$(ls -1 level1/image.cfg 2>/dev/null | wc -l)" = 0 ]; then
    echo "Can't find image.cfg"
else
    if [ ! -d out ]; then
        echo "Can't find out folder"
        echo "Created out folder"
        mkdir out
    fi
    file_name=$(cat level1/projectname.txt)
    bin/linux/AmlImagePack -r level1/image.cfg level1 out/"$file_name.img"
    echo "Done."
fi

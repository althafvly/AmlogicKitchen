#!/usr/bin/sudo sh

imgextractor="bin/common/imgextractor.py"

if [ ! -d level1 ]; then
    echo "Unpack level 1 first"
    exit 0
fi

if [ -d level2 ]
then
    echo "Deleting existing level2"
    rm -rf level2 && mkdir level2
else
    mkdir level2
fi

for part in system system_ext vendor product odm oem
do
    if [ -f level1/$part.PARTITION ]; then
    echo "Extracting $part"
    bin/linux/simg2img level1/$part.PARTITION level2/$part.raw.img
    python3 $imgextractor "level2/$part.raw.img" "level2"
    fi
done

rm -rf level2/*.raw.img
echo "Done."

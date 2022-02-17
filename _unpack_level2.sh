#!/usr/bin/sudo sh

imgextractor="bin/common/imgextractor.py"

version=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
if [ -z "$version" ]; then
    echo "No Python installed!" 
fi

if [ ! -d level1 ]; then
    echo "Unpack level 1 first"
    exit 0
fi

if [ -d level2 ]
then
    echo "Deleting existing level2"
    rm -rf level2 && mkdir -p level2/config 
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

if [ -f level1/super.PARTITION ]; then
    bin/linux/simg2img level1/super.PARTITION level2/super.img
    echo $(du -b level2/super.img | cut -f1) > level2/config/super_size.txt
    bin/linux/super/lpunpack -slot=0 level2/super.img level2/
    rm -rf level2/super.img

    for part in system_a system_ext_a vendor_a product_a odm_a system_b system_ext_b vendor_b product_b odm_b
    do
        if [ -f level2/$part.img ]; then
            size=$(du -b level2/$part.img | cut -f1)
            if [ $size -ge 1024 ]; then
                python3 $imgextractor "level2/$part.img" "level2"
                awk -i inplace '!seen[$0]++' level2/config/*
                rm -rf level2/$part.img
            fi
        fi
    done
fi

echo "Done."

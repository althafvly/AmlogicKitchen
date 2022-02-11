#!/usr/bin/sudo sh

if [ ! `which dtc` ]; then
    echo "install dtc, please (apt-get install device-tree-compiler)"
    exit 0
fi

if [ ! -d level3 ]; then
    echo "Unpack level 3 first"
    exit 0
fi

for part in boot recovery
do
    if [ -d level3/${part} ]; then
        bin/linux/aik/cleanup.sh
        cp -r level3/$part/ramdisk bin/linux/aik/
        cp -r level3/$part/split_img bin/linux/aik/
        bin/linux/aik/repackimg.sh
        mv bin/linux/aik/image-new.img level1/${part}.PARTITION
        bin/linux/aik/cleanup.sh
    fi
done

if [ -d level3/logo ]; then
    bin/linux/imgpack -r level3/logo level1/logo.PARTITION
fi

if [ -d level3/devtree ]; then
    DIR='level3/devtree/'
    count=$(ls -1U $DIR | wc -l)
    if [ $count -gt 1 ]; then
        for filename in level3/devtree/*.dts; do
            [ -e "$filename" ] || continue
            name=$(basename $filename .dts)
            dtc -I dts -O dtb level3/devtree/$name.dts -o "`echo level3/devtree/$name.dtb | sed -e s'/\.dts/\.dtb/'`"
            rm level3/devtree/$name.dts
            bin/linux/dtbTool -o level1/_aml_dtb.PARTITION level3/devtree/
        done
    else
        dtc -I dts -O dtb level3/devtree/single.dts -o "`echo level1/_aml_dtb.PARTITION | sed -e s'/\.dts/\.dtb/'`"
    fi
fi

size=$(du -b level1/_aml_dtb.PARTITION | cut -f1)
if [ $size -gt 196607 ]; then
    gzip -nc level1/_aml_dtb.PARTITION > level1/_aml_dtb.PARTITION.gzip
    mv level1/_aml_dtb.PARTITION.gzip level1/_aml_dtb.PARTITION
fi

echo "Done."

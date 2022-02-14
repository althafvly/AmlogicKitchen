#!/usr/bin/sudo sh

if [ ! -d level2 ]; then
    echo "Unpack level 2 first"
    exit 0
fi

for part in system system_ext vendor product odm oem
do
    if [ -d level2/$part ]; then
    size=$(cat level2/config/${part}_size.txt)
    fs=level2/config/${part}_fs_config
    fc=level2/config/${part}_file_contexts
    bin/linux/make_ext4fs -s -J -L $part -T -1 -S $fc -C $fs -l $size -a $part level1/$part.PARTITION level2/$part/
    echo "Done."
    fi
done

if [ -f level1/super.PARTITION ]; then
    for part in system_a system_ext_a vendor_a product_a odm_a system_b system_ext_b vendor_b product_b odm_b
    do
        if [ -d level2/$part ]; then
            size=$(cat level2/config/${part}_size.txt)
            foldersize=$(du -shb level2/$part | cut -f1)
            fs=level2/config/${part}_fs_config
            fc=level2/config/${part}_file_contexts
            echo "Creating ${part} image"
            bin/linux/make_ext4fs -s -J -L $part -T -1 -S $fc -C $fs -l $size -a $part level2/$part.img level2/$part/
            echo "Done."
        fi
    done
fi

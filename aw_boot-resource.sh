#!/usr/bin/sudo sh

foldername=$(cat level1/projectname.txt).img.dump

if [ -d level3/boot_resource ]; then
    umount level3/boot_resource
fi

if [ -f level1/$foldername/boot-resource.fex ]; then
    echo "Mounting boot-resource in level3"
    mkdir -p level3/boot_resource
    mount -o loop -t vfat "level1/$foldername/boot-resource.fex" level3/boot_resource
fi


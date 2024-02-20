#!/usr/bin/sudo bash

echo "....................."
echo "Amlogic Dump to Image script"
echo "....................."

version=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
if [ -z "$version" ]; then
    echo "No Python installed!"
fi

if [ -f dump/super.img ]; then
    echo "super image isn't supported yet"
    exit 0
fi

for dir in level1 level2 level3; do
    if [ -d $dir ]; then
        echo "Deleting existing $dir"
        rm -rf $dir && mkdir $dir
    else
        mkdir $dir
    fi
done

if [ ! -d out ]; then
    mkdir out
fi

for part in boot recovery vendor_boot logo dtbo vbmeta bootloader odm odm_ext oem product vendor system system_ext vbmeta_system; do
    if [ -f dump/$part.img ]; then
        cp dump/$part.img level1/$part.PARTITION
    fi
done

if [ -f dump/dtb.img ]; then
    cp dump/dtb.img level1/_aml_dtb.PARTITION
fi

cp bin/common/aml_sdc_burn.ini level1/aml_sdc_burn.ini

configname="level1/image.cfg"

echo "[LIST_NORMAL]" >$configname

if [ ! -f level1/DDR.USB ]; then
    echo "DDR.USB is missing, copy DDR.USB to level1 dir"
    read -p "Press enter to continue"
fi

if [ -f level1/DDR.USB ]; then
    echo "file=\"DDR.USB\"		main_type=\"USB\"		sub_type=\"DDR\"" >>$configname
fi

if [ ! -f level1/UBOOT.USB ]; then
    echo "UBOOT.USB is missing, copy UBOOT.USB to level1 dir"
    read -p "Press enter to continue"
fi

if [ -f level1/UBOOT.USB ]; then
    echo "file=\"UBOOT.USB\"		main_type=\"USB\"		sub_type=\"UBOOT\"" >>$configname
fi

if [ ! -f level1/aml_sdc_burn.UBOOT ]; then
    echo "aml_sdc_burn.UBOOT is missing, copy aml_sdc_burn.UBOOT to level1 dir"
    read -p "Press enter to continue"
fi

if [ -f level1/aml_sdc_burn.UBOOT ]; then
    echo "file=\"aml_sdc_burn.UBOOT\"		main_type=\"UBOOT\"		sub_type=\"aml_sdc_burn\"" >>$configname
fi

if [ -f level1/aml_sdc_burn.ini ]; then
    echo "file=\"aml_sdc_burn.ini\"		main_type=\"ini\"		sub_type=\"aml_sdc_burn\"" >>$configname
fi

if [ ! -f level1/meson1.PARTITION ]; then
    echo "meson1.PARTITION is missing, copy meson1.PARTITION to level1 dir"
    read -p "Press enter to continue"
fi

if [ -f level1/meson1.PARTITION ]; then
    echo "file=\"meson1.PARTITION\"		main_type=\"dtb\"		sub_type=\"meson1\"" >>$configname
fi

if [ ! -f level1/platform.conf ]; then
    echo "platform.conf is missing, copy platform.conf to level1 dir"
    read -p "Press enter to continue"
fi

if [ -f level1/platform.conf ]; then
    echo "file=\"platform.conf\"		main_type=\"conf\"		sub_type=\"platform\"" >>$configname
fi

for part in _aml_dtb boot vendor_boot recovery bootloader dtbo logo odm odm_ext oem product vendor system system_ext vbmeta vbmeta_system; do
    if [ -f level1/$part.PARTITION ]; then
        echo "file=\"$part.PARTITION\"		main_type=\"PARTITION\"		sub_type=\"$part\"" >>$configname
    fi
done

echo "[LIST_VERIFY]" >>$configname

for part in system system_ext vendor product odm oem; do
    if [ -f level1/$part.PARTITION ]; then
        echo "Unpacking $part"
        python3 bin/common/imgextractor.py "level1/$part.PARTITION" "level2" >/dev/null 2>&1
        awk -i inplace '!seen[$0]++' level2/config/*_file_contexts
        size=$(cat level2/config/${part}_size.txt)
        fs=level2/config/${part}_fs_config
        fc=level2/config/${part}_file_contexts
        echo "Repacking $part"
        bin/linux/make_ext4fs -s -J -L $part -T -1 -S $fc -C $fs -l $size -a $part level1/$part.PARTITION level2/$part/ >/dev/null 2>&1
    fi
done

for part in boot recovery boot_a recovery_a; do
    if [ -f level1/${part}.PARTITION ]; then
        mkdir level3/$part
        echo "Repacking $part"
        bin/linux/aik/unpackimg.sh level1/${part}.PARTITION >/dev/null 2>&1
        bin/linux/aik/repackimg.sh >/dev/null 2>&1
        mv bin/linux/aik/image-new.img level1/${part}.PARTITION >/dev/null 2>&1
        bin/linux/aik/cleanup.sh >/dev/null 2>&1
    fi
done

if [ -f level1/logo.PARTITION ]; then
    mkdir level3/logo
    echo "Repacking logo"
    bin/linux/imgpack -d level1/logo.PARTITION level3/logo >/dev/null 2>&1
    bin/linux/imgpack -r level3/logo level1/logo.PARTITION >/dev/null 2>&1
fi

if [ ! -f level1/_aml_dtb.PARTITION ]; then
    if [ -f level3/boot*/split_img/*-dtb ]; then
        cp level3/boot*/split_img/*-dtb level1/_aml_dtb.PARTITION
    elif [ -f level3/boot*/split_img/*-second ]; then
        cp level3/boot*/split_img/*-second level1/_aml_dtb.PARTITION
    elif [ -f level3/recovery*/split_img/*-dtb ]; then
        cp level3/recovery*/split_img/*-dtb level1/_aml_dtb.PARTITION
    elif [ -f level3/recovery*/split_img/*-second ]; then
        cp level3/recovery*/split_img/*-second level1/_aml_dtb.PARTITION
    fi
fi

if [ -f level1/_aml_dtb.PARTITION ]; then
    echo "Repacking dtb"
    mkdir level3/devtree
    bin/linux/7za x level1/_aml_dtb.PARTITION -y >/dev/null 2>&1
    bin/linux/dtbSplit _aml_dtb level3/devtree/ >/dev/null 2>&1
    rm -rf _aml_dtb
    bin/linux/dtbSplit level1/_aml_dtb.PARTITION level3/devtree/ >/dev/null 2>&1
    if [ "$(ls -A level3/devtree/)" ]; then
        for filename in level3/devtree/*.dtb; do
            [ -e "$filename" ] || continue
            name=$(basename $filename .dtb)
            dtc -I dtb -O dts level3/devtree/$name.dtb -o "$(echo level3/devtree/$name.dts | sed -e s'/\.dtb/\.dts/')" >/dev/null 2>&1
            rm -rf level3/devtree/$name.dtb
        done
    else
        dtc -I dtb -O dts level1/_aml_dtb.PARTITION -o "$(echo level3/devtree/single.dts | sed -e s'/\.dtb/\.dts/')" >/dev/null 2>&1
    fi

    count=$(ls -1U 'level3/devtree/' | wc -l)
    if [ $count -gt 1 ]; then
        for filename in level3/devtree/*.dts; do
            [ -e "$filename" ] || continue
            name=$(basename $filename .dts)
            dtc -I dts -O dtb level3/devtree/$name.dts -o "$(echo level3/devtree/$name.dtb | sed -e s'/\.dts/\.dtb/')" >/dev/null 2>&1
            bin/linux/dtbTool -o level1/_aml_dtb.PARTITION level3/devtree/ 2>&1
        done
    else
        dtc -I dts -O dtb level3/devtree/single.dts -o "$(echo level1/_aml_dtb.PARTITION | sed -e s'/\.dts/\.dtb/')" >/dev/null 2>&1
    fi

    size=$(du -b level1/_aml_dtb.PARTITION | cut -f1)
    if [ $size -gt 196607 ]; then
        gzip -nc level1/_aml_dtb.PARTITION >level1/_aml_dtb.PARTITION.gzip >/dev/null 2>&1
        mv level1/_aml_dtb.PARTITION.gzip level1/_aml_dtb.PARTITION
    fi

    if [ -f level3/devtree/*.dtb ]; then
        rm level3/devtree/*.dtb
    fi
fi

echo "Enter a name for aml package: "
read filename
bin/linux/AmlImagePack -r level1/image.cfg level1 out/"$filename.img"
echo "....................."
echo "Done."
./write_perm.sh
exit

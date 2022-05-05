#!/usr/bin/sudo sh

echo "....................."
echo "Amlogic Kitchen"
echo "....................."
echo "....................."
echo "Select level 1,2,3 or q/Q to exit: "
read level

if [ $level = 1 ]; then
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
elif [ $level = 2 ]; then
    if [ ! -d level2 ]; then
        echo "Unpack level 2 first"
        exit 0
    fi

    if [ ! -f level1/super.PARTITION ]; then
        for part in system system_ext vendor product odm oem; do
            if [ -d level2/$part ]; then
                echo "Creating $part image"
                size=$(cat level2/config/${part}_size.txt)
                fs=level2/config/${part}_fs_config
                fc=level2/config/${part}_file_contexts
                if [ ! -z "$size" ]; then
                    bin/linux/make_ext4fs -s -J -L $part -T -1 -S $fc -C $fs -l $size -a $part level1/$part.PARTITION level2/$part
                fi
                echo "Done."
            fi
        done
    fi

    if [ -f level1/super.PARTITION ]; then
        for part in system system_ext vendor product odm oem system_a system_ext_a vendor_a product_a odm_a system_b system_ext_b vendor_b product_b odm_b; do
            if [ -d level2/$part ]; then
                msize=$(du -sk level2/$part | cut -f1 | gawk '{$1*=1024;$1=int($1*1.08);printf $1}')
                fs=level2/config/${part}_fs_config
                fc=level2/config/${part}_file_contexts
                echo "Creating $part image"
                if [ $msize -lt 1048576 ]; then
                    msize=1048576
                fi
                bin/linux/make_ext4fs -J -L $part -T -1 -S $fc -C $fs -l $msize -a $part level2/$part.img level2/$part/
                bin/linux/ext4/resize2fs -M level2/${part}.img
                echo "Done."
            fi
        done
    fi

    if [ -f level2/config/super_type.txt ]; then
        supertype=$(cat level2/config/super_type.txt)
    fi
    if [ ! -z "$supertype" ] && [ $supertype -eq "3" ]; then
        metadata_size=65536
        metadata_slot=3
        supername="super"
        supersize=$(cat level2/config/super_size.txt)
        superusage1=$(du -cb level2/*.img | grep total | cut -f1)
        command="bin/linux/super/lpmake --metadata-size $metadata_size --super-name $supername --metadata-slots $metadata_slot"
        command="$command --device $supername:$supersize --group amlogic_dynamic_partitions_a:$superusage1"

        for part in system_ext_a system_a odm_a product_a vendor_a; do
            if [ -f level2/$part.img ]; then
                asize=$(du -skb level2/$part.img | cut -f1)
                if [ $asize -gt 0 ]; then 
                    command="$command --partition $part:readonly:$asize:amlogic_dynamic_partitions_a --image $part=level2/$part.img"
                fi
            fi
        done

        superusage2=$(expr $supersize - $superusage1)
        command="$command --group amlogic_dynamic_partitions_b:$superusage2"

        for part in system_ext_b system_b odm_b product_b vendor_b; do
            if [ -f level2/$part.img ]; then
                bsize=$(du -skb level2/$part.img | cut -f1)
                if [ $bsize -eq 0 ]; then 
                    command="$command --partition $part:readonly:$bsize:amlogic_dynamic_partitions_b"
                fi
            fi
        done

        if [ $superusage2 -ge $supersize ]; then 
            echo "Unable to create super image, recreated images are too big."
            echo "Cleanup some files before retrying"
            echo "Needed space: $superusage1"
            echo "Available maximum space: $supersize"
            exit 0
        fi

        command="$command --virtual-ab --sparse --output level1/super.PARTITION"
        if [ -f level1/super.PARTITION ]; then
            $($command)
        fi
    elif [ ! -z "$supertype" ] && [ $supertype -eq "2" ]; then
        metadata_size=65536
        metadata_slot=2
        supername="super"
        supersize=$(cat level2/config/super_size.txt)
        superusage=$(du -cb level2/*.img | grep total | cut -f1)
        command="bin/linux/super/lpmake --metadata-size $metadata_size --super-name $supername --metadata-slots $metadata_slot"
        command="$command --device $supername:$supersize --group amlogic_dynamic_partitions:$superusage"

        for part in system_ext system odm product vendor; do
            if [ -f level2/$part.img ]; then
                asize=$(du -skb level2/$part.img | cut -f1)
                if [ $asize -gt 0 ]; then 
                    command="$command --partition $part:readonly:$asize:amlogic_dynamic_partitions --image $part=level2/$part.img"
                fi
            fi
        done

        if [ $superusage -ge $supersize ]; then 
            echo "Unable to create super image, recreated images are too big."
            echo "Cleanup some files before retrying"
            echo "Needed space: $superusage1"
            echo "Available maximum space: $supersize"
            exit 0
        fi

        command="$command --sparse --output level1/super.PARTITION"
        if [ -f level1/super.PARTITION ]; then
            $($command)
        fi
    else
        exit 0
    fi

    rm -rf  level2/*.txt
elif [ $level = 3 ]; then
    if [ ! `which dtc` ]; then
        echo "install dtc, please (apt-get install device-tree-compiler)"
        exit 0
    fi

    if [ ! -d level3 ]; then
        echo "Unpack level 3 first"
        exit 0
    fi

    for part in boot recovery boot_a recovery_a; do
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
                bin/linux/dtbTool -o level1/_aml_dtb.PARTITION level3/devtree/
            done
        else
            dtc -I dts -O dtb level3/devtree/single.dts -o "`echo level1/_aml_dtb.PARTITION | sed -e s'/\.dts/\.dtb/'`"
        fi
    fi

    if [ -d level3/meson1 ]; then
        DIR='level3/meson1/'
        count=$(ls -1U $DIR | wc -l)
        if [ $count -gt 1 ]; then
            for filename in level3/meson1/*.dts; do
                [ -e "$filename" ] || continue
                name=$(basename $filename .dts)
                dtc -I dts -O dtb level3/meson1/$name.dts -o "`echo level3/meson1/$name.dtb | sed -e s'/\.dts/\.dtb/'`"
                bin/linux/dtbTool -o level1/meson1.dtb level3/meson1/
            done
        else
            dtc -I dts -O dtb level3/meson1/single.dts -o "`echo level1/meson1.dtb | sed -e s'/\.dts/\.dtb/'`"
        fi
    fi

    size=$(du -b level1/_aml_dtb.PARTITION | cut -f1)
    if [ $size -gt 196607 ]; then
        gzip -nc level1/_aml_dtb.PARTITION > level1/_aml_dtb.PARTITION.gzip
        mv level1/_aml_dtb.PARTITION.gzip level1/_aml_dtb.PARTITION
    fi
    rm level3/devtree/*.dtb

    msize=$(du -b level1/meson1.dtb | cut -f1)
    if [ $msize -gt 196607 ]; then
        gzip -nc level1/meson1.dtb > level1/meson1.dtb.gzip
        mv level1/meson1.dtb.gzip level1/meson1.dtb
    fi
    rm level3/meson1/*.dtb

    echo "Done."
elif [ $level = "q" -o $level = "Q" ]; then
    exit
fi

while true; do ./pack.sh && break; done

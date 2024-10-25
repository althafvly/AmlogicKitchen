#!/usr/bin/sudo bash

echo "....................."
echo "AllWinner Kitchen"
echo "....................."
echo "....................."
echo "Select level 1,2,3 or q/Q to exit: "
read level

if [ $level = 1 ]; then
    if [ ! -d level1 ]; then
        echo "Can't find level1 folder"
    else
        if [ ! -d out ]; then
            echo "Can't find out folder"
            echo "Created out folder"
            mkdir out
        fi
        file_name=$(cat level1/projectname.txt)
        bin/imgrepacker level1/$file_name.img.dump
        mv level1/$file_name.img out/$file_name.img
        echo "Done."
    fi
elif [ $level = 2 ]; then
    if [ ! -d level2 ]; then
        echo "Unpack level 2 first"
        exit 0
    fi

    foldername=$(cat level1/projectname.txt).img.dump

    if [ ! -f level1/$foldername/super.fex ]; then
        for part in system system_ext vendor product odm oem oem_a; do
            if [ -d level2/$part ]; then
                echo "Creating $part image"
                size=$(cat level2/config/${part}_size.txt)
                fs=level2/config/${part}_fs_config
                fc=level2/config/${part}_file_contexts
                if [ ! -z "$size" ]; then
                    bin/make_ext4fs -s -J -L $part -T -1 -S $fc -C $fs -l $size -a $part level1/$foldername/$part.fex level2/$part
                fi
                echo "Done."
            fi
        done
    fi

    for part in oem_a odm_ext_a odm_ext_b; do
        if [ -d level2/$part ]; then
            echo "Creating $part image"
            size=$(cat level2/config/${part}_size.txt)
            fs=level2/config/${part}_fs_config
            fc=level2/config/${part}_file_contexts
            if [ ! -z "$size" ]; then
                bin/make_ext4fs -s -J -L $part -T -1 -S $fc -C $fs -l $size -a $part level1/$foldername/$part.fex level2/$part
            fi
            echo "Done."
        fi
    done

    if [ -f level1/$foldername/super.fex ]; then
        for filename in level2/*.img; do
            part="$(basename "$filename" .img)"
            if [ -d level2/$part ]; then
                msize=$(du -sk level2/$part | cut -f1 | gawk '{$1*=1024;$1=int($1*1.08);printf $1}')
                fs=level2/config/${part}_fs_config
                fc=level2/config/${part}_file_contexts
                echo "Creating $part image"
                if [ $msize -lt 1048576 ]; then
                    msize=1048576
                fi
                bin/make_ext4fs -J -L $part -T -1 -S $fc -C $fs -l $msize -a $part level2/$part.img level2/$part/
                bin/ext4/resize2fs -M level2/${part}.img
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
        command="bin/super/lpmake --metadata-size $metadata_size --super-name $supername --metadata-slots $metadata_slot"
        command="$command --device $supername:$supersize --group allwinner_dynamic_partitions_a:$superusage1"

        for filename in level2/*_a.img; do
            part="$(basename "$filename" .img)"
            if [ -f level2/$part.img ]; then
                asize=$(du -skb level2/$part.img | cut -f1)
                if [ $asize -gt 0 ]; then
                    command="$command --partition $part:readonly:$asize:allwinner_dynamic_partitions_a --image $part=level2/$part.img"
                fi
            fi
        done

        superusage2=$(expr $supersize - $superusage1)
        command="$command --group allwinner_dynamic_partitions_b:$superusage2"

        for filename in level2/*_b.img; do
            part="$(basename "$filename" .img)"
            if [ -f level2/$part.img ]; then
                bsize=$(du -skb level2/$part.img | cut -f1)
                if [ $bsize -eq 0 ]; then
                    command="$command --partition $part:readonly:$bsize:allwinner_dynamic_partitions_b"
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

        command="$command --virtual-ab --sparse --output level1/$foldername/super.fex"
        if [ -f level1/$foldername/super.fex ]; then
            $($command)
        fi
    elif [ ! -z "$supertype" ] && [ $supertype -eq "2" ]; then
        metadata_size=65536
        metadata_slot=2
        supername="super"
        supersize=$(cat level2/config/super_size.txt)
        superusage=$(du -cb level2/*.img | grep total | cut -f1)
        command="bin/super/lpmake --metadata-size $metadata_size --super-name $supername --metadata-slots $metadata_slot"
        command="$command --device $supername:$supersize --group allwinner_dynamic_partitions:$superusage"

        for part in system_ext system odm product vendor; do
            if [ -f level2/$part.img ]; then
                asize=$(du -skb level2/$part.img | cut -f1)
                if [ $asize -gt 0 ]; then
                    command="$command --partition $part:readonly:$asize:allwinner_dynamic_partitions --image $part=level2/$part.img"
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

        command="$command --sparse --output level1/$foldername/super.fex"
        if [ -f level1/$foldername/super.fex ]; then
            $($command)
        fi
    fi

    rm -rf level2/*.txt
elif [ $level = 3 ]; then
    if [ ! $(which dtc) ]; then
        echo "install dtc, please (apt-get install device-tree-compiler)"
        exit 0
    fi

    if [ ! -d level3 ]; then
        echo "Unpack level 3 first"
        exit 0
    fi

    foldername=$(cat level1/projectname.txt).img.dump

    for part in boot recovery vendor_boot boot_a recovery_a vendor_boot_a; do
        if [ -d level3/${part} ]; then
            bin/aik/cleanup.sh
            cp -r level3/$part/ramdisk bin/aik/
            cp -r level3/$part/split_img bin/aik/
            bin/aik/repackimg.sh
            mv bin/aik/image-new.img level1/$foldername/${part}.fex
            bin/aik/cleanup.sh
        fi
    done

    if [ -d "level3/boot-resource" ]; then
        cd "level3"
        ../bin/fsbuild200/fsbuild ../bin/boot-resource.ini "../level1/$foldername/split_xxxx.fex"
        mv "boot-resource.fex" "../level1/$foldername/boot-resource.fex"
        cd ..
    fi

    echo "Done."
elif [ $level = "q" -o $level = "Q" ]; then
    exit
fi

while true; do ./write_perm.sh && ./awpack.sh && break; done

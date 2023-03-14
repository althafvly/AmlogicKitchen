#!/usr/bin/sudo sh

echo "....................."
echo "Rockchip Kitchen"
echo "....................."
echo "....................."
echo "Select level 1,2,3 or q/Q to exit: "
read level
if [ $level = 1 ]; then
    if [ -d level1 ]; then
        echo "Deleting existing level1"
        rm -rf level1 && mkdir level1
    else
        mkdir -p level1/Image
    fi

    echo "....................."
    echo "Rockchip Kitchen"
    echo "....................."
    if [ ! -d in ]; then
        echo "Can't find /in folder"
        echo "Creating /in folder"
        mkdir in
    fi
    count_file=$(ls -1 in/*.img 2>/dev/null | wc -l)
    if [ "$count_file" = 0 ]; then
        echo "No files found in /in"
        exit 0
    fi
    rename 's/ /_/g' in/*.img
    echo "Files in input dir (*.img)"
    count=0
    for entry in $(ls in/*.img); do
        count=$(($count + 1))
        name=$(basename in/$entry .img)
        echo $count - $name
    done
    echo "....................."
    echo "Enter a file name :"
    read projectname
    echo $projectname >level1/projectname.txt

    if [ ! -f in/$projectname.img ]; then
        echo "Can't find the file"
        exit 0
    fi

    filename=$(cat level1/projectname.txt)
    bin/linux/rkImageMaker -unpack in/$filename.img level1
    bin/linux/afptool -unpack level1/firmware.img level1
    rm -rf level1/boot.bin
    rm -rf level1/firmware.img

    echo "Done."
elif [ $level = 2 ]; then
    imgextractor="bin/common/imgextractor.py"

    version=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
    if [ -z "$version" ]; then
        echo "No Python installed!"
    fi

    if [ ! -d level1 ]; then
        echo "Unpack level 1 first"
        exit 0
    fi

    if [ -d level2 ]; then
        echo "Deleting existing level2"
        rm -rf level2 && mkdir -p level2/config
    else
        mkdir -p level2/config
    fi

    for part in system system_ext vendor product odm oem odm_ext_a odm_ext_b; do
        if [ -f level1/Image/$part.img ]; then
            echo "Extracting $part"
            if echo $(file level1/Image/$part.img) | grep -q "sparse"; then
                bin/linux/simg2img level1/Image/$part.img level2/$part.raw.img
                python3 $imgextractor "level2/$part.raw.img" "level2"
            else
                python3 $imgextractor level1/Image/$part.img "level2"
            fi
            awk -i inplace '!seen[$0]++' level2/config/*
        fi
    done

    rm -rf level2/*.raw.img

    if [ -f level1/Image/super.img ]; then
        bin/linux/simg2img level1/Image/super.img level2/super.img
        echo $(du -b level2/super.img | cut -f1) >level2/config/super_size.txt
        bin/linux/super/lpunpack -slot=0 level2/super.img level2/
        rm -rf level2/super.img

        if [ $(ls -1q level2/*_a.img 2>/dev/null | wc -l) -gt 0 ]; then
            echo "3" >level2/config/super_type.txt
        else
            echo "2" >level2/config/super_type.txt
        fi

        for part in system system_ext vendor product odm oem system_a system_ext_a vendor_a product_a odm_a system_b system_ext_b vendor_b product_b odm_b; do
            if [ -f level2/$part.img ]; then
                size=$(du -b level2/$part.img | cut -f1)
                if [ $size -ge 1024 ]; then
                    python3 $imgextractor "level2/$part.img" "level2"
                    awk -i inplace '!seen[$0]++' level2/config/*
                fi
            fi
        done
    fi

    echo "Done."
elif [ $level = 3 ]; then
    if [ ! -d level1 ]; then
        echo "Unpack level 1 first"
        exit 0
    fi

    if [ -d level3 ]; then
        rm -rf level3 && mkdir level3
    else
        mkdir level3
    fi

    for part in boot recovery boot_a recovery_a; do
        if [ -f level1/Image/${part}.img ]; then
            mkdir level3/$part
            bin/linux/aik/unpackimg.sh level1/Image/${part}.img
            mv -i bin/linux/aik/ramdisk level3/$part/
            mv -i bin/linux/aik/split_img level3/$part/
            if [ -f level3/$part/split_img/$part.img-second ]; then
                mkdir -p level3/resource_$part
                bin/linux/resource_tool --unpack --verbose --image=level3/$part/split_img/$part.img-second level3/resource_$part 2>&1|grep entry|sed "s/^.*://"|xargs echo
            fi
        fi
    done

    if [ -f level1/Image/resource.img ]; then
        mkdir -p level3/resource
        bin/linux/resource_tool --unpack --verbose --image=level1/Image/resource.img level3/resource 2>&1|grep entry|sed "s/^.*://"|xargs echo
    fi

    echo "Done."
elif [ $level = "q" -o $level = "Q" ]; then
    exit
fi

while true; do ./write_perm.sh && ./rkunpack.sh && break; done

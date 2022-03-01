#!/usr/bin/sudo sh


echo "....................."
echo "Amlogic Dumper"
echo "....................."
echo "Before going any further"
echo "Please connect your amlogic box in mask mode"
echo "....................."


if [ -d dtb ]; then
    echo "Deleting existing dtb"
    rm -rf dtb && mkdir dtb
else
    mkdir -p dtb
fi

if [ -d dtb ]; then
    echo "Deleting existing dump"
    rm -rf dump && mkdir dump
else
    mkdir -p dump
fi

echo "....................."
echo "Input bootloader size in bytes (most are: 4194304) :"
read blsize
echo "Input dtb size in bytes (most are: 262144) :"
read dtbsize
bin/linux/update mread store bootloader normal $blsize dump/bootloader.img
bin/linux/update mread store _aml_dtb normal $dtbsize dtb/dtb.img

if [ -f dtb/dtb.img ]; then
    if [ ! `which dtc` ]; then
        echo "install dtc, please (apt-get install device-tree-compiler)"
        exit 0
    fi

    bin/linux/7za x dtb/dtb.img -y
    if [ -f _aml_dtb ]; then
        bin/linux/dtbSplit _aml_dtb dtb/
        rm -rf _aml_dtb
    fi
    bin/linux/dtbSplit dtb/dtb.img dtb/
    for filename in dtb/*.dtb; do
        [ -e "$filename" ] || continue
        name=$(basename $filename .dtb)
        dtc -I dtb -O dts dtb/$name.dtb -o "`echo dtb/$name.dts | sed -e s'/\.dtb/\.dts/'`"
        rm -rf dtb/$name.dtb
    done
    dtc -I dtb -O dts dtb/dtb.img -o "`echo dtb/single.dts | sed -e s'/\.dtb/\.dts/'`"
    mv dtb/dtb.img dump/

    echo "Files in input dir (*.dts)"
    count=0
    for entry in `ls dtb/*.dts`; do
        count=$(($count + 1))
        name=$(basename dtb/$entry .dts)
        echo $count - $name
    done
    echo "....................."
    echo "Input a dts name for dump :"
    read dtsname

    if [ ! -f dtb/$dtsname.dts ]; then
        echo "Can't find the file"
        exit 0
    fi

    grep -P "\tpname" dtb/$dtsname.dts | grep -oP "(?<="")\w+"|sort | uniq | awk '{gsub("pname", "");print}'|sed -r '/^\s*$/d'>dump/partitions.txt

    for entry in `cat dump/partitions.txt`; do
        size=$(grep -A 3 "pname" dtb/$dtsname.dts | grep -A 3 "$entry" |grep "size" | grep -oP '(?<=0x00 )\w+')
        bin/linux/update mread store $entry normal $size dump/$entry.img
    done
fi

if [ -f dump/partitions.txt ]; then
    rm -rf dump/partitions.txt
fi

if [ -d dtb ]; then
    rm -rf dtb
fi

echo "Done."
exit

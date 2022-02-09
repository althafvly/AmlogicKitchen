#!/usr/bin/sudo sh

if [ ! `which dtc` ]; then
    echo "install dtc, please (apt-get install device-tree-compiler)"
    exit 0
fi

if [ ! -d level3 ]; then
    echo "Unpack level 3 first"
    exit 0
fi

if [ -d level3/boot ]; then
	kernel="level3/boot/boot.PARTITION-kernel"
	ramdisk="level3/boot/boot.PARTITION-ramdisk"
	second="level3/boot/boot.PARTITION-second"

	cmdline=`cat level3/boot/boot.PARTITION-cmdline`
	headerversion=`cat level3/boot/boot.PARTITION-header_version`
	base=`cat level3/boot/boot.PARTITION-base`
	pagesize=`cat level3/boot/boot.PARTITION-pagesize`
	kerneloff=`cat level3/boot/boot.PARTITION-kernel_offset`
	ramdiskoff=`cat level3/boot/boot.PARTITION-ramdisk_offset`
	secondoff=`cat level3/boot/boot.PARTITION-second_offset`
	tagsoff=`cat level3/boot/boot.PARTITION-tags_offset`
	oslevel=`cat level3/boot/boot.PARTITION-os_patch_level`
	osversion=`cat level3/boot/boot.PARTITION-os_version`
	boardname=`cat level3/boot/boot.PARTITION-board`
	hash=`cat level3/boot/boot.PARTITION-hashtype`

	bin/linux/mkbootimg --kernel $kernel --kernel_offset $kerneloff --ramdisk $ramdisk --ramdisk_offset $ramdiskoff --second $second --second_offset $secondoff --cmdline "$cmdline" --board "$boardname" --base $base --pagesize $pagesize --tags_offset $tagsoff --os_version $osversion --os_patch_level $oslevel --header_version $headerversion --hashtype $hash -o level1/boot.PARTITION
fi

if [ -d level3/recovery ]; then
	kernel="level3/recovery/recovery.PARTITION-kernel"
	ramdisk="level3/recovery/recovery.PARTITION-ramdisk"
	second="level3/recovery/recovery.PARTITION-second"
	recoverydtbo="level3/recovery/recovery.PARTITION-recovery_dtbo"

	cmdline=`cat level3/recovery/recovery.PARTITION-cmdline`
	headerversion=`cat level3/recovery/recovery.PARTITION-header_version`
	base=`cat level3/recovery/recovery.PARTITION-base`
	pagesize=`cat level3/recovery/recovery.PARTITION-pagesize`
	kerneloff=`cat level3/recovery/recovery.PARTITION-kernel_offset`
	ramdiskoff=`cat level3/recovery/recovery.PARTITION-ramdisk_offset`
	secondoff=`cat level3/recovery/recovery.PARTITION-second_offset`
	tagsoff=`cat level3/recovery/recovery.PARTITION-tags_offset`
	oslevel=`cat level3/recovery/recovery.PARTITION-os_patch_level`
	osversion=`cat level3/recovery/recovery.PARTITION-os_version`
	boardname=`cat level3/recovery/recovery.PARTITION-board`
	hash=`cat level3/recovery/recovery.PARTITION-hashtype`

	bin/linux/mkbootimg --kernel $kernel --kernel_offset $kerneloff --ramdisk $ramdisk --ramdisk_offset $ramdiskoff --second $second --second_offset $secondoff --recovery_dtbo $recoverydtbo --cmdline "$cmdline" --board "$boardname" --base $base --pagesize $pagesize --tags_offset $tagsoff --os_version $osversion --os_patch_level $oslevel --header_version $headerversion --hashtype $hash -o level1/recovery.PARTITION
fi

if [ -d level3/logo ]; then
	bin/linux/imgpack -r level3/logo level1/logo.PARTITION
fi

if [ -d level3/devtree ]; then
	for filename in level3/devtree/*.dts; do
	[ -e "$filename" ] || continue
	name=$(basename $filename .dts)
	dtc -I dts -O dtb level3/devtree/$name.dts -o "`echo level3/devtree/$name.dtb | sed -e s'/\.dts/\.dtb/'`"
	rm level3/devtree/$name.dts
	done
	bin/linux/dtbTool -o level1/_aml_dtb.PARTITION level3/devtree/ 
fi

echo "Done."

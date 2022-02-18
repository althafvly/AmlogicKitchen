#!/usr/bin/sudo sh

echo "....................."
echo "Amlogic Kitchen"
echo "....................."
echo "....................."
echo "Select level 1,2 or 3: "
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
elif [ $level = 3 ]; then
	if [ ! `which dtc` ]; then
		echo "install dtc, please (apt-get install device-tree-compiler)"
		exit 0
	fi

	if [ ! -d level3 ]; then
		echo "Unpack level 3 first"
		exit 0
	fi

	for part in boot recovery boot_a recovery_a
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
	rm level3/devtree/*.dtb

	echo "Done."
fi

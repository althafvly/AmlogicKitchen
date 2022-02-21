#!/usr/bin/sudo sh

echo "....................."
echo "Amlogic Kitchen"
echo "....................."
echo "....................."
echo "Select level 1,2 or 3: "
read level
if [ $level = 1 ]; then
	if [ -d level1 ]
	then
		echo "Deleting existing level1"
		rm -rf level1 && mkdir level1
	else
		mkdir level1
	fi

	echo "....................."
	echo "Amlogic Kitchen"
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
	echo "Files in input dir (*.img)"
	count=0
	for entry in `ls in/*.img`; do
		count=$(($count + 1))
		name=$(basename in/$entry .img)
		echo $count - $name
	done
	echo "....................."
	echo "Enter a file name :"
	read projectname
	echo $projectname> level1/projectname.txt

	if [ ! -f in/$projectname.img ]
	then
		echo "Can't find the file"
		exit 0
	fi

	filename=$(cat level1/projectname.txt)
	bin/linux/AmlImagePack -d in/$filename.img level1
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

	if [ -d level2 ]
	then
		echo "Deleting existing level2"
		rm -rf level2 && mkdir -p level2/config
	else
		mkdir -p level2/config
	fi

	for part in system system_ext vendor product odm oem
	do
		if [ -f level1/$part.PARTITION ]; then
			echo "Extracting $part"
			bin/linux/simg2img level1/$part.PARTITION level2/$part.raw.img
			python3 $imgextractor "level2/$part.raw.img" "level2"
		fi
	done

	rm -rf level2/*.raw.img

	if [ -f level1/super.PARTITION ]; then
		bin/linux/simg2img level1/super.PARTITION level2/super.img
		echo $(du -b level2/super.img | cut -f1) > level2/config/super_size.txt
		bin/linux/super/lpunpack -slot=0 level2/super.img level2/
		rm -rf level2/super.img

		for part in system_a system_ext_a vendor_a product_a odm_a system_b system_ext_b vendor_b product_b odm_b
		do
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
	if [ ! `which dtc` ]; then
		echo "install dtc, please (apt-get install device-tree-compiler)"
		exit 0
	fi

	if [ ! -d level1 ]; then
		echo "Unpack level 1 first"
		exit 0
	fi

	if [ -d level3 ]; then
		rm -rf level3 && mkdir level3
	else
		mkdir level3
	fi

	for part in boot recovery boot_a recovery_a
	do
		if [ -f level1/${part}.PARTITION ]; then
			mkdir level3/$part
			bin/linux/aik/unpackimg.sh level1/${part}.PARTITION
			mv -i bin/linux/aik/ramdisk level3/$part/
			mv -i bin/linux/aik/split_img level3/$part/
		fi
	done

	if [ -f level1/logo.PARTITION ]; then
		mkdir level3/logo
		bin/linux/imgpack -d level1/logo.PARTITION level3/logo
	fi

	if [ -f level1/_aml_dtb.PARTITION ]; then
		mkdir level3/devtree
		bin/linux/7za x level1/_aml_dtb.PARTITION -y
		bin/linux/dtbSplit _aml_dtb level3/devtree/
		rm -rf _aml_dtb
		bin/linux/dtbSplit level1/_aml_dtb.PARTITION level3/devtree/
		DIR='level3/devtree/'
		if [ "$(ls -A $DIR)" ]; then
			for filename in level3/devtree/*.dtb; do
			[ -e "$filename" ] || continue
			name=$(basename $filename .dtb)
			dtc -I dtb -O dts level3/devtree/$name.dtb -o "`echo level3/devtree/$name.dts | sed -e s'/\.dtb/\.dts/'`"
			rm -rf level3/devtree/$name.dtb
			done
		else
			dtc -I dtb -O dts level1/_aml_dtb.PARTITION -o "`echo level3/devtree/single.dts | sed -e s'/\.dtb/\.dts/'`"
		fi
	fi

	echo "Done."
fi


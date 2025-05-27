#!/usr/bin/sudo bash

echo "....................."
echo "Amlogic Kitchen"
echo "....................."
echo "....................."
echo "Select level 1,2,3 or q/Q to exit: "
read level
if [ $level = 1 ]; then
  if [ -d level1 ]; then
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
  bin/AmlImagePack -d in/$filename.img level1
  echo "Done."
elif [ $level = 2 ]; then
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

  ./common/extract_images.sh "level1" "level2"

  if [ -f level1/super.PARTITION ]; then
    ./common/extract_super.sh level1/super.PARTITION level2/
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

  for part in boot recovery vendor_boot boot_a recovery_a vendor_boot_a; do
    if [ -f level1/${part}.PARTITION ]; then
      mkdir level3/$part
      bin/aik/unpackimg.sh level1/${part}.PARTITION
      mv -i bin/aik/ramdisk level3/$part/
      mv -i bin/aik/split_img level3/$part/
    fi
  done

  if [ -f level1/logo.PARTITION ]; then
    mkdir level3/logo
    bin/logo_img_packer -d level1/logo.PARTITION level3/logo
  fi

  if [ ! -f level1/_aml_dtb.PARTITION ]; then
    echo "Do you want to copy dtb to level1? (y/n)"
    read answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      for part in boot recovery vendor_boot boot_a recovery_a vendor_boot_a; do
        if [ -f level1/_aml_dtb.PARTITION ]; then
          break
        fi
        if [ -f "level3/$part/split_img/$part.PARTITION-dtb" ]; then
          cp "level3/$part/split_img/$part.PARTITION-dtb" level1/_aml_dtb.PARTITION
        elif [ -f "level3/$part/split_img/$part.PARTITION-second" ]; then
          cp "level3/$part/split_img/$part.PARTITION-second" level1/_aml_dtb.PARTITION
        fi
      done
    fi
  fi

  if [ -f level1/_aml_dtb.PARTITION ]; then
    echo "Do you want to unpack _aml_dtb.PARTITION? (y/n)"
    read answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      mkdir level3/devtree
      7zz x level1/_aml_dtb.PARTITION -y
      bin/dtbSplit _aml_dtb level3/devtree/
      rm -rf _aml_dtb
      bin/dtbSplit level1/_aml_dtb.PARTITION level3/devtree/
      DIR='level3/devtree/'
      if [ "$(ls -A $DIR)" ]; then
        for filename in level3/devtree/*.dtb; do
          [ -e "$filename" ] || continue
          name=$(basename $filename .dtb)
          dtc -I dtb -O dts level3/devtree/$name.dtb -o "$(echo level3/devtree/$name.dts | sed -e s'/\.dtb/\.dts/')"
          rm -rf level3/devtree/$name.dtb
        done
      else
        dtc -I dtb -O dts level1/_aml_dtb.PARTITION -o "$(echo level3/devtree/single.dts | sed -e s'/\.dtb/\.dts/')"
      fi
    fi
  fi

  if [ -f level1/meson1.dtb ]; then
    echo "Do you want to unpack meson1.dtb? (y/n)"
    read answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      mkdir level3/meson1
      bin/dtbSplit level1/meson1.dtb level3/meson1/
      DIR='level3/meson1/'
      if [ "$(ls -A $DIR)" ]; then
        for filename in level3/meson1/*.dtb; do
          [ -e "$filename" ] || continue
          name=$(basename $filename .dtb)
          dtc -I dtb -O dts level3/meson1/$name.dtb -o "$(echo level3/meson1/$name.dts | sed -e s'/\.dtb/\.dts/')"
          rm -rf level3/meson1/$name.dtb
        done
      else
        dtc -I dtb -O dts level1/meson1.dtb -o "$(echo level3/meson1/single.dts | sed -e s'/\.dtb/\.dts/')"
      fi
    fi
  fi

  echo "Done."
elif [ $level = "q" -o $level = "Q" ]; then
  exit
fi

while true; do ./common/write_perm.sh && ./amlunpack.sh && break; done

#!/usr/bin/sudo bash

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
  bin/rkImageMaker -unpack in/$filename.img level1
  bin/afptool -unpack level1/firmware.img level1
  rm -rf level1/boot.bin
  rm -rf level1/firmware.img

  echo "Done."
elif [ $level = 2 ]; then
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

  ./common/extract_images.sh "level1/Image" "level2"

  if [ -f level1/Image/super.img ]; then
    ./common/extract_super.sh level1/Image/super.img level2/
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
    if [ -f level1/Image/${part}.img ]; then
      mkdir level3/$part
      bin/aik/unpackimg.sh level1/Image/${part}.img
      mv -i bin/aik/ramdisk level3/$part/
      mv -i bin/aik/split_img level3/$part/
      if [ -f level3/$part/split_img/$part.img-second ]; then
        mkdir -p level3/resource_$part
        bin/resource_tool --unpack --verbose --image=level3/$part/split_img/$part.img-second level3/resource_$part 2>&1 | grep entry | sed "s/^.*://" | xargs echo
      fi
    fi
  done

  if [ -f level1/Image/resource.img ]; then
    mkdir -p level3/resource
    bin/resource_tool --unpack --verbose --image=level1/Image/resource.img level3/resource 2>&1 | grep entry | sed "s/^.*://" | xargs echo
  fi

  echo "Done."
elif [ $level = "q" -o $level = "Q" ]; then
  exit
fi

while true; do ./common/write_perm.sh && ./rkunpack.sh && break; done

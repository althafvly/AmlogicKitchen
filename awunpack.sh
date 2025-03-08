#!/usr/bin/sudo bash

echo "....................."
echo "AllWinner Kitchen"
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
  echo "AllWinner Kitchen"
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
  cp in/$filename.img level1/$filename.img
  bin/imgrepacker level1/$filename.img
  rm level1/$filename.img
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

  foldername=$(cat level1/projectname.txt).img.dump

  ./extract_images.sh "level1/$foldername" "level2"

  if [ -f level1/$foldername/super.fex ]; then
    ./extract_super.sh level1/$foldername/super.fex level2/
  fi

  echo "Done."
elif [ $level = 3 ]; then
  if [ ! $(which dtc) ]; then
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

  foldername=$(cat level1/projectname.txt).img.dump

  for part in boot recovery vendor_boot boot_a recovery_a vendor_boot_a; do
    if [ -f level1/$foldername/${part}.fex ]; then
      mkdir level3/$part
      bin/aik/unpackimg.sh level1/$foldername/${part}.fex
      mv -i bin/aik/ramdisk level3/$part/
      mv -i bin/aik/split_img level3/$part/
    fi
  done

  if [ -f "level1/$foldername/boot-resource.fex" ]; then
    echo "Extracting boot-resource in level3"
    tmp_mount_dir=$(mktemp -d)
    mount -o loop -t vfat "level1/$foldername/boot-resource.fex" "$tmp_mount_dir"
    cp -a "$tmp_mount_dir"/. "level3/boot-resource/"
    umount "$tmp_mount_dir"
    rmdir "$tmp_mount_dir"
    rm -f "level3/boot-resource/magic.bin"
  fi

  echo "Done."
elif [ $level = "q" -o $level = "Q" ]; then
  exit
fi

while true; do ./write_perm.sh && ./awunpack.sh && break; done

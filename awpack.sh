#!/usr/bin/sudo bash

set -e

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
    # Check for 32-bit dependencies
    if ldd bin/imgrepacker | grep -q "not found"; then
        echo "❌ Missing 32-bit libraries. Please check readme"
        exit 1
    fi
    file_name=$(cat level1/projectname.txt)
    setarch i386 bin/imgrepacker level1/$file_name.img.dump
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
        if [ ! -z "$size" ]; then
          ./common/make_image.sh -s $part $size level2/$part/ level1/$foldername/$part.fex
        fi
        echo "Done."
      fi
    done
  fi

  for part in oem_a odm_ext_a odm_ext_b; do
    if [ -d level2/$part ]; then
      echo "Creating $part image"
      size=$(cat level2/config/${part}_size.txt)
      if [ ! -z "$size" ]; then
        ./common/make_image.sh -s $part $size level2/$part/ level1/$foldername/$part.fex
      fi
      echo "Done."
    fi
  done

  ./common/make_super.sh level1/$foldername/super.fex allwinner

  rm -rf level2/*.txt
elif [ $level = 3 ]; then
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
    ../bin/fsbuild ../bin/boot-resource.ini "../level1/$foldername/split_xxxx.fex"
    mv "boot-resource.fex" "../level1/$foldername/boot-resource.fex"
    cd ..
  fi

  echo "Done."
elif [ $level = "q" -o $level = "Q" ]; then
  exit
fi

while true; do ./common/write_perm.sh && ./awpack.sh && break; done

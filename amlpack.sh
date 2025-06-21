#!/usr/bin/sudo bash

set -e

echo "....................."
echo "Amlogic Kitchen"
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
    echo "Choose pack tool:"
    echo "1) ampack"
    echo "2) aml_image_v2_packer"
    read -p "Enter choice [1 or 2]: " choice
    case "$choice" in
        1)
            echo "Using ampack..."
            rm level1/projectname.txt
            bin/ampack pack level1 out/"$file_name.img"
            echo $file_name >level1/projectname.txt
            ;;
        2)
            if [ "$(ls -1 level1/image.cfg 2>/dev/null | wc -l)" = 0 ]; then
                echo "Can't find image.cfg"
            else
                echo "Using aml_image_v2_packer..."
                bin/aml_image_v2_packer -r level1/image.cfg level1 out/"$file_name.img"
            fi
            ;;
        *)
            echo "Invalid choice."
            exit 1
            ;;
    esac
    echo "Done."
  fi
elif [ $level = 2 ]; then
  if [ ! -d level2 ]; then
    echo "Unpack level 2 first"
    exit 0
  fi

  if [ ! -f level1/super.PARTITION ]; then
    for part in system system_ext vendor product odm oem oem_a; do
      if [ -d level2/$part ]; then
        echo "Creating $part image"
        size=$(cat level2/config/${part}_size.txt)
        if [ ! -z "$size" ]; then
          ./common/make_image.sh -s $part $size level2/$part/ level1/$part.PARTITION
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
        ./common/make_image.sh -s $part $size level2/$part/ level1/$part.PARTITION
      fi
      echo "Done."
    fi
  done

  ./common/make_super.sh level1/super.PARTITION amlogic

  rm -rf level2/*.txt
elif [ $level = 3 ]; then
  if [ ! -d level3 ]; then
    echo "Unpack level 3 first"
    exit 0
  fi

  if [ -d level3/logo ]; then
    bin/logo_img_packer -r level3/logo level1/logo.PARTITION
  fi

  if [ -d level3/devtree ]; then
    DIR='level3/devtree/'
    count=$(ls -1U $DIR | wc -l)
    if [ $count -gt 1 ]; then
      for filename in level3/devtree/*.dts; do
        [ -e "$filename" ] || continue
        name=$(basename $filename .dts)
        dtc -I dts -O dtb level3/devtree/$name.dts -o "$(echo level3/devtree/$name.dtb | sed -e s'/\.dts/\.dtb/')"
        bin/dtbTool -o level1/_aml_dtb.PARTITION level3/devtree/
      done
    else
      dtc -I dts -O dtb level3/devtree/single.dts -o "$(echo level1/_aml_dtb.PARTITION | sed -e s'/\.dts/\.dtb/')"
    fi
  fi

  if [ -d level3/meson1 ]; then
    DIR='level3/meson1/'
    count=$(ls -1U $DIR | wc -l)
    if [ $count -gt 1 ]; then
      for filename in level3/meson1/*.dts; do
        [ -e "$filename" ] || continue
        name=$(basename $filename .dts)
        dtc -I dts -O dtb level3/meson1/$name.dts -o "$(echo level3/meson1/$name.dtb | sed -e s'/\.dts/\.dtb/')"
        bin/dtbTool -o level1/meson1.dtb level3/meson1/
      done
    else
      dtc -I dts -O dtb level3/meson1/single.dts -o "$(echo level1/meson1.dtb | sed -e s'/\.dts/\.dtb/')"
    fi
  fi

  if [ -f level1/_aml_dtb.PARTITION ]; then
    echo "Do you want to compress _aml_dtb.PARTITION? (y/n)"
    read answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      size=$(du -b level1/_aml_dtb.PARTITION | cut -f1)
      if [ $size -gt 196607 ]; then
        gzip -nc level1/_aml_dtb.PARTITION >level1/_aml_dtb.PARTITION.gzip
        mv level1/_aml_dtb.PARTITION.gzip level1/_aml_dtb.PARTITION
      fi
      rm -rf level3/devtree/*.dtb
    fi
  fi

  if [ -f level1/meson1.dtb ]; then
    echo "Do you want to compress _aml_dtb.PARTITION? (y/n)"
    echo "Not recommeded if not supported"
    read answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      msize=$(du -b level1/meson1.dtb | cut -f1)
      if [ $msize -gt 196607 ]; then
        gzip -nc level1/meson1.dtb >level1/meson1.dtb.gzip
        mv level1/meson1.dtb.gzip level1/meson1.dtb
      fi
      rm -rf level3/meson1/*.dtb
    fi
  fi

  for part in boot recovery vendor_boot boot_a recovery_a vendor_boot_a; do
    if [ -d level3/${part} ]; then
      if [ -f "level3/$part/split_img/$part.PARTITION-dtb" ]; then
        cp level1/_aml_dtb.PARTITION "level3/$part/split_img/$part.PARTITION-dtb"
      fi
      if [ -f "level3/$part/split_img/$part.PARTITION-second" ]; then
        cp level1/_aml_dtb.PARTITION "level3/$part/split_img/$part.PARTITION-second"
      fi
      bin/aik/cleanup.sh
      cp -r level3/$part/ramdisk bin/aik/
      cp -r level3/$part/split_img bin/aik/
      bin/aik/repackimg.sh
      mv bin/aik/image-new.img level1/${part}.PARTITION
      bin/aik/cleanup.sh
    fi
  done

  echo "Done."
elif [ $level = "q" -o $level = "Q" ]; then
  exit
fi

while true; do ./common/write_perm.sh && ./amlpack.sh && break; done

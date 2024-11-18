#!/usr/bin/sudo bash

set -e

echo "....................."
echo "Rockchip Kitchen"
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
    echo "Supported models:"
    echo "px30            RKPX30"
    echo "px3se           RK312A"
    echo "rk1808          RK180A"
    echo "rk3036          RK303A"
    echo "rk3128h         RK312X"
    echo "rk312*          RK312A"
    echo "rk322*          RK322A"
    echo "rk3229          RK3229"
    echo "rk3288          RK320A"
    echo "rk3308          RK3308"
    echo "rk3326          RK3326"
    echo "rk3328          RK322H"
    echo "rk3368          RK330A"
    echo "rk3399*         RK330C"
    echo "rk356*          RK3568"
    echo "rk3588          RK3588"
    echo "rk3562          RK3562"
    echo "rk3528          RK3528"
    echo "rk3576          RK3576"
    echo "rv1126_rv1109   RK1126"
    echo "If your model starts with rk312* then its RK312A"
    echo "Enter your chip model, Eg: RK312X:"
    read chip
    file_name=$(cat level1/projectname.txt)
    if [ $chip ]; then
      if grep -q trust.img "level1/package-file"; then
        if [ ! -f "level1/Image/trust.img" ]; then
          touch level1/Image/trust.img
        fi
      fi
      if [ -f "level1/parameter.txt" ] && grep -q "Image/parameter.txt" "level1/package-file"; then
        mv "level1/parameter.txt" "level1/Image/parameter.txt"
      fi
      if [ -f "level1/MiniLoaderAll.bin" ] && grep -q "Image/MiniLoaderAll.bin" "level1/package-file"; then
        mv "level1/MiniLoaderAll.bin" "level1/Image/MiniLoaderAll.bin"
      fi
      bin/afptool -pack level1/ level1/Image/update.img
      bin/rkImageMaker -$chip level1/Image/MiniLoaderAll.bin level1/Image/update.img out/"$file_name.img" -os_type:androidos
    else
      echo "Error: Chip is invalid, must be started with RK"
      exit 0
    fi

    echo "Done."
  fi
elif [ $level = 2 ]; then
  if [ ! -d level2 ]; then
    echo "Unpack level 2 first"
    exit 0
  fi

  if [ ! -f level1/Image/super.img ]; then
    for part in system system_ext vendor product odm oem oem_a; do
      if [ -d level2/$part ]; then
        echo "Creating $part image"
        size=$(cat level2/config/${part}_size.txt)
        fs=level2/config/${part}_fs_config
        fc=level2/config/${part}_file_contexts
        if [ ! -z "$size" ]; then
          bin/make_ext4fs -J -L $part -T -1 -S $fc -C $fs -l $size -a $part level1/Image/$part.img level2/$part
        fi
        echo "Done."
      fi
    done
  fi

  for part in oem_a odm_ext_a odm_ext_b; do
    if [ -d level2/$part ]; then
      echo "Creating $part image"
      size=$(cat level2/config/${part}_size.txt)
      fs=level2/config/${part}_fs_config
      fc=level2/config/${part}_file_contexts
      if [ ! -z "$size" ]; then
        bin/make_ext4fs -J -L $part -T -1 -S $fc -C $fs -l $size -a $part level1/Image/$part.img level2/$part
      fi
      echo "Done."
    fi
  done

  if [ -f level1/Image/super.img ]; then
    for filename in level2/*.img; do
      part="$(basename "$filename" .img)"
      if [ -d level2/$part ]; then
        msize=$(du -sk level2/$part | cut -f1 | gawk '{$1*=1024;$1=int($1*1.08);printf $1}')
        fs=level2/config/${part}_fs_config
        fc=level2/config/${part}_file_contexts
        echo "Creating $part image"
        if [ $msize -lt 1048576 ]; then
          msize=1048576
        fi
        bin/make_ext4fs -J -L $part -T -1 -S $fc -C $fs -l $msize -a $part level2/$part.img level2/$part/
        bin/resize2fs -M level2/${part}.img
        echo "Done."
      fi
    done
  fi

  if [ -f level2/config/super_type.txt ]; then
    supertype=$(cat level2/config/super_type.txt)
  fi
  if [ ! -z "$supertype" ] && [ $supertype -eq "3" ]; then
    metadata_size=65536
    metadata_slot=3
    supername="super"
    supersize=$(cat level2/config/super_size.txt)
    superusage1=$(du -cb level2/*.img | grep total | cut -f1)
    command="bin/lpmake --metadata-size $metadata_size --super-name $supername --metadata-slots $metadata_slot"
    command="$command --device $supername:$supersize --group rockchip_dynamic_partitions_a:$superusage1"

    for filename in level2/*_a.img; do
      part="$(basename "$filename" .img)"
      if [ -f level2/$part.img ]; then
        asize=$(du -skb level2/$part.img | cut -f1)
        if [ $asize -gt 0 ]; then
          command="$command --partition $part:readonly:$asize:rockchip_dynamic_partitions_a --image $part=level2/$part.img"
        fi
      fi
    done

    superusage2=$(expr $supersize - $superusage1)
    command="$command --group rockchip_dynamic_partitions_b:$superusage2"

    for filename in level2/*_b.img; do
      part="$(basename "$filename" .img)"
      if [ -f level2/$part.img ]; then
        bsize=$(du -skb level2/$part.img | cut -f1)
        if [ $bsize -eq 0 ]; then
          command="$command --partition $part:readonly:$bsize:rockchip_dynamic_partitions_b"
        fi
      fi
    done

    if [ $superusage2 -ge $supersize ]; then
      echo "Unable to create super image, recreated images are too big."
      echo "Cleanup some files before retrying"
      echo "Needed space: $superusage1"
      echo "Available maximum space: $supersize"
      exit 0
    fi

    command="$command --virtual-ab --sparse --output level1/Image/super.img"
    if [ -f level1/Image/super.img ]; then
      $($command)
    fi
  elif [ ! -z "$supertype" ] && [ $supertype -eq "2" ]; then
    metadata_size=65536
    metadata_slot=2
    supername="super"
    supersize=$(cat level2/config/super_size.txt)
    superusage=$(du -cb level2/*.img | grep total | cut -f1)
    command="bin/lpmake --metadata-size $metadata_size --super-name $supername --metadata-slots $metadata_slot"
    command="$command --device $supername:$supersize --group rockchip_dynamic_partitions:$superusage"

    for part in system_ext system odm product vendor; do
      if [ -f level2/$part.img ]; then
        asize=$(du -skb level2/$part.img | cut -f1)
        if [ $asize -gt 0 ]; then
          command="$command --partition $part:readonly:$asize:rockchip_dynamic_partitions --image $part=level2/$part.img"
        fi
      fi
    done

    if [ $superusage -ge $supersize ]; then
      echo "Unable to create super image, recreated images are too big."
      echo "Cleanup some files before retrying"
      echo "Needed space: $superusage1"
      echo "Available maximum space: $supersize"
      exit 0
    fi

    command="$command --sparse --output level1/Image/super.img"
    if [ -f level1/Image/super.img ]; then
      $($command)
    fi
  fi

  rm -rf level2/*.txt
elif [ $level = 3 ]; then
  if [ ! -d level3 ]; then
    echo "Unpack level 3 first"
    exit 0
  fi

  if [ -d "level3/resource" ]; then
    bin/resource_tool --pack --root=level3/resource --image=level1/Image/resource.img $(find level3/resource -type f | sort)
  fi

  for part in boot recovery vendor_boot boot_a recovery_a vendor_boot_a; do
    if [ -d "level3/resource_${part}" ]; then
      bin/resource_tool --pack --root=level3/resource_${part} --image=level3/$part/split_img/$part.img-second $(find level3/resource_${part} -type f | sort)
    fi
    if [ -d level3/${part} ]; then
      bin/aik/cleanup.sh
      cp -r level3/$part/ramdisk bin/aik/
      cp -r level3/$part/split_img bin/aik/
      bin/aik/repackimg.sh
      mv bin/aik/image-new.img level1/Image/${part}.img
      bin/aik/cleanup.sh
    fi
  done

  echo "Done."
elif [ $level = "q" -o $level = "Q" ]; then
  exit
fi

while true; do ./write_perm.sh && ./rkpack.sh && break; done

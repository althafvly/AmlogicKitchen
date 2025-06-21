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
    for part in system system_ext vendor vendor_dlkm product odm odm_dlkm oem oem_a; do
      if [ -d level2/$part ]; then
        echo "Creating $part image"
        size=$(cat level2/config/${part}_size.txt)
        if [ ! -z "$size" ]; then
          ./common/make_image.sh $part $size level2/$part/ level1/Image/$part.img
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
        ./common/make_image.sh $part $size level2/$part/ level1/Image/$part.img
      fi
      echo "Done."
    fi
  done

  ./common/make_super.sh level1/Image/super.img rockchip

  rm -rf level2/*.txt
elif [ $level = 3 ]; then
  if [ ! -d level3 ]; then
    echo "Unpack level 3 first"
    exit 0
  fi

  if [ -d "level3/resource" ]; then
    bin/resource_tool --pack --root=level3/resource --image=level1/Image/resource.img $(find level3/resource -type f | sort)
  fi

  ./common/pack_boot.sh

  echo "Done."
elif [ $level = "q" -o $level = "Q" ]; then
  exit
fi

while true; do ./common/write_perm.sh && ./rkpack.sh && break; done

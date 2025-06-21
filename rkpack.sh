#!/usr/bin/sudo bash

set -e

echo "....................."
echo "Rockchip Kitchen"
echo "....................."
read -p "Select level 1, 2, 3 or q/Q to exit: " level

case "$level" in
  1)
    if [[ ! -d level1 ]]; then
      echo "Can't find level1 folder"
      exit 1
    fi

    [[ -d out ]] || { echo "Created out folder"; mkdir out; }

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
    echo "Note: If your model starts with rk312*, choose RK312A"

    read -p "Enter your chip model (e.g. RK312X): " chip
    file_name=$(cat level1/projectname.txt)

    if [[ "$chip" =~ ^RK ]]; then
      [[ -f level1/package-file && ! -f level1/Image/trust.img ]] && \
        grep -q trust.img level1/package-file && touch level1/Image/trust.img

      [[ -f level1/parameter.txt && -f level1/package-file ]] && \
        grep -q "Image/parameter.txt" level1/package-file && \
        mv level1/parameter.txt level1/Image/parameter.txt

      [[ -f level1/MiniLoaderAll.bin && -f level1/package-file ]] && \
        grep -q "Image/MiniLoaderAll.bin" level1/package-file && \
        mv level1/MiniLoaderAll.bin level1/Image/MiniLoaderAll.bin

      bin/afptool -pack level1/ level1/Image/update.img
      bin/rkImageMaker -"$chip" level1/Image/MiniLoaderAll.bin level1/Image/update.img out/"$file_name.img" -os_type:androidos
      echo "Done."
    else
      echo "Error: Chip is invalid, must start with RK"
      exit 1
    fi
    ;;

  2)
    if [[ ! -d level2 ]]; then
      echo "Unpack level 2 first"
      exit 1
    fi

    if [[ ! -f level1/Image/super.img ]]; then
      for part in system system_ext vendor vendor_dlkm product odm odm_dlkm oem oem_a; do
        [[ -d level2/$part ]] || continue
        echo "Creating $part image"
        size=$(<level2/config/${part}_size.txt)
        [[ -n "$size" ]] && ./common/make_image.sh "$part" "$size" level2/$part/ level1/Image/$part.img
        echo "Done."
      done
    fi

    for part in oem_a odm_ext_a odm_ext_b; do
      [[ -d level2/$part ]] || continue
      echo "Creating $part image"
      size=$(<level2/config/${part}_size.txt)
      [[ -n "$size" ]] && ./common/make_image.sh "$part" "$size" level2/$part/ level1/Image/$part.img
      echo "Done."
    done

    ./common/make_super.sh level1/Image/super.img rockchip
    rm -f level2/*.txt
    ;;

  3)
    if [[ ! -d level3 ]]; then
      echo "Unpack level 3 first"
      exit 1
    fi

    if [[ -d level3/resource ]]; then
      echo "Packing resource.img"
      bin/resource_tool --pack --root=level3/resource \
        --image=level1/Image/resource.img \
        $(find level3/resource -type f | sort)
    fi

    ./common/pack_boot.sh
    echo "Done."
    ;;

  q|Q)
    exit 0
    ;;

  *)
    echo "Invalid selection"
    exit 1
    ;;
esac

# Always run final step
while true; do
  ./common/write_perm.sh && ./rkpack.sh && break
done

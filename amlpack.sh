#!/usr/bin/sudo bash

set -e

echo "....................."
echo "Amlogic Kitchen"
echo "....................."
read -p "Select level 1, 2, 3 or q/Q to exit: " level

case "$level" in
  1)
    if [[ ! -d level1 ]]; then
      echo "Can't find level1 folder"
      exit 1
    fi

    [[ -d out ]] || { echo "Created out folder"; mkdir out; }

    file_name=$(<level1/projectname.txt)

    echo "Choose pack tool:"
    echo "1) ampack"
    echo "2) aml_image_v2_packer"
    read -p "Enter choice [1 or 2]: " choice

    case "$choice" in
      1)
        echo "Using ampack..."
        rm -f level1/projectname.txt
        bin/ampack pack level1 "out/${file_name}.img"
        echo "$file_name" >level1/projectname.txt
        ;;
      2)
        if [[ ! -f level1/image.cfg ]]; then
          echo "Can't find image.cfg"
        else
          echo "Using aml_image_v2_packer..."
          bin/aml_image_v2_packer -r level1/image.cfg level1 "out/${file_name}.img"
        fi
        ;;
      *)
        echo "Invalid choice"
        exit 1
        ;;
    esac
    echo "Done."
    ;;

  2)
    if [[ ! -d level2 ]]; then
      echo "Unpack level 2 first"
      exit 1
    fi

    parts_common=(system system_ext vendor product odm oem oem_a)
    parts_extra=(oem_a odm_ext_a odm_ext_b)

    if [[ ! -f level1/super.PARTITION ]]; then
      for part in "${parts_common[@]}"; do
        [[ -d level2/$part ]] || continue
        echo "Creating $part image"
        size=$(<level2/config/${part}_size.txt)
        [[ -n "$size" ]] && ./common/make_image.sh -s "$part" "$size" "level2/$part/" "level1/$part.PARTITION"
        echo "Done."
      done
    fi

    for part in "${parts_extra[@]}"; do
      [[ -d level2/$part ]] || continue
      echo "Creating $part image"
      size=$(<level2/config/${part}_size.txt)
      [[ -n "$size" ]] && ./common/make_image.sh -s "$part" "$size" "level2/$part/" "level1/$part.PARTITION"
      echo "Done."
    done

    ./common/make_super.sh level1/super.PARTITION amlogic
    rm -f level2/*.txt
    ;;

  3)
    if [[ ! -d level3 ]]; then
      echo "Unpack level 3 first"
      exit 1
    fi

    # logo
    [[ -d level3/logo ]] && bin/logo_img_packer -r level3/logo level1/logo.PARTITION

    # devtree / meson1
    for tree in devtree meson1; do
      dir="level3/$tree"
      outfile="level1/_aml_dtb.PARTITION"
      [[ $tree == "meson1" ]] && outfile="level1/meson1.dtb"

      [[ -d "$dir" ]] || continue
      files=($dir/*.dts)
      if [[ ${#files[@]} -gt 1 ]]; then
        for dts in "${files[@]}"; do
          dtb="${dts%.dts}.dtb"
          dtc -I dts -O dtb "$dts" -o "$dtb"
        done
        bin/dtbTool -o "$outfile" "$dir/"
      else
        dtc -I dts -O dtb "$dir/single.dts" -o "$outfile"
      fi
    done

    # Compression
    for f in "_aml_dtb.PARTITION" "meson1.dtb"; do
      [[ -f level1/$f ]] || continue
      echo "Do you want to compress $f? (y/n)"
      [[ "$f" == "meson1.dtb" ]] && echo "Not recommended unless supported"
      read answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        size=$(du -b "level1/$f" | cut -f1)
        if [[ $size -gt 196607 ]]; then
          gzip -nc "level1/$f" >"level1/$f.gzip"
          mv "level1/$f.gzip" "level1/$f"
        fi
        rm -f level3/${f%.*}/*.dtb
      fi
    done

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

# Final step
while true; do ./common/write_perm.sh && ./amlpack.sh && break; done

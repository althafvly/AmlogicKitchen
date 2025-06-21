#!/usr/bin/sudo bash

set -e

echo "....................."
echo "Amlogic Kitchen"
echo "....................."
read -p "Select level 1, 2, 3 or q/Q to exit: " level

case "$level" in
  1)
    [[ -d level1 ]] && { echo "Deleting existing level1"; rm -rf level1; }
    mkdir level1

    echo "....................."
    echo "Amlogic Kitchen"
    echo "....................."

    [[ -d in ]] || { echo "Creating /in folder"; mkdir in; }

    img_list=(in/*.img)
    if [[ ${#img_list[@]} -eq 0 || ! -f "${img_list[0]}" ]]; then
      echo "No .img files found in /in"
      exit 0
    fi

    rename 's/ /_/g' in/*.img
    echo "Files in input dir (*.img):"
    count=1
    for entry in in/*.img; do
      name=$(basename "$entry" .img)
      echo "$count - $name"
      ((count++))
    done

    echo "....................."
    read -p "Enter a file name: " projectname
    [[ -f "in/$projectname.img" ]] || { echo "File not found."; exit 1; }

    echo "Choose unpack tool:"
    echo "1) ampack"
    echo "2) aml_image_v2_packer"
    read -p "Enter choice [1 or 2]: " choice

    case "$choice" in
      1) echo "Using ampack..."; bin/ampack unpack "in/$projectname.img" level1 ;;
      2) echo "Using aml_image_v2_packer..."; bin/aml_image_v2_packer -d "in/$projectname.img" level1 ;;
      *) echo "Invalid choice."; exit 1 ;;
    esac

    echo "$projectname" > level1/projectname.txt
    echo "Done."
    ;;

  2)
    [[ -d level1 ]] || { echo "Unpack level 1 first"; exit 1; }
    [[ -d level2 ]] && { echo "Deleting existing level2"; rm -rf level2; }
    mkdir -p level2/config

    ./common/extract_images.sh level1 level2

    [[ -f level1/super.PARTITION ]] && ./common/extract_super.sh level1/super.PARTITION level2/

    echo "Done."
    ;;

  3)
    [[ -d level1 ]] || { echo "Unpack level 1 first"; exit 1; }
    [[ -d level3 ]] && rm -rf level3
    mkdir level3

    ./common/unpack_boot.sh

    if [[ -f level1/logo.PARTITION ]]; then
      mkdir level3/logo
      bin/logo_img_packer -d level1/logo.PARTITION level3/logo
    fi

    if [[ ! -f level1/_aml_dtb.PARTITION ]]; then
      read -p "Do you want to copy dtb to level1? (y/n): " answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        for part in boot recovery vendor_boot boot_a recovery_a vendor_boot_a; do
          [[ -f level1/_aml_dtb.PARTITION ]] && break
          for suffix in PARTITION-dtb PARTITION-second; do
            src="level3/$part/split_img/$part.$suffix"
            [[ -f "$src" ]] && cp "$src" level1/_aml_dtb.PARTITION && break
          done
        done
      fi
    fi

    if [[ -f level1/_aml_dtb.PARTITION ]]; then
      read -p "Do you want to unpack _aml_dtb.PARTITION? (y/n): " answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        mkdir -p level3/devtree
        7zz x level1/_aml_dtb.PARTITION -y || true
        [[ -d _aml_dtb ]] && bin/dtbSplit _aml_dtb level3/devtree/ && rm -rf _aml_dtb
        bin/dtbSplit level1/_aml_dtb.PARTITION level3/devtree/

        if [[ "$(ls -A level3/devtree/)" ]]; then
          for dtb in level3/devtree/*.dtb; do
            [[ -e "$dtb" ]] || continue
            dts="${dtb%.dtb}.dts"
            dtc -I dtb -O dts "$dtb" -o "$dts"
            rm -f "$dtb"
          done
        else
          dtc -I dtb -O dts level1/_aml_dtb.PARTITION -o level3/devtree/single.dts
        fi
      fi
    fi

    if [[ -f level1/meson1.dtb ]]; then
      read -p "Do you want to unpack meson1.dtb? (y/n): " answer
      if [[ "$answer" =~ ^[Yy]$ ]]; then
        mkdir -p level3/meson1
        bin/dtbSplit level1/meson1.dtb level3/meson1/

        if [[ "$(ls -A level3/meson1/)" ]]; then
          for dtb in level3/meson1/*.dtb; do
            [[ -e "$dtb" ]] || continue
            dts="${dtb%.dtb}.dts"
            dtc -I dtb -O dts "$dtb" -o "$dts"
            rm -f "$dtb"
          done
        else
          dtc -I dtb -O dts level1/meson1.dtb -o level3/meson1/single.dts
        fi
      fi
    fi

    echo "Done."
    ;;

  q|Q) exit 0 ;;
  *) echo "Invalid option." ;;
esac

# Always run final steps after any level
while true; do
  ./common/write_perm.sh && ./amlunpack.sh && break
done

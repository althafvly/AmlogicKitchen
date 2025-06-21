#!/usr/bin/sudo bash

set -e

echo "....................."
echo "Rockchip Kitchen"
echo "....................."
read -p "Select level 1, 2, 3 or q/Q to exit: " level

case "$level" in
  1)
    [[ -d level1 ]] && { echo "Deleting existing level1"; rm -rf level1; }
    mkdir -p level1/Image

    echo "....................."
    echo "Rockchip Kitchen"
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
    [[ -f "in/$projectname.img" ]] || { echo "File not found: $projectname.img"; exit 1; }

    echo "$projectname" > level1/projectname.txt

    bin/rkImageMaker -unpack "in/$projectname.img" level1
    bin/afptool -unpack level1/firmware.img level1

    rm -f level1/boot.bin level1/firmware.img
    echo "Done."
    ;;

  2)
    [[ -d level1 ]] || { echo "Unpack level 1 first"; exit 1; }

    [[ -d level2 ]] && { echo "Deleting existing level2"; rm -rf level2; }
    mkdir -p level2/config

    ./common/extract_images.sh "level1/Image" "level2"

    [[ -f level1/Image/super.img ]] && ./common/extract_super.sh level1/Image/super.img level2/
    echo "Done."
    ;;

  3)
    [[ -d level1 ]] || { echo "Unpack level 1 first"; exit 1; }

    [[ -d level3 ]] && rm -rf level3
    mkdir level3

    ./common/unpack_boot.sh

    if [[ -f level1/Image/resource.img ]]; then
      mkdir -p level3/resource
      bin/resource_tool --unpack --verbose \
        --image=level1/Image/resource.img level3/resource \
        2>&1 | grep entry | sed 's/^.*://' | xargs echo
    fi

    echo "Done."
    ;;

  q|Q) exit 0 ;;
  *) echo "Invalid option." ;;
esac

# Final step (post-processing hook)
while true; do
  ./common/write_perm.sh && ./rkunpack.sh && break
done

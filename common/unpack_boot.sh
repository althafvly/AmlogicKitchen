#!/bin/bash

set -e

foldername=$(<level1/projectname.txt).img.dump
parts="boot init_boot recovery vendor_boot boot_a init_boot_a recovery_a vendor_boot_a"

for part in $parts; do
  for ext in fex PARTITION img; do
    case $ext in
      fex)       file="level1/$foldername/$part.fex" ;;
      PARTITION) file="level1/$part.PARTITION" ;;
      img)       file="level1/Image/$part.img" ;;
    esac

    [ -f "$file" ] || continue

    out_dir="level3/$part"
    mkdir -p "$out_dir"
    bin/aik/unpackimg.sh "$file"
    mv -i bin/aik/ramdisk "$out_dir/"
    mv -i bin/aik/split_img "$out_dir/"

    # Only for .img with second stage
    if [[ $ext == "img" && -f $out_dir/split_img/$part.img-second ]]; then
      res_dir="level3/resource_$part"
      mkdir -p "$res_dir"
      bin/resource_tool --unpack --verbose \
        --image="$out_dir/split_img/$part.img-second" "$res_dir" \
        2>&1 | grep entry | sed 's/^.*://' | xargs echo
    fi

    break
  done
done

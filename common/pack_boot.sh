#!/bin/bash

set -e

# Add bin/ to LD_LIBRARY_PATH if not already present
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
[[ ":$LD_LIBRARY_PATH:" != *":$ROOT_DIR/bin:"* ]] && export LD_LIBRARY_PATH="$ROOT_DIR/bin${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

foldername=$(<level1/projectname.txt).img.dump
parts="boot init_boot recovery vendor_boot boot_a init_boot_a recovery_a vendor_boot_a"

repack() {
  local part=$1 output=$2
  bin/aik/cleanup.sh
  cp -r "level3/$part"/{ramdisk,split_img} bin/aik/
  bin/aik/repackimg.sh
  mv -f bin/aik/*-new.img "$output" 2>/dev/null || {
    echo "⚠️ No output image found for $part"
  }
  bin/aik/cleanup.sh
}

for part in $parts; do
  part_dir="level3/$part"
  [[ -d $part_dir ]] || continue

  # Patch DTB and second stage for .PARTITION
  for suffix in dtb second; do
    patch_file="$part_dir/split_img/$part.PARTITION-$suffix"
    [[ -f $patch_file ]] && cp level1/_aml_dtb.PARTITION "$patch_file"
  done

  # Pack resources if applicable
  resource_dir="level3/resource_$part"
  [[ -d $resource_dir ]] && bin/resource_tool --pack \
    --root="$resource_dir" \
    --image="$part_dir/split_img/$part.img-second" \
    $(find "$resource_dir" -type f | sort)

  # Repack to available output targets
  for type in fex img PARTITION; do
    case $type in
      fex)       out="level1/$foldername/$part.fex" ;;
      img)       out="level1/Image/$part.img" ;;
      PARTITION) out="level1/$part.PARTITION" ;;
    esac
    [[ -d $(dirname "$out") ]] && repack "$part" "$out"
  done
done

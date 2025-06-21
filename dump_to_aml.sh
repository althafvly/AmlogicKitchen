#!/usr/bin/sudo bash

set -e

echo "....................."
echo "Amlogic Dump to Image Script"
echo "....................."

# Super image not supported
if [[ -f dump/super.img ]]; then
  echo "super.img is not supported yet."
  exit 0
fi

# Reset level folders
for dir in level1 level2 level3; do
  echo "Resetting $dir"
  rm -rf "$dir" && mkdir "$dir"
done

[[ -d out ]] || mkdir out

# Copy PARTITION files
for part in boot recovery vendor_boot logo dtbo vbmeta bootloader odm odm_ext oem product vendor system system_ext vbmeta_system; do
  [[ -f dump/$part.img ]] && cp "dump/$part.img" "level1/$part.PARTITION"
done

# DTB
[[ -f dump/dtb.img ]] && cp dump/dtb.img level1/_aml_dtb.PARTITION

# Required files
cp bin/aml_sdc_burn.ini level1/

# Generate image.cfg
configname="level1/image.cfg"
echo "[LIST_NORMAL]" >"$configname"

for file in DDR.USB UBOOT.USB aml_sdc_burn.UBOOT meson1.PARTITION platform.conf; do
  if [[ ! -f level1/$file ]]; then
    echo "$file is missing. Copy it to level1 directory."
    read -p "Press Enter to continue..."
  fi
done

[[ -f level1/DDR.USB ]] && echo 'file="DDR.USB"	main_type="USB"	sub_type="DDR"' >>"$configname"
[[ -f level1/UBOOT.USB ]] && echo 'file="UBOOT.USB"	main_type="USB"	sub_type="UBOOT"' >>"$configname"
[[ -f level1/aml_sdc_burn.UBOOT ]] && echo 'file="aml_sdc_burn.UBOOT"	main_type="UBOOT"	sub_type="aml_sdc_burn"' >>"$configname"
[[ -f level1/aml_sdc_burn.ini ]] && echo 'file="aml_sdc_burn.ini"	main_type="ini"	sub_type="aml_sdc_burn"' >>"$configname"
[[ -f level1/meson1.PARTITION ]] && echo 'file="meson1.PARTITION"	main_type="dtb"	sub_type="meson1"' >>"$configname"
[[ -f level1/platform.conf ]] && echo 'file="platform.conf"	main_type="conf"	sub_type="platform"' >>"$configname"

# Add PARTITION entries
for part in _aml_dtb boot vendor_boot recovery bootloader dtbo logo odm odm_ext oem product vendor system system_ext vbmeta vbmeta_system; do
  [[ -f level1/$part.PARTITION ]] && \
    echo "file=\"$part.PARTITION\"	main_type=\"PARTITION\"	sub_type=\"$part\"" >>"$configname"
done

echo "[LIST_VERIFY]" >>"$configname"

# Extract images
./common/extract_images.sh level1 level2

# Repack boot & recovery
for part in boot recovery boot_a recovery_a; do
  img=level1/${part}.PARTITION
  if [[ -f $img ]]; then
    mkdir -p level3/$part
    echo "Repacking $part"
    bin/aik/unpackimg.sh "$img" >/dev/null 2>&1
    bin/aik/repackimg.sh >/dev/null 2>&1
    mv bin/aik/image-new.img "$img"
    bin/aik/cleanup.sh >/dev/null 2>&1
  fi
done

# Repack logo
if [[ -f level1/logo.PARTITION ]]; then
  mkdir -p level3/logo
  echo "Repacking logo"
  bin/logo_img_packer -d level1/logo.PARTITION level3/logo >/dev/null 2>&1
  bin/logo_img_packer -r level3/logo level1/logo.PARTITION >/dev/null 2>&1
fi

# Restore _aml_dtb.PARTITION from split_img fallback
if [[ ! -f level1/_aml_dtb.PARTITION ]]; then
  for src in boot recovery; do
    for suffix in dtb second; do
      file=$(find level3/$src*/split_img/*-$suffix 2>/dev/null | head -n1)
      [[ -f $file ]] && cp "$file" level1/_aml_dtb.PARTITION && break 2
    done
  done
fi

# Repack DTB
if [[ -f level1/_aml_dtb.PARTITION ]]; then
  echo "Repacking _aml_dtb.PARTITION..."
  mkdir -p level3/devtree

  # Unpack dtb
  7zz x level1/_aml_dtb.PARTITION -y >/dev/null 2>&1 || true
  bin/dtbSplit _aml_dtb level3/devtree/ >/dev/null 2>&1 || true
  rm -rf _aml_dtb
  bin/dtbSplit level1/_aml_dtb.PARTITION level3/devtree/ >/dev/null 2>&1

  if ls level3/devtree/*.dtb >/dev/null 2>&1; then
    for dtb in level3/devtree/*.dtb; do
      [[ -e "$dtb" ]] || continue
      base=${dtb%.dtb}
      dtc -I dtb -O dts "$dtb" -o "${base}.dts" >/dev/null 2>&1
      rm -f "$dtb"
    done
  else
    dtc -I dtb -O dts level1/_aml_dtb.PARTITION -o level3/devtree/single.dts >/dev/null 2>&1
  fi

  # Repack from DTS
  count=$(ls -1U level3/devtree/ | wc -l)
  if [[ $count -gt 1 ]]; then
    for dts in level3/devtree/*.dts; do
      base=${dts%.dts}
      dtc -I dts -O dtb "$dts" -o "${base}.dtb" >/dev/null 2>&1
    done
    bin/dtbTool -o level1/_aml_dtb.PARTITION level3/devtree/ >/dev/null 2>&1
  else
    dtc -I dts -O dtb level3/devtree/single.dts -o level1/_aml_dtb.PARTITION >/dev/null 2>&1
  fi

  # Compress if too big
  size=$(du -b level1/_aml_dtb.PARTITION | cut -f1)
  if [[ $size -gt 196607 ]]; then
    gzip -nc level1/_aml_dtb.PARTITION >level1/_aml_dtb.PARTITION.gzip
    mv level1/_aml_dtb.PARTITION.gzip level1/_aml_dtb.PARTITION
  fi

  rm -f level3/devtree/*.dtb
fi

# Final pack
echo "Enter output image name (without extension):"
read filename
bin/aml_image_v2_packer -r level1/image.cfg level1 out/"$filename.img"

echo "....................."
echo "Done."
./common/write_perm.sh

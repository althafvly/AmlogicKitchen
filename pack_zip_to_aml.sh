#!/usr/bin/sudo bash

set -e

# Clean and prepare working directories
for dir in level1 tmp; do
  echo "Resetting $dir"
  rm -rf "$dir"
  mkdir "$dir"
done

[[ -d in ]] || { echo "Creating /in folder"; mkdir in; }

# Check for input zip files
count_file=$(ls -1 in/*.zip 2>/dev/null | wc -l)
if [[ "$count_file" = 0 ]]; then
  echo "No files found in /in"
  exit 1
fi

echo "....................."
echo "Amlogic Kitchen"
echo "....................."
echo "Available input files (*.zip):"
count=0
for entry in in/*.zip; do
  count=$((count + 1))
  name=$(basename "$entry" .zip)
  echo "$count - $name"
done

echo "....................."
read -p "Enter a file name (without .zip): " projectname
echo "$projectname" >level1/projectname.txt

zipfile="in/$projectname.zip"
if [[ ! -f "$zipfile" ]]; then
  echo "Can't find the file: $zipfile"
  exit 1
fi

7zz x "$zipfile" -otmp

# Clean unnecessary files
rm -rf tmp/{compatibility.zip,file_contexts.bin} tmp/{META-INF,system}

# Convert sparse dat to .img
for part in odm oem product vendor system system_ext; do
  if [[ -f tmp/$part.transfer.list ]]; then
    if [[ -f tmp/$part.new.dat.br ]]; then
      brotli -d -o tmp/$part.new.dat tmp/$part.new.dat.br
      rm -f tmp/$part.new.dat.br
    fi
    python bin/sdat2img.py tmp/$part.transfer.list tmp/$part.new.dat tmp/$part.img
    rm -f tmp/$part.new.dat tmp/$part.transfer.list tmp/$part.patch.dat 2>/dev/null
    img2simg tmp/$part.img tmp/${part}_simg.img
    mv tmp/${part}_simg.img tmp/$part.img
  fi
done

# Optional dt.img to dtb
[[ -f tmp/dt.img ]] && cp tmp/dt.img level1/_aml_dtb.PARTITION

# Move recognized partitions
for part in boot recovery logo dtbo vbmeta bootloader odm odm_ext oem product vendor system system_ext vendor_boot vbmeta_system; do
  [[ -f tmp/$part.img ]] && mv tmp/$part.img level1/$part.PARTITION
done

rm -rf tmp

# Copy burn ini
cp bin/aml_sdc_burn.ini level1/

# Generate image.cfg
configname="level1/image.cfg"
echo "[LIST_NORMAL]" >"$configname"

# Required binaries
for item in DDR.USB UBOOT.USB aml_sdc_burn.UBOOT meson1.PARTITION platform.conf; do
  if [[ ! -f level1/$item ]]; then
    echo "$item is missing. Please copy it to level1/"
    read -p "Press Enter to continue..."
  fi
done

# Add binaries to image.cfg
[[ -f level1/DDR.USB ]] && echo 'file="DDR.USB"	main_type="USB"	sub_type="DDR"' >>"$configname"
[[ -f level1/UBOOT.USB ]] && echo 'file="UBOOT.USB"	main_type="USB"	sub_type="UBOOT"' >>"$configname"
[[ -f level1/aml_sdc_burn.UBOOT ]] && echo 'file="aml_sdc_burn.UBOOT"	main_type="UBOOT"	sub_type="aml_sdc_burn"' >>"$configname"
[[ -f level1/aml_sdc_burn.ini ]] && echo 'file="aml_sdc_burn.ini"	main_type="ini"	sub_type="aml_sdc_burn"' >>"$configname"
[[ -f level1/meson1.PARTITION ]] && echo 'file="meson1.PARTITION"	main_type="dtb"	sub_type="meson1"' >>"$configname"
[[ -f level1/platform.conf ]] && echo 'file="platform.conf"	main_type="conf"	sub_type="platform"' >>"$configname"

# Add partition files
for part in _aml_dtb boot recovery vendor_boot bootloader dtbo logo odm odm_ext oem product vendor system system_ext vbmeta vbmeta_system; do
  [[ -f level1/$part.PARTITION ]] && \
    echo "file=\"$part.PARTITION\"	main_type=\"PARTITION\"	sub_type=\"$part\"" >>"$configname"
done

echo "[LIST_VERIFY]" >>"$configname"

# Read output image filename from user
filename=$(cat level1/projectname.txt)
bin/aml_image_v2_packer -r level1/image.cfg level1 out/"$filename.img"

echo "....................."
echo "Done."

./common/write_perm.sh

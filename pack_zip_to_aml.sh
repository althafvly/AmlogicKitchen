#!/usr/bin/sudo bash

version=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
if [ -z "$version" ]; then
  echo "No Python installed!"
fi

for dir in level1 tmp; do
  if [ -d $dir ]; then
    echo "Deleting existing $dir"
    rm -rf $dir && mkdir $dir
  else
    mkdir $dir
  fi
done

if [ ! -d $dir ]; then
  mkdir $dir
fi

echo "....................."
echo "Amlogic Kitchen"
echo "....................."
if [ ! -d in ]; then
  echo "Can't find /in folder"
  echo "Creating /in folder"
  mkdir in
fi
count_file=$(ls -1 in/*.zip 2>/dev/null | wc -l)
if [ "$count_file" = 0 ]; then
  echo "No files found in /in"
  exit 0
fi
echo "Files in input dir (*.zip)"
count=0
for entry in $(ls in/*.zip); do
  count=$(($count + 1))
  name=$(basename in/$entry .zip)
  echo $count - $name
done
echo "....................."
echo "Enter a file name :"
read projectname
echo $projectname >level1/projectname.txt

if [ ! -f in/$projectname.zip ]; then
  echo "Can't find the file"
  exit 0
fi

filename=$(cat level1/projectname.txt)
bin/7za x in/${filename}.zip -otmp

for file in compatibility.zip file_contexts.bin; do
  if [ -f tmp/$file ]; then
    rm -rf tmp/$file
  fi
done

for dir in META-INF system; do
  if [ -d tmp/$dir ]; then
    rm -rf tmp/$dir
  fi
done

for part in odm oem product vendor system system_ext; do
  if [ -f tmp/$part.transfer.list ]; then
    if [ -f tmp/$part.new.dat.br ]; then
      bin/brotli --decompress tmp/$part.new.dat.br --o=tmp/$part.new.dat
      rm -rf tmp/$part.new.dat.br
    fi
    python bin/sdat2img.py tmp/$part.transfer.list tmp/$part.new.dat tmp/$part.img
    rm -rf tmp/$part.new.dat tmp/$part.transfer.list
    if [ -f tmp/$part.patch.dat ]; then
      rm -rf tmp/$part.patch.dat
    fi
    bin/img2simg tmp/$part.img tmp/${part}_simg.img
    cp tmp/${part}_simg.img tmp/$part.img
  fi
done

if [ -f tmp/dt.img ]; then
  cp tmp/dt.img level1/_aml_dtb.PARTITION
fi

for part in boot recovery logo dtbo vbmeta bootloader odm odm_ext oem product vendor system system_ext vendor_boot vbmeta_system; do
  if [ -f tmp/$part.img ]; then
    mv tmp/$part.img level1/$part.PARTITION
  fi
done

rm -rf tmp

cp bin/aml_sdc_burn.ini level1/aml_sdc_burn.ini

configname="level1/image.cfg"

echo "[LIST_NORMAL]" >$configname

if [ ! -f level1/DDR.USB ]; then
  echo "DDR.USB is missing, DDR.USB to level1 dir"
  read -p "Press enter to continue"
fi

if [ -f level1/DDR.USB ]; then
  echo "file=\"DDR.USB\"		main_type=\"USB\"		sub_type=\"DDR\"" >>$configname
fi

if [ ! -f level1/UBOOT.USB ]; then
  echo "UBOOT.USB is missing, UBOOT.USB to level1 dir"
  read -p "Press enter to continue"
fi

if [ -f level1/UBOOT.USB ]; then
  echo "file=\"UBOOT.USB\"		main_type=\"USB\"		sub_type=\"UBOOT\"" >>$configname
fi

if [ ! -f level1/aml_sdc_burn.UBOOT ]; then
  echo "aml_sdc_burn.UBOOT is missing, aml_sdc_burn.UBOOT to level1 dir"
  read -p "Press enter to continue"
fi

if [ -f level1/aml_sdc_burn.UBOOT ]; then
  echo "file=\"aml_sdc_burn.UBOOT\"		main_type=\"UBOOT\"		sub_type=\"aml_sdc_burn\"" >>$configname
fi

if [ -f level1/aml_sdc_burn.ini ]; then
  echo "file=\"aml_sdc_burn.ini\"		main_type=\"ini\"		sub_type=\"aml_sdc_burn\"" >>$configname
fi

if [ ! -f level1/meson1.PARTITION ]; then
  echo "meson1.PARTITION is missing, meson1.PARTITION to level1 dir"
  read -p "Press enter to continue"
fi

if [ -f level1/meson1.PARTITION ]; then
  echo "file=\"meson1.PARTITION\"		main_type=\"dtb\"		sub_type=\"meson1\"" >>$configname
fi

if [ ! -f level1/platform.conf ]; then
  echo "platform.conf is missing, platform.conf to level1 dir"
  read -p "Press enter to continue"
fi

if [ -f level1/platform.conf ]; then
  echo "file=\"platform.conf\"		main_type=\"conf\"		sub_type=\"platform\"" >>$configname
fi

for part in _aml_dtb boot recovery vendor_boot bootloader dtbo logo odm odm_ext oem product vendor system system_ext vbmeta vbmeta_system; do
  if [ -f level1/$part.PARTITION ]; then
    echo "file=\"$part.PARTITION\"		main_type=\"PARTITION\"		sub_type=\"$part\"" >>$configname
  fi
done

echo "[LIST_VERIFY]" >>$configname

bin/AmlImagePack -r level1/image.cfg level1 out/"$filename.img"
echo "Done."

./write_perm.sh

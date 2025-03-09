#!/usr/bin/sudo bash

version=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
if [ -z "$version" ]; then
  echo "No Python installed!"
fi

if [ ! -d level1 ]; then
  echo "Unpack level 1 first"
  exit 0
fi

if [ -f level1/super.PARTITION ]; then
  echo "super image isn't supported yet"
  exit 0
fi

if [ "$JAVA_HOME" != "" ]; then
  echo "Install Java first"
  exit 0
fi

if [ ! -d out ]; then
  mkdir out
fi

if [ -d tmp ]; then
  echo "Deleting out folder"
  rm -rf tmp && mkdir tmp
else
  mkdir tmp
fi

cp -r bin/fota/* tmp/

if [ -f level1/ddr.USB ]; then
  cp level1/ddr.USB tmp/bootloader.img
elif [ -f level1/DDR.USB ]; then
  cp level1/DDR.USB tmp/bootloader.img
fi

if [ -f level1/_aml_dtb.PARTITION ]; then
  cp level1/_aml_dtb.PARTITION tmp/dt.img
fi

for part in boot vendor_boot dtbo logo recovery vbmeta vbmeta_system; do
  if [ -f level1/${part}.PARTITION ]; then
    cp level1/${part}.PARTITION tmp/${part}.img
  fi
done

echo "....................."
echo "Compress with brolti?"
echo "input y default n: "
read compress

for part in system system_ext vendor product odm oem; do
  if [ -f level1/$part.PARTITION ]; then
    cp level1/$part.PARTITION tmp/$part.img
    python bin/img2sdat.py tmp/$part.img -o tmp -v 4 -p $part
    if [ $compress = "y" ]; then
      bin/brotli tmp/$part.new.dat --output=tmp/$part.new.dat.br -q 6 -w 24
      rm -rf tmp/$part.img tmp/$part.new.dat
    fi
    echo "Done compressing $part"
  fi
done

script="tmp/META-INF/com/google/android/updater-script"

echo "set_bootloader_env(\"upgrade_step\", \"3\");" >$script
echo "show_progress(0.650000, 0);" >>$script

for part in system system_ext vendor product odm odm_ext oem; do
  if [ -f tmp/$part.new.dat.br ]; then
    echo "ui_print(\"Patching $part image unconditionally...\");" >>$script
    echo "block_image_update(\"/dev/block/$part\", package_extract_file(\"$part.transfer.list\"), \"$part.new.dat.br\", \"$part.patch.dat\") ||" >>$script
    echo "  abort(\"E1001: Failed to update $part image.\");" >>$script
  elif [ -f tmp/$part.new.dat ]; then
    echo "ui_print(\"Patching $part image unconditionally...\");" >>$script
    echo "block_image_update(\"/dev/block/$part\", package_extract_file(\"$part.transfer.list\"), \"$part.new.dat\", \"$part.patch.dat\") ||" >>$script
    echo "  abort(\"E1001: Failed to update $part image.\");" >>$script
  fi
done

if [ -f tmp/logo.img ]; then
  echo "ui_print(\"update logo.img...\");" >>$script
  echo "package_extract_file(\"logo.img\", \"/dev/block/logo\");" >>$script
fi

if [ -f tmp/dtbo.img ]; then
  echo "ui_print(\"update dtbo.img...\");" >>$script
  echo "package_extract_file(\"dtbo.img\", \"/dev/block/dtbo\");" >>$script
fi

if [ -f tmp/dtb.img ]; then
  echo "ui_print(\"update dtb.img...\");" >>$script
  echo "backup_data_cache(dtb, /cache/recovery/);" >>$script
  echo "delete_file(\"/cache/recovery/dtb.img\");" >>$script
fi

if [ -f tmp/recovery.img ]; then
  echo "backup_data_cache(recovery, /cache/recovery/);" >>$script
  echo "ui_print(\"update recovery.img...\");" >>$script
  echo "package_extract_file(\"recovery.img\", \"/dev/block/recovery\");" >>$script
  echo "delete_file(\"/cache/recovery/recovery.img\");" >>$script
fi

if [ -f tmp/dt.img ]; then
  echo "write_dtb_image(package_extract_file(\"dt.img\"));" >>$script
fi

if [ -f tmp/vbmeta.img ]; then
  echo "ui_print(\"update vbmeta.img...\");" >>$script
  echo "package_extract_file(\"vbmeta.img\", \"/dev/block/vbmeta\");" >>$script
fi

if [ -f tmp/bootloader.img ]; then
  echo "ui_print(\"update bootloader.img...\");" >>$script
  echo "write_bootloader_image(package_extract_file(\"bootloader.img\"));" >>$script
fi

echo "if get_update_stage() == \"2\" then" >>$script
echo "format(\"ext4\", \"EMMC\", \"/dev/block/metadata\", \"0\", \"/metadata\");" >>$script
echo "format(\"ext4\", \"EMMC\", \"/dev/block/tee\", \"0\", \"/tee\");" >>$script
echo "wipe_cache();" >>$script
echo "set_update_stage(\"0\");" >>$script
echo "endif;" >>$script
echo "set_bootloader_env(\"upgrade_step\", \"1\");" >>$script
echo "set_bootloader_env(\"force_auto_update\", \"false\");" >>$script
echo "set_progress(1.000000);" >>$script

if [ -f out/update_tmp.zip ]; then
  rm -rf out/update_tmp.zip
fi

bin/7zz a out/update_tmp.zip ./tmp/*

filename=$(cat level1/projectname.txt)
echo "Signing with AOSP test keys..."
if [ -f out/$filename_fota.zip ]; then
  rm -rf out/$filename_fota.zip
fi
java -jar bin/zipsigner.jar bin/testkey.x509.pem bin/testkey.pk8 out/update_tmp.zip "out/${filename}_fota.zip"

rm -rf out/update_tmp.zip

if [ -d tmp ]; then
  rm -rf tmp
fi

./common/write_perm.sh
